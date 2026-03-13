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

    // MARK: - Fasting window (persisted — always today's editable values)
    var windowStartHour: Int {
        didSet { UserDefaults.standard.set(windowStartHour, forKey: "windowStartHour"); snapshotTodayWindow() }
    }
    var windowStartMinute: Int {
        didSet { UserDefaults.standard.set(windowStartMinute, forKey: "windowStartMinute"); snapshotTodayWindow() }
    }
    var windowDurationHours: Int {
        didSet { UserDefaults.standard.set(windowDurationHours, forKey: "windowDurationHours"); snapshotTodayWindow() }
    }

    var isSelectedDateToday: Bool { Calendar.current.isDateInToday(selectedDate) }

    // MARK: - Per-date window snapshots
    // Displayed properties return the snapshot for past dates, live values for today.
    // Past dates with no snapshot return 0/0/0 — callers should check hasWindowForSelectedDate first.
    var displayedWindowStartHour:   Int { windowForDisplayedDate["startHour"]     ?? windowStartHour }
    var displayedWindowStartMinute: Int { windowForDisplayedDate["startMinute"]   ?? windowStartMinute }
    var displayedWindowDuration:    Int { windowForDisplayedDate["durationHours"] ?? windowDurationHours }

    private var windowForDisplayedDate: [String: Int] {
        if isSelectedDateToday { return ["startHour": windowStartHour, "startMinute": windowStartMinute, "durationHours": windowDurationHours] }
        // Use snapshot if one exists; fall back to current setting for dates before snapshots existed
        return dailyWindowSnapshots[dateKey(selectedDate)] ?? ["startHour": windowStartHour, "startMinute": windowStartMinute, "durationHours": windowDurationHours]
    }

    private var dailyWindowSnapshots: [String: [String: Int]] {
        get {
            guard let outer = UserDefaults.standard.dictionary(forKey: "dailyWindowSnapshots") else { return [:] }
            // UserDefaults stores Int as NSNumber, so cast each value explicitly
            var result: [String: [String: Int]] = [:]
            for (dateKey, value) in outer {
                guard let inner = value as? [String: Any] else { continue }
                var innerInts: [String: Int] = [:]
                for (k, v) in inner {
                    if let i = v as? Int { innerInts[k] = i }
                    else if let n = v as? NSNumber { innerInts[k] = n.intValue }
                }
                result[dateKey] = innerInts
            }
            return result
        }
        set { UserDefaults.standard.set(newValue, forKey: "dailyWindowSnapshots") }
    }

    func snapshotTodayWindow() {
        let key = dateKey(Date())
        var snapshots = dailyWindowSnapshots
        snapshots[key] = ["startHour": windowStartHour, "startMinute": windowStartMinute, "durationHours": windowDurationHours]
        dailyWindowSnapshots = snapshots
    }

    private func dateKey(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }

    var windowEndHour: Int {
        let totalMinutes = displayedWindowStartHour * 60 + displayedWindowStartMinute + displayedWindowDuration * 60
        return (totalMinutes / 60) % 24
    }
    var windowEndMinute: Int {
        let totalMinutes = displayedWindowStartHour * 60 + displayedWindowStartMinute + displayedWindowDuration * 60
        return totalMinutes % 60
    }
    var windowStartFractional: Double { Double(displayedWindowStartHour) + Double(displayedWindowStartMinute) / 60.0 }
    var windowEndFractional: Double   { windowStartFractional + Double(displayedWindowDuration) }

    // MARK: - Today's macro totals (for selectedDate)
    var totalCalories: Double = 0
    var totalProtein:  Double = 0
    var totalCarbs:    Double = 0
    var totalFat:      Double = 0

    // MARK: - Meal log times for today (fractional hours, e.g. 12.5 = 12:30)
    var mealLogTimes: [Double] = []

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
            // Calories: stay within a range (not too low, not too high)
            totalCalories >= goalCalories * 0.85 && totalCalories <= goalCalories * 1.15,
            // Protein & fat: floor only — eating more than the goal is always a win
            totalProtein  >= goalProtein  * 0.85,
            // Carbs: floor only — going over isn't penalised either
            totalCarbs    >= goalCarbs    * 0.85,
            totalFat      >= goalFat      * 0.85
        ]
    }
    var macrosMetToday: Int { macroGoalsMet.filter { $0 }.count }

    // MARK: - Brainstorm state
    enum BrainstormState: Equatable {
        case idle, loading, result(String), error(String)
    }
    var brainstormState: BrainstormState = .idle

    // MARK: - Streak (consecutive days where ALL macro goals were met, ending yesterday)
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

        // Backfill any past days that have no snapshot with the current (pre-edit) window
        // values, so that editing today can't retroactively change how past days look.
        let currentSnapshot = ["startHour": windowStartHour, "startMinute": windowStartMinute, "durationHours": windowDurationHours]
        var snapshots = dailyWindowSnapshots
        let today = Date()
        for offset in 1...90 {
            guard let day = Calendar.current.date(byAdding: .day, value: -offset, to: today) else { break }
            let key = dateKey(day)
            if snapshots[key] == nil { snapshots[key] = currentSnapshot }
        }
        dailyWindowSnapshots = snapshots

        // Ensure today always has a snapshot so past days see their actual recorded window
        snapshotTodayWindow()
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

        let cal = Calendar.current
        mealLogTimes = entries.map { entry in
            let h = Double(cal.component(.hour,   from: entry.loggedAt))
            let m = Double(cal.component(.minute, from: entry.loggedAt))
            return h + m / 60.0
        }

        // Record whether all macro goals were met today so streak can track it
        let allMet = totalCalories > 0 && macroGoalsMet.allSatisfy { $0 }
        userSettings.setGoalsMet(allMet, for: selectedDate)

        loadStreak()
    }

    // MARK: - Brainstorm

    func brainstorm() async {
        brainstormState = .loading
        let input = ClaudeAnalysisService.BrainstormInput(
            totalCalories: totalCalories, goalCalories: goalCalories,
            totalProtein:  totalProtein,  goalProtein:  goalProtein,
            totalCarbs:    totalCarbs,    goalCarbs:    goalCarbs,
            totalFat:      totalFat,      goalFat:      goalFat
        )
        do {
            let result = try await ClaudeAnalysisService().brainstorm(input)
            brainstormState = .result(result)
        } catch {
            brainstormState = .error(error.localizedDescription)
        }
    }

    func resetBrainstorm() { brainstormState = .idle }

    // MARK: - Macro recalculation from goal weight

    func recalculateMacrosFromGoalWeight() {
        let gw = userSettings.goalWeight
        guard gw > 0 else { return }
        let cals    = gw * 14.0
        let protein = gw * userSettings.proteinPerLb
        let fat     = (cals * 0.25) / 9.0
        let carbs   = (cals - protein * 4.0 - fat * 9.0) / 4.0

        goalCalories = max(cals,    1200)
        goalProtein  = max(protein,   50)
        goalFat      = max(fat,       30)
        goalCarbs    = max(carbs,     50)
    }

    // MARK: - Private

    private func loadStreak() {
        let calendar    = Calendar.current
        let goalsMetDates = userSettings.goalsMetDates
        let fmt         = DateFormatter()
        fmt.dateFormat  = "yyyy-MM-dd"
        fmt.calendar    = calendar

        var streak = 0
        var offset = 1
        while offset <= 365 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { break }
            if goalsMetDates.contains(fmt.string(from: day)) { streak += 1 } else { break }
            offset += 1
        }
        macroStreak              = streak
        userSettings.macroStreak = streak
        checkStreakMilestones(streak)
    }

    private func checkStreakMilestones(_ streak: Int) {
        let milestones: [(days: Int, pts: Int, reason: String, msg: String)] = [
            (3,    50,  "🔥 3-Day Streak",   "3 days of hitting every goal. that's discipline."),
            (7,   150,  "🔥 7-Day Streak",   "one full week of locking in on every macro. keep it going."),
            (14,  300,  "🔥 14-Day Streak",  "two straight weeks of meeting every goal. real consistency."),
            (30,  500,  "🔥 30-Day Streak",  "30 days of actually hitting your numbers. that's rare."),
            (60,  750,  "🔥 60-Day Streak",  "60 days of goal-hitting discipline. the results are showing."),
            (100, 1000, "🔥 100-Day Streak", "100 days of meeting every macro goal. you're built different."),
        ]
        for m in milestones where streak >= m.days && !userSettings.achievedMilestones.contains(m.days) {
            userSettings.markMilestoneAchieved(m.days)
            userSettings.awardAura(points: m.pts)
        }
    }
}
