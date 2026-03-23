//
//  ClaudeHaikuService.swift
//  Wellness
//
//  Tier 2 Step 1 — Claude Haiku 4.5 Vision for food identification.
//

import UIKit

final class ClaudeHaikuService {
    static let shared = ClaudeHaikuService()
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
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

        let requestBody: [String: Any] = [
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

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 15
        urlRequest.setValue(Config.claudeApiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await performRequest(urlRequest)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw FoodRecognitionError.apiError(statusCode: code)
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        guard let text = claudeResponse.content.first(where: { $0.type == "text" })?.text else {
            throw FoodRecognitionError.noContent
        }

        let jsonString = stripMarkdownFences(text)
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw FoodRecognitionError.malformedJSON(text)
        }

        return try JSONDecoder().decode(HaikuFoodIdentification.self, from: jsonData)
    }

    // MARK: - Network Helpers

    private func performRequest(_ request: URLRequest, maxRetries: Int = 3) async throws -> (Data, URLResponse) {
        for attempt in 1...maxRetries {
            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await URLSession.shared.data(for: request)
            } catch is URLError {
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(2_000_000_000 * attempt))
                    continue
                }
                throw FoodRecognitionError.noConnection
            }

            guard let http = response as? HTTPURLResponse else {
                return (data, response)
            }

            if http.statusCode == 200 { return (data, response) }

            if http.statusCode == 529 && attempt < maxRetries {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                continue
            }

            switch http.statusCode {
            case 429: throw FoodRecognitionError.rateLimited
            case 529: throw FoodRecognitionError.overloaded
            case 500: throw FoodRecognitionError.serverError
            default:  throw FoodRecognitionError.apiError(statusCode: http.statusCode)
            }
        }
        throw FoodRecognitionError.serverError
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
