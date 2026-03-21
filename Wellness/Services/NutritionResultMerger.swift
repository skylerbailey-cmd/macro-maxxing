//
//  NutritionResultMerger.swift
//  Wellness
//
//  Tier 2 — Merges results from FatSecret and Open Food Facts.
//

import Foundation

struct NutritionResultMerger {

    /// Merges macro results from FatSecret and Open Food Facts.
    ///
    /// Priority rules:
    /// 1. Prefers FatSecret for branded and restaurant foods
    /// 2. Prefers Open Food Facts for packaged goods with barcodes
    /// 3. If both return results and calories differ by >20%, averages them and flags it
    /// 4. If only one returns a result, uses that one
    /// 5. If neither returns a result, returns nil
    static func merge(
        fatSecret: MacroResult?,
        openFoodFacts: MacroResult?,
        isMixedMeal: Bool
    ) -> (result: MacroResult, flagged: Bool)? {
        switch (fatSecret, openFoodFacts) {
        case (.none, .none):
            return nil

        case (.some(let fs), .none):
            return (fs, false)

        case (.none, .some(let off)):
            return (off, false)

        case (.some(let fs), .some(let off)):
            // Check if calories differ by more than 20%
            let avgCal = (fs.calories + off.calories) / 2.0
            let diff = abs(fs.calories - off.calories)
            let threshold = avgCal * 0.20

            if diff > threshold {
                // Average both and flag
                let merged = MacroResult(
                    food: fs.food,
                    calories: (fs.calories + off.calories) / 2.0,
                    protein: (fs.protein + off.protein) / 2.0,
                    carbs: (fs.carbs + off.carbs) / 2.0,
                    fat: (fs.fat + off.fat) / 2.0,
                    source: "FatSecret + Open Food Facts (averaged)"
                )
                return (merged, true)
            }

            // Prefer FatSecret for mixed/restaurant, OFF for packaged
            if isMixedMeal {
                return (MacroResult(
                    food: fs.food,
                    calories: fs.calories,
                    protein: fs.protein,
                    carbs: fs.carbs,
                    fat: fs.fat,
                    source: "FatSecret"
                ), false)
            } else {
                return (MacroResult(
                    food: off.food,
                    calories: off.calories,
                    protein: off.protein,
                    carbs: off.carbs,
                    fat: off.fat,
                    source: "Open Food Facts"
                ), false)
            }
        }
    }
}
