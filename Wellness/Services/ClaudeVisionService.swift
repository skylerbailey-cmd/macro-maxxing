//
//  ClaudeVisionService.swift
//  Wellness
//

import UIKit

// MARK: - Public Types

struct MacroResult: Decodable {
    let food: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

enum ClaudeServiceError: Error, LocalizedError {
    case overloaded
    case rateLimited
    case serverError
    case noConnection
    case badResponse(statusCode: Int)
    case noContent
    case malformedJSON(String)

    var errorDescription: String? {
        switch self {
        case .overloaded:              return "Our AI coach is a little busy right now. Tap to try again in a moment."
        case .rateLimited:             return "There's a lot of requests right now. Try again in a few minutes."
        case .serverError:             return "Something went wrong on our end. Please try again."
        case .noConnection:            return "No internet connection. Please check your network and try again."
        case .badResponse(let code):   return "Something went wrong (error \(code)). Please try again."
        case .noContent:               return "No content in API response"
        case .malformedJSON(let text): return "Could not parse response: \(text)"
        }
    }
}

// MARK: - Private Request/Response Types

private struct ClaudeRequest: Encodable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
    }
}

private struct ClaudeMessage: Encodable {
    let role: String
    let content: [ClaudeContentBlock]
}

private enum ClaudeContentBlock: Encodable {
    case image(mediaType: String, base64Data: String)
    case text(String)

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .image(let mediaType, let base64Data):
            try container.encode("image", forKey: .type)
            var sourceContainer = container.nestedContainer(keyedBy: SourceKeys.self, forKey: .source)
            try sourceContainer.encode("base64", forKey: .type)
            try sourceContainer.encode(mediaType, forKey: .mediaType)
            try sourceContainer.encode(base64Data, forKey: .data)
        case .text(let value):
            try container.encode("text", forKey: .type)
            try container.encode(value, forKey: .text)
        }
    }

    enum CodingKeys: String, CodingKey {
        case type, source, text
    }
    enum SourceKeys: String, CodingKey {
        case type, mediaType = "media_type", data
    }
}

private struct ClaudeResponse: Decodable {
    let content: [ClaudeResponseContent]
}

private struct ClaudeResponseContent: Decodable {
    let type: String
    let text: String?
}

// MARK: - Service

final class ClaudeVisionService {
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-sonnet-4-6"

    func analyzeFoodImage(_ image: UIImage) async throws -> MacroResult {
        guard let jpegData = resized(image, maxEdge: 1024).jpegData(compressionQuality: 0.8) else {
            throw ClaudeServiceError.noContent
        }

        let base64 = jpegData.base64EncodedString()

        let prompt = """
        Analyze this food photo and estimate its macronutrients. \
        Reply with ONLY a single-line JSON object, no markdown, no explanation:
        {"food":"<name>","calories":<kcal>,"protein":<g>,"carbs":<g>,"fat":<g>}
        """

        let request = ClaudeRequest(
            model: model,
            maxTokens: 256,
            messages: [
                ClaudeMessage(role: "user", content: [
                    .image(mediaType: "image/jpeg", base64Data: base64),
                    .text(prompt)
                ])
            ]
        )

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(Config.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, _) = try await performRequest(urlRequest)

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        guard let text = claudeResponse.content.first(where: { $0.type == "text" })?.text else {
            throw ClaudeServiceError.noContent
        }

        // Strip optional markdown fences
        let jsonString = stripMarkdownFences(text)

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw ClaudeServiceError.malformedJSON(text)
        }

        do {
            return try JSONDecoder().decode(MacroResult.self, from: jsonData)
        } catch {
            throw ClaudeServiceError.malformedJSON(jsonString)
        }
    }

    func analyzeFoodImageWithVoice(_ image: UIImage, voiceNote: String) async throws -> MacroResult {
        guard let jpegData = resized(image, maxEdge: 1024).jpegData(compressionQuality: 0.8) else {
            throw ClaudeServiceError.noContent
        }

        let base64 = jpegData.base64EncodedString()

        let prompt = """
        Analyze this food photo and the user's description to estimate macronutrients. \
        User said: "\(voiceNote)". \
        Use both the photo and the description together for a more accurate estimate. \
        Reply with ONLY a single-line JSON object, no markdown, no explanation:
        {"food":"<name>","calories":<kcal>,"protein":<g>,"carbs":<g>,"fat":<g>}
        """

        let request = ClaudeRequest(
            model: model,
            maxTokens: 256,
            messages: [
                ClaudeMessage(role: "user", content: [
                    .image(mediaType: "image/jpeg", base64Data: base64),
                    .text(prompt)
                ])
            ]
        )

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(Config.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, _) = try await performRequest(urlRequest)

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        guard let text = claudeResponse.content.first(where: { $0.type == "text" })?.text else {
            throw ClaudeServiceError.noContent
        }

        let jsonString = stripMarkdownFences(text)
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw ClaudeServiceError.malformedJSON(text)
        }

        do {
            return try JSONDecoder().decode(MacroResult.self, from: jsonData)
        } catch {
            throw ClaudeServiceError.malformedJSON(jsonString)
        }
    }

    /// Performs an API request, retrying up to `maxRetries` times on 529 (overloaded)
    /// with a 2-second delay between attempts. Maps common HTTP errors to user-friendly cases.
    private func performRequest(_ request: URLRequest, maxRetries: Int = 3) async throws -> (Data, URLResponse) {
        for attempt in 1...maxRetries {
            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await URLSession.shared.data(for: request)
            } catch let urlError as URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost,
                     .cannotFindHost, .cannotConnectToHost, .timedOut, .dataNotAllowed:
                    throw ClaudeServiceError.noConnection
                default:
                    throw urlError
                }
            }

            guard let http = response as? HTTPURLResponse else {
                return (data, response)
            }

            if http.statusCode == 200 {
                return (data, response)
            }

            // Retry on 529 (overloaded) with 2-second delay
            if http.statusCode == 529 && attempt < maxRetries {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                continue
            }

            switch http.statusCode {
            case 529: throw ClaudeServiceError.overloaded
            case 429: throw ClaudeServiceError.rateLimited
            case 500: throw ClaudeServiceError.serverError
            default:  throw ClaudeServiceError.badResponse(statusCode: http.statusCode)
            }
        }
        throw ClaudeServiceError.serverError
    }

    private nonisolated func resized(_ image: UIImage, maxEdge: CGFloat) -> UIImage {
        let size = image.size
        let longestEdge = max(size.width, size.height)
        guard longestEdge > maxEdge else { return image }
        let scale = maxEdge / longestEdge
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }

    private nonisolated func stripMarkdownFences(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("```") {
            result = result.components(separatedBy: "\n").dropFirst().joined(separator: "\n")
            if result.hasSuffix("```") {
                result = String(result.dropLast(3))
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
