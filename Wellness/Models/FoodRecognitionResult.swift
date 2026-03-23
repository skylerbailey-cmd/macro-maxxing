//
//  FoodRecognitionResult.swift
//  Wellness
//

import Foundation

struct MacrosPer100g {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double

    func scaled(to portionGrams: Double) -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let factor = portionGrams / 100.0
        return (
            calories: calories * factor,
            protein: protein * factor,
            carbs: carbs * factor,
            fat: fat * factor
        )
    }
}

struct FoodRecognitionResult {
    var foodName: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var portionGrams: Double
    var tier: Int            // 1 = Haiku, 2 = Sonnet
    var source: String       // which APIs were used
    var confidence: Double
    var needsUserConfirmation: Bool

    /// Components for mixed meals (Tier 3)
    var components: [MealComponent]?

    var tierBadge: String {
        switch tier {
        case 1:  return "🔍 AI Scan"
        case 2:  return "🧠 AI Analysis"
        default: return "Unknown"
        }
    }
}

struct MealComponent: Codable {
    let name: String
    let portionGrams: Double
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
}

/// Intermediate result from Claude Haiku — identification + macro estimation in one call.
struct HaikuFoodIdentification: Codable {
    let foodName: String
    let portionGrams: Double
    let isMixedMeal: Bool
    let confidence: Double
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let components: [MealComponent]?
}

/// Lightweight food item used by Sonnet text-only macro estimation
struct HaikuFoodItem: Codable {
    let name: String
    let portionGrams: Double
}

/// Intermediate result from database lookups
struct MacroResult: Codable {
    let food: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let source: String

    init(food: String, calories: Double, protein: Double, carbs: Double, fat: Double, source: String = "") {
        self.food = food
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.source = source
    }
}

/// Full Sonnet response (Tier 3)
struct SonnetAnalysisResult: Codable {
    let foodName: String
    let components: [MealComponent]?
    let portionGrams: Double
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let confidenceScore: Double
    let reasoning: String?
}
