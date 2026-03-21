//
//  OpenFoodFactsService.swift
//  Wellness
//
//  Tier 2 — Open Food Facts API for packaged goods nutrition lookup.
//  No API key required, completely free, no rate limits.
//

import Foundation

final class OpenFoodFactsService {
    static let shared = OpenFoodFactsService()
    private let baseURL = "https://world.openfoodfacts.org"

    private init() {}

    // MARK: - Search by Name

    /// Searches Open Food Facts for a food by name and returns macro data scaled to the target portion.
    /// Returns nil gracefully on timeout or network failure — never surfaces errors to the user.
    func searchFood(query: String, targetPortionGrams: Double) async throws -> MacroResult? {
        guard var components = URLComponents(string: "\(baseURL)/cgi/search.pl") else { return nil }
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "5"),
            URLQueryItem(name: "fields", value: "product_name,nutriments,serving_size")
        ]

        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("WellnessApp/1.0 iOS", forHTTPHeaderField: "User-Agent")

        guard let (data, response) = await performWithRetry(request) else { return nil }
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

        do {
            let searchResult = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
            guard let product = searchResult.products?.first,
                  let nutriments = product.nutriments else { return nil }

            let factor = targetPortionGrams / 100.0
            return MacroResult(
                food: product.productName ?? query,
                calories: (nutriments.energyKcal100g ?? 0) * factor,
                protein: (nutriments.proteins100g ?? 0) * factor,
                carbs: (nutriments.carbohydrates100g ?? 0) * factor,
                fat: (nutriments.fat100g ?? 0) * factor,
                source: "Open Food Facts"
            )
        } catch {
            print("[OpenFoodFacts] Decode error for \"\(query)\": \(error.localizedDescription)")
            return nil
        }
    }

    /// Returns base macros per 100g for caching.
    func fetchBaseMacros(query: String) async throws -> MacrosPer100g? {
        guard var components = URLComponents(string: "\(baseURL)/cgi/search.pl") else { return nil }
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "3"),
            URLQueryItem(name: "fields", value: "product_name,nutriments")
        ]

        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("WellnessApp/1.0 iOS", forHTTPHeaderField: "User-Agent")

        guard let (data, response) = await performWithRetry(request) else { return nil }
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

        do {
            let searchResult = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
            guard let product = searchResult.products?.first,
                  let n = product.nutriments else { return nil }
            return MacrosPer100g(
                calories: n.energyKcal100g ?? 0,
                protein: n.proteins100g ?? 0,
                carbs: n.carbohydrates100g ?? 0,
                fat: n.fat100g ?? 0
            )
        } catch {
            print("[OpenFoodFacts] Decode error for \"\(query)\": \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Barcode Lookup (for future barcode scanning)

    func lookupBarcode(_ barcode: String, targetPortionGrams: Double) async throws -> MacroResult? {
        guard let url = URL(string: "\(baseURL)/api/v0/product/\(barcode).json") else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("WellnessApp/1.0 iOS", forHTTPHeaderField: "User-Agent")

        guard let (data, response) = await performWithRetry(request) else { return nil }
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

        do {
            let barcodeResult = try JSONDecoder().decode(OFFBarcodeResponse.self, from: data)
            guard let product = barcodeResult.product,
                  let nutriments = product.nutriments else { return nil }

            let factor = targetPortionGrams / 100.0
            return MacroResult(
                food: product.productName ?? "Unknown",
                calories: (nutriments.energyKcal100g ?? 0) * factor,
                protein: (nutriments.proteins100g ?? 0) * factor,
                carbs: (nutriments.carbohydrates100g ?? 0) * factor,
                fat: (nutriments.fat100g ?? 0) * factor,
                source: "Open Food Facts (barcode)"
            )
        } catch {
            return nil
        }
    }

    // MARK: - Network Helper

    /// Performs a request with one retry on timeout. Returns nil on failure
    /// instead of throwing, so callers fall through to the next tier gracefully.
    private func performWithRetry(_ request: URLRequest) async -> (Data, URLResponse)? {
        for attempt in 1...2 {
            do {
                return try await URLSession.shared.data(for: request)
            } catch let error as URLError where error.code == .timedOut {
                print("[OpenFoodFacts] Timeout (attempt \(attempt)/2)")
                if attempt < 2 { continue }
            } catch {
                print("[OpenFoodFacts] Network error: \(error.localizedDescription)")
            }
            break
        }
        return nil
    }
}

// MARK: - Open Food Facts Response Models

private struct OFFSearchResponse: Codable {
    let products: [OFFProduct]?
}

private struct OFFBarcodeResponse: Codable {
    let product: OFFProduct?
    let status: Int?
}

private struct OFFProduct: Codable {
    let productName: String?
    let nutriments: OFFNutriments?
    let servingSize: String?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case nutriments
        case servingSize = "serving_size"
    }
}

private struct OFFNutriments: Codable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
    }
}
