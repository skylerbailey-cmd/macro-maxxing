//
//  ClaudeAnalysisService.swift
//  Wellness
//

import Foundation
import FirebaseFunctions

final class ClaudeAnalysisService {
    private let model = "claude-haiku-4-5-20251001"
    /// Stronger fallback model used only when the primary Haiku call returns
    /// suggestions that violate the user's macro upper limits. Paying for
    /// Sonnet on the ~20% of calls that fail validation is cheaper than
    /// running Sonnet on every brainstorm.
    private let fallbackModel = "claude-sonnet-4-6"

    // MARK: - Recent brainstorm ingredient tracking

    private static let recentIngredientsKey = "brainstormRecentIngredients"
    /// Max ingredients to remember across sessions (roughly 3-4 brainstorms).
    private static let maxRecentIngredients = 8

    /// Returns the list of recently suggested primary ingredients.
    private var recentIngredients: [String] {
        UserDefaults.standard.stringArray(forKey: Self.recentIngredientsKey) ?? []
    }

    /// Appends new ingredients and trims the list to the rolling window.
    private func saveRecentIngredients(_ newIngredients: [String]) {
        var list = recentIngredients
        list.append(contentsOf: newIngredients)
        // Keep only the most recent entries
        if list.count > Self.maxRecentIngredients {
            list = Array(list.suffix(Self.maxRecentIngredients))
        }
        UserDefaults.standard.set(list, forKey: Self.recentIngredientsKey)
    }

    /// Extracts bold text (e.g. "**Canned tuna**") from a brainstorm result
    /// and returns just the food names.
    private func extractIngredients(from text: String) -> [String] {
        // Match **bold text** patterns
        let pattern = #"\*\*(.+?)\*\*"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
    }

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
        // Calculate remaining grams to reach the goal
        let remainingCalories = max(0, input.goalCalories - input.totalCalories)
        let remainingProtein  = max(0, input.goalProtein  - input.totalProtein)
        let remainingCarbs    = max(0, input.goalCarbs    - input.totalCarbs)
        let remainingFat      = max(0, input.goalFat      - input.totalFat)

        // Upper limits — the app uses a ±15% acceptable range around each goal.
        // "Room" is how much the user can still eat before exceeding the upper limit.
        let upperCalories = input.goalCalories * 1.15
        let upperProtein  = input.goalProtein  * 1.15
        let upperCarbs    = input.goalCarbs    * 1.15
        let upperFat      = input.goalFat      * 1.15

        let roomCalories = max(0, upperCalories - input.totalCalories)
        let roomProtein  = max(0, upperProtein  - input.totalProtein)
        let roomCarbs    = max(0, upperCarbs    - input.totalCarbs)
        let roomFat      = max(0, upperFat      - input.totalFat)

        // Determine which macros are met or over goal
        let caloriesMet = input.totalCalories >= input.goalCalories
        let proteinMet  = input.totalProtein  >= input.goalProtein
        let carbsMet    = input.totalCarbs    >= input.goalCarbs
        let fatMet      = input.totalFat      >= input.goalFat

        // Determine which macros are nearly met (>=90% of goal) — treat as "almost done"
        let caloriesNearlyMet = !caloriesMet && input.goalCalories > 0 && (input.totalCalories / input.goalCalories) >= 0.90
        let proteinNearlyMet  = !proteinMet  && input.goalProtein  > 0 && (input.totalProtein  / input.goalProtein)  >= 0.90
        let carbsNearlyMet    = !carbsMet    && input.goalCarbs    > 0 && (input.totalCarbs    / input.goalCarbs)    >= 0.90
        let fatNearlyMet      = !fatMet      && input.goalFat      > 0 && (input.totalFat      / input.goalFat)      >= 0.90

        // Build per-macro status lines with exact gram amounts AND upper-limit room
        var macroLines: [String] = []

