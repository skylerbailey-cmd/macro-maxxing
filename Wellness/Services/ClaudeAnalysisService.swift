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
        typealias FastingWindow = (startHour: Int, startMinute: Int, durationHours: Int)

        let entries:      [(name: String, calories: Double, protein: Double, carbs: Double, fat: Double, loggedAt: Date)]
        let goalCalories: Double
        let goalProtein:  Double
        let goalCarbs:    Double
        let goalFat:      Double
        let date:         Date
        var workouts:     [WorkoutSummary] = []
        /// nil = fasting not enabled
        var fastingWindow: FastingWindow? = nil
    }

    func analyze(_ input: NutritionInput) async throws -> String {
        let prompt = buildPrompt(input)

        let body = RequestBody(
            model: model,
            maxTokens: 2048,
            messages: [RequestBody.Message(role: "user", content: prompt)]
        )

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue(Config.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await performRequest(req)

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

        // Build fasting window string if enabled
        var fastingLine = ""
        if let fw = input.fastingWindow {
            let startTotalMin = fw.startHour * 60 + fw.startMinute
            let endTotalMin   = (startTotalMin + fw.durationHours * 60) % (24 * 60)
            func fmt(_ totalMin: Int) -> String {
                let h = (totalMin / 60) % 24
                let m = totalMin % 60
                let suffix = h < 12 ? "AM" : "PM"
                let h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
                return m == 0 ? "\(h12) \(suffix)" : "\(h12):\(String(format: "%02d", m)) \(suffix)"
            }
            let fastHours = 24 - fw.durationHours
            fastingLine = "\n**Intermittent Fasting — Active**\n" +
                "- Eating window: \(fmt(startTotalMin)) – \(fmt(endTotalMin)) (\(fw.durationHours)h window)\n" +
                "- Fasting period: \(fastHours)h\n" +
                "Any recommendation must respect this eating window. " +
                "Do not suggest eating outside of it. " +
                "Factor in how the window affects meal timing and macro distribution.\n"
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
        - Fat: \(Int(input.goalFat))g\(fastingLine)\n
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

        p += """
        \n
        You are reviewing this person's full day of eating and training. \
        Act like a real sports nutritionist doing a daily check-in. \
        Analyze everything — every meal, the macro split across the day, \
        meal timing relative to workouts, and overall goal adherence — \
        then give a concise daily debrief covering these areas:

        1. **Macro overview** — How did they land vs. goals? Call out any macro that was \
        significantly over or under. Be specific with numbers.

        2. **Meal timing & distribution** — Was protein spread evenly or back-loaded? \
        Did they fuel properly around their workout (pre/post)? \
        Were there long gaps without eating that hurt performance or recovery?

        3. **Food quality** — Any meals that were mostly empty carbs or low-quality fats? \
        Any standout meals that were well-balanced?

        4. **Top recommendation** — Based on the full picture, give ONE specific, \
        actionable change for tomorrow. Name the meal or food. \
        Explain WHY it matters (muscle recovery, energy, satiety, etc.).

        **Format rules:**
        - Use short paragraphs, not bullet lists.
        - Keep the whole response to 4–6 sentences max.
        - Be direct and specific — reference actual foods and times from the log.
        - No generic advice like "eat more protein" — say exactly what to swap, add, or shift and when.
        - Keep the tone motivating but real — like a coach who actually reviews their athletes' logs.
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
        // Calculate remaining grams for each macro
        let remainingCalories = max(0, input.goalCalories - input.totalCalories)
        let remainingProtein  = max(0, input.goalProtein  - input.totalProtein)
        let remainingCarbs    = max(0, input.goalCarbs    - input.totalCarbs)
        let remainingFat      = max(0, input.goalFat      - input.totalFat)

        // Determine which macros are met or over goal
        let caloriesMet = input.totalCalories >= input.goalCalories
        let proteinMet  = input.totalProtein  >= input.goalProtein
        let carbsMet    = input.totalCarbs    >= input.goalCarbs
        let fatMet      = input.totalFat      >= input.goalFat

        // Build per-macro status lines with exact gram amounts
        var macroLines: [String] = []

        if caloriesMet {
            let over = Int(input.totalCalories - input.goalCalories)
            macroLines.append("- Calories: ALREADY MET (\(Int(input.totalCalories)) / \(Int(input.goalCalories)) kcal, over by \(over) kcal) — OFF LIMITS, do NOT suggest calorie-dense foods")
        } else {
            macroLines.append("- Calories: \(Int(remainingCalories)) kcal remaining (\(Int(input.totalCalories)) eaten of \(Int(input.goalCalories)) kcal goal)")
        }

        if proteinMet {
            let over = Int(input.totalProtein - input.goalProtein)
            macroLines.append("- Protein: ALREADY MET (\(Int(input.totalProtein))g / \(Int(input.goalProtein))g, over by \(over)g) — OFF LIMITS, do NOT suggest high-protein foods")
        } else {
            macroLines.append("- Protein: \(Int(remainingProtein))g remaining (\(Int(input.totalProtein))g eaten of \(Int(input.goalProtein))g goal)")
        }

        if carbsMet {
            let over = Int(input.totalCarbs - input.goalCarbs)
            macroLines.append("- Carbs: ALREADY MET (\(Int(input.totalCarbs))g / \(Int(input.goalCarbs))g, over by \(over)g) — OFF LIMITS, do NOT suggest carb-heavy foods")
        } else {
            macroLines.append("- Carbs: \(Int(remainingCarbs))g remaining (\(Int(input.totalCarbs))g eaten of \(Int(input.goalCarbs))g goal)")
        }

        if fatMet {
            let over = Int(input.totalFat - input.goalFat)
            macroLines.append("- Fat: ALREADY MET (\(Int(input.totalFat))g / \(Int(input.goalFat))g, over by \(over)g) — OFF LIMITS, avoid added fats entirely")
        } else {
            macroLines.append("- Fat: \(Int(remainingFat))g remaining (\(Int(input.totalFat))g eaten of \(Int(input.goalFat))g goal)")
        }

        // Build the list of deficits to target
        var deficits: [String] = []
        if !caloriesMet { deficits.append("\(Int(remainingCalories)) kcal") }
        if !proteinMet  { deficits.append("\(Int(remainingProtein))g protein") }
        if !carbsMet    { deficits.append("\(Int(remainingCarbs))g carbs") }
        if !fatMet      { deficits.append("\(Int(remainingFat))g fat") }

        // Build the list of macros to avoid
        var offLimits: [String] = []
        if caloriesMet { offLimits.append("calories") }
        if proteinMet  { offLimits.append("protein") }
        if carbsMet    { offLimits.append("carbs") }
        if fatMet      { offLimits.append("fat") }

        let deficitSummary = deficits.isEmpty
            ? "All macros are met — suggest only a very light option if anything."
            : "The user still needs: \(deficits.joined(separator: ", "))."

        let avoidSummary = offLimits.isEmpty
            ? ""
            : " Macros that are OFF LIMITS (already met or over): \(offLimits.joined(separator: ", ")). Do NOT suggest foods high in these."

        let prompt = """
        You are a no-nonsense nutrition coach who's been in the gym long enough to know what actually works. \
        You give precise, accurate advice in a direct, confident tone — like someone who's dialed in and wants \
        to help others get there too. A word of gym culture here and there is fine when it flows naturally, \
        but the quality of the advice always comes first.

        A user is mid-day and wants to know what to eat NEXT. Your job is to suggest foods that fill \
        their remaining macro gaps WITHOUT increasing any macro that is already at or over its goal.

        **Macro status (exact gram amounts):**
        \(macroLines.joined(separator: "\n"))

        **Summary:** \(deficitSummary)\(avoidSummary)

        Suggest exactly 2 specific meals or snacks that primarily address the remaining deficits:
        1. A full meal option
        2. A quick snack option

        Rules:
        - CRITICAL: Any macro marked OFF LIMITS must not be meaningfully increased by your suggestions. \
          Choose foods that are naturally low in those macros.
        - Each option must use a DIFFERENT primary ingredient / protein source — no repeating proteins across options
        - Draw from the full range of real foods: chicken, beef, fish, eggs, Greek yogurt, \
          cottage cheese, tofu, turkey, tuna, lentils, oats, rice, fruit, nuts, seeds, etc.
        - Be very specific with amounts in grams (e.g. "200g ground beef + 150g sweet potato") \
          and include estimated macros for each suggestion (calories, protein, carbs, fat)
        - Format: bold the food name, then one short sentence on why it fits the macro gap, \
          then the estimated macros in parentheses
        - No intro line, no outro — just the 2 numbered options
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

        let (data, _) = try await performRequest(req)
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

        let (data, _) = try await performRequest(req)
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

    // MARK: - Request helper with retry

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

            // Map status codes to user-friendly errors
            switch http.statusCode {
            case 529: throw ClaudeServiceError.overloaded
            case 429: throw ClaudeServiceError.rateLimited
            case 500: throw ClaudeServiceError.serverError
            default:  throw ClaudeServiceError.badResponse(statusCode: http.statusCode)
            }
        }
        throw ClaudeServiceError.serverError
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
