//
//  RestaurantMenuService.swift
//  Wellness
//
//  Sends a photo of a restaurant menu + the user's remaining macros to
//  Claude Sonnet and returns three ranked menu-item recommendations.
//

import UIKit
import FirebaseFunctions

struct MenuRecommendation: Identifiable, Codable, Equatable {
    let id: String
    let rank: Int
    let itemName: String
    let description: String
    let estimatedCalories: Int
    let estimatedProtein: Int
    let estimatedCarbs: Int
    let estimatedFat: Int
    /// Why this item was picked (ties back to the user's remaining macros).
    let reason: String
    /// Optional modification tip (e.g. "Ask for grilled instead of fried").
    let modification: String

    private enum CodingKeys: String, CodingKey {
        case id, rank, itemName, description, estimatedCalories, estimatedProtein
        case estimatedCarbs, estimatedFat, reason, modification
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id                = UUID().uuidString
        self.rank              = try c.decode(Int.self, forKey: .rank)
        self.itemName          = try c.decode(String.self, forKey: .itemName)
        self.description       = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.estimatedCalories = try c.decode(Int.self, forKey: .estimatedCalories)
        self.estimatedProtein  = try c.decode(Int.self, forKey: .estimatedProtein)
        self.estimatedCarbs    = try c.decode(Int.self, forKey: .estimatedCarbs)
        self.estimatedFat      = try c.decode(Int.self, forKey: .estimatedFat)
        self.reason            = try c.decode(String.self, forKey: .reason)
        self.modification      = try c.decodeIfPresent(String.self, forKey: .modification) ?? ""
    }

    init(rank: Int, itemName: String, description: String,
         estimatedCalories: Int, estimatedProtein: Int,
         estimatedCarbs: Int, estimatedFat: Int,
         reason: String, modification: String) {
        self.id                = UUID().uuidString
        self.rank              = rank
        self.itemName          = itemName
        self.description       = description
        self.estimatedCalories = estimatedCalories
        self.estimatedProtein  = estimatedProtein
        self.estimatedCarbs    = estimatedCarbs
        self.estimatedFat      = estimatedFat
        self.reason            = reason
        self.modification      = modification
    }
}

struct RestaurantMenuResult: Codable, Equatable {
    let recommendations: [MenuRecommendation]
}

/// A saved scan — groups 3 recommendations with metadata.
struct SavedMenuScan: Identifiable, Codable, Equatable {
    let id: String
    let date: Date
    /// "Photo" or the URL hostname (e.g. "chipotle.com")
    let source: String
    let recommendations: [MenuRecommendation]

    init(source: String, recommendations: [MenuRecommendation]) {
        self.id              = UUID().uuidString
        self.date            = Date()
        self.source          = source
        self.recommendations = recommendations
    }
}

/// Persists the last 3 restaurant mode scans in UserDefaults.
enum SavedMenuScanStore {
    private static let key = "savedMenuScans"
    private static let maxScans = 3

