//
//  BrainstormCardsView.swift
//  Wellness
//
//  Swipeable card carousel for AI Meal Planner results.

import SwiftUI

struct BrainstormCardsView: View {
    let result: BrainstormResult

    @State private var currentPage = 0

    private var accent: Color { Color.premiumGold }
    private let cardBg = Color(red: 0.13, green: 0.13, blue: 0.16)

    /// Total number of cards: 1 summary + N suggestions (or 1 completion)
    private var totalPages: Int {
        result.suggestions.isEmpty ? 1 : 1 + result.suggestions.count
    }

    var body: some View {
        VStack(spacing: 12) {
            // Cards
            TabView(selection: $currentPage) {
                gapCard.tag(0)

                if let msg = result.completionMessage {
                    completionCard(msg).tag(1)
                } else {
                    ForEach(Array(result.suggestions.enumerated()), id: \.element.id) { idx, suggestion in
                        suggestionCard(suggestion).tag(idx + 1)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 260)

            // Page dots
            HStack(spacing: 6) {
                ForEach(0..<totalPages, id: \.self) { idx in
                    Circle()
                        .fill(idx == currentPage ? accent : Color.white.opacity(0.20))
                        .frame(width: 7, height: 7)
                        .scaleEffect(idx == currentPage ? 1.2 : 1.0)
                        .animation(.spring(duration: 0.2), value: currentPage)
                }
            }
        }
    }

    // MARK: - Card 1: What You Still Need

    private var gapCard: some View {
        VStack(spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accent)
                Text("What You Still Need")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }

            // Four ring gauges in a row
            HStack(spacing: 0) {
                macroRing(
                    label: "Calories",
                    remaining: result.remainingCalories,
                    unit: "cal",
                    met: false,
                    color: accent
                )
                macroRing(
                    label: "Protein",
                    remaining: result.remainingProtein,
                    unit: "g",
                    met: result.overProtein,
                    color: Color(red: 0.35, green: 0.75, blue: 1.0)
                )
                macroRing(
                    label: "Carbs",
                    remaining: result.remainingCarbs,
                    unit: "g",
                    met: result.overCarbs,
                    color: Color(red: 0.40, green: 0.90, blue: 0.72)
                )
                macroRing(
                    label: "Fat",
                    remaining: result.remainingFat,
                    unit: "g",
                    met: result.overFat,
                    color: Color(red: 1.0, green: 0.60, blue: 0.40)
                )
            }

            // Dynamic focus description
            Text(gapDescription)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.50))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            // Swipe hint
            HStack(spacing: 4) {
                Text("Swipe for meal ideas")
                    .font(.system(size: 11, weight: .medium))
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(.white.opacity(0.30))
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 16))
    }

    /// Builds actionable guidance: what to prioritize, what to avoid.
    private var gapDescription: String {
        let allMet = result.overProtein && result.overCarbs && result.overFat
        if allMet { return "All macros are on track — just fill your remaining calories." }

        // Collect unmet macros sorted by remaining amount (biggest gap first)
        var gaps: [(name: String, remaining: Int)] = []
        if !result.overProtein && result.remainingProtein > 5 { gaps.append(("protein", result.remainingProtein)) }
        if !result.overCarbs   && result.remainingCarbs   > 5 { gaps.append(("carbs",   result.remainingCarbs)) }
        if !result.overFat     && result.remainingFat     > 5 { gaps.append(("fat",     result.remainingFat)) }
        gaps.sort { $0.remaining > $1.remaining }

        if gaps.isEmpty { return "You're almost there — just a small gap left to close." }

        var lines: [String] = []

        // Identify the biggest gap to prioritize
        if let biggest = gaps.first, gaps.count > 1 {
            let secondBiggest = gaps[1].remaining
            // If the top gap is significantly larger than the next (>1.5x), call it out
            if biggest.remaining > Int(Double(secondBiggest) * 1.5) {
                lines.append("Prioritize \(biggest.name) — it's your biggest gap at \(biggest.remaining)\(biggest.name == "calories" ? " cal" : "g") left.")
            } else {
                let names = gaps.count == 2
                    ? "\(gaps[0].name) and \(gaps[1].name)"
                    : "\(gaps[0].name), \(gaps[1].name), and \(gaps[2].name)"
                lines.append("Focus on \(names) to close the gap.")
            }
        } else if let only = gaps.first {
            lines.append("Focus on \(only.name) — \(only.remaining)\(only.name == "calories" ? " cal" : "g") left to hit your goal.")
        }

        // Call out macros to avoid (already met or nearly met)
        var avoidNames: [String] = []
        if result.overProtein { avoidNames.append("protein") }
        if result.overCarbs   { avoidNames.append("carbs") }
        if result.overFat     { avoidNames.append("fat") }

        // Also flag "close" macros — small remaining relative to the biggest gap
        if let biggest = gaps.first {
            for g in gaps.dropFirst() {
                if Double(g.remaining) < Double(biggest.remaining) * 0.25 && g.remaining <= 15 {
                    avoidNames.append(g.name)
                }
            }
        }

        if !avoidNames.isEmpty {
            let joined = avoidNames.count == 1
                ? avoidNames[0]
                : avoidNames.dropLast().joined(separator: ", ") + " and " + avoidNames.last!
            lines.append("Watch your \(joined) — \(avoidNames.count == 1 ? "it's" : "they're") already close to the limit.")
        }

        return lines.joined(separator: " ")
    }

    /// A single ring gauge showing how much of a macro is left to eat.
    /// When `met` is true the ring is full green with a checkmark.
    private func macroRing(label: String, remaining: Int, unit: String, met: Bool, color: Color) -> some View {
        let ringSize: CGFloat = 56
        // Progress: 1.0 = nothing left (full ring), 0.0 = just started.
        // We approximate using 200g / 2000cal as a "typical goal" just for
        // the ring visual — the exact number is shown in text.
        let maxRef: Double = label == "Calories" ? 2500 : 200
        let progress: Double = met ? 1.0 : max(0, 1.0 - Double(remaining) / maxRef)

        return VStack(spacing: 8) {
            ZStack {
                // Track
                Circle()
                    .stroke(color.opacity(0.12), lineWidth: 5)
                    .frame(width: ringSize, height: ringSize)

                // Fill
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        met ? Color.green : color,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))

                // Center label
                if met {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.green)
                } else {
                    VStack(spacing: 0) {
                        Text("\(remaining)")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text(unit)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.40))
                    }
                }
            }

            Text(met ? "\(label) ✓" : label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(met ? .green.opacity(0.70) : .white.opacity(0.50))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Suggestion cards

    private func suggestionCard(_ suggestion: MealSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Category badge
            HStack(spacing: 8) {
                Text(suggestion.category == "Snack" ? "🍎" : "🍽️")
                    .font(.system(size: 16))
                Text(suggestion.category)
                    .font(.system(size: 13, weight: .black))
                    .tracking(1)
                    .foregroundStyle(accent)
                Spacer()
                Text("\(suggestion.calories) cal")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.50))
            }

            // Meal name
            Text(suggestion.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Portion
            Text(suggestion.portion)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.45))

            // Macro pills
            HStack(spacing: 8) {
                macroPill("P", value: suggestion.protein, color: Color(red: 0.35, green: 0.75, blue: 1.0))
                macroPill("C", value: suggestion.carbs, color: Color(red: 0.40, green: 0.90, blue: 0.72))
                macroPill("F", value: suggestion.fat, color: Color(red: 1.0, green: 0.60, blue: 0.40))
            }

            Spacer(minLength: 0)

            // Reason
            Text(suggestion.reason)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 16))
    }

    private func macroPill(_ label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
            Text("\(value)g")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Completion card

    private func completionCard(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
            Text("Goals Met")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.60))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 16))
    }
}
