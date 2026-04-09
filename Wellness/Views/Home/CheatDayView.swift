//
//  CheatDayView.swift
//  Wellness
//
//  Shown when the user taps the Cheat Day button on the hub.
//  Offers a $0.99 purchase to extend their streak without logging food for the day.
//

import SwiftUI

struct CheatDayView: View {

    let currentStreak: Int
    let onPurchased: () -> Void   // called after successful purchase
    let onDismiss:   () -> Void   // called when user taps dismiss

    @State private var store = CheatDayStore.shared
    @State private var showError = false

    private let teal   = Color(red: 0.20, green: 0.85, blue: 0.75)
    private let cyan   = Color(red: 0.10, green: 0.65, blue: 0.90)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Icon
                ZStack {
                    Circle()
                        .fill(teal.opacity(0.15))
                        .frame(width: 96, height: 96)
                    Text("\u{1F3D6}\u{FE0F}")
                        .font(.system(size: 52))
                }
                .padding(.top, 48)

                // Headline
                Text("Cheat Day")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 20)

                Text("Keep your \(currentStreak)-day streak alive.")
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.top, 6)

                // Detail cards
                VStack(spacing: 12) {
                    detailRow(
                        icon: "flame.fill",
                        iconColor: .orange,
                        title: "Streak Protected",
                        subtitle: "Today counts as meeting your macro goals — your streak won't break."
                    )

                    detailRow(
                        icon: "fork.knife",
                        iconColor: teal,
                        title: "No Logging Required",
                        subtitle: "Take a break from tracking. Enjoy your day off without the stress."
                    )

                    detailRow(
                        icon: "calendar.badge.checkmark",
                        iconColor: cyan,
                        title: "Once Per Day",
                        subtitle: "Use a cheat day when life gets busy, you're traveling, or you just need a rest day from tracking."
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
                                    colors: [teal, cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 54)

                        if store.isPurchasing {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Use Cheat Day — \(store.priceString)")
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
                .stroke(teal.opacity(0.25), lineWidth: 1)
        )
    }

    private func handlePurchase() async {
        let success = await store.purchase()
        if success {
            onPurchased()
        }
    }
}

#Preview {
    CheatDayView(currentStreak: 12, onPurchased: {}, onDismiss: {})
}
