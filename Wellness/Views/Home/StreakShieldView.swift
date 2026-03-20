//
//  StreakShieldView.swift
//  Wellness
//
//  Shown when the user's streak breaks. Offers a one-time purchase to restore it.
//

import SwiftUI

struct StreakShieldView: View {

    let brokenStreak: Int
    let onRestore:  () -> Void   // called after successful purchase
    let onDismiss:  () -> Void   // called when user taps "No thanks"

    @State private var store = StreakShieldStore.shared
    @State private var showError = false

    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)
    private let orange = Color(red: 1.00, green: 0.55, blue: 0.10)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Flame icon
                ZStack {
                    Circle()
                        .fill(orange.opacity(0.15))
                        .frame(width: 96, height: 96)
                    Text("🔥")
                        .font(.system(size: 52))
                }
                .padding(.top, 48)

                // Headline
                Text("Streak Lost")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 20)

                Text("Your \(brokenStreak)-day streak ended.")
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.top, 6)

                // Detail card
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(gold)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Streak Shield")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("Restore your streak back to \(brokenStreak) days and keep your progress alive.")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.60))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding()
                    .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(gold.opacity(0.25), lineWidth: 1)
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
                                    colors: [gold, orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 54)

                        if store.isPurchasing {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Restore Streak — \(store.priceString)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.black)
                        }
                    }
                }
                .disabled(store.isPurchasing)
                .padding(.horizontal, 28)

                // Dismiss button
                Button("No thanks, I'll start over") {
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

    private func handlePurchase() async {
        let success = await store.purchase()
        if success {
            onRestore()
        }
    }
}

#Preview {
    StreakShieldView(brokenStreak: 7, onRestore: {}, onDismiss: {})
}
