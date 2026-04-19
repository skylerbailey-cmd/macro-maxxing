//
//  MealPlannerView.swift
//  Wellness
//
//  Full navigation page for the AI Meal Planner — generates macro-matched
//  meal suggestions and persists the last 3 plans.
//

import SwiftUI

struct MealPlannerView: View {
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let goalCalories: Double
    let goalProtein: Double
    let goalCarbs: Double
    let goalFat: Double
    let excludeDairy: Bool
    let excludeGluten: Bool

    @State private var savedPlans: [SavedMealPlan] = []
    @State private var viewingPlan: SavedMealPlan?
    @State private var currentPage = 0
    @State private var isGenerating = false

    private var accent: Color { Color.premiumGold }
    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            if isGenerating {
                generatingPhase
            } else if let plan = viewingPlan {
                planDetailView(plan)
            } else {
                landingPhase
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("AI Meal Planner")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { savedPlans = SavedMealPlanStore.load() }
    }

    // MARK: - Landing: History + Generate

    private var landingPhase: some View {
        ScrollView {
            VStack(spacing: 20) {
                remainingMacrosBar
                    .padding(.top, 12)

                // Generate button
                Button { generate() } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "lightbulb.max.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Brainstorm Meals")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.30))
                    }
                    .foregroundStyle(.black)
                    .padding(16)
                    .background(Color.premiumGold, in: RoundedRectangle(cornerRadius: 16))
                    .shimmering(cornerRadius: 16)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                // Saved plans
                if savedPlans.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Plans")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.50))
                            .padding(.horizontal, 20)

                        ForEach(savedPlans) { plan in
                            savedPlanRow(plan)
                        }
                    }
                }
            }
            .padding(.bottom, 30)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 40)
            Image(systemName: "lightbulb")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.15))
            Text("No plans yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.30))
            Text("Brainstorm meals tailored to your\nremaining macro goals for the day.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.20))
                .multilineTextAlignment(.center)
        }
    }

    private func savedPlanRow(_ plan: SavedMealPlan) -> some View {
        Button {
            currentPage = 0
            viewingPlan = plan
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accent.opacity(0.14))
                        .frame(width: 40, height: 40)
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    // Show top suggestion name
                    Text(plan.result.suggestions.first?.name ?? "Meal Plan")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(plan.date.formatted(.relative(presentation: .named)))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                        Text("·")
                            .foregroundStyle(.white.opacity(0.20))
                        Text("\(plan.result.suggestions.count) meals")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                        if plan.result.completionMessage != nil {
                            Text("·")
                                .foregroundStyle(.white.opacity(0.20))
                            Text("Goals met")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.green.opacity(0.60))
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.20))
            }
            .padding(14)
            .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .contextMenu {
            Button(role: .destructive) { deletePlan(plan) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Generating Phase

    private var generatingPhase: some View {
        VStack(spacing: 24) {
            Spacer()
            BrainstormSkeletonView()
                .padding(.horizontal, 20)
            VStack(spacing: 8) {
                Text("Planning your meals...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Based on your remaining macros")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.40))
            }
            Spacer()
        }
    }

    // MARK: - Plan Detail (swipeable cards)

    private func planDetailView(_ plan: SavedMealPlan) -> some View {
        VStack(spacing: 16) {
            // Macro gap summary from the plan
            macroGapBar(plan.result)
                .padding(.top, 8)

            if let msg = plan.result.completionMessage {
                // All goals met
                completionView(msg)
            } else {
                // Swipeable suggestion cards
                TabView(selection: $currentPage) {
                    // First card: What You Still Need
                    gapCard(plan.result).tag(0)

                    ForEach(Array(plan.result.suggestions.enumerated()), id: \.element.id) { idx, suggestion in
                        suggestionCard(suggestion).tag(idx + 1)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 320)

                // Page dots
                let totalPages = 1 + plan.result.suggestions.count
                HStack(spacing: 6) {
                    ForEach(0..<totalPages, id: \.self) { idx in
                        Circle()
                            .fill(idx == currentPage ? accent : Color.white.opacity(0.20))
                            .frame(width: 8, height: 8)
                            .scaleEffect(idx == currentPage ? 1.2 : 1.0)
                            .animation(.spring(duration: 0.2), value: currentPage)
                    }
                }
            }

            Button {
                viewingPlan = nil
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("All Plans")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Gap Card (What You Still Need — ring gauges)

    private func gapCard(_ result: BrainstormResult) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accent)
                Text("What You Still Need")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }

            HStack(spacing: 0) {
                gapRing(label: "Calories", remaining: result.remainingCalories, unit: "cal", met: false, color: accent)
                gapRing(label: "Protein", remaining: result.remainingProtein, unit: "g", met: result.overProtein, color: Color(red: 0.35, green: 0.75, blue: 1.0))
                gapRing(label: "Carbs", remaining: result.remainingCarbs, unit: "g", met: result.overCarbs, color: Color(red: 0.40, green: 0.90, blue: 0.72))
                gapRing(label: "Fat", remaining: result.remainingFat, unit: "g", met: result.overFat, color: Color(red: 1.0, green: 0.60, blue: 0.40))
            }

            // Focus description
            Text(gapDescription(result))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.50))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .frame(maxWidth: .infinity)

            HStack(spacing: 4) {
                Text("Swipe for meal ideas")
                    .font(.system(size: 11, weight: .medium))
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(.white.opacity(0.30))
            .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private func gapRing(label: String, remaining: Int, unit: String, met: Bool, color: Color) -> some View {
        let ringSize: CGFloat = 56
        let maxRef: Double = label == "Calories" ? 2500 : 200
        let progress: Double = met ? 1.0 : max(0, 1.0 - Double(remaining) / maxRef)

        return VStack(spacing: 8) {
            ZStack {
                Circle().stroke(color.opacity(0.12), lineWidth: 5).frame(width: ringSize, height: ringSize)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(met ? Color.green : color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))
                if met {
                    Image(systemName: "checkmark").font(.system(size: 16, weight: .bold)).foregroundStyle(.green)
                } else {
                    VStack(spacing: 0) {
                        Text("\(remaining)").font(.system(size: 15, weight: .black, design: .rounded)).foregroundStyle(.white)
                        Text(unit).font(.system(size: 9, weight: .semibold)).foregroundStyle(.white.opacity(0.40))
                    }
                }
            }
            Text(met ? "\(label) ✓" : label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(met ? .green.opacity(0.70) : .white.opacity(0.50))
        }
        .frame(maxWidth: .infinity)
    }

    private func gapDescription(_ result: BrainstormResult) -> String {
        let allMet = result.overProtein && result.overCarbs && result.overFat
        if allMet { return "All macros are on track — just fill your remaining calories." }

        var gaps: [(name: String, remaining: Int)] = []
        if !result.overProtein && result.remainingProtein > 5 { gaps.append(("protein", result.remainingProtein)) }
        if !result.overCarbs   && result.remainingCarbs   > 5 { gaps.append(("carbs",   result.remainingCarbs)) }
        if !result.overFat     && result.remainingFat     > 5 { gaps.append(("fat",     result.remainingFat)) }
        gaps.sort { $0.remaining > $1.remaining }

        if gaps.isEmpty { return "You're almost there — just a small gap left to close." }

        var lines: [String] = []

        if let biggest = gaps.first, gaps.count > 1 {
            let secondBiggest = gaps[1].remaining
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

        var avoidNames: [String] = []
        if result.overProtein { avoidNames.append("protein") }
        if result.overCarbs   { avoidNames.append("carbs") }
        if result.overFat     { avoidNames.append("fat") }

        if !avoidNames.isEmpty {
            let joined = avoidNames.count == 1
                ? avoidNames[0]
                : avoidNames.dropLast().joined(separator: ", ") + " and " + avoidNames.last!
            lines.append("Watch your \(joined) — \(avoidNames.count == 1 ? "it's" : "they're") already close to the limit.")
        }

        return lines.joined(separator: " ")
    }

    // MARK: - Suggestion Card

    private func suggestionCard(_ suggestion: MealSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 14) {
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

            Text(suggestion.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(suggestion.portion)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.45))

            HStack(spacing: 8) {
                macroPill("P", value: suggestion.protein, color: Color(red: 0.35, green: 0.75, blue: 1.0))
                macroPill("C", value: suggestion.carbs, color: Color(red: 0.40, green: 0.90, blue: 0.72))
                macroPill("F", value: suggestion.fat, color: Color(red: 1.0, green: 0.60, blue: 0.40))
            }

            Text(suggestion.reason)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private func completionView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("Goals Met")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Shared Components

    private func macroGapBar(_ result: BrainstormResult) -> some View {
        HStack(spacing: 12) {
            miniMacro("Cal", value: result.remainingCalories, unit: "", color: accent)
            miniMacro("Pro", value: result.overProtein ? 0 : result.remainingProtein, unit: "g",
                      color: result.overProtein ? .green : Color(red: 0.35, green: 0.75, blue: 1.0))
            miniMacro("Carb", value: result.overCarbs ? 0 : result.remainingCarbs, unit: "g",
                      color: result.overCarbs ? .green : Color(red: 0.40, green: 0.90, blue: 0.72))
            miniMacro("Fat", value: result.overFat ? 0 : result.remainingFat, unit: "g",
                      color: result.overFat ? .green : Color(red: 1.0, green: 0.60, blue: 0.40))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }

    private func miniMacro(_ label: String, value: Int, unit: String, color: Color) -> some View {
        VStack(spacing: 3) {
            if value == 0 && color == .green {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.green)
            } else {
                Text("\(max(0, value))\(unit)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.40))
        }
        .frame(maxWidth: .infinity)
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

    private var remainingMacrosBar: some View {
        let remCal = max(0, Int(goalCalories - totalCalories))
        let remPro = max(0, Int(goalProtein - totalProtein))
        let remCarb = max(0, Int(goalCarbs - totalCarbs))
        let remFat = max(0, Int(goalFat - totalFat))

        return HStack(spacing: 12) {
            macroLabel("Cal", value: remCal, unit: "", color: accent)
            macroLabel("Pro", value: remPro, unit: "g", color: Color(red: 0.35, green: 0.75, blue: 1.0))
            macroLabel("Carb", value: remCarb, unit: "g", color: Color(red: 0.40, green: 0.90, blue: 0.72))
            macroLabel("Fat", value: remFat, unit: "g", color: Color(red: 1.0, green: 0.60, blue: 0.40))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }

    private func macroLabel(_ label: String, value: Int, unit: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text("\(value)\(unit)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.40))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Generate & Persist

    private func generate() {
        isGenerating = true
        let engine = MacroRecommendationEngine()
        let input = MacroRecommendationEngine.BrainstormInput(
            totalCalories: totalCalories, goalCalories: goalCalories,
            totalProtein:  totalProtein,  goalProtein:  goalProtein,
            totalCarbs:    totalCarbs,    goalCarbs:    goalCarbs,
            totalFat:      totalFat,      goalFat:      goalFat,
            excludeDairy:  excludeDairy,
            excludeGluten: excludeGluten
        )
        let structured = engine.recommendStructured(input)

        Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            let plan = SavedMealPlan(result: structured)
            SavedMealPlanStore.save(plan)
            savedPlans = SavedMealPlanStore.load()
            viewingPlan = plan
            currentPage = 0
            isGenerating = false
        }
    }

    private func deletePlan(_ plan: SavedMealPlan) {
        SavedMealPlanStore.delete(plan.id)
        savedPlans = SavedMealPlanStore.load()
        if viewingPlan?.id == plan.id { viewingPlan = nil }
    }
}
