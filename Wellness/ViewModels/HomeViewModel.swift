//
//  HomeViewModel.swift
//  Wellness
//

import Foundation
import SwiftData

@Observable final class HomeViewModel {
    // MARK: - Selected date (drives all fetches)
    var selectedDate: Date {
        didSet {
            if !Calendar.current.isDate(selectedDate, inSameDayAs: oldValue) {
                loadTodayTotals()
            }
        }
    }

    // MARK: - Fasting window (persisted)
    var windowStartHour: Int {
        didSet { UserDefaults.standard.set(windowStartHour, forKey: "windowStartHour") }
    }
    var windowStartMinute: Int {
        didSet { UserDefaults.standard.set(windowStartMinute, forKey: "windowStartMinute") }
    }
    var windowDurationHours: Int {
        didSet { UserDefaults.standard.set(windowDurationHours, forKey: "windowDurationHours") }
    }

    var windowEndHour: Int {
        let totalMinutes = windowStartHour * 60 + windowStartMinute + windowDurationHours * 60
        return (totalMinutes / 60) % 24
    }
    var windowEndMinute: Int {
        let totalMinutes = windowStartHour * 60 + windowStartMinute + windowDurationHours * 60
        return totalMinutes % 60
    }
    var windowStartFractional: Double { Double(windowStartHour) + Double(windowStartMinute) / 60.0 }
    var windowEndFractional: Double   { windowStartFractional + Double(windowDurationHours) }

    // MARK: - Today's macro totals (for selectedDate)
    var totalCalories: Double = 0
    var totalProtein:  Double = 0
    var totalCarbs:    Double = 0
    var totalFat:      Double = 0

    // MARK: - Macro goals (persisted, sensible defaults)
    var goalCalories: Double = 2000 {
        didSet { UserDefaults.standard.set(goalCalories, forKey: "goalCalories") }
    }
    var goalProtein: Double = 150 {
        didSet { UserDefaults.standard.set(goalProtein, forKey: "goalProtein") }
    }
    var goalCarbs: Double = 200 {
        didSet { UserDefaults.standard.set(goalCarbs, forKey: "goalCarbs") }
    }
    var goalFat: Double = 65 {
        didSet { UserDefaults.standard.set(goalFat, forKey: "goalFat") }
    }

    // MARK: - Weight (persisted)
    var currentWeight: Double = 0 {
        didSet { UserDefaults.standard.set(currentWeight, forKey: "currentWeight") }
    }
    var goalWeight: Double = 0 {
        didSet {
            UserDefaults.standard.set(goalWeight, forKey: "goalWeight")
            if goalWeight > 0 { recalculateMacrosFromGoalWeight() }
        }
    }

    // MARK: - Streaks & activity (always based on today, not selectedDate)
    var macroStreak: Int = 0
    var daysLoggedThisWeek: Int = 0

    private let modelContext: ModelContext

    init(modelContext: ModelContext,
         selectedDate: Date = Calendar.current.startOfDay(for: Date())) {
        self.modelContext  = modelContext
        self.selectedDate  = selectedDate

        let storedHour = UserDefaults.standard.object(forKey: "windowStartHour")
        self.windowStartHour   = storedHour != nil ? UserDefaults.standard.integer(forKey: "windowStartHour") : 9
        self.windowStartMinute = UserDefaults.standard.integer(forKey: "windowStartMinute")

        let storedDuration = UserDefaults.standard.object(forKey: "windowDurationHours")
        self.windowDurationHours = storedDuration != nil
            ? UserDefaults.standard.integer(forKey: "windowDurationHours")
            : 8

        if UserDefaults.standard.object(forKey: "goalCalories") != nil {
            self.goalCalories = UserDefaults.standard.double(forKey: "goalCalories")
        }
        if UserDefaults.standard.object(forKey: "goalProtein") != nil {
            self.goalProtein = UserDefaults.standard.double(forKey: "goalProtein")
        }
        if UserDefaults.standard.object(forKey: "goalCarbs") != nil {
            self.goalCarbs = UserDefaults.standard.double(forKey: "goalCarbs")
        }
        if UserDefaults.standard.object(forKey: "goalFat") != nil {
            self.goalFat = UserDefaults.standard.double(forKey: "goalFat")
        }
        self.currentWeight = UserDefaults.standard.double(forKey: "currentWeight")
        self.goalWeight    = UserDefaults.standard.double(forKey: "goalWeight")

        loadTodayTotals()
    }

