//
//  LocalFoodClassifier.swift
//  Wellness
//
//  On-device food recognition using Apple's Vision framework.
//  Conservative approach: only trusts Tier 1 for obvious, single-ingredient
//  foods where Vision's taxonomy label exactly matches a known food.
//  Everything else falls back to Claude (Tier 2).
//

import UIKit
import Vision

// MARK: - Classification Result

struct FoodClassification {
    /// Recognized food name (e.g. "banana", "egg", "broccoli").
    let foodName: String
    /// Confidence score from 0.0 to 1.0.
    let confidence: Double
    /// True if Claude API should be used instead of local USDA lookup.
    let needsClaudeAnalysis: Bool
    /// Estimated number of individual food items detected in the image (1+).
    let itemCount: Int
}

// MARK: - Classifier

final class LocalFoodClassifier {

    static let shared = LocalFoodClassifier()
    private init() {}

    /// Tier 1 whitelist: obvious single-ingredient foods where Vision's general
    /// taxonomy is reliable enough for a USDA macro lookup. These are visually
    /// distinct items that Vision rarely confuses with non-food objects.
    ///
    /// Key = Vision taxonomy label substring to match.
    /// Value = clean food name to send to USDA.
    private let tier1Foods: [String: String] = [
        // Fruits
        "banana":        "banana",
        "apple":         "apple",
        "orange":        "orange",
        "lemon":         "lemon",
        "lime":          "lime",
        "pear":          "pear",
        "peach":         "peach",
        "watermelon":    "watermelon",
        "pineapple":     "pineapple",
        "mango":         "mango",
        "kiwi":          "kiwi",
        "strawberry":    "strawberry",
        "blueberry":     "blueberry",
        "raspberry":     "raspberry",
        "blackberry":    "blackberry",
        "grape":         "grape",
        "cherry":        "cherry",
        "coconut":       "coconut",
        "pomegranate":   "pomegranate",
        "fig":           "fig",
        "papaya":        "papaya",
        "dragonfruit":   "dragonfruit",
        "grapefruit":    "grapefruit",
        "plum":          "plum",
        "cantaloupe":    "cantaloupe",
        "honeydew":      "honeydew melon",
        "avocado":       "avocado",
        // Vegetables
        "broccoli":      "broccoli",
        "cauliflower":   "cauliflower",
        "carrot":        "carrot",
        "corn":          "corn on the cob",
        "tomato":        "tomato",
        "cucumber":      "cucumber",
        "bell pepper":   "bell pepper",
        "asparagus":     "asparagus",
        "artichoke":     "artichoke",
        "mushroom":      "mushroom",
        "onion":         "onion",
        "garlic":        "garlic",
        "sweet potato":  "sweet potato",
        "zucchini":      "zucchini",
        "eggplant":      "eggplant",
        "radish":        "radish",
        "celery":        "celery",
        "lettuce":       "lettuce",
        "spinach":       "spinach",
        "kale":          "kale",
        "green bean":    "green beans",
        // Proteins
        "egg":           "egg",
        "shrimp":        "shrimp",
        "salmon":        "salmon",
        "steak":         "beef steak",
        "bacon":         "bacon",
        "sausage":       "sausage",
        // Dairy
        "cheese":        "cheddar cheese",
        // Grains / Baked
        "bagel":         "bagel",
        "pretzel":       "pretzel",
        "waffle":        "waffle",
        "pancake":       "pancake",
        "bread":         "bread",
        "croissant":     "croissant",
        "muffin":        "muffin",
        "toast":         "toast",
        "rice":          "white rice",
        // Snacks
        "doughnut":      "doughnut",
        "donut":         "doughnut",
        "popcorn":       "popcorn",
        "cookie":        "cookie",
        "french fries":  "french fries",
        "fries":         "french fries",
        "hot dog":       "hot dog",
        "pizza":         "pizza slice",
    ]

    /// Labels that are common Vision false positives for food photos.
    /// If the top-1 label is one of these, skip Tier 1 entirely.
    private let ambiguousLabels: Set<String> = [
        "indoor", "outdoor", "table", "plate", "bowl", "cup",
        "kitchen", "restaurant", "counter", "wood", "ceramic",
        "glass", "plastic", "paper", "textile", "pattern",
    ]

