//
//  ClaudeAnalysisService.swift
//  Wellness
//

import Foundation

final class ClaudeAnalysisService {
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model    = "claude-sonnet-4-6"

    struct NutritionInput {
        let entries:      [(name: String, calories: Double, protein: Double, carbs: Double, fat: Double)]
        let goalCalories: Double
        let goalProtein:  Double
        let goalCarbs:    Double
        let goalFat:      Double
        let date:         Date
    }

    func analyze(_ input: NutritionInput) async throws -> String {
        let prompt = buildPrompt(input)

        let body = RequestBody(
            model: model,
            maxTokens: 1024,
            messages: [RequestBody.Message(role: "user", content: prompt)]
        )

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue(Config.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw ClaudeServiceError.badResponse(statusCode: http.statusCode)
        }

        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        guard let text = decoded.content.first(where: { $0.type == "text" })?.text else {
            throw ClaudeServiceError.noContent
        }
        return text
    }

    // MARK: - Prompt

    private func buildPrompt(_ input: NutritionInput) -> String {
        let calendar = Calendar.current
        let isToday  = calendar.isDateInToday(input.date)
        let fmt      = DateFormatter()
        fmt.dateFormat = "MMMM d"
        let dateStr  = isToday ? "today" : fmt.string(from: input.date)

        let totalCal  = input.entries.reduce(0) { $0 + $1.calories }
        let totalPro  = input.entries.reduce(0) { $0 + $1.protein }
        let totalCarb = input.entries.reduce(0) { $0 + $1.carbs }
        let totalFat  = input.entries.reduce(0) { $0 + $1.fat }

        func pct(_ val: Double, _ goal: Double) -> String {
            guard goal > 0 else { return "0%" }
            return "\(Int((val / goal) * 100))%"
        }

        var p = """
        You are a supportive nutrition coach reviewing a user's food log for \(dateStr). \
        Provide practical, encouraging suggestions to help them better reach their macro goals.

        **Daily Macro Goals**
        - Calories: \(Int(input.goalCalories)) kcal
        - Protein: \(Int(input.goalProtein))g
        - Carbs: \(Int(input.goalCarbs))g
        - Fat: \(Int(input.goalFat))g\n\n
        """

        if input.entries.isEmpty {
            p += "**Food Logged \(dateStr.capitalized):** Nothing logged yet.\n\n"
        } else {
            p += "**Food Logged \(dateStr.capitalized):**\n"
            for e in input.entries {
                p += "- \(e.name): \(Int(e.calories)) kcal, "
                p += "\(Int(e.protein))g protein, \(Int(e.carbs))g carbs, \(Int(e.fat))g fat\n"
            }
            p += "\n**Current Totals vs Goals:**\n"
            p += "- Calories: \(Int(totalCal))/\(Int(input.goalCalories)) kcal (\(pct(totalCal, input.goalCalories)))\n"
            p += "- Protein: \(Int(totalPro))/\(Int(input.goalProtein))g (\(pct(totalPro, input.goalProtein)))\n"
            p += "- Carbs: \(Int(totalCarb))/\(Int(input.goalCarbs))g (\(pct(totalCarb, input.goalCarbs)))\n"
            p += "- Fat: \(Int(totalFat))/\(Int(input.goalFat))g (\(pct(totalFat, input.goalFat)))\n"
        }

        p += """
        \n
        Please provide a short, helpful response covering:
        1. A one-sentence assessment of the day so far
        2. Specific foods, snacks, or meals to add or swap to close any macro gaps
        3. Any easy modifications to existing meals if helpful

        Format using **bold** for emphasis and - bullet points for lists. \
        Do not use # headers. Keep it concise and actionable (4-8 bullet points max).
        """
        return p
    }

    // MARK: - Brainstorm

    struct BrainstormInput {
        let totalCalories: Double; let goalCalories: Double
        let totalProtein:  Double; let goalProtein:  Double
        let totalCarbs:    Double; let goalCarbs:    Double
        let totalFat:      Double; let goalFat:      Double
    }

    func brainstorm(_ input: BrainstormInput) async throws -> String {
        let remCal  = max(input.goalCalories - input.totalCalories, 0)
        let remPro  = max(input.goalProtein  - input.totalProtein,  0)
        let remCarb = max(input.goalCarbs    - input.totalCarbs,    0)
        let remFat  = max(input.goalFat      - input.totalFat,      0)

        let prompt = """
        You are a fitness nutrition coach. A user needs to hit their remaining macro goals \
        for today. Suggest 3–5 specific, practical meals or snacks that would \
        collectively satisfy the remaining budget.

        **Remaining macros needed:**
        - Calories: \(Int(remCal)) kcal  (logged \(Int(input.totalCalories)) / \(Int(input.goalCalories)))
        - Protein:  \(Int(remPro))g       (logged \(Int(input.totalProtein))g / \(Int(input.goalProtein))g)
        - Carbs:    \(Int(remCarb))g      (logged \(Int(input.totalCarbs))g / \(Int(input.goalCarbs))g)
        - Fat:      \(Int(remFat))g       (logged \(Int(input.totalFat))g / \(Int(input.goalFat))g)

        Focus on foods that hit multiple targets at once. Be specific (e.g. \
        "2 eggs + 1 slice whole-grain toast" not just "eggs"). \
        Format using **bold** for food names and - bullet points. \
        Keep it concise — no intro sentence, just the suggestions.
        """

        let body = RequestBody(
            model: model,
            maxTokens: 600,
            messages: [RequestBody.Message(role: "user", content: prompt)]
        )
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue(Config.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw ClaudeServiceError.badResponse(statusCode: http.statusCode)
        }
        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        guard let text = decoded.content.first(where: { $0.type == "text" })?.text else {
            throw ClaudeServiceError.noContent
        }
        return text
    }

    // MARK: - Codable types

    private struct RequestBody: Encodable {
        let model:     String
        let maxTokens: Int
        let messages:  [Message]

        struct Message: Encodable {
            let role:    String
            let content: String
        }

        enum CodingKeys: String, CodingKey {
            case model, messages
            case maxTokens = "max_tokens"
        }
    }

    private struct ResponseBody: Decodable {
        let content: [ContentBlock]
        struct ContentBlock: Decodable {
            let type: String
            let text: String?
        }
    }
}
