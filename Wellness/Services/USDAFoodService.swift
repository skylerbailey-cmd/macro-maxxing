//
//  USDAFoodService.swift
//  Wellness
//
//  Looks up macro data from the USDA FoodData Central API (free, no API key required
//  for the demo endpoint). Used as Tier 1 macro estimation for simple, single-ingredient
//  foods identified by the on-device classifier.
//

import Foundation

// MARK: - Result

struct USDAMacroResult {
    let foodName: String
    let calories: Double
    let protein:  Double
    let carbs:    Double
    let fat:      Double
}

// MARK: - Service

final class USDAFoodService {

    static let shared = USDAFoodService()
    private init() {}

    /// USDA FoodData Central API key. The demo key has generous limits.
    /// Replace with your own key from https://fdc.nal.usda.gov/api-key-signup.html
    private let apiKey = "DEMO_KEY"

    /// Searches USDA FoodData Central for the given food name and returns
    /// macro data for the best match. Returns nil if no suitable match is found.
    /// Uses the "Foundation" data type for standardized per-100g nutrient data,
    /// then scales to a typical single serving.
    func lookup(foodName: String) async -> USDAMacroResult? {
        let query = foodName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? foodName

        guard let url = URL(string:
            "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(query)&dataType=Foundation,SR%20Legacy&pageSize=3&api_key=\(apiKey)"
        ) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("[USDAFoodService] HTTP error for \"\(foodName)\"")
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let foods = json["foods"] as? [[String: Any]],
                  let best = foods.first,
                  let nutrients = best["foodNutrients"] as? [[String: Any]]
            else {
                print("[USDAFoodService] No results for \"\(foodName)\"")
                return nil
            }

            let description = (best["description"] as? String ?? foodName).capitalized

            // Extract per-100g values from nutrient array
            var cal100: Double = 0
            var pro100: Double = 0
            var carb100: Double = 0
            var fat100: Double = 0

            for nutrient in nutrients {
                guard let id = nutrient["nutrientId"] as? Int,
                      let value = nutrient["value"] as? Double else { continue }
                switch id {
                case 1008: cal100  = value  // Energy (kcal)
                case 1003: pro100  = value  // Protein
                case 1005: carb100 = value  // Carbohydrate
                case 1004: fat100  = value  // Total fat
                default: break
                }
            }

            // No calorie data → not a useful result
            guard cal100 > 0 else {
                print("[USDAFoodService] No calorie data for \"\(foodName)\"")
                return nil
            }

            // Scale from per-100g to a reasonable single serving estimate.
            // Use common portion sizes for different food types.
            let servingGrams = estimateServingGrams(for: foodName)
            let scale = servingGrams / 100.0

            let result = USDAMacroResult(
                foodName: description,
                calories: (cal100 * scale).rounded(),
                protein:  (pro100 * scale * 10).rounded() / 10,
                carbs:    (carb100 * scale * 10).rounded() / 10,
                fat:      (fat100 * scale * 10).rounded() / 10
            )

            print("[USDAFoodService] \"\(foodName)\" → \(description): \(Int(result.calories)) kcal, \(result.protein)p, \(result.carbs)c, \(result.fat)f (serving: \(Int(servingGrams))g)")
            return result
        } catch {
            print("[USDAFoodService] Network error for \"\(foodName)\": \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Serving Size Estimation

    /// Returns an estimated serving size in grams for common food categories.
    /// This is a rough heuristic — Claude provides better portion estimates
    /// for complex meals, which is why Tier 2 exists.
    private func estimateServingGrams(for foodName: String) -> Double {
        let name = foodName.lowercased()

        // Fruits
        if ["apple", "banana", "orange", "pear", "peach", "mango", "kiwi"].contains(where: { name.contains($0) }) {
            return 150
        }
        // Berries
        if ["berry", "strawberry", "blueberry", "raspberry"].contains(where: { name.contains($0) }) {
            return 140
        }
        // Vegetables
        if ["broccoli", "carrot", "spinach", "kale", "celery", "cucumber", "pepper", "tomato", "lettuce"].contains(where: { name.contains($0) }) {
            return 120
        }
        // Proteins
        if ["chicken", "beef", "steak", "pork", "turkey", "salmon", "tuna", "shrimp", "fish", "egg"].contains(where: { name.contains($0) }) {
            return name.contains("egg") ? 100 : 170  // ~6 oz for meats, 2 eggs
        }
        // Dairy
        if ["cheese", "yogurt", "milk"].contains(where: { name.contains($0) }) {
            return name.contains("milk") ? 240 : 150
        }
        // Grains
        if ["rice", "oat", "bread", "toast", "cereal", "granola"].contains(where: { name.contains($0) }) {
            return name.contains("bread") || name.contains("toast") ? 60 : 150
        }
        // Nuts
        if ["almond", "peanut", "walnut", "cashew", "nut", "pistachio"].contains(where: { name.contains($0) }) {
            return 30  // ~1 oz
        }
        // Default single serving
        return 150
    }
}
