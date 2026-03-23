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
    var tier: Int            // 1, 2, or 3
    var source: String       // which APIs were used
    var confidence: Double
    var needsUserConfirmation: Bool

    /// Components for mixed meals (Tier 3)
    var components: [MealComponent]?

    var tierBadge: String {
        switch tier {
        case 1:  return "⚡ Instant"
        case 2:  return "🔍 Enhanced"
        case 3:  return "🧠 AI Analysis"
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

/// Intermediate result from Claude Haiku (Tier 2 Step 1)
struct HaikuFoodIdentification: Codable {
    let foodName: String
    let portionGrams: Double
    let isMixedMeal: Bool
    let confidence: Double
    /// Individual food items identified on the plate (used for hybrid Haiku→Sonnet flow)
    let items: [HaikuFoodItem]?
}

/// A single food item identified by Haiku vision
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
