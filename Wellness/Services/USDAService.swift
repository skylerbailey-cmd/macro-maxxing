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

        guard let food = searchResponse.foods.first else { return nil }

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
    func fetchBaseMacros(query: String) async throws -> MacrosPer100g? {
        let apiKey = Config.usdaApiKey
        guard apiKey != "YOUR_USDA_KEY" else { return nil }

        guard var urlComponents = URLComponents(string: "\(baseURL)/foods/search") else {
            return nil
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "pageSize", value: "5"),
            URLQueryItem(name: "dataType", value: "SR Legacy,Foundation")
        ]

        guard let url = urlComponents.url else { return nil }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

        let searchResponse = try JSONDecoder().decode(USDASearchResponse.self, from: data)
        guard let food = searchResponse.foods.first else { return nil }

        return MacrosPer100g(
            calories: food.nutrientValue(id: 1008) ?? 0,
            protein: food.nutrientValue(id: 1003) ?? 0,
            carbs: food.nutrientValue(id: 1005) ?? 0,
            fat: food.nutrientValue(id: 1004) ?? 0
        )
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
