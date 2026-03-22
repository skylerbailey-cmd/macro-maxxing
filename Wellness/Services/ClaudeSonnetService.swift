//
//  ClaudeSonnetService.swift
//  Wellness
//
//  Tier 3 — Claude Sonnet 4.6 for full meal analysis (complex meals, fallback).
//

import UIKit

import FirebaseFunctions

final class ClaudeSonnetService {
    static let shared = ClaudeSonnetService()
    private let model = "claude-sonnet-4-6"

    private init() {}

    /// Full meal analysis using Claude Sonnet. This is the most accurate but highest-cost tier.
    /// Optionally includes context from previous tier attempts.
    func analyzeFood(image: UIImage, previousGuess: String? = nil, voiceNote: String? = nil) async throws -> SonnetAnalysisResult {
        guard let jpegData = resized(image, maxEdge: 1024).jpegData(compressionQuality: 0.8) else {
            throw FoodRecognitionError.imageProcessingFailed
        }

        let base64 = jpegData.base64EncodedString()

        var contextLines: [String] = []
        if let guess = previousGuess {
            contextLines.append("Previous analysis attempt identified this as: \"\(guess)\". Use this as context but make your own determination.")
        }
        if let voice = voiceNote, !voice.isEmpty {
            contextLines.append("PRIORITY: The user verbally described this food as: \"\(voice)\". This description overrides what you see in the photo. Use the photo only for visual confirmation — base your food identification, portion size, and macro calculation primarily on the user's description.")
        }
        let contextBlock = contextLines.isEmpty ? "" : contextLines.joined(separator: "\n") + "\n\n"

        let prompt = """
\(contextBlock)Analyze this food photo carefully. Think step by step:
1. Identify every food item visible in the photo
2. **Estimate portion sizes using ALL available visual cues in the photo:**
   - Hands, fingers, or thumbs → use as size reference (average adult hand ~19cm long)
   - Forks, spoons, knives → standard dinner fork is ~19cm, teaspoon bowl is ~4cm
   - Plates and bowls → standard dinner plate is 25–27cm diameter, salad plate ~20cm
   - Cups and glasses → standard mug ~240ml, water glass ~350ml
   - Compare food items to these references to estimate grams accurately
3. If this is a mixed meal, break down each component separately
4. Calculate total macros by summing all components

IMPORTANT: Use accurate, real-world nutritional values consistent with USDA FoodData Central.
Common reference points — a medium orange (~150g) is ~70 kcal, a medium banana (~120g) is ~105 kcal,
a chicken breast (~170g) is ~280 kcal, a large egg (~50g) is ~72 kcal.
Do NOT guess or inflate calorie counts. Base every estimate on established nutritional data.

Return your analysis as a single JSON object with these exact fields:
{
  "foodName": "<descriptive name of the full meal>",
  "components": [
    {"name": "<component>", "portionGrams": <number>, "calories": <int>, "protein": <g>, "carbs": <g>, "fat": <g>}
  ],
  "portionGrams": <total grams>,
  "calories": <total kcal as integer>,
  "protein": <total g>,
  "carbs": <total g>,
  "fat": <total g>,
  "confidenceScore": <0.0-1.0>,
  "reasoning": "<brief explanation of your analysis>"
}

For single items, the components array should have one entry matching the totals.
Reply with ONLY the JSON, no markdown fences, no extra text.
"""

        let payload: [String: Any] = [
            "model": model,
            "maxTokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "image", "source": ["type": "base64", "media_type": "image/jpeg", "data": base64]],
                        ["type": "text", "text": prompt]
                    ]
                ]
            ]
        ]

        let result: HTTPSCallableResult
        do {
            result = try await Functions.functions().httpsCallable("proxyClaude").call(payload)
        } catch {
            throw FoodRecognitionError.noConnection
        }

        guard let responseDict = result.data as? [String: Any],
              let content = responseDict["content"] as? [[String: Any]],
              let text = content.first(where: { $0["type"] as? String == "text" })?["text"] as? String else {
            throw FoodRecognitionError.noContent
        }

        let jsonString = stripMarkdownFences(text)
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw FoodRecognitionError.malformedJSON(text)
        }

        return try JSONDecoder().decode(SonnetAnalysisResult.self, from: jsonData)
    }


    private nonisolated func resized(_ image: UIImage, maxEdge: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxEdge else { return image }
        let scale = maxEdge / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }

    private nonisolated func stripMarkdownFences(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("```") {
            result = result.components(separatedBy: "\n").dropFirst().joined(separator: "\n")
            if result.hasSuffix("```") { result = String(result.dropLast(3)) }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