    static func load() -> [SavedMenuScan] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let scans = try? JSONDecoder().decode([SavedMenuScan].self, from: data)
        else { return [] }
        return scans
    }

    static func save(_ scan: SavedMenuScan) {
        var scans = load()
        scans.insert(scan, at: 0)
        if scans.count > maxScans { scans = Array(scans.prefix(maxScans)) }
        if let data = try? JSONEncoder().encode(scans) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func delete(_ id: String) {
        var scans = load()
        scans.removeAll { $0.id == id }
        if let data = try? JSONEncoder().encode(scans) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

final class RestaurantMenuService {
    static let shared = RestaurantMenuService()
    private let model = "claude-sonnet-4-6"
    private init() {}

    struct MacroContext {
        let remainingCalories: Int
        let remainingProtein: Int
        let remainingCarbs: Int
        let remainingFat: Int
        let goalCalories: Int
        let goalProtein: Int
        let goalCarbs: Int
        let goalFat: Int
    }

    func analyzeMenu(image: UIImage, macros: MacroContext) async throws -> [MenuRecommendation] {
        guard let jpegData = resized(image, maxEdge: 1024).jpegData(compressionQuality: 0.75) else {
            throw MenuServiceError.imageProcessingFailed
        }
        let base64 = jpegData.base64EncodedString()

        let dietary = DietaryRestrictions.visionPromptFragment()
        let dietarySection = dietary.isEmpty ? "" : "\n\(dietary)\n"

        let prompt = """
        You are a sports nutrition coach helping someone eat at a restaurant. \
        They have photographed the menu. Based on what's on the menu and their \
        remaining macro budget for the day, recommend the TOP 3 menu items \
        that best fit their goals.

        **User's Remaining Macros for Today:**
        - Calories: \(macros.remainingCalories) kcal remaining (of \(macros.goalCalories) kcal goal)
        - Protein: \(macros.remainingProtein)g remaining (of \(macros.goalProtein)g goal)
        - Carbs: \(macros.remainingCarbs)g remaining (of \(macros.goalCarbs)g goal)
        - Fat: \(macros.remainingFat)g remaining (of \(macros.goalFat)g goal)
        \(dietarySection)
        **Instructions:**
        1. Read the menu items from the photo.
        2. Estimate macros for each item using USDA-accurate nutritional knowledge.
        3. Rank the top 3 items that best help the user hit their remaining macro \
        targets — prioritize protein coverage, then calorie fit, then overall \
        macro balance.
        4. For each recommendation, include a short modification tip if it would \
        meaningfully improve the macro fit (e.g. "sub fries for a side salad", \
        "ask for sauce on the side"). Leave modification empty string if none needed.
        5. Keep the reason for each pick to one concise sentence.

        Return ONLY a JSON object — no markdown fences, no explanation:
        {
          "recommendations": [
            {
              "rank": 1,
              "itemName": "<exact menu item name>",
              "description": "<brief 5-10 word description of the dish>",
              "estimatedCalories": <int>,
              "estimatedProtein": <int>,
              "estimatedCarbs": <int>,
              "estimatedFat": <int>,
              "reason": "<why this item fits their macros>",
              "modification": "<optional tweak to improve macros, or empty string>"
            }
          ]
        }
        """

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
            throw MenuServiceError.networkError
        }

        guard let responseDict = result.data as? [String: Any],
              let content = responseDict["content"] as? [[String: Any]],
              let text = content.first(where: { $0["type"] as? String == "text" })?["text"] as? String else {
            throw MenuServiceError.noContent
        }

        let jsonString = stripMarkdownFences(text)
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw MenuServiceError.malformedJSON
        }

        let decoded = try JSONDecoder().decode(RestaurantMenuResult.self, from: jsonData)
        return decoded.recommendations
    }

    // MARK: - URL-based analysis

    func analyzeMenuURL(_ url: URL, macros: MacroContext) async throws -> [MenuRecommendation] {
        // Fetch the page HTML
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw MenuServiceError.urlFetchFailed
        }
        guard let html = String(data: data, encoding: .utf8) else {
            throw MenuServiceError.urlFetchFailed
        }

        // Strip HTML tags to plain text, truncate to keep token usage sane
        let plainText = String(stripHTML(html).prefix(12_000))
        guard plainText.count > 50 else {
            throw MenuServiceError.noMenuContent
        }

        let dietary = DietaryRestrictions.visionPromptFragment()
        let dietarySection = dietary.isEmpty ? "" : "\n\(dietary)\n"

        let prompt = """
        You are a sports nutrition coach helping someone eat at a restaurant. \
        They have shared the restaurant's online menu. Based on the menu items \
        and their remaining macro budget for the day, recommend the TOP 3 menu \
        items that best fit their goals.

        **User's Remaining Macros for Today:**
        - Calories: \(macros.remainingCalories) kcal remaining (of \(macros.goalCalories) kcal goal)
        - Protein: \(macros.remainingProtein)g remaining (of \(macros.goalProtein)g goal)
        - Carbs: \(macros.remainingCarbs)g remaining (of \(macros.goalCarbs)g goal)
        - Fat: \(macros.remainingFat)g remaining (of \(macros.goalFat)g goal)
        \(dietarySection)
        **Restaurant Menu (from \(url.host ?? "website")):**
        \(plainText)

        **Instructions:**
        1. Identify the menu items from the text above.
        2. Estimate macros for each item using USDA-accurate nutritional knowledge.
        3. Rank the top 3 items that best help the user hit their remaining macro \
        targets — prioritize protein coverage, then calorie fit, then overall \
        macro balance.
        4. For each recommendation, include a short modification tip if it would \
        meaningfully improve the macro fit (e.g. "sub fries for a side salad", \
        "ask for sauce on the side"). Leave modification empty string if none needed.
        5. Keep the reason for each pick to one concise sentence.

        Return ONLY a JSON object — no markdown fences, no explanation:
        {
          "recommendations": [
            {
              "rank": 1,
              "itemName": "<exact menu item name>",
              "description": "<brief 5-10 word description of the dish>",
              "estimatedCalories": <int>,
              "estimatedProtein": <int>,
              "estimatedCarbs": <int>,
              "estimatedFat": <int>,
              "reason": "<why this item fits their macros>",
              "modification": "<optional tweak to improve macros, or empty string>"
            }
          ]
        }
        """

        let payload: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        let result: HTTPSCallableResult
        do {
            result = try await Functions.functions().httpsCallable("proxyClaude").call(payload)
        } catch {
            throw MenuServiceError.networkError
        }

        guard let responseDict = result.data as? [String: Any],
              let content = responseDict["content"] as? [[String: Any]],
              let text = content.first(where: { $0["type"] as? String == "text" })?["text"] as? String else {
            throw MenuServiceError.noContent
        }

        let jsonString = stripMarkdownFences(text)
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw MenuServiceError.malformedJSON
        }

        let decoded = try JSONDecoder().decode(RestaurantMenuResult.self, from: jsonData)
        return decoded.recommendations
    }

    // MARK: - Helpers

    private func stripHTML(_ html: String) -> String {
        // Remove script/style blocks entirely, then strip remaining tags
        var s = html
        let blockPatterns = ["<script[^>]*>[\\s\\S]*?</script>",
                             "<style[^>]*>[\\s\\S]*?</style>",
                             "<nav[^>]*>[\\s\\S]*?</nav>",
                             "<footer[^>]*>[\\s\\S]*?</footer>"]
        for pattern in blockPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                s = regex.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: " ")
            }
        }
        // Strip all remaining HTML tags
        if let tagRegex = try? NSRegularExpression(pattern: "<[^>]+>") {
            s = tagRegex.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: " ")
        }
        // Decode common HTML entities
        s = s.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
        // Collapse whitespace
        s = s.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return s
    }

    private nonisolated func resized(_ image: UIImage, maxEdge: CGFloat) -> UIImage {
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

    private func stripMarkdownFences(_ text: String) -> String {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("```json") { s = String(s.dropFirst(7)) }
        else if s.hasPrefix("```")  { s = String(s.dropFirst(3)) }
        if s.hasSuffix("```") { s = String(s.dropLast(3)) }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum MenuServiceError: LocalizedError {
    case imageProcessingFailed, networkError, noContent, malformedJSON
    case urlFetchFailed, noMenuContent

    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed: "Couldn't process the menu photo."
        case .networkError:          "No connection — check your signal and try again."
        case .noContent:             "Couldn't read the menu. Try a clearer photo."
        case .malformedJSON:         "Unexpected response — please try again."
        case .urlFetchFailed:        "Couldn't load that URL — check the link and try again."
        case .noMenuContent:         "No menu content found on that page."
        }
    }
}