        if caloriesMet {
            if roomCalories > 0 {
                macroLines.append("- Calories: OVER GOAL but \(Int(roomCalories)) kcal room before upper limit (\(Int(input.totalCalories))/\(Int(input.goalCalories)) kcal, upper limit \(Int(upperCalories))) — keep any suggestion under \(Int(roomCalories)) kcal total")
            } else {
                macroLines.append("- Calories: OVER UPPER LIMIT (\(Int(input.totalCalories))/\(Int(input.goalCalories)) kcal, limit \(Int(upperCalories))) — HARD STOP, do not suggest eating more")
            }
        } else if caloriesNearlyMet {
            macroLines.append("- Calories: NEARLY MET — only \(Int(remainingCalories)) kcal to goal, \(Int(roomCalories)) kcal to upper limit (\(Int(input.totalCalories))/\(Int(input.goalCalories))) — keep suggestions low-calorie")
        } else {
            macroLines.append("- Calories: \(Int(remainingCalories)) kcal remaining (\(Int(input.totalCalories)) eaten of \(Int(input.goalCalories)) kcal goal)")
        }

        if proteinMet {
            let over = Int(input.totalProtein - input.goalProtein)
            macroLines.append("- Protein: ALREADY MET (\(Int(input.totalProtein))g / \(Int(input.goalProtein))g, over by \(over)g) — OFF LIMITS, do NOT suggest high-protein foods")
        } else if proteinNearlyMet {
            macroLines.append("- Protein: NEARLY MET — only \(Int(remainingProtein))g remaining (\(Int(input.totalProtein))g eaten of \(Int(input.goalProtein))g goal) — MINIMIZE, choose foods naturally low in protein")
        } else {
            macroLines.append("- Protein: \(Int(remainingProtein))g remaining (\(Int(input.totalProtein))g eaten of \(Int(input.goalProtein))g goal)")
        }

        if carbsMet {
            if roomCarbs > 0 {
                macroLines.append("- Carbs: OVER GOAL but \(Int(roomCarbs))g room before upper limit (\(Int(input.totalCarbs))g/\(Int(input.goalCarbs))g, limit \(Int(upperCarbs))g) — keep carbs under \(Int(roomCarbs))g")
            } else {
                macroLines.append("- Carbs: OVER UPPER LIMIT (\(Int(input.totalCarbs))g/\(Int(input.goalCarbs))g, limit \(Int(upperCarbs))g) — HARD STOP on carbs, zero-carb foods only")
            }
        } else if carbsNearlyMet {
            macroLines.append("- Carbs: NEARLY MET — only \(Int(remainingCarbs))g remaining (\(Int(input.totalCarbs))g eaten of \(Int(input.goalCarbs))g goal) — MINIMIZE, keep suggestions low-carb")
        } else {
            macroLines.append("- Carbs: \(Int(remainingCarbs))g remaining (\(Int(input.totalCarbs))g eaten of \(Int(input.goalCarbs))g goal)")
        }

        if fatMet {
            if roomFat > 0 {
                macroLines.append("- Fat: OVER GOAL but \(Int(roomFat))g room before upper limit (\(Int(input.totalFat))g/\(Int(input.goalFat))g, limit \(Int(upperFat))g) — keep fat under \(Int(roomFat))g")
            } else {
                macroLines.append("- Fat: OVER UPPER LIMIT (\(Int(input.totalFat))g/\(Int(input.goalFat))g, limit \(Int(upperFat))g) — HARD STOP on fat, zero-fat foods only")
            }
        } else if fatNearlyMet {
            macroLines.append("- Fat: NEARLY MET — only \(Int(remainingFat))g remaining (\(Int(input.totalFat))g eaten of \(Int(input.goalFat))g goal) — MINIMIZE, avoid fatty foods")
        } else {
            macroLines.append("- Fat: \(Int(remainingFat))g remaining (\(Int(input.totalFat))g eaten of \(Int(input.goalFat))g goal)")
        }

        // Build the list of deficits to target, sorted by percentage remaining (largest gap first)
        struct MacroGap {
            let label: String
            let remainingFraction: Double // fraction of goal still needed (1.0 = none eaten, 0.0 = fully met)
        }
        var gaps: [MacroGap] = []
        if !caloriesMet && !caloriesNearlyMet {
            gaps.append(MacroGap(label: "\(Int(remainingCalories)) kcal", remainingFraction: input.goalCalories > 0 ? remainingCalories / input.goalCalories : 0))
        }
        if !proteinMet && !proteinNearlyMet {
            gaps.append(MacroGap(label: "\(Int(remainingProtein))g protein", remainingFraction: input.goalProtein > 0 ? remainingProtein / input.goalProtein : 0))
        }
        if !carbsMet && !carbsNearlyMet {
            gaps.append(MacroGap(label: "\(Int(remainingCarbs))g carbs", remainingFraction: input.goalCarbs > 0 ? remainingCarbs / input.goalCarbs : 0))
        }
        if !fatMet && !fatNearlyMet {
            gaps.append(MacroGap(label: "\(Int(remainingFat))g fat", remainingFraction: input.goalFat > 0 ? remainingFat / input.goalFat : 0))
        }
        gaps.sort { $0.remainingFraction > $1.remainingFraction }
        let deficits = gaps.map { $0.label }

