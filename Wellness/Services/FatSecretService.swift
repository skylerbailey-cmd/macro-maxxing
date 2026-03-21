//
//  FatSecretService.swift
//  Wellness
//
//  Tier 2 — FatSecret Platform API for branded and restaurant food lookup.
//

import Foundation

final class FatSecretService {
    static let shared = FatSecretService()

    private let tokenURL = URL(string: "https://oauth.fatsecret.com/connect/token")!
    private let apiURL = URL(string: "https://platform.fatsecret.com/rest/server.api")!

    private var accessToken: String?
    private var tokenExpiry: Date?

    private init() {}

    // MARK: - OAuth 2.0 Token

    private func ensureToken() async throws {
        if accessToken != nil, let expiry = tokenExpiry, Date() < expiry {
            return
        }

        let credentials = "\(Config.fatSecretClientId):\(Config.fatSecretClientSecret)"
        guard let credData = credentials.data(using: .utf8) else {
            throw FoodRecognitionError.apiError(statusCode: 0)
        }
        let base64Creds = credData.base64EncodedString()

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64Creds)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "grant_type=client_credentials&scope=basic".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw FoodRecognitionError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        let tokenResponse = try JSONDecoder().decode(FatSecretTokenResponse.self, from: data)
        accessToken = tokenResponse.accessToken
        // Expire 60 seconds early to avoid edge cases
        tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn - 60))
    }

    // MARK: - Food Search

    /// Searches FatSecret for the given food query and returns macro data scaled to the target portion.
    func searchFood(query: String, targetPortionGrams: Double) async throws -> MacroResult? {
        try await ensureToken()
        guard let token = accessToken else { return nil }

        guard var components = URLComponents(string: apiURL.absoluteString) else { return nil }
        components.queryItems = [
            URLQueryItem(name: "method", value: "foods.search"),
            URLQueryItem(name: "search_expression", value: query),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "max_results", value: "5")
        ]

        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

        let searchResult = try JSONDecoder().decode(FatSecretSearchResponse.self, from: data)
        guard let firstFood = searchResult.foods?.food?.first else { return nil }

        // Get detailed nutrition for the first match
        return try await getFoodDetails(foodId: firstFood.foodId, targetPortionGrams: targetPortionGrams)
    }

    /// Returns base macros per 100g for caching.
    func fetchBaseMacros(query: String) async throws -> MacrosPer100g? {
        try await ensureToken()
        guard let token = accessToken else { return nil }

        guard var components = URLComponents(string: apiURL.absoluteString) else { return nil }
        components.queryItems = [
            URLQueryItem(name: "method", value: "foods.search"),
            URLQueryItem(name: "search_expression", value: query),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "max_results", value: "3")
        ]

        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

        let searchResult = try JSONDecoder().decode(FatSecretSearchResponse.self, from: data)
        guard let firstFood = searchResult.foods?.food?.first else { return nil }

        return try await getBaseMacrosFromDetails(foodId: firstFood.foodId)
    }

    // MARK: - Food Details

    private func getFoodDetails(foodId: String, targetPortionGrams: Double) async throws -> MacroResult? {
        guard let token = accessToken else { return nil }

        guard var components = URLComponents(string: apiURL.absoluteString) else { return nil }
        components.queryItems = [
            URLQueryItem(name: "method", value: "food.get.v4"),
            URLQueryItem(name: "food_id", value: foodId),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

        let detailResult = try JSONDecoder().decode(FatSecretFoodDetailResponse.self, from: data)
        guard let food = detailResult.food,
              let servings = food.servings?.serving else { return nil }

        // Find the serving closest to our target portion
        let bestServing = findClosestServing(servings: servings, targetGrams: targetPortionGrams)

        guard let serving = bestServing else { return nil }

        // Scale to target portion
        let servingGrams = Double(serving.metricServingAmount ?? "100") ?? 100.0
        let factor = targetPortionGrams / servingGrams

        return MacroResult(
            food: food.foodName ?? "Unknown",
            calories: (Double(serving.calories ?? "0") ?? 0) * factor,
            protein: (Double(serving.protein ?? "0") ?? 0) * factor,
            carbs: (Double(serving.carbohydrate ?? "0") ?? 0) * factor,
            fat: (Double(serving.fat ?? "0") ?? 0) * factor,
            source: "FatSecret"
        )
    }

    private func getBaseMacrosFromDetails(foodId: String) async throws -> MacrosPer100g? {
        guard let token = accessToken else { return nil }

        guard var components = URLComponents(string: apiURL.absoluteString) else { return nil }
        components.queryItems = [
            URLQueryItem(name: "method", value: "food.get.v4"),
            URLQueryItem(name: "food_id", value: foodId),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

        let detailResult = try JSONDecoder().decode(FatSecretFoodDetailResponse.self, from: data)
        guard let food = detailResult.food,
              let servings = food.servings?.serving else { return nil }

        // Find the "per 100g" serving if available, otherwise use first
        let per100g = servings.first(where: {
            ($0.metricServingAmount ?? "") == "100" || ($0.servingDescription ?? "").lowercased().contains("100g")
        }) ?? servings.first

        guard let serving = per100g else { return nil }

        let servingGrams = Double(serving.metricServingAmount ?? "100") ?? 100.0
        let factor = 100.0 / servingGrams

        return MacrosPer100g(
            calories: (Double(serving.calories ?? "0") ?? 0) * factor,
            protein: (Double(serving.protein ?? "0") ?? 0) * factor,
            carbs: (Double(serving.carbohydrate ?? "0") ?? 0) * factor,
            fat: (Double(serving.fat ?? "0") ?? 0) * factor
        )
    }

    private func findClosestServing(servings: [FatSecretServing], targetGrams: Double) -> FatSecretServing? {
        servings.min(by: { a, b in
            let aGrams = Double(a.metricServingAmount ?? "100") ?? 100.0
            let bGrams = Double(b.metricServingAmount ?? "100") ?? 100.0
            return abs(aGrams - targetGrams) < abs(bGrams - targetGrams)
        })
    }
}

// MARK: - FatSecret Response Models

private struct FatSecretTokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

private struct FatSecretSearchResponse: Codable {
    let foods: FatSecretFoods?
}

private struct FatSecretFoods: Codable {
    let food: [FatSecretFoodItem]?
}

private struct FatSecretFoodItem: Codable {
    let foodId: String
    let foodName: String?
    let foodDescription: String?

    enum CodingKeys: String, CodingKey {
        case foodId = "food_id"
        case foodName = "food_name"
        case foodDescription = "food_description"
    }
}

private struct FatSecretFoodDetailResponse: Codable {
    let food: FatSecretFoodDetail?
}

private struct FatSecretFoodDetail: Codable {
    let foodId: String?
    let foodName: String?
    let servings: FatSecretServings?

    enum CodingKeys: String, CodingKey {
        case foodId = "food_id"
        case foodName = "food_name"
        case servings
    }
}

private struct FatSecretServings: Codable {
    let serving: [FatSecretServing]?
}

private struct FatSecretServing: Codable {
    let servingDescription: String?
    let metricServingAmount: String?
    let metricServingUnit: String?
    let calories: String?
    let protein: String?
    let carbohydrate: String?
    let fat: String?

    enum CodingKeys: String, CodingKey {
        case servingDescription = "serving_description"
        case metricServingAmount = "metric_serving_amount"
        case metricServingUnit = "metric_serving_unit"
        case calories, protein, carbohydrate, fat
    }
}
