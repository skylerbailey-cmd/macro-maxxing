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

import SwiftUI

struct AISubscriptionPaywallView: View {

    /// Called when the purchase is successful (or an existing entitlement is
    /// discovered via Restore). The parent should dismiss the paywall and
    /// resume whatever action the user was trying to take.
    var onSubscribed: () -> Void

    /// Called when the user dismisses the paywall without subscribing.
    var onDismiss: () -> Void = {}

    @State private var store = AISubscriptionStore.shared
    @State private var showError = false

    @Environment(\.dismiss) private var dismiss

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let accent = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header

                    featuresCard

                    priceBox

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
            await store.loadProduct()
            await store.refreshEntitlement()
            // If the user already has the entitlement (e.g. they subscribed on
            // another device and we just hadn't refreshed yet) let them through
            // without making them tap again.
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
    }

    // MARK: - Sections

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

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow(
                icon:  "lightbulb.fill",
                color: gold,
                title: "AI Meal Planner",
                text:  "Get specific meal suggestions based on your remaining macro gaps for the day."
            )
            divider
            featureRow(
                icon:  "wand.and.stars",
                color: accent,
                title: "AI Nutrition Coach",
                text:  "Personalized nutritionist-level debrief of your day — meals, macros, workouts, and timing."
            )
            divider
            featureRow(
                icon:  "camera.fill",
                color: Color(red: 0.20, green: 0.85, blue: 0.75),
                title: "AI Meal Logging",
                text:  "Snap a photo of your food and let AI estimate calories, protein, carbs, and fat for you."
            )
            divider
            featureRow(
                icon:  "figure.run",
                color: Color(red: 0.30, green: 0.90, blue: 0.55),
                title: "AI Workout Logging",
                text:  "Describe your workout out loud — AI fills in the name, duration, and calories burned."
            )
        }
        .padding(20)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accent.opacity(0.22), lineWidth: 1)
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
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

    private var priceBox: some View {
        VStack(spacing: 6) {
            if store.isEligibleForIntroOffer {
                Text("7 DAYS FREE")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(gold.opacity(0.15), in: Capsule())
                Text("then \(store.priceString) / \(store.periodString)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("You won't be charged until your trial ends. Cancel anytime.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            } else {
                Text("\(store.priceString) / \(store.periodString)")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Auto-renews monthly. Cancel anytime in Settings.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.50))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(cardBg.opacity(0.6), in: RoundedRectangle(cornerRadius: 14))
    }

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
                        Text(store.ctaString)
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

    /// Apple requires the subscription terms disclosure on any paywall that
    /// includes a free trial — including length, price after trial, and the
    /// fact that it auto-renews. Reviewers reject paywalls that omit it.
    private var legalFooterText: String {
        if store.isEligibleForIntroOffer {
            return "Your 7-day free trial begins after purchase. You won't be charged during the trial. After 7 days your subscription auto-renews at \(store.priceString)/\(store.periodString) and is charged to your Apple ID. Cancel anytime at least 24 hours before the end of the current period in your Apple ID settings — otherwise it renews automatically."
        }
        return "Payment charged to your Apple ID. Subscription auto-renews at \(store.priceString)/\(store.periodString) unless canceled at least 24 hours before the end of the current period. Manage or cancel in your Apple ID settings."
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
        let success = await store.purchase()
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
}

#Preview {
    AISubscriptionPaywallView(onSubscribed: {})
}