        // Build the list of macros to avoid (met/over) and minimize (nearly met)
        var offLimits: [String] = []
        if caloriesMet { offLimits.append("calories") }
        if proteinMet  { offLimits.append("protein") }
        if carbsMet    { offLimits.append("carbs") }
        if fatMet      { offLimits.append("fat") }

        var minimizeMacros: [String] = []
        if caloriesNearlyMet { minimizeMacros.append("calories") }
        if proteinNearlyMet  { minimizeMacros.append("protein") }
        if carbsNearlyMet    { minimizeMacros.append("carbs") }
        if fatNearlyMet      { minimizeMacros.append("fat") }

        let deficitSummary = deficits.isEmpty
            ? "All macros are met or nearly met — suggest only a very light option if anything."
            : "The user still needs: \(deficits.joined(separator: ", ")). Focus primarily on the FIRST macro listed — it has the largest gap."

        let avoidSummary = offLimits.isEmpty
            ? ""
            : " Macros that are OVER GOAL (already met or over): \(offLimits.joined(separator: ", ")). Stay within the upper limit room shown above."

        let minimizeSummary = minimizeMacros.isEmpty
            ? ""
            : " Macros that are NEARLY MET: \(minimizeMacros.joined(separator: ", ")). Keep these as low as possible in your suggestions — do not build meals around these macros."

        // Dynamically choose suggestion format based on calorie budget.
        // When the user is near or over their calorie goal, full meals don't make
        // sense — suggest small, targeted snacks or single-ingredient options instead.
        let formatInstruction: String
        if roomCalories <= 0 {
            formatInstruction = """
            The user is at or over their calorie upper limit. Do NOT suggest eating more. \
            Instead, give 2 brief tips: one about how they did today, and one about what \
            to prioritize tomorrow to close the gap (e.g. front-load protein earlier).
            """
        } else if roomCalories < 200 {
            formatInstruction = """
            The user has very little calorie room left (\(Int(roomCalories)) kcal to upper limit). \
            Do NOT suggest meals. Suggest exactly 2 small, single-ingredient snacks that \
            target the remaining deficit with minimal calories. Think: a can of tuna, a \
            protein shake, plain chicken breast, egg whites, deli turkey slices, beef jerky, \
            or similar lean/simple options. Each suggestion must stay under \(Int(roomCalories)) kcal.
            1. Best option
            2. Quick alternative
            """
        } else if roomCalories < 400 {
            formatInstruction = """
            The user has limited calorie room (\(Int(roomCalories)) kcal to upper limit). \
            Suggest exactly 2 light snacks (not full meals) that target the remaining deficit. \
            Each suggestion must stay under \(Int(roomCalories)) kcal.
            1. A light snack
            2. A quick alternative
            """
        } else {
            formatInstruction = """
            Suggest exactly 2 specific meals or snacks that primarily address the remaining deficits:
            1. A full meal option
            2. A quick snack option
            """
        }

        // Build "do not repeat" rule from recent brainstorm history
        let recent = recentIngredients
        let varietyRule: String
        if recent.isEmpty {
            varietyRule = ""
        } else {
            varietyRule = """
            - VARIETY: The user was recently suggested these foods: \(recent.joined(separator: ", ")). \
              Do NOT repeat any of these — pick completely different primary ingredients this time.
            """
        }

