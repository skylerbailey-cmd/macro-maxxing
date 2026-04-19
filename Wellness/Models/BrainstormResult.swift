//
//  BrainstormResult.swift
//  Wellness
//
//  Structured output from the AI Meal Planner.

import Foundation

/// A single meal/snack suggestion card.
struct MealSuggestion: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let portion: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    /// Why this meal was picked (e.g. "Fills your protein gap with minimal carbs")
    let reason: String
    /// "Meal" or "Snack"
    let category: String

    init(name: String, portion: String, calories: Int, protein: Int,
         carbs: Int, fat: Int, reason: String, category: String) {
        self.id       = UUID().uuidString
        self.name     = name
        self.portion  = portion
        self.calories = calories
        self.protein  = protein
        self.carbs    = carbs
        self.fat      = fat
        self.reason   = reason
        self.category = category
    }
}

/// Full brainstorm result — macro gaps + meal cards.
struct BrainstormResult: Codable, Equatable {
    let remainingCalories: Int
    let remainingProtein: Int
    let remainingCarbs: Int
    let remainingFat: Int

    let overProtein: Bool
    let overCarbs: Bool
    let overFat: Bool

    /// Human-readable gap summary for the overview card.
    let gapSummary: String

    /// 3 suggestions: 2 meals + 1 snack.
    let suggestions: [MealSuggestion]

    /// Fallback plain-text message when all macros are met/over.
    let completionMessage: String?
}

/// A saved meal plan — wraps a BrainstormResult with metadata.
struct SavedMealPlan: Identifiable, Codable, Equatable {
    let id: String
    let date: Date
    let result: BrainstormResult

    init(result: BrainstormResult) {
        self.id     = UUID().uuidString
        self.date   = Date()
        self.result = result
    }
}

/// Persists the last 3 meal plans in UserDefaults.
enum SavedMealPlanStore {
    private static let key = "savedMealPlans"
    private static let maxPlans = 30

    static func load() -> [SavedMealPlan] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let plans = try? JSONDecoder().decode([SavedMealPlan].self, from: data)
        else { return [] }
        return plans
    }

    static func save(_ plan: SavedMealPlan) {
        var plans = load()
        plans.insert(plan, at: 0)
        if plans.count > maxPlans { plans = Array(plans.prefix(maxPlans)) }
        if let data = try? JSONEncoder().encode(plans) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func delete(_ id: String) {
        var plans = load()
        plans.removeAll { $0.id == id }
        if let data = try? JSONEncoder().encode(plans) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
