//
//  MacroAdjustmentEngine.swift
//  Wellness
//
//  Scientifically grounded macro adjustments based on workout type.
//
//  Sources:
//  - ISSN Position Stand: Nutrition & Athletic Performance (Stout et al. 2018)
//  - Phillips & Van Loon (2011): Dietary protein for athletes — 1.4–2.0 g/kg/day
//  - Burke et al. (2011): Carbohydrates for training & recovery
//  - Jeukendrup (2011): Nutrition for endurance sports
//  - Churchward-Venne et al. (2012): Post-exercise protein synthesis window
//

import Foundation

// MARK: - WorkoutType

enum WorkoutType: String, CaseIterable, Codable {
    case strength    = "Strength"
    case cardio      = "Cardio"
    case hiit        = "HIIT"
    case flexibility = "Flexibility / Yoga"
    case restDay     = "Rest Day"
    case other       = "Other"

    var icon: String {
        switch self {
        case .strength:    return "dumbbell.fill"
        case .cardio:      return "figure.run"
        case .hiit:        return "bolt.heart.fill"
        case .flexibility: return "figure.flexibility"
        case .restDay:     return "moon.zzz.fill"
        case .other:       return "figure.mixed.cardio"
        }
    }

    var shortLabel: String {
        switch self {
        case .strength:    return "Strength"
        case .cardio:      return "Cardio"
        case .hiit:        return "HIIT"
        case .flexibility: return "Flex / Yoga"
        case .restDay:     return "Rest Day"
        case .other:       return "Other"
        }
    }
}

// MARK: - MacroAdjustment

struct MacroAdjustment {
    let caloriesDelta: Int  // kcal
    let carbsDelta:    Int  // g
    let proteinDelta:  Int  // g
    let fatDelta:      Int  // g

    var isEmpty: Bool {
        caloriesDelta == 0 && carbsDelta == 0 && proteinDelta == 0 && fatDelta == 0
    }
}

// MARK: - Per-kg rates (evidence-based)
//
// Carbohydrate replenishment: 0.3–0.45 g/kg per session (Burke et al. 2011)
// Post-exercise protein: 0.25–0.40 g/kg per session (Witard et al. 2014)
// Fat: slightly reduced on high-carb days to keep total calories appropriate
// Rest day: carbs ↓ 0.30 g/kg, fat ↑ 0.08 g/kg for hormone support & satiety (Phillips 2011)

private struct PerKgRates {
    let carbs:   Double   // g/kg
    let protein: Double   // g/kg
    let fat:     Double   // g/kg (negative = reduction)
}

// MARK: - MacroAdjustmentEngine

enum MacroAdjustmentEngine {

    // MARK: Adjustment Calculation (weight-personalised)

    /// Returns macro deltas scaled to the user's body weight.
    /// - Parameter bodyWeightLbs: User's current weight in pounds (from UserSettings).
    static func adjustment(for type: WorkoutType, bodyWeightLbs: Double) -> MacroAdjustment {
        let kg = max(40, bodyWeightLbs) / 2.20462  // guard against 0

        let rates: PerKgRates
        switch type {
        case .strength:    rates = PerKgRates(carbs:  0.30, protein: 0.15, fat:  0.00)
        case .cardio:      rates = PerKgRates(carbs:  0.40, protein: 0.10, fat: -0.07)
        case .hiit:        rates = PerKgRates(carbs:  0.45, protein: 0.15, fat: -0.04)
        case .flexibility: rates = PerKgRates(carbs:  0.07, protein: 0.00, fat:  0.00)
        case .restDay:     rates = PerKgRates(carbs: -0.30, protein: 0.00, fat:  0.08)
        case .other:       rates = PerKgRates(carbs:  0.20, protein: 0.07, fat:  0.00)
        }

        let carbs   = Int((rates.carbs   * kg).rounded())
        let protein = Int((rates.protein * kg).rounded())
        let fat     = Int((rates.fat     * kg).rounded())
        // Calories derived from macros (1g carb = 4 kcal, 1g protein = 4 kcal, 1g fat = 9 kcal)
        let calories = carbs * 4 + protein * 4 + fat * 9

        return MacroAdjustment(caloriesDelta: calories, carbsDelta: carbs,
                               proteinDelta: protein, fatDelta: fat)
    }

