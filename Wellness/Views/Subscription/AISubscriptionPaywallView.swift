//
//  AISubscriptionPaywallView.swift
//  Wellness
//
//  Paywall sheet shown whenever a non-subscriber taps an AI feature:
//    • AI Meal Planner (Hub → Brainstorm)
//    • AI Nutrition Coach (Analyze)
//    • AI when logging a meal (food photo analysis)
//    • AI when logging a workout (voice → workout parser)
//
//  Two tiers (annual primary, monthly anchor), an optional "skip free trial"
//  toggle, and a "Have a promo code?" entry point that opens Apple's native
//  offer-code redemption sheet for affiliate discounts.
//

import SwiftUI
import StoreKit

struct AISubscriptionPaywallView: View {

    /// Called when the purchase is successful (or an existing entitlement is
    /// discovered via Restore). The parent should dismiss the paywall and
    /// resume whatever action the user was trying to take.
    var onSubscribed: () -> Void

    /// Called when the user dismisses the paywall without subscribing.
    var onDismiss: () -> Void = {}

    @State private var store = AISubscriptionStore.shared
    @State private var selectedProductID: String = AISubscriptionStore.annualProductID
    @State private var skipFreeTrial: Bool = false
    @State private var showError = false

    @State private var showPromoSheet = false
    @State private var promoCodeInput: String = ""
    @State private var isRedeemingPromo = false

