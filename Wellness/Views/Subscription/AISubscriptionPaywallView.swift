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
//  Two tiers (annual primary, monthly anchor) with a prominent inline promo
//  code field. When a user enters a promo code we optimistically show the
//  affiliate discount (strikethrough original price + % saved) on the
//  selected tier, then copy the code to the clipboard and present Apple's
//  offer-code redemption sheet on purchase so the user can paste in one tap.
//

import SwiftUI
import StoreKit
import UIKit

struct AISubscriptionPaywallView: View {

    /// Called when the purchase is successful (or an existing entitlement is
    /// discovered via Restore).
    var onSubscribed: () -> Void

    /// Called when the user dismisses the paywall without subscribing.
    var onDismiss: () -> Void = {}

    @State private var store = AISubscriptionStore.shared
    @State private var selectedProductID: String = AISubscriptionStore.annualProductID
    @State private var showError = false

    @State private var promoCodeInput: String = ""
    @State private var appliedPromoCode: String? = nil
    @State private var showPromoField: Bool = false
    @State private var isRedeemingPromo = false
    @State private var isValidatingPromo = false
    @State private var promoFieldError: String? = nil

    /// Currently-highlighted AI feature in the interactive row. Starts on the
    /// Meal Planner so the user lands on a pulsing gold outline that draws
    /// the eye to the most valuable feature in the bundle.
    @State private var selectedFeatureID: String = "mealPlanner"
    /// Drives the pulsing opacity on the selected feature's gold ring.
    @State private var featurePulse: Bool = false

