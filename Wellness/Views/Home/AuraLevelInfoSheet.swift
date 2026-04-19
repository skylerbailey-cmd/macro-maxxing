//
//  AuraLevelInfoSheet.swift
//  Wellness
//

import SwiftUI

struct AuraLevelInfoSheet: View {
    let userSettings: UserSettings
    @Environment(\.dismiss) private var dismiss

    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var accent: Color { ThemeStore.shared.accent }

    private var currentLevel: Int { userSettings.auraLevel }
    private var currentTitle: String { userSettings.auraTitle }
    private var totalXP: Int { userSettings.auraPoints }

    // All level tiers with their ranges and titles
    private static let tiers: [(range: ClosedRange<Int>, title: String, emoji: String)] = [
        (1...5,    "Initiate",        "🌱"),
        (6...10,   "Rookie",          "🥉"),
        (11...15,  "Grinder",         "⚙️"),
        (16...20,  "Disciple",        "📖"),
        (21...25,  "Ascender",        "🧗"),
        (26...35,  "Mog Apprentice",  "🔨"),
        (36...45,  "Aura Seeker",     "🔍"),
        (46...55,  "Aura Farmer",     "🌾"),
        (56...65,  "Aesthetic",       "✨"),
        (66...75,  "Elite Aesthetic", "💎"),
        (76...90,  "Transcendent",    "🔱"),
        (91...100, "Final Form",      "👑"),
    ]

    // Ways to earn XP
    private static let earnMethods: [(action: String, xp: String, icon: String)] = [
        ("Log a meal",           "+1 XP",   "fork.knife"),
        ("Log a meal with photo", "+5 XP",  "camera.fill"),
        ("Log a workout",        "+5 XP",   "figure.run"),
        ("Create a post",        "+25 XP",  "square.and.pencil"),
        ("Hit all macro goals",  "+50 XP",  "checkmark.seal.fill"),
        ("Streak milestones",    "Bonus XP", "flame.fill"),
        ("React to someone's post", "+1 XP", "face.smiling.inverse"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    currentLevelCard
                    howToEarnSection
                    allLevelsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(pageBg)
            .preferredColorScheme(.dark)
            .navigationTitle("Aura Levels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(accent)
                }
            }
        }
    }

    // MARK: - Current level card

    private var currentLevelCard: some View {
        VStack(spacing: 14) {
            Text("Your Level")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.40))

            Text("Level \(currentLevel)")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(accent)

            Text(currentTitle.uppercased())
                .font(.system(size: 13, weight: .black))
                .tracking(2)
                .foregroundStyle(accent.opacity(0.80))

            Text("\(totalXP) XP")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.60))

            // Progress to next level
            if currentLevel < 100 {
                let levelStart = UserSettings.auraThreshold(currentLevel)
                let levelEnd   = UserSettings.auraThreshold(currentLevel + 1)
                let inLevel    = max(0, totalXP - levelStart)
                let forLevel   = max(1, levelEnd - levelStart)
                let progress   = Double(inLevel) / Double(forLevel)
                let remaining  = forLevel - inLevel

                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 8)
                            Capsule()
                                .fill(accent)
                                .frame(width: max(8, geo.size.width * progress), height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(remaining) XP to Level \(currentLevel + 1)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.45))
                }
            } else {
                Text("MAX LEVEL")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(accent)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(cardBg)
        .cornerRadius(16)
    }

    // MARK: - How to earn XP

    private var howToEarnSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Earn XP")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                ForEach(Array(Self.earnMethods.enumerated()), id: \.offset) { idx, method in
                    HStack(spacing: 12) {
                        Image(systemName: method.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(accent)
                            .frame(width: 24)

                        Text(method.action)
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.80))

                        Spacer()

                        Text(method.xp)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(accent)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)

                    if idx < Self.earnMethods.count - 1 {
                        Divider().background(Color.white.opacity(0.06))
                            .padding(.leading, 50)
                    }
                }
            }
            .background(cardBg)
            .cornerRadius(12)
        }
    }

    // MARK: - All levels

    private var allLevelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Levels")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                ForEach(Array(Self.tiers.enumerated()), id: \.offset) { idx, tier in
                    let isCurrent = tier.range.contains(currentLevel)
                    let isUnlocked = currentLevel >= tier.range.lowerBound
                    let startXP = UserSettings.auraThreshold(tier.range.lowerBound)

                    HStack(spacing: 12) {
                        Text(tier.emoji)
                            .font(.system(size: 20))
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(tier.title)
                                    .font(.system(size: 14, weight: isCurrent ? .bold : .medium))
                                    .foregroundStyle(isCurrent ? accent : isUnlocked ? .white : .white.opacity(0.40))

                                if isCurrent {
                                    Text("YOU")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(accent, in: Capsule())
                                }
                            }

                            Text("Lv \(tier.range.lowerBound)–\(tier.range.upperBound)  ·  \(startXP) XP")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.35))
                        }

                        Spacer()

                        if isUnlocked {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(accent.opacity(0.60))
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.20))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(isCurrent ? accent.opacity(0.08) : Color.clear)

                    if idx < Self.tiers.count - 1 {
                        Divider().background(Color.white.opacity(0.06))
                            .padding(.leading, 56)
                    }
                }
            }
            .background(cardBg)
            .cornerRadius(12)
        }
    }
}
