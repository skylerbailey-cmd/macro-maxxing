//
//  AuraPopupView.swift
//  Wellness
//

import SwiftUI

// MARK: - Motivating messages by points tier

private func hypeMessage(for points: Int) -> String {
    switch points {
    case 1...5:
        return [
            "every rep counts. keep stacking.",
            "small moves, real progress.",
            "consistent and disciplined. that's the way.",
            "the grind rewards the grinder.",
            "no days off.",
        ].randomElement()!
    case 6...49:
        return [
            "locked in. keep it going.",
            "the progress is showing.",
            "discipline compounds. so does aura.",
            "this is what showing up looks like.",
            "results don't lie. neither does the streak.",
            "built on consistency. the numbers back it up.",
        ].randomElement()!
    case 50...149:
        return [
            "big aura drop. we see you putting in work.",
            "the grind is paying off.",
            "this is what being locked in looks like.",
            "peak performance is a habit, not an accident.",
            "keep this up and the results will speak for themselves.",
        ].randomElement()!
    default:
        return [
            "massive aura drop. you're on another level.",
            "the streak speaks for itself. keep going.",
            "this kind of consistency is rare. respect.",
            "you're building something real here.",
            "the dedication is showing. don't stop.",
        ].randomElement()!
    }
}

// MARK: - AuraPopupView

struct AuraPopupView: View {
    let gain:         AuraGain
    let userSettings: UserSettings
    let onDismiss:    () -> Void

    @State private var scale:   CGFloat = 0.3
    @State private var opacity: Double  = 0
    @State private var bgOpacity: Double = 0

    private let gold  = Color(red: 1.00, green: 0.80, blue: 0.20)
    private var accent: Color { ThemeStore.shared.accent }

    private var level: Int    { userSettings.auraLevel }
    private var title: String { userSettings.auraTitle }
    private var total: Int    { userSettings.auraPoints }

    private var ptsToNextLevel: Int? {
        guard level < 100 else { return nil }
        return (level + 1) * 1000 - total
    }

    var body: some View {
        ZStack {
            Color.black.opacity(bgOpacity * 0.60)
                .ignoresSafeArea()
                .onTapGesture { animatedDismiss() }

            VStack(spacing: 14) {
                // Points earned
                Text("+\(gain.pointsEarned) Aura")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [gold, Color(red: 1.00, green: 0.65, blue: 0.10)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )

                // Reason (e.g. streak milestone)
                if let reason = gain.reason {
                    Text(reason)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(gold.opacity(0.90))
                }

                // Level + title
                HStack(spacing: 6) {
                    Text("Level \(level)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(gold)
                    if !title.isEmpty {
                        Text("·")
                            .foregroundStyle(.white.opacity(0.30))
                        Text(title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(gold)
                    }
                }

                // Total + progress to next level
                VStack(spacing: 4) {
                    Text("\(total) total aura XP")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                    if let needed = ptsToNextLevel {
                        Text("\(needed) XP to Level \(level + 1)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(gold.opacity(0.80))
                    } else {
                        Text("MAX LEVEL 🔱")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(gold)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.white.opacity(0.06))
                .cornerRadius(10)

                // Hype message
                Text(hypeMessage(for: gain.pointsEarned))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                // Dismiss button
                Button(action: animatedDismiss) {
                    Text("Got it 💪")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(gold)
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.14))
                    .shadow(color: gold.opacity(0.25), radius: 30)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(gold.opacity(0.30), lineWidth: 1)
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
        }
    }

    private func animatedDismiss() {
        withAnimation(.easeIn(duration: 0.15)) {
            scale = 0.85; opacity = 0; bgOpacity = 0
        }
        Task {
            try? await Task.sleep(for: .seconds(0.18))
            onDismiss()
        }
    }
}