        // Shuffle example foods so the model doesn't always gravitate to
        // whichever items appear first in the list.
        var exampleFoods = [
            "chicken", "beef", "fish", "eggs", "Greek yogurt",
            "cottage cheese", "tofu", "turkey", "tuna", "lentils",
            "oats", "rice", "fruit", "nuts", "seeds", "pasta",
            "bread", "potatoes", "sweet potatoes", "granola",
            "cereal", "juice", "dried fruit", "protein shake",
            "shrimp", "salmon", "pork tenderloin", "edamame",
            "beef jerky", "deli turkey slices", "egg whites",
            "protein bar", "chickpeas", "tempeh", "sardines",
            "skyr", "bone broth", "collagen peptides"
        ]
        exampleFoods.shuffle()

        let prompt = """
        You are a no-nonsense nutrition coach who's been in the gym long enough to know what actually works. \
        You give precise, accurate advice in a direct, confident tone — like someone who's dialed in and wants \
        to help others get there too. A word of gym culture here and there is fine when it flows naturally, \
        but the quality of the advice always comes first.

        A user is mid-day and wants to know what to eat NEXT. Your job is to suggest foods that fill \
        their remaining macro gaps while respecting the calorie and macro room they have left. \
        Each macro has a goal and an upper limit (goal + 15%). Suggestions must stay within the upper limit.

        **Macro status (exact amounts with upper-limit room):**
        \(macroLines.joined(separator: "\n"))

        **Summary:** \(deficitSummary)\(avoidSummary)\(minimizeSummary)
        \(dietaryRestrictionsPrompt)
        \(formatInstruction)

        Rules:
        - CRITICAL: Every suggestion must fit within the calorie room to the upper limit (\(Int(roomCalories)) kcal max). \
          Do NOT suggest anything that would push the user over their upper limit.
        - CRITICAL: For any macro marked OVER GOAL, stay within the remaining room to the upper limit shown above. \
          Choose foods that are naturally low in those macros.
        - IMPORTANT: Any macro marked NEARLY MET should be kept as low as possible. Do NOT build meals \
          around nearly-met macros. For example, if protein is nearly met, do NOT suggest chicken breast \
          or other high-protein foods — instead choose carb-dominant or fat-dominant foods as needed.
        - Focus your suggestions on the macro with the LARGEST remaining gap. The deficits are listed \
          in priority order (biggest gap first).
        - Each option must use a DIFFERENT primary ingredient — no repeating main ingredients across options
        \(varietyRule)\
        - Draw from the full range of real foods: \(exampleFoods.joined(separator: ", ")), etc.
        - Be very specific with amounts in grams (e.g. "142g can of tuna, drained") \
          and include estimated macros for each suggestion (calories, protein, carbs, fat)
        - Format: bold the food name, then one short sentence on why it fits the macro gap, \
          then the estimated macros in parentheses
        - No intro line, no outro — just the 2 numbered options
        """

        let initialText = try await callBrainstormModel(prompt: prompt)

        // Validate that each suggestion fits within the upper-limit room.
        // If the model returned a suggestion that would push the user over a
        // macro upper limit, retry ONCE with the violation called out explicitly.
        let limits = MacroLimits(
            roomCalories: roomCalories, roomProtein: roomProtein,
            roomCarbs: roomCarbs, roomFat: roomFat
        )
        var finalText = initialText
        let initialViolations = validateBrainstormText(initialText, against: limits)
        if !initialViolations.isEmpty {
            let retryPrompt = prompt + "\n\n" + """
            RETRY — your previous suggestions violated the upper-limit constraints:
            \(initialViolations.map { "- Suggestion \($0.suggestionIndex): \($0.macroName) = \(Int($0.actual))\($0.unit), exceeds remaining room of \(Int($0.allowed))\($0.unit)" }.joined(separator: "\n"))
            Rewrite BOTH suggestions so every macro in every suggestion stays within the remaining room. \
            Use smaller portions or lower-\(initialViolations.first?.macroName ?? "macro") foods.
            """
            // Use Sonnet for the retry — stronger constraint-following on the
            // ~20% of calls Haiku gets wrong. See cost analysis: Haiku+Sonnet
            // fallback ≈ $0.33/user/mo vs Sonnet-everywhere ≈ $0.61/user/mo.
            let retryText = try await callBrainstormModel(prompt: retryPrompt, model: fallbackModel)
            let retryViolations = validateBrainstormText(retryText, against: limits)
            // Only adopt the retry if it's no worse than the first attempt.
            if retryViolations.count < initialViolations.count {
                finalText = retryText
            }
        }

