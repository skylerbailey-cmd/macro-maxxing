//
//  AISubscriptionStore.swift
//  Wellness
//
//  Handles the StoreKit 2 auto-renewable subscription that unlocks every AI
//  feature in the app: the AI Meal Planner (brainstorm), the AI Nutrition
//  Coach (Analyze), AI-assisted meal logging (food photo + voice parsing),
//  and AI-assisted workout logging (voice → workout parser).
//
//  Product type: Auto-renewable subscription
//  Product ID:   com.sbailey.Wellness.aiMonthly
//  Price:        $9.99 / month
//  Subscription group: "AI Features"
//
//  Setup required in App Store Connect:
//    1. App Store Connect → My Apps → Macro Maxxing → Subscriptions
//    2. Create a subscription group named "AI Features"
//    3. Add a subscription:
//         • Reference name: "AI Monthly"
//         • Product ID:     com.sbailey.Wellness.aiMonthly
//         • Duration:       1 Month
//         • Price:          $9.99 USD (Tier 10)
//    4. Fill in localizations (display name + description)
//    5. Submit for review with the next app binary
//    6. For local sandbox testing, add the product to Wellness.storekit and
//       select that file in the scheme's Run → Options → StoreKit Configuration.
//

import Foundation
import StoreKit

@MainActor
@Observable
final class AISubscriptionStore {

    // MARK: - Singleton

    static let shared = AISubscriptionStore()

    // MARK: - Product config

    static let productID = "com.sbailey.Wellness.aiMonthly"

    // MARK: - Observable state

    /// Loaded from the App Store once `loadProduct()` runs.
    var product: Product? = nil

    /// True while a purchase sheet is in flight.
    var isPurchasing: Bool = false

    /// True while `restore()` is running.
    var isRestoring: Bool = false

    /// Most recent user-facing error message (purchase or restore).
    var errorMessage: String? = nil

    /// True when the user currently has an active, unexpired entitlement to the
    /// AI subscription. This is the single source of truth that every AI entry
    /// point in the app checks before running.
    var isSubscribed: Bool = false

    /// When the current subscription expires (if any). Nil when not subscribed.
    var expirationDate: Date? = nil

    // MARK: - Private

    private var updatesTask: Task<Void, Never>? = nil

    private init() {
        // Begin listening for transaction updates from the App Store. This
        // covers purchases finalized outside the app (Ask to Buy, renewals,
        // Family Sharing, subscription changes) and must run for the lifetime
        // of the app per Apple's guidance. Since this is a singleton we never
        // cancel the task — it lives for the app's lifetime.
        updatesTask = Task { [weak self] in
            for await verification in Transaction.updates {
                guard let self else { return }
                await self.handle(verification: verification)
            }
        }
    }

    // MARK: - Public API

    /// Loads the subscription product from the App Store. Safe to call more
    /// than once — subsequent calls are no-ops once the product is cached.
    func loadProduct() async {
        guard product == nil else { return }
        do {
            let results = try await Product.products(for: [Self.productID])
            product = results.first
            if product == nil {
                AppLogger.log("[AISubscriptionStore] Product not found — check App Store Connect configuration")
            }
        } catch {
            AppLogger.log("[AISubscriptionStore] Failed to load product: \(error)")
        }
    }

    /// Recomputes `isSubscribed` / `expirationDate` from the user's current
    /// entitlements. Call once at launch (via `WellnessApp`) and whenever the
    /// paywall is shown so the UI reflects a brand-new restore.
    func refreshEntitlement() async {
        var active = false
        var expiry: Date? = nil

        for await verification in Transaction.currentEntitlements {
            guard case .verified(let transaction) = verification else { continue }
            guard transaction.productID == Self.productID else { continue }

            // An entitlement is active if it has no revocation date and either
            // no expiration date or one that's in the future.
            let notRevoked = transaction.revocationDate == nil
            let notExpired: Bool = {
                guard let exp = transaction.expirationDate else { return true }
                return exp > Date()
            }()

            if notRevoked && notExpired {
                active = true
                if let exp = transaction.expirationDate,
                   expiry == nil || exp > expiry! {
                    expiry = exp
                }
            }
        }

        self.isSubscribed   = active
        self.expirationDate = expiry
        AppLogger.log("[AISubscriptionStore] Entitlement refreshed — active=\(active) expires=\(expiry?.description ?? "nil")")
    }

    /// Initiates the App Store purchase flow. Returns `true` if the user is
    /// subscribed after the call completes (success or already-subscribed).
    @discardableResult
    func purchase() async -> Bool {
        guard let product else {
            errorMessage = "Subscription unavailable. Please try again later."
            return false
        }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    AppLogger.log("[AISubscriptionStore] Purchase verified — transaction \(transaction.id)")
                    await refreshEntitlement()
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

    /// Restores previous purchases. Use from the "Restore Purchases" button in
    /// Settings or from the paywall.
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

    /// Formatted price string from the App Store (e.g. "$9.99"). Falls back to
    /// a hard-coded string while the product is still loading so the paywall
    /// never shows an empty price.
    var priceString: String {
        product?.displayPrice ?? "$9.99"
    }

    /// Human-friendly billing period (e.g. "month"). Falls back to "month".
    var periodString: String {
        guard let unit = product?.subscription?.subscriptionPeriod.unit else { return "month" }
        switch unit {
        case .day:   return "day"
        case .week:  return "week"
        case .month: return "month"
        case .year:  return "year"
        @unknown default: return "month"
        }
    }

    // MARK: - Private helpers

    private func handle(verification: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = verification else { return }
        guard transaction.productID == Self.productID else { return }
        await transaction.finish()
        await refreshEntitlement()
    }
}