    // MARK: Notification

    static let macroAdjustedNotification = Notification.Name("com.sbailey.Wellness.macroAdjusted")

    // MARK: UserDefaults keys

    private static let baseCalKey  = "base_goalCalories"
    private static let basePrtKey  = "base_goalProtein"
    private static let baseCrbKey  = "base_goalCarbs"
    private static let baseFatKey  = "base_goalFat"
    private static let adjDateKey  = "workoutAdjustmentDate"

    // MARK: Apply

    /// Applies the macro adjustment for the given workout type to today's goals.
    /// Preserves the original base goals and restores them automatically tomorrow.
    static func apply(for type: WorkoutType, bodyWeightLbs: Double) {
        let ud    = UserDefaults.standard
        let today = todayString()

        // Save current goals as base only if no adjustment has been applied today yet
        if ud.string(forKey: adjDateKey) != today {
            ud.set(ud.double(forKey: "goalCalories"), forKey: baseCalKey)
            ud.set(ud.double(forKey: "goalProtein"),  forKey: basePrtKey)
            ud.set(ud.double(forKey: "goalCarbs"),    forKey: baseCrbKey)
            ud.set(ud.double(forKey: "goalFat"),      forKey: baseFatKey)
        }

        let adj  = adjustment(for: type, bodyWeightLbs: bodyWeightLbs)
        let base = baseGoals()
        ud.set(max(1200, base.calories + Double(adj.caloriesDelta)), forKey: "goalCalories")
        ud.set(max(50,   base.protein  + Double(adj.proteinDelta)),  forKey: "goalProtein")
        ud.set(max(50,   base.carbs    + Double(adj.carbsDelta)),    forKey: "goalCarbs")
        ud.set(max(20,   base.fat      + Double(adj.fatDelta)),      forKey: "goalFat")
        ud.set(today, forKey: adjDateKey)

        NotificationCenter.default.post(name: macroAdjustedNotification, object: nil)
    }

    // MARK: Revert (called on new day)

    /// Restores base goals if the last adjustment was on a previous day.
    /// Call this whenever the app loads or the date changes.
    static func revertIfNewDay() {
        let ud    = UserDefaults.standard
        let today = todayString()
        guard ud.string(forKey: adjDateKey) != today,
              ud.object(forKey: baseCalKey) != nil else { return }

        ud.set(ud.double(forKey: baseCalKey), forKey: "goalCalories")
        ud.set(ud.double(forKey: basePrtKey), forKey: "goalProtein")
        ud.set(ud.double(forKey: baseCrbKey), forKey: "goalCarbs")
        ud.set(ud.double(forKey: baseFatKey), forKey: "goalFat")
        ud.removeObject(forKey: adjDateKey)

        NotificationCenter.default.post(name: macroAdjustedNotification, object: nil)
    }

    // MARK: Preview (no side effects)

    /// Returns what the adjusted goals would look like without writing anything.
    static func preview(for type: WorkoutType, bodyWeightLbs: Double) -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let adj  = adjustment(for: type, bodyWeightLbs: bodyWeightLbs)
        let base = baseGoals()
        return (
            calories: max(1200, base.calories + Double(adj.caloriesDelta)),
            protein:  max(50,   base.protein  + Double(adj.proteinDelta)),
            carbs:    max(50,   base.carbs    + Double(adj.carbsDelta)),
            fat:      max(20,   base.fat      + Double(adj.fatDelta))
        )
    }

    // MARK: Helpers

    static func baseGoals() -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let ud = UserDefaults.standard
        // Use stored base if available (adjustment active today), else use current goals
        let hasBase = ud.object(forKey: baseCalKey) != nil
        return (
            calories: hasBase ? ud.double(forKey: baseCalKey) : ud.double(forKey: "goalCalories"),
            protein:  hasBase ? ud.double(forKey: basePrtKey) : ud.double(forKey: "goalProtein"),
            carbs:    hasBase ? ud.double(forKey: baseCrbKey) : ud.double(forKey: "goalCarbs"),
            fat:      hasBase ? ud.double(forKey: baseFatKey) : ud.double(forKey: "goalFat")
        )
    }

    static func isAdjustedToday() -> Bool {
        UserDefaults.standard.string(forKey: adjDateKey) == todayString()
    }

    private static func todayString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: Date())
    }
}
