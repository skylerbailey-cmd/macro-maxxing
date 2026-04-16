//
//  AISubscriptionStore.swift
//  Wellness
//
//  Handles the StoreKit 2 auto-renewable subscriptions that unlock every AI
//  feature in the app: the AI Meal Planner (brainstorm), the AI Nutrition
//  Coach (Analyze), AI-assisted meal logging (food photo + voice parsing),
//  and AI-assisted workout logging (voice → workout parser).
//
//  Product catalogue (all in subscription group "AI Features"):
//    • com.sbailey.Wellness.aiAnnual   — $69.99 / year   (primary)
//    • com.sbailey.Wellness.aiMonthly  — $12.99 / month  (anchor)
//
//  Introductory offer on BOTH products: 3-day free trial (P3D), one per
//  Apple ID across the subscription group — Apple enforces this server-side.
//
//  Promotional "offer codes" for affiliates (redeemed via Apple's native
//  code-redemption sheet):
//    • affiliate_annual_year1_discount  — $59 first year, then $69.99
//    • affiliate_monthly_first_discount — $9.99 first month, then $12.99
//
//  When a user redeems an affiliate code we record it in Firestore via
//  PromoCodeTrackingService so we can attribute commissions.
//
//  Setup required in App Store Connect — see the full checklist at the
//  bottom of this file.
//

import Foundation
import StoreKit
import UIKit

@MainActor
@Observable
final class AISubscriptionStore {

    // MARK: - Singleton

    static let shared = AISubscriptionStore()

    // MARK: - Product config

    static let annualProductID  = "com.sbailey.Wellness.aiAnnual"
    static let monthlyProductID = "com.sbailey.Wellness.aiMonthly"

    /// Legacy accessor — defaults to the monthly product so older call sites
    /// that read `AISubscriptionStore.productID` keep compiling. New code
    /// should reference the explicit IDs.
    static let productID = monthlyProductID

    static var allProductIDs: [String] {
        [annualProductID, monthlyProductID]
    }

    /// Products that grant AI entitlements. Used by the notification webhook
    /// and commission export to determine which transactions matter.
    static var entitlementProductIDs: Set<String> { Set(allProductIDs) }

    /// Known affiliate offer IDs — mirror what is configured in App Store
    /// Connect. Kept here so the store can classify transactions without a
    /// network call.
    enum AffiliateOffer: String, CaseIterable {
        case annualFirstYear  = "affiliate_annual_year1_discount"
        case monthlyFirstMonth = "affiliate_monthly_first_discount"
    }

    // MARK: - Observable state

    /// Both products, keyed by ID. Populated by `loadProducts()`.
    var products: [String: Product] = [:]

    /// True while a purchase sheet is in flight.
    var isPurchasing: Bool = false

    /// True while `restore()` is running.
    var isRestoring: Bool = false

    /// Most recent user-facing error message (purchase or restore).
    var errorMessage: String? = nil

    /// True when the user currently has an active, unexpired entitlement to
    /// any AI subscription product. Every AI entry point in the app checks
    /// this.
    var isSubscribed: Bool = false

    /// When the current subscription expires (if any). Nil when not
    /// subscribed.
    var expirationDate: Date? = nil

    /// Product ID of the user's currently-active subscription (if any).
    var activeProductID: String? = nil

    /// True when this Apple ID is still eligible for the 3-day free trial on
    /// the subscription group. Apple enforces this server-side — we mirror it
    /// locally so the paywall can show/hide trial copy.
    var isEligibleForIntroOffer: Bool = false

    // MARK: - Private

    private var updatesTask: Task<Void, Never>? = nil

    private init() {
        // Listen for transaction updates from the App Store for the lifetime of
        // the app. This covers purchases finalized outside the app (Ask to Buy,
        // renewals, Family Sharing, code redemptions) per Apple's guidance.
        updatesTask = Task { [weak self] in
            for await verification in Transaction.updates {
                guard let self else { return }
                await self.handle(verification: verification)
            }
        }
    }

    // MARK: - Loading

    /// Loads both products from the App Store. Safe to call more than once —
    /// already-cached products are not re-fetched.
    func loadProducts() async {
        if products.count < Self.allProductIDs.count {
            do {
                let results = try await Product.products(for: Set(Self.allProductIDs))
                for p in results { products[p.id] = p }
                if products.isEmpty {
                    AppLogger.log("[AISubscriptionStore] No products found — check App Store Connect configuration")
                }
            } catch {
                AppLogger.log("[AISubscriptionStore] Failed to load products: \(error)")
            }
        }
        await refreshIntroEligibility()
    }

    /// Legacy alias used by WellnessApp and older call sites.
    func loadProduct() async { await loadProducts() }

