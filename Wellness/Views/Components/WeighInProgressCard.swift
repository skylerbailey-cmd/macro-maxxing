//
//  WeighInProgressCard.swift
//  Wellness
//
//  Reusable weight progress visual for Goal posts that include weigh-in data.
//  Shows Before → Now → Goal with a progress bar.
//

import SwiftUI

struct WeighInProgressCard: View {
    let previousWeight: Double
    let currentWeight:  Double
    let goalWeight:     Double

    private let goalPurple = PostLabel.goalPost.color
    private let cardBg     = Color(red: 0.11, green: 0.11, blue: 0.14)

    private var delta: Double { currentWeight - previousWeight }
    private var isLossGoal: Bool { goalWeight < previousWeight }
    private var movedToward: Bool {
        isLossGoal ? currentWeight <= previousWeight : currentWeight >= previousWeight
    }
    private var hitGoal: Bool {
        isLossGoal ? currentWeight <= goalWeight : currentWeight >= goalWeight
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: hitGoal ? "trophy.fill" : "target")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(goalPurple)
                Text(hitGoal ? "Goal reached!" : "Weigh-in update")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }

            // Weight journey: Before → Now → Goal
            HStack(spacing: 0) {
                bubble(label: "Before", value: Int(previousWeight),
                       color: .white.opacity(0.50), bg: Color.white.opacity(0.06))
                Spacer()
                VStack(spacing: 2) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(deltaColor)
                    Text("\(delta >= 0 ? "+" : "")\(String(format: "%.1f", delta))")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(deltaColor)
                }
                Spacer()
                bubble(label: "Now", value: Int(currentWeight),
                       color: goalPurple, bg: goalPurple.opacity(0.12))
                Spacer()
                Image(systemName: hitGoal ? "checkmark" : "ellipsis")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.25))
                Spacer()
                bubble(label: "Goal", value: Int(goalWeight),
                       color: .white.opacity(0.35), bg: Color.white.opacity(0.04))
            }

            // Progress bar
            let totalRange = abs(previousWeight - goalWeight)
            let progress   = totalRange > 0 ? min(abs(previousWeight - currentWeight) / totalRange, 1.0) : 0
            let barPct     = movedToward ? progress : 0

            VStack(spacing: 3) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.08)).frame(height: 5)
                        Capsule().fill(goalPurple.opacity(0.80))
                            .frame(width: max(4, geo.size.width * barPct), height: 5)
                    }
                }
                .frame(height: 5)
                HStack {
                    Text(statusText)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.40))
                    Spacer()
                    Text("\(Int(barPct * 100))%")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(goalPurple)
                }
            }
        }
        .padding(12)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(goalPurple.opacity(0.20), lineWidth: 1))
    }

    private var deltaColor: Color {
        movedToward ? Color(red: 0.25, green: 0.85, blue: 0.50) : Color(red: 1.00, green: 0.55, blue: 0.15)
    }

    private var statusText: String {
        if hitGoal { return "Goal reached!" }
        if movedToward { return "\(String(format: "%.1f", abs(currentWeight - goalWeight))) lbs to go" }
        return "Keep pushing!"
    }

    private func bubble(label: String, value: Int, color: Color, bg: Color) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.35))
            Text("\(value)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text("lbs")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.25))
        }
        .frame(width: 56, height: 54)
        .background(bg, in: RoundedRectangle(cornerRadius: 8))
    }
}
