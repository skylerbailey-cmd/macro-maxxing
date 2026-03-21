//
//  LocalFoodClassifier.swift
//  Wellness
//
//  On-device food recognition using Apple's Vision framework.
//  Runs classification entirely offline with no network calls.
//  Falls back to Claude API when confidence is low or the food is complex.
//

import UIKit
import Vision

// MARK: - Classification Result

struct FoodClassification {
    /// Recognized food name (e.g. "pizza", "salad", "grilled chicken").
    let foodName: String
    /// Confidence score from 0.0 to 1.0.
    let confidence: Double
    /// True if Claude API should be used for more accurate macro estimation.
    /// Triggered when confidence < 0.80 or the food is a complex/mixed meal.
    let needsClaudeAnalysis: Bool
}

// MARK: - Classifier

final class LocalFoodClassifier {

    static let shared = LocalFoodClassifier()
    private init() {}

    /// Foods that are inherently complex or mixed — even high-confidence
    /// classifications can't reliably estimate macros for these without AI.
    private let complexMealCategories: Set<String> = [
        "burrito", "sushi", "pizza", "sandwich", "salad", "bowl",
        "wrap", "taco", "pasta", "noodle", "soup", "stew", "curry",
        "casserole", "stir fry", "plate", "meal", "dinner", "lunch",
        "breakfast", "brunch", "buffet", "combo", "platter", "bento",
        "poke", "ramen", "pho", "pad thai", "lasagna", "paella",
        "risotto", "omelette", "omelet", "quiche", "potpie",
        "bibimbap", "nachos", "quesadilla", "enchilada",
        "mixed", "assorted", "variety",
    ]

    /// Classifies a food image on-device using Vision.
    /// Returns results in under 500ms on modern hardware.
    /// - Parameter image: The food photo to classify.
    /// - Returns: A `FoodClassification` with the top result.
    func classify(_ image: UIImage) async -> FoodClassification {
        await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: FoodClassification(
                    foodName: "unknown food",
                    confidence: 0,
                    needsClaudeAnalysis: true
                ))
                return
            }

            let request = VNClassifyImageRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNClassificationObservation],
                      let top = self.bestFoodMatch(from: observations)
                else {
                    continuation.resume(returning: FoodClassification(
                        foodName: "unknown food",
                        confidence: 0,
                        needsClaudeAnalysis: true
                    ))
                    return
                }

                let name = self.cleanLabel(top.identifier)
                let confidence = Double(top.confidence)
                let isComplex = self.isComplexMeal(name)
                let needsClaude = confidence < 0.80 || isComplex

                continuation.resume(returning: FoodClassification(
                    foodName: name,
                    confidence: confidence,
                    needsClaudeAnalysis: needsClaude
                ))
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("[LocalFoodClassifier] Vision error: \(error.localizedDescription)")
                continuation.resume(returning: FoodClassification(
                    foodName: "unknown food",
                    confidence: 0,
                    needsClaudeAnalysis: true
                ))
            }
        }
    }

    // MARK: - Private Helpers

    /// Picks the best food-related classification from the full taxonomy.
    /// Vision's built-in classifier returns many non-food categories;
    /// this filters to results that are likely food items.
    private func bestFoodMatch(from observations: [VNClassificationObservation]) -> VNClassificationObservation? {
        // Food-related keywords to match against Vision taxonomy labels
        let foodKeywords: Set<String> = [
            "food", "fruit", "vegetable", "meat", "bread", "cake", "dessert",
            "snack", "meal", "dish", "drink", "beverage", "egg", "cheese",
            "rice", "pasta", "noodle", "soup", "salad", "sandwich", "pizza",
            "sushi", "seafood", "fish", "chicken", "beef", "pork", "steak",
            "burger", "fries", "taco", "burrito", "ice cream", "chocolate",
            "cookie", "pie", "waffle", "pancake", "cereal", "yogurt",
            "smoothie", "juice", "coffee", "tea", "wine", "beer",
            "apple", "banana", "orange", "grape", "berry", "strawberry",
            "avocado", "tomato", "potato", "corn", "broccoli", "carrot",
            "nut", "almond", "peanut", "oat", "granola", "toast",
            "bacon", "sausage", "ham", "turkey", "shrimp", "lobster",
            "crab", "salmon", "tuna", "doughnut", "donut", "muffin",
            "croissant", "bagel", "pretzel", "popcorn", "chip",
            "guacamole", "hummus", "curry", "ramen", "pho",
        ]

        // First pass: find high-confidence food matches
        for obs in observations.prefix(20) {
            let label = obs.identifier.lowercased()
            if foodKeywords.contains(where: { label.contains($0) }) {
                return obs
            }
        }

        // Fallback: return the top result if it has reasonable confidence
        // (the user pointed their camera at something, so assume it's food)
        if let top = observations.first, top.confidence > 0.3 {
            return top
        }

        return nil
    }

    /// Cleans up a Vision taxonomy label into a human-readable food name.
    private func cleanLabel(_ identifier: String) -> String {
        identifier
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .components(separatedBy: ",").first?
            .trimmingCharacters(in: .whitespaces)
            .lowercased() ?? identifier.lowercased()
    }

    /// Returns true if the food name matches any complex meal category
    /// where macro estimation requires detailed AI analysis.
    private func isComplexMeal(_ name: String) -> Bool {
        let lower = name.lowercased()
        return complexMealCategories.contains(where: { lower.contains($0) })
    }
}