        // Remember the suggested ingredients so the next brainstorm avoids repeats.
        let suggested = extractIngredients(from: finalText)
        if !suggested.isEmpty {
            saveRecentIngredients(suggested)
        }

        return finalText
    }

    private func callBrainstormModel(prompt: String, model: String? = nil) async throws -> String {
        let payload: [String: Any] = [
            "model": model ?? self.model,
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

    // MARK: - Brainstorm validation

    private struct MacroLimits {
        let roomCalories: Double
        let roomProtein:  Double
        let roomCarbs:    Double
        let roomFat:      Double
    }

    fileprivate struct BrainstormViolation {
        let suggestionIndex: Int
        let macroName: String  // "calories", "protein", "carbs", "fat"
        let actual:   Double
        let allowed:  Double
        let unit:     String   // " kcal" or "g"
    }

    fileprivate struct SuggestionMacros {
        var calories: Double?
        var protein:  Double?
        var carbs:    Double?
        var fat:      Double?
    }

    /// Splits the brainstorm response into numbered suggestions and parses the
    /// estimated macros from each one. Returns any macros that exceed the
    /// remaining room to the upper limit.
    private func validateBrainstormText(_ text: String, against limits: MacroLimits) -> [BrainstormViolation] {
        let suggestions = splitNumberedSuggestions(text)
        // Tolerance: allow up to 5% slop on top of the computed room to avoid
        // false positives from rounding in the model's macro estimates.
        let tolerance = 1.05
        var violations: [BrainstormViolation] = []
        for (idx, suggestionText) in suggestions.enumerated() {
            let macros = parseSuggestionMacros(from: suggestionText)
            let i = idx + 1
            if let c = macros.calories, c > limits.roomCalories * tolerance {
                violations.append(.init(suggestionIndex: i, macroName: "calories", actual: c, allowed: limits.roomCalories, unit: " kcal"))
            }
            if let p = macros.protein, p > limits.roomProtein * tolerance {
                violations.append(.init(suggestionIndex: i, macroName: "protein", actual: p, allowed: limits.roomProtein, unit: "g"))
            }
            if let cb = macros.carbs, cb > limits.roomCarbs * tolerance {
                violations.append(.init(suggestionIndex: i, macroName: "carbs", actual: cb, allowed: limits.roomCarbs, unit: "g"))
            }
            if let f = macros.fat, f > limits.roomFat * tolerance {
                violations.append(.init(suggestionIndex: i, macroName: "fat", actual: f, allowed: limits.roomFat, unit: "g"))
            }
        }
        return violations
    }

    /// Splits text on leading "1." / "2." / "3." markers (possibly after a
    /// newline) and returns the body of each numbered suggestion.
    private func splitNumberedSuggestions(_ text: String) -> [String] {
        let pattern = #"(?m)^\s*\d+\.\s"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return [] }
        var chunks: [String] = []
        for (i, match) in matches.enumerated() {
            let start = match.range.location + match.range.length
            let end = i + 1 < matches.count ? matches[i + 1].range.location : ns.length
            chunks.append(ns.substring(with: NSRange(location: start, length: end - start)))
        }
        return chunks
    }

    /// Extracts calories / protein / carbs / fat values from a suggestion's
    /// body. Matches formats like "605 kcal", "42g protein", "55 g carbs".
    private func parseSuggestionMacros(from text: String) -> SuggestionMacros {
        var out = SuggestionMacros()
        out.calories = firstNumericMatch(in: text, pattern: #"(\d+(?:\.\d+)?)\s*(?:kcal|cal\b|calories)"#)
        out.protein  = firstNumericMatch(in: text, pattern: #"(\d+(?:\.\d+)?)\s*g\s*protein"#)
        out.carbs    = firstNumericMatch(in: text, pattern: #"(\d+(?:\.\d+)?)\s*g\s*carb"#)
        out.fat      = firstNumericMatch(in: text, pattern: #"(\d+(?:\.\d+)?)\s*g\s*fat"#)
        return out
    }

    private func firstNumericMatch(in text: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
              match.numberOfRanges >= 2 else { return nil }
        return Double(ns.substring(with: match.range(at: 1)))
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