    @Environment(\.dismiss) private var dismiss

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let accent = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)

    // Known affiliate pricing — mirrors what's configured in App Store Connect.
    // Used to show a live discount preview when the user applies a promo code
    // before Apple's redemption sheet appears.
    private let annualAffiliatePrice:  Decimal = 59.00
    private let monthlyAffiliatePrice: Decimal = 9.99

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    header
                    compactFeaturesRow
                    promoCodeSection
                    tierPicker
                    ctaButtons
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
        .alert(alertTitle, isPresented: $showError) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .onChange(of: store.errorMessage) { _, msg in
            showError = (msg != nil && !msg!.isEmpty)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.16))
                    .frame(width: 72, height: 72)
                Image(systemName: "sparkles")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(accent)
            }
            Text("Unlock AI")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Every AI feature in Macromaxxing — one subscription.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Compact features row

    /// The four AI features shown as interactive pills. Tapping one swaps
    /// the description box below the row and moves the pulsing gold outline
    /// onto the tapped pill.
    private struct AIFeatureCopy: Identifiable {
        let id: String
        let icon: String
        let color: Color
        let title: String
        let description: String
    }

    private var features: [AIFeatureCopy] {
        [
            AIFeatureCopy(
                id: "mealPlanner",
                icon: "lightbulb.fill",
                color: gold,
                title: "Meal Planner",
                description: "Tell the AI what you've eaten today and it suggests specific meals to close your remaining protein, carb, and fat gaps — tailored to your diet, calorie budget, and taste."
            ),
            AIFeatureCopy(
                id: "coach",
                icon: "wand.and.stars",
                color: accent,
                title: "Coach",
                description: "End-of-day debrief from a nutritionist-level AI: grades your meals, macros, workout timing, and tells you exactly what to adjust tomorrow."
            ),
            AIFeatureCopy(
                id: "foodScan",
                icon: "camera.fill",
                color: Color(red: 0.20, green: 0.85, blue: 0.75),
                title: "Food Scan",
                description: "Snap a photo of any meal and the AI estimates calories, protein, carbs, and fat in seconds — no manual lookup, no barcode hunting."
            ),
            AIFeatureCopy(
                id: "workouts",
                icon: "figure.run",
                color: Color(red: 0.30, green: 0.90, blue: 0.55),
                title: "Workouts",
                description: "Describe your workout out loud and the AI fills in the exercise name, duration, and calories burned — log a whole session in under 10 seconds."
            ),
        ]
    }

    private var compactFeaturesRow: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(features) { feature in
                    featurePill(feature: feature)
                }
            }
            featureDescriptionBox
        }
        .onAppear {
            // Kick off the pulsing animation on the initially-selected pill.
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                featurePulse = true
            }
        }
    }

    private func featurePill(feature: AIFeatureCopy) -> some View {
        let isSelected = feature.id == selectedFeatureID
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFeatureID = feature.id
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(feature.color.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: feature.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(feature.color)
                }
                Text(feature.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(isSelected ? 1.0 : 0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                cardBg.opacity(isSelected ? 0.95 : 0.6),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? gold.opacity(featurePulse ? 1.0 : 0.35)
                                   : Color.white.opacity(0.04),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            // Subtle lift on the selected pill so the gold ring pops.
            .shadow(
                color: isSelected ? gold.opacity(featurePulse ? 0.45 : 0.15) : .clear,
                radius: isSelected ? 8 : 0,
                x: 0, y: 0
            )
        }
        .buttonStyle(.plain)
    }

    /// Description box that sits directly below the feature row. Updates
    /// whenever the user taps a different pill. Content transitions with a
    /// crossfade so the change feels intentional.
    private var featureDescriptionBox: some View {
        let feature = features.first { $0.id == selectedFeatureID } ?? features[0]
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: feature.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(feature.color)
                .frame(width: 20, alignment: .leading)
            Text(feature.description)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardBg.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(feature.color.opacity(0.22), lineWidth: 1)
        )
        .id(feature.id) // forces the transition on selection change
        .transition(.opacity)
    }

    // MARK: - Promo code (inline, prominent)

    @ViewBuilder
    private var promoCodeSection: some View {
        if let code = appliedPromoCode {
            // Applied state: show confirmation chip
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Promo \(code) applied")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Discount will be confirmed at checkout.")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Button("Remove") {
                    appliedPromoCode = nil
                    promoCodeInput = ""
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(accent)
            }
            .padding(14)
            .background(gold.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(gold.opacity(0.35), lineWidth: 1))

        } else if showPromoField {
            // Entry state: text field + apply
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    TextField("ENTER CODE", text: $promoCodeInput)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(
                            promoFieldError != nil
                                ? Color.red.opacity(0.6)
                                : accent.opacity(0.3),
                            lineWidth: 1))
                        .onChange(of: promoCodeInput) { _, _ in
                            // Clear stale error as soon as the user edits.
                            promoFieldError = nil
                        }

                    Button {
                        Task { await applyPromoCode() }
                    } label: {
                        if isValidatingPromo {
                            ProgressView()
                                .tint(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 11)
                        } else {
                            Text("Apply")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 11)
                        }
                    }
                    .background(accent, in: RoundedRectangle(cornerRadius: 10))
                    .disabled(
                        isValidatingPromo
                        || promoCodeInput.trimmingCharacters(in: .whitespaces).isEmpty
                    )
                    .opacity(
                        promoCodeInput.trimmingCharacters(in: .whitespaces).isEmpty
                        ? 0.5 : 1
                    )
                }
                if let err = promoFieldError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 11))
                        Text(err)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.red.opacity(0.85))
                    .transition(.opacity)
                }
            }
        } else {
            // Collapsed state: prominent button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showPromoField = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Have a promo code?")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(accent.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private func applyPromoCode() async {
        let code = promoCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else { return }
        promoFieldError   = nil
        isValidatingPromo = true
        defer { isValidatingPromo = false }

        let result = await PromoCodeTrackingService.shared.validatePromoCode(code)
        switch result {
        case .valid(let productID, _):
            // Switch the picker to the product the code is actually for so
            // the strikethrough price + savings line apply to the right tier.
            withAnimation(.easeInOut(duration: 0.2)) {
                if AISubscriptionStore.allProductIDs.contains(productID) {
                    selectedProductID = productID
                }
                appliedPromoCode = code
                promoCodeInput   = code
            }
        case .unknown:
            promoFieldError = "We don't recognize \"\(code)\". Double-check spelling."
        case .inactive:
            promoFieldError = "\"\(code)\" has been deactivated."
        case .expired:
            promoFieldError = "\"\(code)\" has expired."
        case .error:
            promoFieldError = "Couldn't check the code right now. Try again."
        }
    }

    // MARK: - Tier picker

    private var tierPicker: some View {
        VStack(spacing: 10) {
            tierRow(productID: AISubscriptionStore.annualProductID,
                    title:     "Annual",
                    badge:     "BEST VALUE")
            tierRow(productID: AISubscriptionStore.monthlyProductID,
                    title:     "Monthly",
                    badge:     nil)
        }
    }

    private func tierRow(productID: String,
                         title: String,
                         badge: String?) -> some View {
        let isSelected = selectedProductID == productID
        let hasPromo   = appliedPromoCode != nil

        return Button {
            selectedProductID = productID
        } label: {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? accent : Color.white.opacity(0.25), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(accent).frame(width: 12, height: 12)
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .tracking(1.1)
                                .foregroundStyle(gold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(gold.opacity(0.15), in: Capsule())
                        }
                    }
                    priceLine(productID: productID, hasPromo: hasPromo)
                    if productID == AISubscriptionStore.annualProductID,
                       let vsMonthly = vsMonthlySavings(hasPromo: hasPromo) {
                        Text(vsMonthly)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(gold)
                    }
                    Text(trialLine(productID: productID, hasPromo: hasPromo))
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer(minLength: 0)
                if hasPromo {
                    Text(discountBadge(for: productID))
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(gold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(gold.opacity(0.18), in: Capsule())
                }
            }
            .padding(14)
            .background(cardBg.opacity(isSelected ? 0.9 : 0.5),
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? accent : Color.white.opacity(0.08),
                            lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func priceLine(productID: String, hasPromo: Bool) -> some View {
        let period = store.period(for: productID)
        let original = store.displayPrice(for: productID)
        if hasPromo {
            HStack(spacing: 6) {
                Text(original)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                    .strikethrough()
                Text("\(discountedPriceString(for: productID)) / \(period)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(gold)
            }
        } else {
            Text("\(original) / \(period)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private func trialLine(productID: String, hasPromo: Bool) -> String {
        let period = store.period(for: productID)
        if hasPromo {
            return "Affiliate pricing applies to your first \(period). Renews at regular price."
        }
        if store.isEligibleForIntroOffer {
            return "\(store.trialDayCount) days free, then charged."
        }
        return "Cancel anytime."
    }

    /// The total yearly savings when picking annual over paying monthly for
    /// 12 months. Shown on the annual tier regardless of promo state — but
    /// the number grows when an affiliate code is applied because the
    /// annual year-1 price drops to $59 while monthly stays at $12.99/mo.
    ///
    /// Returns `nil` if we can't compute it (products haven't loaded yet).
    private func vsMonthlySavings(hasPromo: Bool) -> String? {
        guard let monthlyPrice = store.monthlyProduct?.price else { return nil }
        let annualCost: Decimal = hasPromo
            ? annualAffiliatePrice
            : (store.annualProduct?.price ?? Decimal(69.99))
        let monthlyYearCost = monthlyPrice * Decimal(12)
        let savings = monthlyYearCost - annualCost
        guard savings > 0 else { return nil }
        let savingsStr = formatUSD(savings)
        let pct = percentInt(savings: savings, base: monthlyYearCost)
        return "Save \(savingsStr)/yr vs monthly (\(pct)% off)"
    }

    private func percentInt(savings: Decimal, base: Decimal) -> Int {
        let s = NSDecimalNumber(decimal: savings).doubleValue
        let b = NSDecimalNumber(decimal: base).doubleValue
        guard b > 0 else { return 0 }
        return Int((s / b) * 100.0)
    }

    private func discountedPriceString(for productID: String) -> String {
        let price = productID == AISubscriptionStore.annualProductID
                    ? annualAffiliatePrice : monthlyAffiliatePrice
        return formatUSD(price)
    }

    private func discountBadge(for productID: String) -> String {
        let originalDecimal: Decimal = productID == AISubscriptionStore.annualProductID
            ? (store.annualProduct?.price ?? Decimal(69.99))
            : (store.monthlyProduct?.price ?? Decimal(12.99))
        let discounted = productID == AISubscriptionStore.annualProductID
            ? annualAffiliatePrice : monthlyAffiliatePrice
        let originalD  = NSDecimalNumber(decimal: originalDecimal).doubleValue
        let discountD  = NSDecimalNumber(decimal: discounted).doubleValue
        guard originalD > 0 else { return "SAVE" }
        let pct = Int(((originalD - discountD) / originalD) * 100.0)
        return "SAVE \(pct)%"
    }

    private func formatUSD(_ d: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f.string(from: NSDecimalNumber(decimal: d)) ?? "$\(d)"
    }

    // MARK: - CTA

    private var ctaButtons: some View {
        VStack(spacing: 10) {
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
                    if store.isPurchasing || isRedeemingPromo {
                        ProgressView().tint(.white)
                    } else {
                        Text(ctaText)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(store.isPurchasing || store.isRestoring || isRedeemingPromo)

            Button {
                onDismiss()
                dismiss()
            } label: {
                Text("No thanks, I don't want this offer")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
                    .underline()
            }
            .buttonStyle(.plain)
            .disabled(store.isPurchasing || store.isRestoring || isRedeemingPromo)

            Button {
                Task { await handleRestore() }
            } label: {
                if store.isRestoring {
                    ProgressView().tint(.white.opacity(0.6))
                } else {
                    Text("Restore Purchases")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.42))
                }
            }
            .buttonStyle(.plain)
            .disabled(store.isPurchasing || store.isRestoring)
        }
    }

    private var ctaText: String {
        if appliedPromoCode != nil {
            return "Redeem Promo & Subscribe"
        }
        if store.isEligibleForIntroOffer {
            return "Start 3-Day Free Trial"
        }
        let price = store.displayPrice(for: selectedProductID)
        let period = store.period(for: selectedProductID)
        return "Subscribe — \(price)/\(period)"
    }

    // MARK: - Legal footer

    private var legalFooter: some View {
        VStack(spacing: 6) {
            Text(legalFooterText)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.38))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 14) {
                Button {
                    if let url = URL(string: "https://www.macromaxxing.app/terms") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Terms of Service")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.48))
                }
                Button {
                    if let url = URL(string: "https://macromaxxing.app/privacy-policy") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Privacy Policy")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.48))
                }
            }
        }
    }

    private var legalFooterText: String {
        let price  = store.displayPrice(for: selectedProductID)
        let period = store.period(for: selectedProductID)
        if appliedPromoCode != nil {
            return "Promo pricing applies to your first \(period) when the code is accepted in Apple's secure redemption sheet. After that your subscription auto-renews at \(price)/\(period) unless canceled at least 24 hours before the end of the current period."
        }
        if store.isEligibleForIntroOffer {
            return "Your \(store.trialDayCount)-day free trial begins after purchase. You won't be charged during the trial. After \(store.trialDayCount) days your subscription auto-renews at \(price)/\(period). Cancel anytime in Apple ID settings at least 24 hours before the end of the current period."
        }
        return "Payment charged to your Apple ID on confirmation. Auto-renews at \(price)/\(period) unless canceled 24+ hours before the end of the current period."
    }

    /// Chooses a contextual alert title based on the current error. Promo
    /// failures get their own heading so users don't see "Purchase Failed"
    /// when the real issue was just an invalid code.
    private var alertTitle: String {
        if let msg = store.errorMessage, msg.contains("could not be redeemed") {
            return "Invalid Promo Code"
        }
        return "Purchase Failed"
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
        if let code = appliedPromoCode {
            await redeemPromo(code: code)
            return
        }
        let success = await store.purchase(productID: selectedProductID)
        if success {
            onSubscribed()
            dismiss()
        }
    }

    private func redeemPromo(code: String) async {
        isRedeemingPromo = true
        defer { isRedeemingPromo = false }

        // Copy to the pasteboard so the user can paste into Apple's sheet in
        // a single tap — Apple's redemption UI does not accept a pre-filled
        // code via API, but iOS 16+ shows a paste-to-field suggestion.
        UIPasteboard.general.string = code

        // Snapshot subscription state before presenting Apple's sheet so we
        // can detect whether anything actually changed.
        let wasSubscribedBefore = store.isSubscribed

        await store.redeemPromoCode(stashedCode: code)

        // Apple's sheet is modal and `presentOfferCodeRedeemSheet` returns
        // before the transaction finalises. Poll entitlement for a few
        // seconds so we catch a successful redemption that lands after the
        // sheet dismisses.
        var redeemed = false
        for _ in 0..<8 {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await store.refreshEntitlement()
            if store.isSubscribed && !wasSubscribedBefore {
                redeemed = true
                break
            }
        }

        if redeemed {
            onSubscribed()
            dismiss()
        } else {
            // Code was invalid / expired / Apple rejected it / user cancelled.
            // Clear the optimistic discount UI and surface a clear error.
            appliedPromoCode = nil
            promoCodeInput   = code  // keep what they typed so they can edit
            store.errorMessage =
                "\"\(code)\" could not be redeemed. Please double-check the code, make sure it hasn't expired, and try again."
        }
    }

    private func handleRestore() async {
        let success = await store.restore()
        if success {
            onSubscribed()
            dismiss()
        }
    }
}

#Preview {
    AISubscriptionPaywallView(onSubscribed: {})
}
