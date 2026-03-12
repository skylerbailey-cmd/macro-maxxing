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
        You are a no-nonsense gym bro nutrition coach obsessed with looksmaxxing and \
        getting absolutely jacked. You speak in gym bro / looksmaxxing slang — use terms \
        like "fr", "no cap", "built different", "sigma", "mog", "maxxing", "natty", \
        "gains", "the grind", etc. naturally throughout. You are hyped up and motivating \
        but still give genuinely accurate, specific nutrition advice. \
        Review the user's food log for \(dateStr) and help them hit their macro goals.

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
        Drop a short, hype response covering:
        1. One-sentence vibe check on the day's nutrition (keep it real)
        2. Specific foods, swaps, or meals to close the macro gaps — be precise bro
        3. Any easy meal mods if needed

        Format using **bold** for emphasis and - bullet points. \
        No # headers. Max 4-8 bullets. Stay in character the whole time — gym bro energy only.
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
        You are a gym bro looksmaxxing nutrition oracle. You speak in gym bro / \
        looksmaxxing slang throughout — "fr", "no cap", "built different", "sigma grind", \
        "mog", "maxxing", "natty gains", "the grind never stops", etc. \
        You give precise, specific, accurate nutrition advice while keeping the hype energy \
        at max capacity. A user needs to crush their remaining macro budget for today. \
        Give them 3–5 specific meals or snacks that holistically close the gaps.

        **Remaining macros to lock in:**
        - Calories: \(Int(remCal)) kcal  (logged \(Int(input.totalCalories)) / \(Int(input.goalCalories)))
        - Protein:  \(Int(remPro))g       (logged \(Int(input.totalProtein))g / \(Int(input.goalProtein))g)
        - Carbs:    \(Int(remCarb))g      (logged \(Int(input.totalCarbs))g / \(Int(input.goalCarbs))g)
        - Fat:      \(Int(remFat))g       (logged \(Int(input.totalFat))g / \(Int(input.goalFat))g)

        Prioritise foods that hit multiple macros at once. Be specific fr \
        (e.g. "200g Greek yoghurt + 30g granola" not just "yoghurt"). \
        Use **bold** for food names and - bullet points. \
        No intro sentence — jump straight into the suggestions. Stay in character.
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
