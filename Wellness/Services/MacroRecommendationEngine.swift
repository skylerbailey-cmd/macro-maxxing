//
//  MacroRecommendationEngine.swift
//  Wellness
//
//  Picks meal and snack suggestions from LocalMealDatabase based on which
//  macros the user still needs to fill, with dietary filtering and
//  randomisation to avoid repetition.
//

import Foundation

struct MacroRecommendationEngine {

    // UserDefaults key that stores the last N meal names shown (avoids repeats)
    private static let recentKey = "recentBrainstormMeals"
    private static let recentMaxCount = 20

    // How many grams below goal counts as "still needed"
    private static let significantGap: Double = 15

    // How many grams above upper limit (goal × 1.15) counts as "over"
    // (mirrored from the existing ClaudeAnalysisService logic)
    private static let overLimitFactor: Double = 1.15

    // MARK: - Public entry point

    /// Synchronously returns a markdown-formatted suggestion string.
    func recommend(_ input: BrainstormInput) -> String {
        let remaining = Remaining(
            calories: max(0, input.goalCalories - input.totalCalories),
            protein:  max(0, input.goalProtein  - input.totalProtein),
            carbs:    max(0, input.goalCarbs    - input.totalCarbs),
            fat:      max(0, input.goalFat      - input.totalFat)
        )

        let over = Over(
            protein: input.totalProtein > input.goalProtein * Self.overLimitFactor,
            carbs:   input.totalCarbs   > input.goalCarbs   * Self.overLimitFactor,
            fat:     input.totalFat     > input.goalFat      * Self.overLimitFactor
        )

        let excludeDairy  = input.excludeDairy
        let excludeGluten = input.excludeGluten

        // Determine how many macros still have a significant gap
        let proteinNeeded = !over.protein && remaining.protein > Self.significantGap
        let carbsNeeded   = !over.carbs   && remaining.carbs   > Self.significantGap
        let fatNeeded     = !over.fat     && remaining.fat     > Self.significantGap

        let neededCount = [proteinNeeded, carbsNeeded, fatNeeded].filter { $0 }.count

        // All macros close to goal → show a balanced or light snack suggestion
        if neededCount == 0 {
            return buildAlmostDoneMessage(remaining: remaining)
        }

        // All macros over → nothing recommended
        if over.protein && over.carbs && over.fat {
            return "**You've hit or exceeded all your macro goals today** — great work! Focus on hydration and rest."
        }

        let suggestions: [String]

        if neededCount == 3 {
            // All three macros still needed → suggest a balanced meal
            suggestions = pickMeals(
                from: filterMeals(LocalMealDatabase.balanced, dairy: excludeDairy, gluten: excludeGluten),
                count: 2)
        } else if neededCount == 2 {
            suggestions = twoMacroSuggestions(
                proteinNeeded: proteinNeeded, carbsNeeded: carbsNeeded, fatNeeded: fatNeeded,
                remaining: remaining, excludeDairy: excludeDairy, excludeGluten: excludeGluten)
        } else {
            // Exactly one macro still needed
            suggestions = oneMacroSuggestions(
                proteinNeeded: proteinNeeded, carbsNeeded: carbsNeeded, fatNeeded: fatNeeded,
                remaining: remaining, excludeDairy: excludeDairy, excludeGluten: excludeGluten)
        }

        let picked = suggestions.isEmpty
            ? ["Balanced meal — keep working on those macros!"]
            : suggestions

        markAsRecent(picked.compactMap { firstWord($0) })
        return formatOutput(remaining: remaining, over: over, suggestions: picked)
    }

    // MARK: - Input / helpers

    struct BrainstormInput {
        let totalCalories: Double; let goalCalories: Double
        let totalProtein:  Double; let goalProtein:  Double
        let totalCarbs:    Double; let goalCarbs:    Double
        let totalFat:      Double; let goalFat:      Double
        var excludeDairy:  Bool = false
        var excludeGluten: Bool = false
    }

    private struct Remaining {
        let calories: Double
        let protein:  Double
        let carbs:    Double
        let fat:      Double
    }

    private struct Over {
        let protein: Bool
        let carbs:   Bool
        let fat:     Bool
    }

    // MARK: - Two-macro suggestion (component combining)

