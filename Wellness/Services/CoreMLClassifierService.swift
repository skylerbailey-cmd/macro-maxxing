//
//  CoreMLClassifierService.swift
//  Wellness
//
//  Tier 1 — On-device food classification using Vision + Core ML (Food101 model).
//

import UIKit
import Vision
import CoreML

struct ClassificationResult {
    let foodName: String
    let confidence: Double
    let isSingleIngredient: Bool
}

final class CoreMLClassifierService {
    static let shared = CoreMLClassifierService()

    private var vnModel: VNCoreMLModel?

    private init() {
        loadModel()
    }

    // MARK: - Model Loading

    /// Attempts to load the Food101 Core ML model bundled in the app.
    /// If no model is found, Tier 1 will always fall through to Tier 2.
    private func loadModel() {
        // The compiled .mlmodelc should be in the app bundle as "Food101"
        guard let modelURL = Bundle.main.url(forResource: "Food101", withExtension: "mlmodelc") else {
            print("[CoreMLClassifier] Food101.mlmodelc not found in bundle — Tier 1 classification unavailable.")
            return
        }

        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            vnModel = try VNCoreMLModel(for: mlModel)
        } catch {
            print("[CoreMLClassifier] Failed to load Food101 model: \(error.localizedDescription)")
        }
    }

    // MARK: - Classification

    /// Classifies a food image on-device. Must complete within ~500ms.
    /// Returns nil if the model is unavailable.
    func classify(image: UIImage) async -> ClassificationResult? {
        guard let model = vnModel,
              let cgImage = image.cgImage else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                guard error == nil,
                      let observations = request.results as? [VNClassificationObservation],
                      let top = observations.first else {
                    continuation.resume(returning: nil)
                    return
                }

                let foodName = Self.cleanLabel(top.identifier)
                let confidence = Double(top.confidence)
                let isSingle = Self.isSingleIngredient(foodName)

                continuation.resume(returning: ClassificationResult(
                    foodName: foodName,
                    confidence: confidence,
                    isSingleIngredient: isSingle
                ))
            }

            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    // MARK: - Helpers

    /// Cleans up the Core ML label (e.g. "grilled_chicken_breast" → "grilled chicken breast").
    private static func cleanLabel(_ raw: String) -> String {
        raw.replacingOccurrences(of: "_", with: " ")
           .trimmingCharacters(in: .whitespacesAndNewlines)
           .lowercased()
    }

    /// Simple heuristic: if the food name has no common "mixed meal" keywords, treat it as single-ingredient.
    private static func isSingleIngredient(_ name: String) -> Bool {
        let mixedKeywords = [
            "pizza", "burger", "sandwich", "salad", "soup", "stew",
            "pasta", "lasagna", "burrito", "taco", "sushi", "curry",
            "stir fry", "fried rice", "pad thai", "ramen", "casserole",
            "wrap", "bowl", "plate", "combo", "platter"
        ]
        let lower = name.lowercased()
        return !mixedKeywords.contains(where: { lower.contains($0) })
    }
}
