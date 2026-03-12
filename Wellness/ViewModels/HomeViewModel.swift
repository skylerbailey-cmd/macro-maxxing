//
//  HomeViewModel.swift
//  Wellness
//

import Foundation
import SwiftData

@Observable final class HomeViewModel {
    // MARK: - Selected date
    var selectedDate: Date {
        didSet {
            if !Calendar.current.isDate(selectedDate, inSameDayAs: oldValue) {
                loadTodayTotals()
            }
        }
    }

    // MARK: - User settings (shared reference)
    let userSettings: UserSettings

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

    // MARK: - Macro goals (persisted)
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

    // MARK: - Macros met today (computed from totals vs goals)
    /// True/false for [calories, protein, carbs, fat]
    var macroGoalsMet: [Bool] {
        guard totalCalories > 0 else { return [false, false, false, false] }
        return [
            totalCalories >= goalCalories * 0.85 && totalCalories <= goalCalories * 1.10,
            totalProtein  >= goalProtein  * 0.90,
            totalCarbs    >  0 && totalCarbs <= goalCarbs * 1.10,
            totalFat      >  0 && totalFat  <= goalFat   * 1.10
        ]
    }
    var macrosMetToday: Int { macroGoalsMet.filter { $0 }.count }

    // MARK: - Streak (consecutive days with any food logged, ending yesterday)
    var macroStreak: Int = 0

    private let modelContext: ModelContext

    init(modelContext: ModelContext,
         selectedDate: Date = Calendar.current.startOfDay(for: Date()),
         userSettings: UserSettings) {
        self.modelContext  = modelContext
        self.selectedDate  = selectedDate
        self.userSettings  = userSettings

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

        // Data is loaded lazily from the view's onAppear to avoid blocking init
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

        loadStreak()
    }

    // MARK: - Macro recalculation from goal weight

    func recalculateMacrosFromGoalWeight() {
        let gw = userSettings.goalWeight
        guard gw > 0 else { return }
        let cals    = gw * 14.0
        let protein = gw * 0.9
        let fat     = (cals * 0.25) / 9.0
        let carbs   = (cals - protein * 4.0 - fat * 9.0) / 4.0

        goalCalories = max(cals,    1200)
        goalProtein  = max(protein,   50)
        goalFat      = max(fat,       30)
        goalCarbs    = max(carbs,     50)
    }

    // MARK: - Private

    private func loadStreak() {
        // Single bulk query for the last 366 days, then group by day in memory.
        // This replaces the previous N+1 pattern (up to 365 individual fetches).
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -366, to: Date()) else { return }

        let pred = #Predicate<FoodEntry> { $0.loggedAt >= cutoff }
        guard let entries = try? modelContext.fetch(FetchDescriptor<FoodEntry>(predicate: pred)) else { return }

        // Build a set of "yyyy-MM-dd" strings for days that have entries
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.calendar   = calendar
        let daysWithFood = Set(entries.map { fmt.string(from: $0.loggedAt) })

        var streak = 0
        var offset = 1
        while offset <= 365 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { break }
            if daysWithFood.contains(fmt.string(from: day)) { streak += 1 } else { break }
            offset += 1
        }
        macroStreak = streak
    }
}
