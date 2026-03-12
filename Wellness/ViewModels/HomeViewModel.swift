//
//  HomeViewModel.swift
//  Wellness
//

import Foundation
import SwiftData

@Observable final class HomeViewModel {
    // Fasting window — persisted as hour+minute in UserDefaults
    var windowStartHour: Int {
        didSet { UserDefaults.standard.set(windowStartHour, forKey: "windowStartHour") }
    }
    var windowStartMinute: Int {
        didSet { UserDefaults.standard.set(windowStartMinute, forKey: "windowStartMinute") }
    }
    let windowDurationHours: Int = 8

    // Derived end time
    var windowEndHour: Int {
        let totalMinutes = windowStartHour * 60 + windowStartMinute + windowDurationHours * 60
        return (totalMinutes / 60) % 24
    }
    var windowEndMinute: Int {
        let totalMinutes = windowStartHour * 60 + windowStartMinute + windowDurationHours * 60
        return totalMinutes % 60
    }

    // Fractional hours for chart (0.0 – 24.0)
    var windowStartFractional: Double {
        Double(windowStartHour) + Double(windowStartMinute) / 60.0
    }
    var windowEndFractional: Double {
        windowStartFractional + Double(windowDurationHours)
    }

    // Today's macro totals
    var totalCalories: Double = 0
    var totalProtein: Double = 0
    var totalCarbs: Double = 0
    var totalFat: Double = 0

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let storedHour = UserDefaults.standard.object(forKey: "windowStartHour")
        self.windowStartHour = storedHour != nil ? UserDefaults.standard.integer(forKey: "windowStartHour") : 9
        self.windowStartMinute = UserDefaults.standard.integer(forKey: "windowStartMinute")
        loadTodayTotals()
    }

    func loadTodayTotals() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        let predicate = #Predicate<FoodEntry> { entry in
            entry.loggedAt >= startOfDay && entry.loggedAt < endOfDay
        }
        let descriptor = FetchDescriptor<FoodEntry>(predicate: predicate)

        guard let entries = try? modelContext.fetch(descriptor) else { return }
        totalCalories = entries.reduce(0) { $0 + $1.calories }
        totalProtein  = entries.reduce(0) { $0 + $1.protein }
        totalCarbs    = entries.reduce(0) { $0 + $1.carbs }
        totalFat      = entries.reduce(0) { $0 + $1.fat }
    }
}