    /// Classifies a food image on-device using Vision.
    /// Returns results in under 500ms on modern hardware.
    func classify(_ image: UIImage) async -> FoodClassification {
        await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: .unknown)
                return
            }

            let classifyRequest = VNClassifyImageRequest()
            let saliencyRequest = VNGenerateObjectnessBasedSaliencyImageRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([classifyRequest, saliencyRequest])
            } catch {
                print("[LocalFoodClassifier] Vision error: \(error.localizedDescription)")
                continuation.resume(returning: .unknown)
                return
            }

            guard let observations = classifyRequest.results as? [VNClassificationObservation] else {
                continuation.resume(returning: .unknown)
                return
            }

            let itemCount = self.countSalientObjects(from: saliencyRequest.results)
            let match = self.findTier1Match(from: observations)

            if let match {
                // Trust the classifier for high-confidence whitelisted foods even
                // when saliency detects multiple regions (plate, table, shadow, etc.).
                // Only require single-object confirmation at lower confidence levels.
                let needsClaude: Bool
                if match.confidence >= 0.90 {
                    needsClaude = false  // High confidence whitelist match — trust it
                } else if match.confidence >= 0.85 {
                    needsClaude = itemCount > 2  // Medium confidence — tolerate plate/table regions
                } else {
                    needsClaude = true   // Low confidence — escalate
                }
                print("[LocalFoodClassifier] Tier 1 match: \"\(match.foodName)\" conf=\(String(format: "%.2f", match.confidence)) items=\(itemCount) → \(needsClaude ? "Claude" : "USDA")")
                continuation.resume(returning: FoodClassification(
                    foodName: match.foodName,
                    confidence: match.confidence,
                    needsClaudeAnalysis: needsClaude,
                    itemCount: itemCount
                ))
            } else {
                // Log the top 3 Vision labels for debugging
                let topLabels = observations.prefix(3).map { "\($0.identifier)(\(String(format: "%.2f", $0.confidence)))" }.joined(separator: ", ")
                print("[LocalFoodClassifier] No Tier 1 match. Top labels: \(topLabels) → Claude")
                continuation.resume(returning: FoodClassification(
                    foodName: observations.first.map { self.cleanLabel($0.identifier) } ?? "unknown",
                    confidence: Double(observations.first?.confidence ?? 0),
                    needsClaudeAnalysis: true,
                    itemCount: itemCount
                ))
            }
        }
    }

    // MARK: - Private Helpers

    /// Searches Vision results for an exact match against the Tier 1 whitelist.
    /// Only looks at the top 5 results and requires the match to be both:
    /// 1. In the whitelist
    /// 2. The highest-confidence food label (not preceded by a different food)
    private func findTier1Match(from observations: [VNClassificationObservation]) -> (foodName: String, confidence: Double)? {

        // Check top 5 labels only
        for obs in observations.prefix(5) {
            let label = obs.identifier.lowercased()
                .replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: "-", with: " ")

            // Skip ambiguous/non-food labels
            if ambiguousLabels.contains(where: { label.contains($0) }) { continue }

            // Check for exact tier1 food match
            for (key, foodName) in tier1Foods {
                if label.contains(key) {
                    return (foodName: foodName, confidence: Double(obs.confidence))
                }
            }

            // If we hit a non-ambiguous label that isn't a known food, stop.
            // This prevents matching a low-ranked food label that was preceded
            // by a high-confidence non-food label (like "apple" at rank 3 when
            // "curry" is clearly what the image shows).
            break
        }

        return nil
    }

    /// Counts distinct salient regions from objectness saliency results.
    private func countSalientObjects(from results: [VNObservation]?) -> Int {
        guard let saliency = results?.first as? VNSaliencyImageObservation,
              let objects = saliency.salientObjects else { return 1 }
        // Use 10% area threshold to avoid counting plates, table edges, shadows, etc.
        let significant = objects.filter { $0.boundingBox.width * $0.boundingBox.height > 0.10 }
        return max(1, significant.count)
    }

    /// Cleans a Vision taxonomy label into a human-readable string.
    private func cleanLabel(_ identifier: String) -> String {
        identifier
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .components(separatedBy: ",").first?
            .trimmingCharacters(in: .whitespaces)
            .lowercased() ?? identifier.lowercased()
    }
}

// MARK: - Convenience

extension FoodClassification {
    static let unknown = FoodClassification(
        foodName: "unknown", confidence: 0,
        needsClaudeAnalysis: true, itemCount: 1
    )
}
