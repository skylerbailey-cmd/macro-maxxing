//
//  ProfileShareCardView.swift
//  Wellness
//

import SwiftUI
import UIKit

// MARK: - Data

struct ProfileShareCardData {
    let displayName:     String
    let username:        String
    let auraLevel:       Int
    let auraPoints:      Int
    let auraTitleString: String
    let profileImage:    UIImage?
    var balanceScore:    Int?    = nil
}

// MARK: - Card  (360 × 640 pt → 1080 × 1920 px at 3×)

struct ProfileShareCardView: View {
    let data: ProfileShareCardData

    private var purpl: Color { ThemeStore.shared.accent }
    private var gold: Color { ThemeStore.shared.accent }
    private let neon   = Color(red: 0.35, green: 1.00, blue: 0.60)
    private let bg     = Color(red: 0.03, green: 0.03, blue: 0.04)
    private let cardBg = Color(red: 0.08, green: 0.08, blue: 0.10)

    private var scoreColor: Color {
        guard let s = data.balanceScore else { return purpl }
        return s >= 75 ? neon : s >= 50 ? gold : Color(red: 1.0, green: 0.35, blue: 0.35)
    }

    private var scoreLabel: String {
        guard let s = data.balanceScore else { return "" }
        return s >= 75 ? "Dialed In" : s >= 50 ? "On Track" : "Building"
    }

    var body: some View {
        ZStack {
            bg

            // Subtle ambient glow behind avatar
            Circle()
                .fill(purpl.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(y: -60)

            VStack(spacing: 0) {
                Spacer()

                // Avatar
                avatarView
                    .overlay(Circle().stroke(
                        AngularGradient(colors: [gold, purpl, neon, gold], center: .center),
                        lineWidth: 3
                    ))
                    .shadow(color: purpl.opacity(0.40), radius: 18)

                Spacer().frame(height: 22)

                // Name
                Text(data.displayName)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                // Username
                if !data.username.isEmpty {
                    Text("@\(data.username)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.top, 4)
                }

                Spacer().frame(height: 24)

                // Level pill
                if data.auraLevel > 0 {
                    HStack(spacing: 6) {
                        Text("Lv \(data.auraLevel)")
                            .font(.system(size: 12, weight: .black))
                            .tracking(1)
                            .foregroundStyle(purpl)
                        Text("·")
                            .foregroundStyle(.white.opacity(0.30))
                        Text(data.auraTitleString.uppercased())
                            .font(.system(size: 12, weight: .black))
                            .tracking(2)
                            .foregroundStyle(gold)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(cardBg)
                    .overlay(Capsule().stroke(purpl.opacity(0.25), lineWidth: 1))
                    .clipShape(Capsule())

                    Spacer().frame(height: 16)
                }

                // Balance Score
                if let score = data.balanceScore {
                    VStack(spacing: 4) {
                        Text("\(score)")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(scoreColor)
                        Text(scoreLabel.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .tracking(3)
                            .foregroundStyle(scoreColor.opacity(0.70))
                        Text("Balance Score")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.30))
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(cardBg)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(scoreColor.opacity(0.20), lineWidth: 1))
                    .cornerRadius(14)

                    Spacer().frame(height: 28)
                } else {
                    Spacer().frame(height: 8)
                }

                // CTA
                VStack(spacing: 3) {
                    Text("Follow me on")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.40))
                    Text("Macromaxxing")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(purpl)
                }

                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .frame(width: 360, height: 640)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var avatarView: some View {
        if let img = data.profileImage {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: 110, height: 110)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(purpl.opacity(0.18))
                .frame(width: 110, height: 110)
                .overlay {
                    Text(String(data.displayName.prefix(1)).uppercased())
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(purpl)
                }
        }
    }
}
