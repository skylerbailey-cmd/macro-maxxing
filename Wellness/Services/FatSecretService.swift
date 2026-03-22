//
//  FatSecretService.swift
//  Wellness
//
//  Tier 2 — FatSecret Platform API via server-side proxy.
//  OAuth is handled by the Cloud Function — no client secrets needed.
//

import Foundation
import FirebaseFunctions

final class FatSecretService {
    static let shared = FatSecretService()
    private init() {}

    // MARK: - Food Search

    /// Searches FatSecret via the server-side proxy and returns macro data scaled to the target portion.
    func searchFood(query: String, targetPortionGrams: Double) async throws -> MacroResult? {
        let payload: [String: Any] = ["query": query, "maxResults": 5]

        let result: HTTPSCallableResult
        do {
            result = try await Functions.functions().httpsCallable("proxyFatSecret").call(payload)
        } catch {
            print("[FatSecret] Proxy call failed: \(error.localizedDescription)")
            return nil
        }

        guard let json = result.data as? [String: Any],
              let foods = json["foods"] as? [String: Any],
              let foodList = foods["food"] as? [[String: Any]],
              let first = foodList.first else { return nil }

        // Parse the serving description for per-100g values
        guard let desc = first["food_description"] as? String else { return nil }
        let macros = parseFatSecretDescription(desc)
        guard macros.calories > 0 else { return nil }

        let factor = targetPortionGrams / 100.0
        return MacroResult(
            food: first["food_name"] as? String ?? query,
            calories: macros.calories * factor,
            protein: macros.protein * factor,
            carbs: macros.carbs * factor,
            fat: macros.fat * factor,
            source: "FatSecret"
        )
    }

    /// Returns base macros per 100g for caching.
    func fetchBaseMacros(query: String) async throws -> MacrosPer100g? {
        let payload: [String: Any] = ["query": query, "maxResults": 3]

        let result: HTTPSCallableResult
        do {
            result = try await Functions.functions().httpsCallable("proxyFatSecret").call(payload)
        } catch { return nil }

        guard let json = result.data as? [String: Any],
              let foods = json["foods"] as? [String: Any],
              let foodList = foods["food"] as? [[String: Any]],
              let first = foodList.first,
              let desc = first["food_description"] as? String else { return nil }

        let macros = parseFatSecretDescription(desc)
        guard macros.calories > 0 else { return nil }

        return MacrosPer100g(
            calories: macros.calories,
            protein: macros.protein,
            carbs: macros.carbs,
            fat: macros.fat
        )
    }

    // MARK: - Parsing

    /// Parses FatSecret's food_description format:
    /// "Per 100g - Calories: 89kcal | Fat: 0.33g | Carbs: 22.84g | Protein: 1.09g"
    private func parseFatSecretDescription(_ desc: String) -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        func extract(_ label: String) -> Double {
            guard let range = desc.range(of: "\(label): ") else { return 0 }
            let start = range.upperBound
            let sub = desc[start...]
            let numStr = sub.prefix(while: { $0.isNumber || $0 == "." })
            return Double(numStr) ?? 0
        }
        return (
            calories: extract("Calories"),
            protein: extract("Protein"),
            carbs: extract("Carbs"),
            fat: extract("Fat")
        )
    }
}