    @Environment(\.dismiss) private var dismiss

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let accent = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    header
                    featuresCard
                    tierPicker
                    trialToggle
                    ctaButtons
                    promoCodeRow
                    legalFooter
                }
                .padding(.horizontal, 24)
                .padding(.top, 36)
                .padding(.bottom, 32)
            }

            closeButton
                .padding(.top, 12)
                .padding(.trailing, 16)
        }
        .preferredColorScheme(.dark)
        .task {
            await store.loadProducts()
            await store.refreshEntitlement()
            if store.isSubscribed {
                onSubscribed()
                dismiss()
            }
        }
        .alert("Purchase Failed", isPresented: $showError) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .onChange(of: store.errorMessage) { _, msg in
            showError = (msg != nil && !msg!.isEmpty)
        }
        .sheet(isPresented: $showPromoSheet) {
            promoSheet
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.16))
                    .frame(width: 92, height: 92)
                Image(systemName: "sparkles")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(accent)
            }
            Text("Unlock AI")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("One subscription unlocks every AI feature in Macromaxxing.")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Features

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow(icon: "lightbulb.fill", color: gold,
                       title: "AI Meal Planner",
                       text: "Specific meal suggestions based on your remaining macro gaps for the day.")
            divider
            featureRow(icon: "wand.and.stars", color: accent,
                       title: "AI Nutrition Coach",
                       text: "Personalized debrief of your day — meals, macros, workouts, and timing.")
            divider
            featureRow(icon: "camera.fill", color: Color(red: 0.20, green: 0.85, blue: 0.75),
                       title: "AI Meal Logging",
                       text: "Snap a photo of your food and let AI estimate calories, protein, carbs, and fat.")
            divider
            featureRow(icon: "figure.run", color: Color(red: 0.30, green: 0.90, blue: 0.55),
                       title: "AI Workout Logging",
                       text: "Describe your workout out loud — AI fills in the name, duration, and calories burned.")
        }
        .padding(20)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(accent.opacity(0.22), lineWidth: 1))
    }

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
    }

    private func featureRow(icon: String, color: Color, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.16))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text(text)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Tier picker

    private var tierPicker: some View {
        VStack(spacing: 12) {
            tierRow(
                productID: AISubscriptionStore.annualProductID,
                title:     "Annual",
                headline:  annualHeadline,
                subline:   annualSubline,
                badge:     "BEST VALUE — SAVE 55%"
            )
            tierRow(
                productID: AISubscriptionStore.monthlyProductID,
                title:     "Monthly",
                headline:  monthlyHeadline,
                subline:   monthlySubline,
                badge:     nil
            )
        }
    }

    private func tierRow(productID: String,
                         title: String,
                         headline: String,
                         subline: String,
                         badge: String?) -> some View {
        let isSelected = selectedProductID == productID
        return Button {
            selectedProductID = productID
        } label: {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? accent : Color.white.opacity(0.25), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(accent).frame(width: 12, height: 12)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(gold)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(gold.opacity(0.15), in: Capsule())
                        }
                    }
                    Text(headline)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(subline)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(cardBg.opacity(isSelected ? 0.9 : 0.5),
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? accent : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var annualHeadline: String {
        let price = store.displayPrice(for: AISubscriptionStore.annualProductID)
        if store.isEligibleForIntroOffer && !skipFreeTrial {
            return "\(store.trialDayCount) days free, then \(price)/year"
        }
        return "\(price) / year"
    }

    private var annualSubline: String {
        // Approximate monthly equivalent for comparison.
        let priceDecimal: Decimal = store.annualProduct?.price ?? Decimal(69.99)
        let monthly = NSDecimalNumber(decimal: priceDecimal / Decimal(12)).doubleValue
        return String(format: "Just $%.2f/mo — billed annually", monthly)
    }

    private var monthlyHeadline: String {
        let price = store.displayPrice(for: AISubscriptionStore.monthlyProductID)
        if store.isEligibleForIntroOffer && !skipFreeTrial {
            return "\(store.trialDayCount) days free, then \(price)/month"
        }
        return "\(price) / month"
    }

    private var monthlySubline: String {
        "Cancel anytime"
    }

    // MARK: - Trial opt-out

    @ViewBuilder
    private var trialToggle: some View {
        // The skip-trial path is backed by a dedicated no-trial annual
        // product (Apple has no client-side way to refuse an intro offer),
        // so we only offer the toggle when annual is selected.
        if store.isEligibleForIntroOffer && selectedProductID == AISubscriptionStore.annualProductID {
            Toggle(isOn: $skipFreeTrial) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Skip free trial")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text("Start your annual subscription immediately — no 3-day trial.")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .tint(accent)
            .padding(.horizontal, 4)
        }
    }

    // MARK: - CTA

    private var ctaButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task { await handlePurchase() }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [accent, Color(red: 0.45, green: 0.30, blue: 0.95)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 54)
                    if store.isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(ctaText)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(store.isPurchasing || store.isRestoring)

            Button {
                Task { await handleRestore() }
            } label: {
                if store.isRestoring {
                    ProgressView().tint(.white.opacity(0.6))
                } else {
                    Text("Restore Purchases")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.60))
                }
            }
            .buttonStyle(.plain)
            .disabled(store.isPurchasing || store.isRestoring)
        }
    }

    private var ctaText: String {
        if store.isEligibleForIntroOffer && !skipFreeTrial {
            return "Start 3-Day Free Trial"
        }
        let price = store.displayPrice(for: selectedProductID)
        let period = store.period(for: selectedProductID)
        return "Subscribe — \(price)/\(period)"
    }

    // MARK: - Promo code

    private var promoCodeRow: some View {
        Button {
            promoCodeInput = ""
            showPromoSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("Have a promo code?")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(accent.opacity(0.85))
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private var promoSheet: some View {
        ZStack {
            pageBg.ignoresSafeArea()
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button { showPromoSheet = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.55))
                            .padding(10)
                            .background(cardBg, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                VStack(spacing: 8) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(accent)
                    Text("Enter Promo Code")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Got a code from an affiliate? Enter it here to get your discount. You'll finish redemption in Apple's secure sheet — no trial required.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                TextField("PROMOCODE", text: $promoCodeInput)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(accent.opacity(0.25), lineWidth: 1)
                    )

                Button {
                    Task { await handleRedeemPromo() }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accent)
                            .frame(height: 50)
                        if isRedeemingPromo {
                            ProgressView().tint(.white)
                        } else {
                            Text("Redeem Code")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isRedeemingPromo)

                Text("Don't have a code? Close this window and pick a plan above.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
    }

    // MARK: - Legal footer

    private var legalFooter: some View {
        VStack(spacing: 6) {
            Text(legalFooterText)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.38))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                Button {
                    if let url = URL(string: "https://www.macromaxxing.app/terms") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Terms of Service")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.50))
                }
                Button {
                    if let url = URL(string: "https://macromaxxing.app/privacy-policy") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Privacy Policy")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.50))
                }
            }
        }
    }

    private var legalFooterText: String {
        let price  = store.displayPrice(for: selectedProductID)
        let period = store.period(for: selectedProductID)
        if store.isEligibleForIntroOffer && !skipFreeTrial {
            return "Your \(store.trialDayCount)-day free trial begins after purchase. You won't be charged during the trial. After \(store.trialDayCount) days your subscription auto-renews at \(price)/\(period) and is charged to your Apple ID. Cancel anytime at least 24 hours before the end of the current period in your Apple ID settings — otherwise it renews automatically."
        }
        return "Payment charged to your Apple ID on confirmation. Subscription auto-renews at \(price)/\(period) unless canceled at least 24 hours before the end of the current period. Manage or cancel in your Apple ID settings."
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    onDismiss()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(10)
                        .background(cardBg, in: Circle())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Actions

    private func handlePurchase() async {
        // If the user picked annual and toggled "skip free trial", buy the
        // dedicated no-trial annual product so Apple does not auto-apply the
        // intro offer. Monthly and standard annual go through as-is.
        let productID: String = {
            if selectedProductID == AISubscriptionStore.annualProductID && skipFreeTrial {
                return AISubscriptionStore.annualNoTrialProductID
            }
            return selectedProductID
        }()
        let success = await store.purchase(productID: productID,
                                           skipFreeTrial: skipFreeTrial)
        if success {
            onSubscribed()
            dismiss()
        }
    }

    private func handleRestore() async {
        let success = await store.restore()
        if success {
            onSubscribed()
            dismiss()
        }
    }

    private func handleRedeemPromo() async {
        isRedeemingPromo = true
        defer { isRedeemingPromo = false }

        let code = promoCodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        await store.redeemPromoCode(stashedCode: code.isEmpty ? nil : code)

        // Close our custom sheet — Apple's redemption sheet will take over.
        showPromoSheet = false

        // Give Apple's sheet a beat to finalize the transaction, then see if
        // we're now subscribed.
        try? await Task.sleep(nanoseconds: 500_000_000)
        await store.refreshEntitlement()
        if store.isSubscribed {
            onSubscribed()
            dismiss()
        }
    }
}

#Preview {
    AISubscriptionPaywallView(onSubscribed: {})
}