    private func twoMacroSuggestions(
        proteinNeeded: Bool, carbsNeeded: Bool, fatNeeded: Bool,
        remaining: Remaining, excludeDairy: Bool, excludeGluten: Bool
    ) -> [String] {
        // Pick a pre-built two-macro meal first; fall back to component combining

        if proteinNeeded && carbsNeeded {
            let pool = filterMeals(LocalMealDatabase.highProteinCarb, dairy: excludeDairy, gluten: excludeGluten)
            if let meal = pickOne(from: pool) {
                return [formatMeal(meal)]
            }
            // Component combine: protein + carb
            return combineComponents(
                a: filterComponents(LocalMealDatabase.proteinComponents, dairy: excludeDairy, gluten: excludeGluten),
                b: filterComponents(LocalMealDatabase.carbComponents,    dairy: excludeDairy, gluten: excludeGluten),
                primaryLabel: "protein", secondaryLabel: "carbs")
        }

        if proteinNeeded && fatNeeded {
            let pool = filterMeals(LocalMealDatabase.highProteinFat, dairy: excludeDairy, gluten: excludeGluten)
            if let meal = pickOne(from: pool) {
                return [formatMeal(meal)]
            }
            return combineComponents(
                a: filterComponents(LocalMealDatabase.proteinComponents, dairy: excludeDairy, gluten: excludeGluten),
                b: filterComponents(LocalMealDatabase.fatComponents,     dairy: excludeDairy, gluten: excludeGluten),
                primaryLabel: "protein", secondaryLabel: "fat")
        }

        if carbsNeeded && fatNeeded {
            let pool = filterMeals(LocalMealDatabase.highCarbFat, dairy: excludeDairy, gluten: excludeGluten)
            if let meal = pickOne(from: pool) {
                return [formatMeal(meal)]
            }
            return combineComponents(
                a: filterComponents(LocalMealDatabase.carbComponents, dairy: excludeDairy, gluten: excludeGluten),
                b: filterComponents(LocalMealDatabase.fatComponents,  dairy: excludeDairy, gluten: excludeGluten),
                primaryLabel: "carbs", secondaryLabel: "fat")
        }

        return []
    }

    // MARK: - One-macro suggestion

    private func oneMacroSuggestions(
        proteinNeeded: Bool, carbsNeeded: Bool, fatNeeded: Bool,
        remaining: Remaining, excludeDairy: Bool, excludeGluten: Bool
    ) -> [String] {

        if proteinNeeded {
            // Choose meal vs snack based on how much protein is still needed
            if remaining.protein > 30 {
                let pool = filterMeals(LocalMealDatabase.highProteinMeals, dairy: excludeDairy, gluten: excludeGluten)
                if let meal = pickOne(from: pool) { return [formatMeal(meal)] }
            }
            let snackPool = filterMeals(LocalMealDatabase.highProteinSnacks, dairy: excludeDairy, gluten: excludeGluten)
            if let snack = pickOne(from: snackPool) { return [formatMeal(snack)] }
            // Fall back to a protein component
            let compPool = filterComponents(LocalMealDatabase.proteinComponents, dairy: excludeDairy, gluten: excludeGluten)
            if let comp = pickOneComponent(from: compPool) { return [formatComponent(comp)] }
        }

        if carbsNeeded {
            if remaining.carbs > 40 {
                let pool = filterMeals(LocalMealDatabase.highCarbMeals, dairy: excludeDairy, gluten: excludeGluten)
                if let meal = pickOne(from: pool) { return [formatMeal(meal)] }
            }
            let snackPool = filterMeals(LocalMealDatabase.highCarbSnacks, dairy: excludeDairy, gluten: excludeGluten)
            if let snack = pickOne(from: snackPool) { return [formatMeal(snack)] }
            let compPool = filterComponents(LocalMealDatabase.carbComponents, dairy: excludeDairy, gluten: excludeGluten)
            if let comp = pickOneComponent(from: compPool) { return [formatComponent(comp)] }
        }

        if fatNeeded {
            if remaining.fat > 20 {
                let pool = filterMeals(LocalMealDatabase.highFatMeals, dairy: excludeDairy, gluten: excludeGluten)
                if let meal = pickOne(from: pool) { return [formatMeal(meal)] }
            }
            let snackPool = filterMeals(LocalMealDatabase.highFatSnacks, dairy: excludeDairy, gluten: excludeGluten)
            if let snack = pickOne(from: snackPool) { return [formatMeal(snack)] }
            let compPool = filterComponents(LocalMealDatabase.fatComponents, dairy: excludeDairy, gluten: excludeGluten)
            if let comp = pickOneComponent(from: compPool) { return [formatComponent(comp)] }
        }

        return []
    }

    // MARK: - Component combining

    private func combineComponents(
        a: [FoodComponent], b: [FoodComponent],
        primaryLabel: String, secondaryLabel: String
    ) -> [String] {
        guard let compA = pickOneComponent(from: a),
              let compB = pickOneComponent(from: b) else { return [] }
        let totalCal = compA.calories + compB.calories
        let totalPro = compA.protein  + compB.protein
        let totalCarb = compA.carbs   + compB.carbs
        let totalFat = compA.fat      + compB.fat
        let line = "**\(compA.name)** (\(compA.portion)) + **\(compB.name)** (\(compB.portion))"
            + " — \(totalCal) cal · \(totalPro)g P · \(totalCarb)g C · \(totalFat)g F"
        return [line]
    }

