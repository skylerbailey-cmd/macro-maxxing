//
//  USDAService.swift
//  Wellness
//
//  Tier 1 — Queries USDA FoodData Central for whole-food macro data.
//

import Foundation

final class USDAService {
    static let shared = USDAService()
    private let baseURL = "https://api.nal.usda.gov/fdc/v1"

    private init() {}

    // MARK: - Search

    /// Searches USDA for a single-ingredient whole food by name.
    /// Filters to SR Legacy and Foundation data types only.
    func searchFood(query: String, portionGrams: Double) async throws -> MacroResult? {
        let apiKey = Config.usdaApiKey
        guard apiKey != "YOUR_USDA_KEY" else {
            print("[USDA] No API key configured — skipping USDA lookup.")
            return nil
        }

        guard var urlComponents = URLComponents(string: "\(baseURL)/foods/search") else {
            return nil
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "pageSize", value: "10"),
            URLQueryItem(name: "dataType", value: "SR Legacy,Foundation")
        ]

        guard let url = urlComponents.url else { return nil }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return nil
        }

        let searchResponse = try JSONDecoder().decode(USDASearchResponse.self, from: data)

        guard !searchResponse.foods.isEmpty else { return nil }
        let food = bestMatch(for: query, in: searchResponse.foods)
            ?? searchResponse.foods.first!

        // Extract macros per 100g from nutrient list
        let caloriesPer100g = food.nutrientValue(id: 1008) ?? 0  // Energy (kcal)
        let proteinPer100g  = food.nutrientValue(id: 1003) ?? 0  // Protein
        let carbsPer100g    = food.nutrientValue(id: 1005) ?? 0  // Carbohydrates
        let fatPer100g      = food.nutrientValue(id: 1004) ?? 0  // Total fat

        // Scale to portion size
        let factor = portionGrams / 100.0

        return MacroResult(
            food: food.description,
            calories: caloriesPer100g * factor,
            protein: proteinPer100g * factor,
            carbs: carbsPer100g * factor,
            fat: fatPer100g * factor,
            source: "USDA FoodData Central"
        )
    }

    /// Returns base macros per 100g for caching.
    /// Uses bestMatch filtering to avoid returning juice/concentrate/dried forms.
    func fetchBaseMacros(query: String) async throws -> MacrosPer100g? {
        let apiKey = Config.usdaApiKey
        guard apiKey != "YOUR_USDA_KEY" else { return nil }

        guard var urlComponents = URLComponents(string: "\(baseURL)/foods/search") else {
            return nil
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "pageSize", value: "10"),
            URLQueryItem(name: "dataType", value: "SR Legacy,Foundation")
        ]

        guard let url = urlComponents.url else { return nil }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

        let searchResponse = try JSONDecoder().decode(USDASearchResponse.self, from: data)
        guard !searchResponse.foods.isEmpty else { return nil }

        let food = bestMatch(for: query, in: searchResponse.foods)
            ?? searchResponse.foods.first!

        print("[USDA] Best match for \"\(query)\": \"\(food.description)\" (\(Int(food.nutrientValue(id: 1008) ?? 0)) kcal/100g)")

        return MacrosPer100g(
            calories: food.nutrientValue(id: 1008) ?? 0,
            protein: food.nutrientValue(id: 1003) ?? 0,
            carbs: food.nutrientValue(id: 1005) ?? 0,
            fat: food.nutrientValue(id: 1004) ?? 0
        )
    }

    // MARK: - Result Filtering

    /// Keywords indicating processed forms that shouldn't match when looking for whole foods.
    private let processedKeywords: Set<String> = [
        "dehydrated", "dried", "powder", "flour", "chips", "fried",
        "candied", "canned", "syrup", "juice", "concentrate", "extract",
        "oil", "butter", "cream", "frozen", "breaded", "battered",
        "sweetened", "glazed", "coated", "stuffed", "marinated",
    ]

    /// Picks the best raw/whole-food match from USDA results.
    /// Penalizes processed forms and rewards "raw" descriptions.
    private func bestMatch(for query: String, in foods: [USDAFood]) -> USDAFood? {
        let q = query.lowercased()
        let penalized = processedKeywords.filter { !q.contains($0) }

        let scored: [(food: USDAFood, score: Int)] = foods.compactMap { food in
            let cals = food.nutrientValue(id: 1008) ?? 0
            guard cals > 0 else { return nil }

            let desc = food.description.lowercased()
            var score = 0

            // Penalize processed forms the query didn't ask for
            if penalized.contains(where: { desc.contains($0) }) {
                score -= 50
            }

            // Reward "raw" when searching for plain whole foods
            if desc.contains("raw") && penalized.count == processedKeywords.count {
                score += 20
            }

            // Reward close description match
            if desc.hasPrefix(q) { score += 10 }
            if desc.contains(q)  { score += 5 }

            return (food, score)
        }

        return scored.sorted { $0.score > $1.score }.first?.food
    }
}

// MARK: - USDA Response Models

private struct USDASearchResponse: Codable {
    let foods: [USDAFood]
}

private struct USDAFood: Codable {
    let fdcId: Int
    let description: String
    let foodNutrients: [USDANutrient]

    func nutrientValue(id: Int) -> Double? {
        foodNutrients.first(where: { $0.nutrientId == id })?.value
    }
}

private struct USDANutrient: Codable {
    let nutrientId: Int
    let value: Double
}
