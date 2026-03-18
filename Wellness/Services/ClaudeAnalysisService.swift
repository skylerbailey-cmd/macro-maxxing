//
//  ClaudeAnalysisService.swift
//  Wellness
//

import Foundation

final class ClaudeAnalysisService {
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model    = "claude-sonnet-4-6"

    struct WorkoutSummary {
        let name:            String
        let type:            String
        let durationMinutes: Int
        let caloriesBurned:  Int
        let loggedAt:        Date
    }

    struct NutritionInput {
        let entries:      [(name: String, calories: Double, protein: Double, carbs: Double, fat: Double, loggedAt: Date)]
        let goalCalories: Double
        let goalProtein:  Double
        let goalCarbs:    Double
        let goalFat:      Double
        let date:         Date
        var workouts:     [WorkoutSummary] = []
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
        let timeFmt  = DateFormatter()
        timeFmt.dateFormat = "h:mm a"
        let dateFmt  = DateFormatter()
        dateFmt.dateFormat = "MMMM d"
        let dateStr  = isToday ? "today" : dateFmt.string(from: input.date)

        let totalCal  = input.entries.reduce(0) { $0 + $1.calories }
        let totalPro  = input.entries.reduce(0) { $0 + $1.protein }
        let totalCarb = input.entries.reduce(0) { $0 + $1.carbs }
        let totalFat  = input.entries.reduce(0) { $0 + $1.fat }

        func pct(_ val: Double, _ goal: Double) -> String {
            guard goal > 0 else { return "0%" }
            return "\(Int((val / goal) * 100))%"
        }

        var p = """
        You are a sharp nutrition coach who lives and breathes the gym lifestyle. \
        You care about physique, consistency, and getting macros dialed in — \
        and you talk like someone who actually trains. Keep advice direct and specific. \
        Slip in a casual gym-culture word or two when it fits naturally, \
        but solid, actionable nutrition guidance is always the priority. \
        Review the user's food log for \(dateStr) and help them lock in their macro goals.

        **Daily Macro Goals**
        - Calories: \(Int(input.goalCalories)) kcal
        - Protein: \(Int(input.goalProtein))g
        - Carbs: \(Int(input.goalCarbs))g
        - Fat: \(Int(input.goalFat))g\n\n
        """

        // Workouts
        if !input.workouts.isEmpty {
            p += "**Workouts Logged \(dateStr.capitalized):**\n"
            for w in input.workouts {
                let timeStr = timeFmt.string(from: w.loggedAt)
                p += "- \(w.name) (\(w.type)) at \(timeStr): \(w.durationMinutes) min, ~\(w.caloriesBurned) kcal burned\n"
            }
            p += "\n"
        }

        // Meals with timestamps
        if input.entries.isEmpty {
            p += "**Food Logged \(dateStr.capitalized):** Nothing logged yet.\n\n"
        } else {
            p += "**Food Logged \(dateStr.capitalized)** (with time eaten):\n"
            for e in input.entries {
                let timeStr = timeFmt.string(from: e.loggedAt)
                p += "- \(timeStr) — \(e.name): \(Int(e.calories)) kcal, "
                p += "\(Int(e.protein))g protein, \(Int(e.carbs))g carbs, \(Int(e.fat))g fat\n"
            }
            p += "\n**Current Totals vs Goals:**\n"
            p += "- Calories: \(Int(totalCal))/\(Int(input.goalCalories)) kcal (\(pct(totalCal, input.goalCalories)))\n"
            p += "- Protein:  \(Int(totalPro))/\(Int(input.goalProtein))g (\(pct(totalPro, input.goalProtein)))\n"
            p += "- Carbs:    \(Int(totalCarb))/\(Int(input.goalCarbs))g (\(pct(totalCarb, input.goalCarbs)))\n"
            p += "- Fat:      \(Int(totalFat))/\(Int(input.goalFat))g (\(pct(totalFat, input.goalFat)))\n"
        }

