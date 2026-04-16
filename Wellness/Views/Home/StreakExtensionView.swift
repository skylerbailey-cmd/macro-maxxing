//
//  StreakExtensionView.swift
//  Wellness
//
//  Shown when the user taps the Streak Extension button on the hub.
//  Offers a $4.99 purchase to extend their streak for 7 days without logging.
//

import SwiftUI

struct StreakExtensionView: View {

    let currentStreak: Int
    let onPurchased: () -> Void
    let onDismiss:   () -> Void

    @State private var store = StreakExtensionStore.shared
    @State private var showError = false

    private let amber  = Color(red: 1.00, green: 0.65, blue: 0.10)
    private let orange = Color(red: 1.00, green: 0.45, blue: 0.05)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)
    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Icon
                ZStack {
                    Circle()
                        .fill(amber.opacity(0.15))
                        .frame(width: 96, height: 96)
                    Text("\u{1F525}")
                        .font(.system(size: 52))
                }
                .padding(.top, 48)

                // Headline
                Text("Streak Extension")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 20)

                Text("Keep your \(currentStreak)-day streak alive for 7 more days.")
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
                    .padding(.horizontal, 28)

                // Detail cards
                VStack(spacing: 12) {
                    detailRow(
                        icon: "flame.fill",
                        iconColor: amber,
                        title: "7 Days Protected",
                        subtitle: "Your streak stays alive for the next 7 days — no logging required."
                    )

                    detailRow(
                        icon: "suitcase.fill",
                        iconColor: orange,
                        title: "Perfect for Travel",
                        subtitle: "Going on vacation, recovering from illness, or just need a full week off from tracking."
                    )

                    detailRow(
                        icon: "bell.badge.fill",
                        iconColor: ThemeStore.shared.accent,
                        title: "Expiration Reminder",
                        subtitle: "You'll get a notification when your extension is about to expire so you can start logging again."
                    )
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)

                Spacer()

                // Purchase button
                Button {
                    Task { await handlePurchase() }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [amber, orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 54)

                        if store.isPurchasing {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Extend Streak — \(store.priceString)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.black)
                        }
                    }
                }
                .disabled(store.isPurchasing)
                .padding(.horizontal, 28)

                // Dismiss button
                Button("Never mind") {
                    onDismiss()
                }
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.45))
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .task { await store.loadProduct() }
        .alert("Purchase Failed", isPresented: $showError) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .onChange(of: store.errorMessage) { _, msg in
            showError = msg != nil
        }
    }

    private func detailRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(iconColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.60))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(amber.opacity(0.25), lineWidth: 1)
        )
    }

    private func handlePurchase() async {
        let success = await store.purchase()
        if success {
            onPurchased()
        }
    }
}
