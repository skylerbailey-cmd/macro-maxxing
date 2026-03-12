//
//  AnalyzeViewModel.swift
//  Wellness
//

import Foundation
import SwiftData

@Observable final class AnalyzeViewModel {
    enum State: Equatable {
        case idle
        case analyzing
        case result(String)
        case error(String)
    }

    var state:        State = .idle
    var selectedDate: Date

    /// True if Log Meals has already been run today (real calendar today).
    var hasRunToday: Bool {
        guard let t = UserDefaults.standard.object(forKey: "lastLogMealsDate") as? Double else { return false }
        return Calendar.current.isDateInToday(Date(timeIntervalSince1970: t))
    }

    private let modelContext: ModelContext
    private let service = ClaudeAnalysisService()

    init(modelContext: ModelContext,
         selectedDate: Date = Calendar.current.startOfDay(for: Date())) {
        self.modelContext = modelContext
        self.selectedDate = selectedDate
    }

    func analyze() async {
        state = .analyzing

        // Fetch entries for the selected date
        let calendar   = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            state = .error("Could not determine date range.")
            return
        }

        let predicate  = #Predicate<FoodEntry> { $0.loggedAt >= startOfDay && $0.loggedAt < endOfDay }
        let descriptor = FetchDescriptor<FoodEntry>(predicate: predicate,
                                                    sortBy: [SortDescriptor(\.loggedAt)])
        let entries = (try? modelContext.fetch(descriptor)) ?? []

        // Read current macro goals from UserDefaults (written by HomeViewModel)
        let ud = UserDefaults.standard
        func goal(_ key: String, fallback: Double) -> Double {
            ud.object(forKey: key) != nil ? ud.double(forKey: key) : fallback
        }

        let input = ClaudeAnalysisService.NutritionInput(
            entries:      entries.map { (name: $0.foodName, calories: $0.calories,
                                         protein: $0.protein, carbs: $0.carbs, fat: $0.fat) },
            goalCalories: goal("goalCalories", fallback: 2000),
            goalProtein:  goal("goalProtein",  fallback: 150),
            goalCarbs:    goal("goalCarbs",    fallback: 200),
            goalFat:      goal("goalFat",      fallback: 65),
            date:         selectedDate
        )

        do {
            let result = try await service.analyze(input)
            // Mark today as used
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastLogMealsDate")
            state = .result(result)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func reset() {
        state = .idle
    }
}