    func loadTodayTotals() {
        let calendar   = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        let predicate  = #Predicate<FoodEntry> { $0.loggedAt >= startOfDay && $0.loggedAt < endOfDay }
        let descriptor = FetchDescriptor<FoodEntry>(predicate: predicate)
        guard let entries = try? modelContext.fetch(descriptor) else { return }

        totalCalories = entries.reduce(0) { $0 + $1.calories }
        totalProtein  = entries.reduce(0) { $0 + $1.protein }
        totalCarbs    = entries.reduce(0) { $0 + $1.carbs }
        totalFat      = entries.reduce(0) { $0 + $1.fat }

        loadStreaks()
    }

    // MARK: - Macro recalculation from goal weight

    /// Recalculates macro goals from goal weight using evidence-based estimates:
    /// - Calories: ~14 kcal/lb goal weight (moderate activity, mild deficit)
    /// - Protein:  0.9 g/lb goal weight (optimal for strength + training / muscle retention)
    /// - Fat:      25% of total calories (minimum healthy fat intake)
    /// - Carbs:    remainder of calories after protein and fat
    func recalculateMacrosFromGoalWeight() {
        guard goalWeight > 0 else { return }
        let cals    = goalWeight * 14.0
        let protein = goalWeight * 0.9
        let fat     = (cals * 0.25) / 9.0
        let carbs   = (cals - protein * 4.0 - fat * 9.0) / 4.0

        goalCalories = max(cals,    1200)
        goalProtein  = max(protein,   50)
        goalFat      = max(fat,       30)
        goalCarbs    = max(carbs,     50)
    }

    // MARK: - Private

    private func loadStreaks() {
        // Streaks always reflect today, not selectedDate
        let calendar = Calendar.current

        var streak = 0
        var offset = 1
        while offset <= 60 {
            guard let checkDate = calendar.date(byAdding: .day, value: -offset, to: Date()) else { break }
            let dayStart = calendar.startOfDay(for: checkDate)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { break }

            let pred = #Predicate<FoodEntry> { $0.loggedAt >= dayStart && $0.loggedAt < dayEnd }
            guard let entries = try? modelContext.fetch(FetchDescriptor<FoodEntry>(predicate: pred)),
                  !entries.isEmpty else { break }

            let cal = entries.reduce(0.0) { $0 + $1.calories }
            let pro = entries.reduce(0.0) { $0 + $1.protein }
            let car = entries.reduce(0.0) { $0 + $1.carbs }
            let fat = entries.reduce(0.0) { $0 + $1.fat }

            let hit = cal >= goalCalories * 0.85 && cal <= goalCalories * 1.10
                   && pro >= goalProtein * 0.90
                   && car <= goalCarbs   * 1.10
                   && fat <= goalFat     * 1.10

            if hit { streak += 1 } else { break }
            offset += 1
        }
        macroStreak = streak

        var logged = 0
        for i in 0..<7 {
            guard let checkDate = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let dayStart = calendar.startOfDay(for: checkDate)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }

            let pred = #Predicate<FoodEntry> { $0.loggedAt >= dayStart && $0.loggedAt < dayEnd }
            if let entries = try? modelContext.fetch(FetchDescriptor<FoodEntry>(predicate: pred)),
               !entries.isEmpty {
                logged += 1
            }
        }
        daysLoggedThisWeek = logged
    }
}
