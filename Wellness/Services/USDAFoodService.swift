//
//  USDAFoodService.swift
//  Wellness
//
//  Looks up macro data from the USDA FoodData Central API (free).
//  Used as Tier 1 macro estimation for simple, single-ingredient foods
//  identified by the on-device classifier.
//
//  API docs: https://fdc.nal.usda.gov/api-guide
//  Free API key: https://fdc.nal.usda.gov/api-key-signup.html
//

import Foundation

// MARK: - USDA Food Item

struct USDAFoodItem {
    let fdcId:       Int
    let description: String
    let dataType:    String
    /// Per-100g macros embedded in the search result (may be partial).
    let calories100g: Double
    let protein100g:  Double
    let carbs100g:    Double
    let fat100g:      Double
}

// MARK: - Service

final class USDAFoodService {

    static let shared = USDAFoodService()
    private init() {}

    // MARK: - Configuration

    /// Free USDA FoodData Central API key.
    /// Get your own at https://fdc.nal.usda.gov/api-key-signup.html
    private let apiKey = "DEMO_KEY"
    private let baseURL = "https://api.nal.usda.gov/fdc/v1"

    // MARK: - In-memory session cache

    /// Caches search results so the same query never hits the API twice per session.
    /// Key: lowercased food name → value: search results with per-100g data.
    /// This is safe because USDA per-100g data never changes — portion scaling
    /// happens after the cache in lookup() and the caller.
    private var searchCache: [String: [USDAFoodItem]] = [:]
    /// Caches detailed nutrient lookups by fdcId (per-100g, unscaled).
    private var nutrientCache: [Int: MacroResult] = [:]

    /// Clears all in-memory caches. Call if you suspect stale data.
    func clearCache() {
        searchCache.removeAll()
        nutrientCache.removeAll()
        print("[USDA] Cache cleared")
    }

    // MARK: - 1. Search Food

    /// Searches USDA FoodData Central for whole, single-ingredient foods.
    /// Returns the top 5 results filtered to SR Legacy and Foundation data types.
    /// Results are cached in memory for the session.
    func searchFood(query: String) async -> [USDAFoodItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }

        // Return cached results if available
        if let cached = searchCache[trimmed] { return cached }

        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/foods/search?query=\(encoded)&dataType=SR%20Legacy,Foundation&pageSize=5&api_key=\(apiKey)")
        else { return [] }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("[USDA] HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0) for \"\(trimmed)\"")
                return []
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let foods = json["foods"] as? [[String: Any]]
            else {
                print("[USDA] No results for \"\(trimmed)\"")
                return []
            }

            let items: [USDAFoodItem] = foods.compactMap { food in
                guard let fdcId = food["fdcId"] as? Int,
                      let desc  = food["description"] as? String,
                      let type  = food["dataType"] as? String
                else { return nil }

                // Extract per-100g macros from the search result's nutrient array
                var cal: Double = 0, pro: Double = 0, carb: Double = 0, fat: Double = 0
                if let nutrients = food["foodNutrients"] as? [[String: Any]] {
                    for n in nutrients {
                        guard let nid = n["nutrientId"] as? Int,
                              let val = n["value"] as? Double else { continue }
                        switch nid {
                        case 1008: cal  = val  // Energy (kcal)
                        case 1003: pro  = val  // Protein (g)
                        case 1005: carb = val  // Carbohydrate (g)
                        case 1004: fat  = val  // Total fat (g)
                        default: break
                        }
                    }
                }

                return USDAFoodItem(
                    fdcId: fdcId, description: desc, dataType: type,
                    calories100g: cal, protein100g: pro, carbs100g: carb, fat100g: fat
                )
            }