    /// Refreshes whether the Apple ID is still eligible for the 3-day trial.
    /// Eligibility is at the subscription-group level, so we only need to
    /// check it against one product.
    func refreshIntroEligibility() async {
        guard let sub = products[Self.annualProductID]?.subscription
                ?? products[Self.monthlyProductID]?.subscription else {
            isEligibleForIntroOffer = false
            return
        }
        let eligible = await sub.isEligibleForIntroOffer
        isEligibleForIntroOffer = eligible && sub.introductoryOffer != nil
    }

    /// Recomputes `isSubscribed` / `expirationDate` from current entitlements.
    func refreshEntitlement() async {
        var active = false
        var expiry: Date? = nil
        var activeID: String? = nil

        for await verification in Transaction.currentEntitlements {
            guard case .verified(let transaction) = verification else { continue }
            guard Self.allProductIDs.contains(transaction.productID) else { continue }

            let notRevoked = transaction.revocationDate == nil
            let notExpired: Bool = {
                guard let exp = transaction.expirationDate else { return true }
                return exp > Date()
            }()

            if notRevoked && notExpired {
                active = true
                activeID = transaction.productID
                if let exp = transaction.expirationDate,
                   expiry == nil || exp > expiry! {
                    expiry = exp
                }
            }
        }

        self.isSubscribed    = active
        self.expirationDate  = expiry
        self.activeProductID = activeID
        AppLogger.log("[AISubscriptionStore] Entitlement — active=\(active) product=\(activeID ?? "nil") expires=\(expiry?.description ?? "nil")")
    }

    // MARK: - Purchase

    /// Initiates the App Store purchase flow for the given product. Apple
    /// auto-applies the 3-day intro offer to eligible Apple IDs; we pass an
    /// appAccountToken so later notifications can be attributed back to the
    /// right Firebase UID.
    @discardableResult
    func purchase(productID: String) async -> Bool {
        guard let product = products[productID] else {
            errorMessage = "Subscription unavailable. Please try again later."
            return false
        }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let options: Set<Product.PurchaseOption> = [
                .appAccountToken(UUID())
            ]
            let result = try await product.purchase(options: options)

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    AppLogger.log("[AISubscriptionStore] Purchase verified — \(transaction.productID) tx=\(transaction.id)")
                    await refreshEntitlement()
                    await refreshIntroEligibility()
                    return isSubscribed
                case .unverified(_, let error):
                    errorMessage = "Purchase could not be verified: \(error.localizedDescription)"
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                errorMessage = "Purchase is pending approval (Ask to Buy)."
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.log("[AISubscriptionStore] Purchase error: \(error)")
            return false
        }
    }

    /// Legacy single-product purchase — defaults to monthly. New code should
    /// call `purchase(productID:)`.
    @discardableResult
    func purchase() async -> Bool {
        await purchase(productID: Self.monthlyProductID)
    }

    /// Restores previous purchases.
    @discardableResult
    func restore() async -> Bool {
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            if !isSubscribed {
                errorMessage = "No active subscription found to restore."
            }
            return isSubscribed
        } catch {
            errorMessage = "Could not restore purchases: \(error.localizedDescription)"
            AppLogger.log("[AISubscriptionStore] Restore error: \(error)")
            return false
        }
    }

    // MARK: - Promo codes (App Store Offer Codes)

    /// Presents Apple's native offer-code redemption sheet. The user types
    /// their affiliate code there — Apple validates it and creates the
    /// subscription with the discounted first period applied. We pick up the
    /// transaction via `Transaction.updates` and record it to Firestore.
    ///
    /// `stashedCode` is the code the user typed into our in-app field. Apple
    /// does not echo the raw code back on the resulting transaction, so we
    /// store it here and attach it to the Firestore record once the
    /// transaction lands.
    func redeemPromoCode(stashedCode: String?) async {
        PromoCodeTrackingService.shared.stashPendingCode(stashedCode)
        guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
                ?? UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            errorMessage = "Couldn't open the promo code sheet. Please try again."
            _ = PromoCodeTrackingService.shared.consumePendingCode()
            return
        }
        do {
            try await AppStore.presentOfferCodeRedeemSheet(in: scene)
        } catch {
            AppLogger.log("[AISubscriptionStore] Offer-code sheet error: \(error)")
            errorMessage = "Couldn't open the promo code sheet. Please try again."
            // Clear the stash — we never got a transaction to pair it with.
            _ = PromoCodeTrackingService.shared.consumePendingCode()
        }
    }

    // MARK: - Display helpers

    /// Product for the primary (annual) tier, once loaded.
    var annualProduct: Product? { products[Self.annualProductID] }

    /// Product for the secondary (monthly) tier, once loaded.
    var monthlyProduct: Product? { products[Self.monthlyProductID] }

    func displayPrice(for productID: String) -> String {
        products[productID]?.displayPrice ?? (productID == Self.annualProductID ? "$69.99" : "$12.99")
    }

    func period(for productID: String) -> String {
        guard let unit = products[productID]?.subscription?.subscriptionPeriod.unit else {
            return productID == Self.annualProductID ? "year" : "month"
        }
        switch unit {
        case .day:   return "day"
        case .week:  return "week"
        case .month: return "month"
        case .year:  return "year"
        @unknown default: return "month"
        }
    }

    /// Number of days in the intro trial (3) for display purposes.
    var trialDayCount: Int {
        guard let offer = (annualProduct ?? monthlyProduct)?.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return 3 }
        let period = offer.period
        switch period.unit {
        case .day:   return period.value
        case .week:  return period.value * 7
        case .month: return period.value * 30
        case .year:  return period.value * 365
        @unknown default: return period.value
        }
    }

    // MARK: - Legacy display helpers
    //
    // These power the existing monthly-oriented call sites in HomeView,
    // SettingsView, LogWorkoutSheet, AnalyzeView, FoodLogView etc. They keep
    // working against the monthly product so nothing breaks while the new
    // paywall rolls out.

    var priceString: String { displayPrice(for: Self.monthlyProductID) }

    var periodString: String { period(for: Self.monthlyProductID) }

    var headlineString: String {
        if isEligibleForIntroOffer {
            return "\(trialDayCount) days free, then \(priceString)/\(periodString)"
        }
        return "\(priceString) / \(periodString)"
    }

    var ctaString: String {
        if isEligibleForIntroOffer { return "Start Free Trial" }
        return "Subscribe — \(priceString)/mo"
    }

    // MARK: - Private helpers

    private func handle(verification: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = verification else { return }
        guard Self.allProductIDs.contains(transaction.productID) else { return }

        // Record the user ↔ subscription mapping on the user doc so the
        // App Store Server Notifications webhook can resolve events for
        // this sub without scanning collections.
        await PromoCodeTrackingService.shared.recordSubscriptionStart(
            productID:             transaction.productID,
            transactionID:         String(transaction.id),
            originalTransactionID: String(transaction.originalID),
            appAccountToken:       transaction.appAccountToken?.uuidString,
            offerID:               transaction.offerID,
            purchaseDate:          transaction.purchaseDate,
            originalPurchaseDate:  transaction.originalPurchaseDate
        )

        // Detect affiliate offer-code redemptions and write to Firestore.
        if let offerID = transaction.offerID,
           let offer = AffiliateOffer(rawValue: offerID) {
            let stashed = PromoCodeTrackingService.shared.consumePendingCode()
            await PromoCodeTrackingService.shared.recordRedemption(
                productID:             transaction.productID,
                offerID:               offer.rawValue,
                transactionID:         String(transaction.id),
                originalTransactionID: String(transaction.originalID),
                originalPurchaseDate:  transaction.originalPurchaseDate,
                code:                  stashed
            )
        }

        await transaction.finish()
        await refreshEntitlement()
        await refreshIntroEligibility()
    }
}

