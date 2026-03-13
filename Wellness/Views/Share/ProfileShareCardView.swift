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
}

// MARK: - Card  (360 × 640 pt → 1080 × 1920 px at 3×)

struct ProfileShareCardView: View {
    let data: ProfileShareCardData

    private let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.02, blue: 0.15),
                    Color(red: 0.03, green: 0.01, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Ambient glow
            Circle()
                .fill(purpl.opacity(0.20))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(y: -20)

            VStack(spacing: 0) {
                Spacer()

                // App branding
                VStack(spacing: 6) {
                    Text("💪")
                        .font(.system(size: 46))
                    Text("Macro Maxxing")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(purpl)
                }

                Spacer().frame(height: 32)

                // Avatar
                avatarView
                    .overlay(Circle().stroke(
                        LinearGradient(colors: [purpl, Color(red: 0.40, green: 0.20, blue: 0.85)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 3
                    ))
                    .shadow(color: purpl.opacity(0.55), radius: 20)

                Spacer().frame(height: 20)

                // Name + handle
                VStack(spacing: 6) {
                    Text(data.displayName)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    if !data.username.isEmpty {
                        Text("@\(data.username)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.50))
                    }
                }

                Spacer().frame(height: 18)

                // Aura badge
                if data.auraPoints > 0 {
                    HStack(spacing: 8) {
                        Text("⭐")
                            .font(.system(size: 14))
                        VStack(spacing: 2) {
                            Text("Lv \(data.auraLevel)\(data.auraTitleString.isEmpty ? "" : " · \(data.auraTitleString)")")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(gold)
                            Text("\(data.auraPoints) aura pts")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.40))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(cardBg)
                    .cornerRadius(12)

                    Spacer().frame(height: 22)
                }

                // Follow CTA
                Text("Follow me on Macro Maxxing! 🔥")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)

                Spacer()

                // Download prompt strip
                VStack(spacing: 5) {
                    Text("Download the app")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.35))
                    Text("Macro Maxxing")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(purpl)
                }
                .padding(.bottom, 36)
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
                .fill(purpl.opacity(0.22))
                .frame(width: 110, height: 110)
                .overlay {
                    Text(String(data.displayName.prefix(1)).uppercased())
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(purpl)
                }
        }
    }
}
