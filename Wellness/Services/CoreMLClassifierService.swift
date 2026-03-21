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
    /// Xcode compiles .mlmodel → .mlmodelc and auto-generates a Swift class.
    /// If the model is added to the project, it will be loaded via bundle lookup.
    /// If no model is found, Tier 1 gracefully falls through to Tier 2.
    private func loadModel() {
        // Look up the compiled model in the bundle by resource name.
let candidateNames = ["Food101", "food101", "Food-101", "MobileNetV2"]

        for name in candidateNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "mlmodelc") {
                do {
                    let mlModel = try MLModel(contentsOf: url)
                    vnModel = try VNCoreMLModel(for: mlModel)
                    print("[CoreMLClassifier] Loaded model from bundle as \(name).mlmodelc")
                    return
                } catch {
                    print("[CoreMLClassifier] Found \(name).mlmodelc but failed to load: \(error.localizedDescription)")
                }
            }
        }

        print("[CoreMLClassifier] No Food101 model found in bundle — Tier 1 classification unavailable.")
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
