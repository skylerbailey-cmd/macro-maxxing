//
//  AuraPopupView.swift
//  Wellness
//

import SwiftUI

struct AuraPopupView: View {
    let award:      UserSettings.AuraAward
    let auraLevel:  Int
    let auraTitle:  String
    let totalPoints: Int
    let onDismiss:  () -> Void

    @State private var scale:   CGFloat = 0.3
    @State private var opacity: Double  = 0
    @State private var bgOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(bgOpacity * 0.60)
                .ignoresSafeArea()
                .onTapGesture { animatedDismiss() }

            VStack(spacing: 14) {
                // Star burst
                Text("⭐")
                    .font(.system(size: 60))

                // Points earned
                Text("+\(award.points) Aura")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.85, blue: 0.2),
                                     Color(red: 1.0, green: 0.55, blue: 0.15)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )

                Text(award.reason)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                // Current standing
                VStack(spacing: 4) {
                    Text("Level \(auraLevel)\(auraTitle.isEmpty ? "" : " · \(auraTitle)")")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.0))
                    Text("\(totalPoints) total aura pts")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.40))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 16)
                .background(Color(red: 0.13, green: 0.10, blue: 0.22))
                .cornerRadius(10)

                // Hype message
                Text(award.message)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Text("tap to dismiss")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.25))
                    .padding(.top, 4)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.16, green: 0.10, blue: 0.28),
                                 Color(red: 0.07, green: 0.04, blue: 0.14)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .shadow(color: Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.35), radius: 30)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.40), lineWidth: 1.5)
            )
            .padding(.horizontal, 28)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.15)) { bgOpacity = 1 }
            withAnimation(.spring(duration: 0.50, bounce: 0.40).delay(0.05)) {
                scale = 1.0; opacity = 1.0
            }
            Task {
                try? await Task.sleep(for: .seconds(3.5))
                animatedDismiss()
            }
        }
    }

    private func animatedDismiss() {
        withAnimation(.easeIn(duration: 0.15)) {
            scale = 0.85; opacity = 0; bgOpacity = 0
        }
        Task {
            try? await Task.sleep(for: .seconds(0.2))
            onDismiss()
        }
    }
}