            searchCache[trimmed] = items
            print("[USDA] Search \"\(trimmed)\" → \(items.count) results")
            return items
        } catch {
            print("[USDA] Network error for \"\(trimmed)\": \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - 2. Get Macros

    /// Fetches detailed nutrition for a specific food by FDC ID,
    /// scales macros to the given portion size in grams, and returns
    /// a `MacroResult` that matches the Claude Vision output format.
    /// Results are cached in memory for the session.
    func getMacros(fdcId: Int, portionGrams: Double) async -> MacroResult? {
        // Check nutrient cache (stored as per-100g, scaled on return)
        if let cached = nutrientCache[fdcId] {
            return scaled(cached, portionGrams: portionGrams)
        }

        guard let url = URL(string: "\(baseURL)/food/\(fdcId)?api_key=\(apiKey)") else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("[USDA] Detail HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0) for fdcId=\(fdcId)")
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let nutrients = json["foodNutrients"] as? [[String: Any]]
            else {
                print("[USDA] No nutrient data for fdcId=\(fdcId)")
                return nil
            }

            let desc = (json["description"] as? String ?? "Unknown").capitalized

            var cal: Double = 0, pro: Double = 0, carb: Double = 0, fat: Double = 0
            for n in nutrients {
                // Detail endpoint nests the nutrient info differently
                let nid: Int
                if let nutrient = n["nutrient"] as? [String: Any], let id = nutrient["id"] as? Int {
                    nid = id
                } else if let id = n["nutrientId"] as? Int {
                    nid = id
                } else {
                    continue
                }
                let val = n["amount"] as? Double ?? n["value"] as? Double ?? 0
                switch nid {
                case 1008: cal  = val
                case 1003: pro  = val
                case 1005: carb = val
                case 1004: fat  = val
                default: break
                }
            }

            guard cal > 0 else {
                print("[USDA] No calorie data for fdcId=\(fdcId)")
                return nil
            }

            // Cache as per-100g MacroResult
            let per100 = MacroResult(food: desc, calories: cal, protein: pro, carbs: carb, fat: fat)
            nutrientCache[fdcId] = per100

            let result = scaled(per100, portionGrams: portionGrams)
            print("[USDA] fdcId=\(fdcId) → \(desc): \(Int(result.calories)) kcal for \(Int(portionGrams))g")
            return result
        } catch {
            print("[USDA] Detail error for fdcId=\(fdcId): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Convenience: Search + Get Best Match

    /// Searches for a food name and returns scaled macros for the best match.
    /// This is the primary entry point used by the Tier 1 recognition flow.
    func lookup(foodName: String, portionGrams: Double? = nil) async -> MacroResult? {
        let items = await searchFood(query: foodName)
        guard let best = bestRawMatch(for: foodName, in: items) else { return nil }

        let grams = portionGrams ?? estimateServingGrams(for: foodName)

        // Use per-100g data from search result, scale to portion
        let scale = grams / 100.0
        let result = MacroResult(
            food:     best.description.capitalized,
            calories: (best.calories100g * scale).rounded(),
            protein:  (best.protein100g * scale * 10).rounded() / 10,
            carbs:    (best.carbs100g * scale * 10).rounded() / 10,
            fat:      (best.fat100g * scale * 10).rounded() / 10
        )
        print("[USDA] lookup \"\(foodName)\" → \(best.description) | per100g: \(Int(best.calories100g)) kcal | serving: \(Int(grams))g | scaled: \(Int(result.calories)) kcal, \(result.protein)p, \(result.carbs)c, \(result.fat)f")
        return result
    }

    // MARK: - Private Helpers

    /// Keywords that indicate a processed/dried/prepared form — not the raw whole food.
    private let processedKeywords: Set<String> = [
        "dehydrated", "dried", "powder", "flour", "chips", "fried",
        "candied", "canned", "syrup", "juice", "concentrate", "extract",
        "oil", "butter", "cream", "frozen", "breaded", "battered",
        "pickled", "smoked", "jerky", "sweetened", "coated",
        "infant", "baby", "formula", "supplement",
    ]

    /// Picks the best raw/whole-food match from search results.
    /// Prefers items whose description contains "raw" and doesn't contain processed keywords,
    /// BUT only penalizes processed terms that aren't part of the original query.
    /// e.g. searching "banana chips" won't penalize results containing "chips".
    private func bestRawMatch(for query: String, in items: [USDAFoodItem]) -> USDAFoodItem? {
        guard !items.isEmpty else { return nil }
        let q = query.lowercased()

        // Build set of processed keywords NOT mentioned in the query
        let penalizedKeywords = processedKeywords.filter { !q.contains($0) }

        let scored: [(item: USDAFoodItem, score: Int)] = items.compactMap { item in
            guard item.calories100g > 0 else { return nil }
            let desc = item.description.lowercased()
            var score = 0

            // Penalize processed forms only if the user didn't ask for them
            if penalizedKeywords.contains(where: { desc.contains($0) }) {
                score -= 50
            }

            // Reward "raw" only when the query itself is a plain whole food
            if desc.contains("raw") && penalizedKeywords.count == processedKeywords.count {
                score += 20
            }

            // Reward if the description starts with or closely matches the query
            if desc.hasPrefix(q) { score += 10 }
            if desc.contains(q)  { score += 5 }

            // Reward Foundation/SR Legacy (whole foods)
            if item.dataType == "Foundation" { score += 3 }

            return (item, score)
        }

        let best = scored.sorted { $0.score > $1.score }.first?.item
        if let b = best {
            print("[USDA] Best match for \"\(query)\": \"\(b.description)\" (filtered from \(items.count) results)")
        }
        return best
    }

    /// Scales a per-100g MacroResult to the given portion size.
    private func scaled(_ per100: MacroResult, portionGrams: Double) -> MacroResult {
        let s = portionGrams / 100.0
        return MacroResult(
            food:     per100.food,
            calories: (per100.calories * s).rounded(),
            protein:  (per100.protein * s * 10).rounded() / 10,
            carbs:    (per100.carbs * s * 10).rounded() / 10,
            fat:      (per100.fat * s * 10).rounded() / 10
        )
    }

    /// Returns an estimated serving size in grams for common food categories.
    private func estimateServingGrams(for foodName: String) -> Double {
        let name = foodName.lowercased()

        // Fruits
        if ["apple", "banana", "orange", "pear", "peach", "mango", "kiwi"].contains(where: { name.contains($0) }) {
            return 150
        }
        if ["berry", "strawberry", "blueberry", "raspberry"].contains(where: { name.contains($0) }) {
            return 140
        }
        // Vegetables
        if ["broccoli", "carrot", "spinach", "kale", "celery", "cucumber", "pepper", "tomato", "lettuce"].contains(where: { name.contains($0) }) {
            return 120
        }
        // Proteins
        if ["chicken", "beef", "steak", "pork", "turkey", "salmon", "tuna", "shrimp", "fish"].contains(where: { name.contains($0) }) {
            return 170  // ~6 oz
        }
        if name.contains("egg") { return 100 }  // ~2 eggs
        // Dairy
        if name.contains("milk") { return 240 }
        if ["cheese", "yogurt"].contains(where: { name.contains($0) }) { return 150 }
        // Grains
        if ["bread", "toast"].contains(where: { name.contains($0) }) { return 60 }
        if ["rice", "oat", "cereal", "granola"].contains(where: { name.contains($0) }) { return 150 }
        // Nuts
        if ["almond", "peanut", "walnut", "cashew", "nut", "pistachio"].contains(where: { name.contains($0) }) {
            return 30  // ~1 oz
        }
        // Default
        return 150
    }
}