    // MARK: - Pool filtering

    private func filterMeals(_ meals: [LocalMeal], dairy: Bool, gluten: Bool) -> [LocalMeal] {
        meals.filter { m in
            (dairy  ? !m.hasDairy  : true) &&
            (gluten ? !m.hasGluten : true)
        }
    }

    private func filterComponents(_ components: [FoodComponent], dairy: Bool, gluten: Bool) -> [FoodComponent] {
        components.filter { c in
            (dairy  ? !c.hasDairy  : true) &&
            (gluten ? !c.hasGluten : true)
        }
    }

    // MARK: - Random picks with recency avoidance

    private func recentNames() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: Self.recentKey) ?? [])
    }

    private func markAsRecent(_ names: [String]) {
        var recent = UserDefaults.standard.stringArray(forKey: Self.recentKey) ?? []
        recent.append(contentsOf: names)
        if recent.count > Self.recentMaxCount {
            recent = Array(recent.suffix(Self.recentMaxCount))
        }
        UserDefaults.standard.set(recent, forKey: Self.recentKey)
    }

    private func firstWord(_ s: String) -> String? {
        s.components(separatedBy: CharacterSet(charactersIn: " (—")).first
    }

    private func pickOne(from pool: [LocalMeal]) -> LocalMeal? {
        let recent = recentNames()
        // Prefer items not recently shown
        let fresh = pool.filter { !recent.contains($0.name) }
        let candidates = fresh.isEmpty ? pool : fresh
        guard !candidates.isEmpty else { return nil }
        return candidates[Int.random(in: 0..<candidates.count)]
    }

    private func pickOneComponent(from pool: [FoodComponent]) -> FoodComponent? {
        guard !pool.isEmpty else { return nil }
        return pool[Int.random(in: 0..<pool.count)]
    }

    private func pickMeals(from pool: [LocalMeal], count: Int) -> [String] {
        var shuffled = pool
        shuffled.shuffle()
        let recent = recentNames()
        let fresh = shuffled.filter { !recent.contains($0.name) }
        let candidates = fresh.isEmpty ? shuffled : fresh
        return Array(candidates.prefix(count)).map { formatMeal($0) }
    }

    // MARK: - Formatters

    private func formatMeal(_ meal: LocalMeal) -> String {
        "**\(meal.name)** (\(meal.portion)) — \(meal.calories) cal · \(meal.protein)g P · \(meal.carbs)g C · \(meal.fat)g F"
    }

    private func formatComponent(_ comp: FoodComponent) -> String {
        "**\(comp.name)** (\(comp.portion)) — \(comp.calories) cal · \(comp.protein)g P · \(comp.carbs)g C · \(comp.fat)g F"
    }

    // MARK: - "Almost done" message

    private func buildAlmostDoneMessage(remaining: Remaining) -> String {
        let anySmallGap = remaining.protein > 0 || remaining.carbs > 0 || remaining.fat > 0
        if anySmallGap {
            var parts: [String] = []
            if remaining.protein > 0 { parts.append("\(Int(remaining.protein))g protein") }
            if remaining.carbs   > 0 { parts.append("\(Int(remaining.carbs))g carbs") }
            if remaining.fat     > 0 { parts.append("\(Int(remaining.fat))g fat") }
            let gap = parts.joined(separator: ", ")
            return "You're almost there — just \(gap) left to fill. A light snack or drink should do it."
        }
        return "**All macros met!** Great job hitting every goal today."
    }

    // MARK: - Output formatting

    private func formatOutput(remaining: Remaining, over: Over, suggestions: [String]) -> String {
        var lines: [String] = []

        // Remaining macro summary
        var gaps: [String] = []
        if remaining.protein > Self.significantGap && !over.protein { gaps.append("\(Int(remaining.protein))g protein") }
        if remaining.carbs   > Self.significantGap && !over.carbs   { gaps.append("\(Int(remaining.carbs))g carbs") }
        if remaining.fat     > Self.significantGap && !over.fat     { gaps.append("\(Int(remaining.fat))g fat") }

        var overList: [String] = []
        if over.protein { overList.append("protein") }
        if over.carbs   { overList.append("carbs") }
        if over.fat     { overList.append("fat") }

        if !gaps.isEmpty {
            lines.append("**Still needed:** \(gaps.joined(separator: " · "))")
        }
        if !overList.isEmpty {
            lines.append("**Over goal:** \(overList.joined(separator: ", ")) — skip foods high in \(overList.joined(separator: "/"))")
        }

        lines.append("")
        lines.append("**Here's what to eat:**")
        for s in suggestions {
            lines.append("• \(s)")
        }

        return lines.joined(separator: "\n")
    }
}