// MARK: - App Store Connect setup checklist
//
// 1. App Store Connect → My Apps → Macromaxxing → Subscriptions.
// 2. Make sure the subscription group is named "AI Features".
// 3. Monthly subscription (existing):
//      • Reference name:  AI Monthly
//      • Product ID:      com.sbailey.Wellness.aiMonthly
//      • Duration:        1 Month
//      • Price:           $12.99 USD (up from $9.99 — schedule a price
//                         change; existing subscribers keep their $9.99
//                         grandfathered rate unless you consent-prompt them)
//      • Introductory Offer:
//          - Type:         Free
//          - Duration:     3 Days
//          - Eligibility:  New subscribers
//      • Subscription Offer (for affiliates):
//          - Reference name:  Affiliate Monthly First Month
//          - Offer Code:      affiliate_monthly_first_discount
//          - Type:            Pay As You Go
//          - Duration:        1 Month
//          - Price:           $9.99 USD
//          - Eligibility:     New, Existing, Expired
//          - Create custom codes (e.g. INFLUENCER25) tied to this offer so
//            each affiliate gets their own distributable string.
// 4. Annual subscription (NEW — create this):
//      • Reference name:  AI Annual
//      • Product ID:      com.sbailey.Wellness.aiAnnual
//      • Duration:        1 Year
//      • Price:           $69.99 USD
//      • Introductory Offer:
//          - Type:         Free
//          - Duration:     3 Days
//          - Eligibility:  New subscribers
//      • Subscription Offer:
//          - Reference name:  Affiliate Annual First Year
//          - Offer Code:      affiliate_annual_year1_discount
//          - Type:            Pay As You Go
//          - Duration:        1 Year
//          - Price:           $59.00 USD
//          - Eligibility:     New, Existing, Expired
//          - Create custom codes for each affiliate.
// 5. Fill in localizations for each new offer (display name + description).
// 6. Submit the new annual subscription with the next app binary. Offer
//    codes don't require app review but the annual product does.
// 7. For sandbox testing, this file already mirrors the configuration above;
//    select Wellness.storekit in the scheme's Run → Options → StoreKit
//    Configuration.
//
