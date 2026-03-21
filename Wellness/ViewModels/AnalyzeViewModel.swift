//
//  AnalyzeViewModel.swift
//  Wellness
//

import Foundation

@MainActor @Observable final class AnalyzeViewModel {
    enum State: Equatable {
        case idle
        case analyzing
        case result(String)
        case error(String)
    }

    var state:        State = .idle
    var selectedDate: Date
    private let userID: String

    /// True if Log Meals has already been run today (real calendar today).
    var hasRunToday: Bool {
        guard let t = UserDefaults.standard.object(forKey: lastRunKey) as? Double else { return false }
        return Calendar.current.isDateInToday(Date(timeIntervalSince1970: t))
    }

    private let service = ClaudeAnalysisService()

    // Per-user keys so cached results don't leak across accounts.
    private let lastRunKey:    String
    private let resultKey:     String
    private let resultDateKey: String

    init(userID: String,
         selectedDate: Date = Calendar.current.startOfDay(for: Date())) {
        self.userID       = userID
        self.selectedDate = selectedDate
        self.lastRunKey    = "lastLogMealsDate_\(userID)"
        self.resultKey     = "aiCoachResult_\(userID)"
        self.resultDateKey = "aiCoachResultDate_\(userID)"
        restoreIfToday()
    }

    func analyze() async {
        state = .analyzing

        async let foodFetch    = FoodEntryService.shared.fetch(userID: userID, date: selectedDate)
        async let workoutFetch = WorkoutService.shared.fetch(userID: userID, date: selectedDate)

        let entries  = (try? await foodFetch)    ?? []
        let workouts = (try? await workoutFetch) ?? []

        // Read current macro goals from UserDefaults (written by HomeViewModel)
        let ud = UserDefaults.standard
        func goal(_ key: String, fallback: Double) -> Double {
            ud.object(forKey: key) != nil ? ud.double(forKey: key) : fallback
        }

        let workoutSummaries = workouts.map {
            ClaudeAnalysisService.WorkoutSummary(
                name:            $0.name,
                type:            $0.workoutType.rawValue,
                durationMinutes: $0.durationMinutes,
                caloriesBurned:  $0.caloriesBurned,
                loggedAt:        $0.loggedAt
            )
        }

        // Read fasting window if enabled
        let fastingEnabled = ud.bool(forKey: "fastingEnabled")
        let fastingWindow: ClaudeAnalysisService.NutritionInput.FastingWindow? = fastingEnabled ? (
            startHour:     ud.integer(forKey: "windowStartHour"),
            startMinute:   ud.integer(forKey: "windowStartMinute"),
            durationHours: {
                let d = ud.integer(forKey: "windowDurationHours")
                return d > 0 ? d : 16
            }()
        ) : nil

        let input = ClaudeAnalysisService.NutritionInput(
            entries:      entries.map { (name: $0.foodName, calories: $0.calories,
                                         protein: $0.protein, carbs: $0.carbs, fat: $0.fat,
                                         loggedAt: $0.loggedAt) },
            goalCalories: goal("goalCalories", fallback: 2000),
            goalProtein:  goal("goalProtein",  fallback: 150),
            goalCarbs:    goal("goalCarbs",    fallback: 200),
            goalFat:      goal("goalFat",      fallback: 65),
            date:         selectedDate,
            workouts:     workoutSummaries,
            fastingWindow: fastingWindow
        )

        do {
            let result = try await service.analyze(input)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastRunKey)
            UserDefaults.standard.set(result, forKey: resultKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: resultDateKey)
            state = .result(result)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// Resets to idle, unless the selected date is today and a persisted result exists.
    func reset() {
        if Calendar.current.isDateInToday(selectedDate) {
            restoreIfToday()
        } else {
            state = .idle
        }
    }

    // MARK: - Private

    private func restoreIfToday() {
        let ud = UserDefaults.standard
        guard
            let ts     = ud.object(forKey: resultDateKey) as? Double,
            Calendar.current.isDateInToday(Date(timeIntervalSince1970: ts)),
            let saved  = ud.string(forKey: resultKey),
            !saved.isEmpty
        else { return }
        state = .result(saved)
    }
}
