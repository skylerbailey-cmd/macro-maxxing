//
//  ClaudeAnalysisService.swift
//  Wellness
//

import Foundation
import FirebaseFunctions

final class ClaudeAnalysisService {
    private let model = "claude-haiku-4-5-20251001"

    /// Reads dietary exclusion toggles from UserDefaults and returns a prompt
    /// fragment to inject into both the nutrition coach and meal planner prompts.
    private var dietaryRestrictionsPrompt: String {
        let ud = UserDefaults.standard
        var exclusions: [String] = []
        if ud.bool(forKey: "excludeDairy")  { exclusions.append("dairy (milk, cheese, yogurt, butter, cream, whey)") }
        if ud.bool(forKey: "excludeGluten") { exclusions.append("gluten (wheat, bread, pasta, flour, barley, rye, soy sauce)") }
        guard !exclusions.isEmpty else { return "" }
        return "\n**Dietary Restrictions — MUST FOLLOW:**\n" +
            "The user has excluded: \(exclusions.joined(separator: "; ")). " +
            "Do NOT suggest any food, ingredient, or recipe that contains these. " +
            "Always choose alternatives (e.g. oat milk instead of milk, rice instead of pasta). " +
            "If a logged meal already contains an excluded ingredient, flag it.\n"
    }

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

        let payload: [String: Any] = [
            "model": model,
            "maxTokens": 2048,
            "messages": [["role": "user", "content": prompt]]
        ]

        let result = try await Functions.functions().httpsCallable("proxyClaude").call(payload)

        guard let responseDict = result.data as? [String: Any],
              let content = responseDict["content"] as? [[String: Any]],
              let text = content.first(where: { $0["type"] as? String == "text" })?["text"] as? String else {
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
        - Fat: \(Int(input.goalFat))g\(fastingLine)\(dietaryRestrictionsPrompt)\n
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
        You are a sports nutritionist doing a quick daily check-in. \
        Give a concise debrief with exactly 3 numbered points. \
        Each point must be ONE sentence only.

        1. **Meal Timing & Distribution** — One sentence about protein spread, workout fueling, or meal gaps.

        2. **Food Quality** — One sentence about any standout good or bad meal choices.

        3. **Top Recommendation** — One specific, actionable change for tomorrow. Name the food or meal and why.

        **Format rules:**
        - Exactly 3 numbered paragraphs, each with a bold title and one sentence.
        - Reference actual foods and times from the log.
        - No generic advice — be specific about what to swap, add, or shift.
        - Direct, motivating tone.
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
        \(dietaryRestrictionsPrompt)
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

        let payload: [String: Any] = [
            "model": model,
            "maxTokens": 800,
            "messages": [["role": "user", "content": prompt]]
        ]

        let result = try await Functions.functions().httpsCallable("proxyClaude").call(payload)
        guard let responseDict = result.data as? [String: Any],
              let content = responseDict["content"] as? [[String: Any]],
              let text = content.first(where: { $0["type"] as? String == "text" })?["text"] as? String else {
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

        let payload: [String: Any] = [
            "model": model,
            "maxTokens": 150,
            "messages": [["role": "user", "content": prompt]]
        ]

        let callResult = try await Functions.functions().httpsCallable("proxyClaude").call(payload)
        guard let responseDict = callResult.data as? [String: Any],
              let contentArr = responseDict["content"] as? [[String: Any]],
              let text = contentArr.first(where: { $0["type"] as? String == "text" })?["text"] as? String
        else { throw ClaudeServiceError.noContent }

        let jsonString = stripMarkdownFences(text)
        guard let jsonData = jsonString.data(using: .utf8),
              let json     = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let name     = json["name"]            as? String,
              let duration = (json["durationMinutes"] as? Int) ?? (json["durationMinutes"] as? Double).map({ Int($0) }),
              let calories = (json["caloriesBurned"] as? Int) ?? (json["caloriesBurned"] as? Double).map({ Int($0) })
        else { throw ClaudeServiceError.noContent }

        let typeRaw    = json["workoutType"] as? String ?? ""
        let workoutType = WorkoutType(rawValue: typeRaw) ?? .other
        return WorkoutParseResult(name: name, workoutType: workoutType,
                                  durationMinutes: duration, caloriesBurned: calories)
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
