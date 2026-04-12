//
//  ClaudeHaikuService.swift
//  Wellness
//
//  Tier 2 Step 1 — Claude Haiku 4.5 Vision for food identification.
//

import UIKit

import FirebaseFunctions

final class ClaudeHaikuService {
    static let shared = ClaudeHaikuService()
    private let model = "claude-haiku-4-5-20251001"

    private init() {}

    /// Sends a food photo to Claude Haiku for identification AND macro estimation in one call.
    /// Optionally includes a Core ML hint if Tier 1 attempted classification.
    func identifyFood(image: UIImage, coreMLHint: String? = nil) async throws -> HaikuFoodIdentification {
        guard let jpegData = resized(image, maxEdge: 768).jpegData(compressionQuality: 0.7) else {
            throw FoodRecognitionError.imageProcessingFailed
        }

        let base64 = jpegData.base64EncodedString()

        var promptParts = [
            "Identify every distinct food item in this photo and calculate accurate macronutrients.",
            "Estimate portion sizes using visual cues: hands, forks, spoons, plate size, bowl size, or any other objects as size references.",
            """
            Use USDA-accurate nutritional values. Reference points:
            - medium orange (~131g): 62 kcal, 1.2g protein, 15.4g carbs, 0.2g fat
            - medium banana (~118g): 105 kcal, 1.3g protein, 27g carbs, 0.4g fat
            - chicken breast (~170g): 280 kcal, 53g protein, 0g carbs, 6g fat
            - white rice cooked (~150g): 195 kcal, 4g protein, 43g carbs, 0.4g fat
            - large egg (~50g): 72 kcal, 6.3g protein, 0.4g carbs, 5g fat
            - broccoli (~150g): 51 kcal, 4.2g protein, 10g carbs, 0.6g fat
            Do NOT inflate calorie counts. Base every estimate on established nutritional data.
            """,
            "Return a single JSON object with these exact fields:",
            """
            {
              "foodName": "<descriptive name>",
              "portionGrams": <total grams>,
              "isMixedMeal": <bool>,
              "confidence": <0.0-1.0>,
              "calories": <total kcal integer>,
              "protein": <total g>,
              "carbs": <total g>,
              "fat": <total g>,
              "components": [{"name": "<item>", "portionGrams": <g>, "calories": <int>, "protein": <g>, "carbs": <g>, "fat": <g>}]
            }
            """,
            "For a single food, components should have one entry matching the totals.",
            "Reply with ONLY the JSON, no markdown fences, no explanation."
        ]

        if let hint = coreMLHint {
            promptParts.insert("Our on-device classifier thinks this might be \"\(hint)\" but was not confident enough. Use this as a hint.", at: 1)
        }

        let prompt = promptParts.joined(separator: "\n")

        let payload: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
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

        return try JSONDecoder().decode(HaikuFoodIdentification.self, from: jsonData)
    }

    private nonisolated func resized(_ image: UIImage, maxEdge: CGFloat) -> UIImage {
        // See ClaudeSonnetService.resized — same pixel-vs-point
        // and scale=1 fix to keep peak memory sane on a 12 MP photo.
        let pxW = image.size.width  * image.scale
        let pxH = image.size.height * image.scale
        let longestPx = max(pxW, pxH)
        guard longestPx > maxEdge else { return image }
        let ratio = maxEdge / longestPx
        let newSize = CGSize(width: (pxW * ratio).rounded(),
                             height: (pxH * ratio).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return autoreleasepool {
            renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        }
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

// MARK: - Shared Claude API Response Types

struct ClaudeAPIResponse: Decodable {
    let content: [ClaudeAPIContent]
}

struct ClaudeAPIContent: Decodable {
    let type: String
    let text: String?
}

// MARK: - Food Recognition Errors

enum FoodRecognitionError: Error, LocalizedError {
    case imageProcessingFailed
    case noContent
    case malformedJSON(String)
    case apiError(statusCode: Int)
    case rateLimited
    case overloaded
    case serverError
    case noConnection
    case allTiersFailed

    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed: return "Failed to process the image."
        case .noContent:             return "No response from the analysis service."
        case .malformedJSON:         return "Could not parse the analysis response."
        case .apiError(let code):    return "Service error (\(code)). Please try again."
        case .rateLimited:           return "Too many requests. Please try again in a moment."
        case .overloaded:            return "Service is busy. Please try again shortly."
        case .serverError:           return "Server error. Please try again."
        case .noConnection:          return "No internet connection."
        case .allTiersFailed:        return "We had trouble identifying this food. Try retaking the photo in better lighting or enter it manually."
        }
    }
}