        if !input.workouts.isEmpty {
            p += """
            \n
            Consider the workout timing relative to the meals logged. \
            Look at pre-workout and post-workout nutrition: were there enough carbs before training \
            and enough protein within 1–2 hours after? Is the macro distribution across the day \
            well-timed relative to the session?

            Look at the specific meals logged and pick ONE meal to swap or tweak — \
            focusing on timing or macro balance relative to the workout. \
            Name the exact meal and the exact change. \
            One sentence only — no intro, no list, no extra commentary. Keep it direct and motivating.
            """
        } else {
            p += """
            \n
            Look at the specific meals logged and pick ONE meal to swap or tweak to better hit \
            the macro goals. Name the exact meal and the exact change. \
            One sentence only — no intro, no list, no extra commentary. Keep it direct and motivating.
            """
        }
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
        // Percentage of each goal completed so far
        func pct(_ logged: Double, _ goal: Double) -> Int {
            guard goal > 0 else { return 0 }
            return Int((logged / goal) * 100)
        }
        let calPct  = pct(input.totalCalories, input.goalCalories)
        let proPct  = pct(input.totalProtein,  input.goalProtein)
        let carbPct = pct(input.totalCarbs,    input.goalCarbs)
        let fatPct  = pct(input.totalFat,      input.goalFat)

        let prompt = """
        You are a no-nonsense nutrition coach who's been in the gym long enough to know what actually works. \
        You give precise, accurate advice in a direct, confident tone — like someone who's dialed in and wants \
        to help others get there too. A word of gym culture here and there is fine when it flows naturally, \
        but the quality of the advice always comes first.

        A user is mid-day and wants to know what to eat NEXT based on how their macros \
        are distributed RIGHT NOW — not simply what's left. Look at which macros are \
        lagging behind relative to the others and prioritise those.

        **Current macro progress (% of daily goal hit so far):**
        - Calories: \(calPct)%  (\(Int(input.totalCalories)) / \(Int(input.goalCalories)) kcal)
        - Protein:  \(proPct)%  (\(Int(input.totalProtein))g / \(Int(input.goalProtein))g)
        - Carbs:    \(carbPct)% (\(Int(input.totalCarbs))g / \(Int(input.goalCarbs))g)
        - Fat:      \(fatPct)%  (\(Int(input.totalFat))g / \(Int(input.goalFat))g)

        Give exactly 3 suggestions that all address the same macro gap but use completely different foods:
        1. A full meal option
        2. A quick snack option
        3. A second snack option using a different food group than option 2

        Rules:
        - Each option must use a DIFFERENT primary ingredient / protein source — no repeating proteins across options
        - Draw from the full range of real foods: chicken, beef, fish, eggs, Greek yogurt, \
          cottage cheese, tofu, turkey, tuna, lentils, oats, rice, fruit, nuts, seeds, etc.
        - Be very specific with amounts (e.g. "200g ground beef + sweet potato" not just "beef and potato")
        - Format: bold the food name, then one short sentence on why it fits the macro gap
        - No intro line, no outro — just the 3 numbered options
        """

        let body = RequestBody(
            model: model,
            maxTokens: 800,
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

    // MARK: - Workout Voice Parse

    struct WorkoutParseResult {
        let name:            String
        let workoutType:     WorkoutType
        let durationMinutes: Int
        let caloriesBurned:  Int
    }

    /// Parses a free-form workout description into structured fields including workout type.
    func parseWorkout(transcript: String) async throws -> WorkoutParseResult {
        let typeOptions = WorkoutType.allCases.map { "\"\($0.rawValue)\"" }.joined(separator: ", ")
        let prompt = """
        You are a fitness assistant. A user verbally described their workout. \
        Extract the workout name, workout type, duration in minutes, and estimated calories burned.

        Workout type must be one of: \(typeOptions)

        If the user mentions calories, use that number. Otherwise estimate accurately \
        based on workout type and duration for an average adult.

        User said: "\(transcript)"

        Respond ONLY with a valid JSON object and nothing else — no explanation, no markdown:
        {"name": "...", "workoutType": "Strength", "durationMinutes": 45, "caloriesBurned": 350}
        """

        let body = RequestBody(
            model: model,
            maxTokens: 150,
            messages: [RequestBody.Message(role: "user", content: prompt)]
        )
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue(Config.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01",           forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json",     forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw ClaudeServiceError.badResponse(statusCode: http.statusCode)
        }
        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        guard let text = decoded.content.first(where: { $0.type == "text" })?.text,
              let jsonData = text.data(using: .utf8),
              let json     = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let name     = json["name"]            as? String,
              let duration = json["durationMinutes"] as? Int,
              let calories = json["caloriesBurned"]  as? Int
        else { throw ClaudeServiceError.noContent }

        let typeRaw    = json["workoutType"] as? String ?? ""
        let workoutType = WorkoutType(rawValue: typeRaw) ?? .other
        return WorkoutParseResult(name: name, workoutType: workoutType,
                                  durationMinutes: duration, caloriesBurned: calories)
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
