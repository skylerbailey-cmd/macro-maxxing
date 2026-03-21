//
//  FoodRecognitionCache.swift
//  Wellness
//
//  Two-layer cache: base macros per 100g + on-the-fly portion scaling.
//  Held in memory only — cleared when app closes.
//

import Foundation

final class FoodRecognitionCache {
    static let shared = FoodRecognitionCache()

    /// Layer 1: base macro data per 100g, keyed by lowercased trimmed food name.
    private var baseMacros: [String: MacrosPer100g] = [:]
    private let lock = NSLock()

    private init() {}

    // MARK: - Cache Key

    private func cacheKey(for foodName: String) -> String {
        foodName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Layer 1: Store / Retrieve Base Macros

    /// Stores base macros per 100g for a food.
    func store(foodName: String, macrosPer100g: MacrosPer100g) {
        let key = cacheKey(for: foodName)
        lock.lock()
        baseMacros[key] = macrosPer100g
        lock.unlock()
    }

    /// Checks if base macros are cached for a food.
    func hasCachedMacros(for foodName: String) -> Bool {
        let key = cacheKey(for: foodName)
        lock.lock()
        let exists = baseMacros[key] != nil
        lock.unlock()
        return exists
    }

    /// Retrieves base macros per 100g for a food, or nil if not cached.
    func getBaseMacros(for foodName: String) -> MacrosPer100g? {
        let key = cacheKey(for: foodName)
        lock.lock()
        let result = baseMacros[key]
        lock.unlock()
        return result
    }

    // MARK: - Layer 2: Portion-Scaled Lookup

    /// Returns macros scaled to the given portion size if cached, or nil.
    /// Never caches a specific portion result — always computes on the fly.
    func scaledMacros(for foodName: String, portionGrams: Double) -> MacroResult? {
        guard let base = getBaseMacros(for: foodName) else { return nil }

        let scaled = base.scaled(to: portionGrams)

        return MacroResult(
            food: foodName,
            calories: scaled.calories,
            protein: scaled.protein,
            carbs: scaled.carbs,
            fat: scaled.fat,
            source: "Cache"
        )
    }

    // MARK: - Store from API Result

    /// Convenience: stores base per-100g macros from a MacroResult that represents a known portion.
    func storeFromResult(foodName: String, macroResult: MacroResult, portionGrams: Double) {
        guard portionGrams > 0 else { return }
        let factor = 100.0 / portionGrams
        let base = MacrosPer100g(
            calories: macroResult.calories * factor,
            protein: macroResult.protein * factor,
            carbs: macroResult.carbs * factor,
            fat: macroResult.fat * factor
        )
        store(foodName: foodName, macrosPer100g: base)
    }

    // MARK: - Clear

    /// Clears all cached data. Called when the app session ends.
    func clearAll() {
        lock.lock()
        baseMacros.removeAll()
        lock.unlock()
    }
}
