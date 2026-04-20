//
//  DailyRoastService.swift
//  Wellness
//
//  Generates a daily AI roast based on the user's meals and workouts.
//  Uses Claude Haiku for fast, cheap humor generation.
//

import Foundation
import FirebaseFunctions

struct DailyRoast: Codable, Equatable, Identifiable {
    var id: String { dateKey + headline }
    let roastText: String
    /// If the roast targets a specific meal, this is its index in the meals array.
    /// -1 means the roast is general (no specific meal called out).
    let targetMealIndex: Int
    /// Short punchy headline (shown large above the roast body).
    let headline: String
    /// Emoji that sets the tone.
    let emoji: String
    /// The date this roast was generated for.
    let dateKey: String
    /// True if the user explicitly saved this roast. Saved roasts are kept
    /// forever; unsaved ones are trimmed to the most recent 3.
    var isSaved: Bool = false
}

final class DailyRoastService {
    static let shared = DailyRoastService()
    private init() {}

    private let model = "claude-haiku-4-5-20251001"

    /// Generate a roast based on today's meals and workouts.
    func generateRoast(
        meals: [(name: String, calories: Int, protein: Int, carbs: Int, fat: Int, time: String, photoURL: String)],
        workouts: [(name: String, type: String, duration: Int, calories: Int, exercises: [String])],
        goalCalories: Int,
        goalProtein: Int,
        streak: Int,
        userName: String
    ) async throws -> DailyRoast {
        var mealDescriptions = ""
        for (i, meal) in meals.enumerated() {
            mealDescriptions += "\(i). \(meal.name) at \(meal.time) — \(meal.calories) cal, \(meal.protein)g P, \(meal.carbs)g C, \(meal.fat)g F"
            if !meal.photoURL.isEmpty { mealDescriptions += " [HAS PHOTO]" }
            mealDescriptions += "\n"
        }

        var workoutDescriptions = ""
        if workouts.isEmpty {
            workoutDescriptions = "No workouts logged today. Couch potato mode."
        } else {
            for w in workouts {
                workoutDescriptions += "- \(w.name) (\(w.type)) — \(w.duration) min, \(w.calories) cal burned"
                if !w.exercises.isEmpty {
                    workoutDescriptions += "\n  Exercises: \(w.exercises.joined(separator: ", "))"
                }
                workoutDescriptions += "\n"
            }
        }

        let totalCal = meals.reduce(0) { $0 + $1.calories }
        let totalPro = meals.reduce(0) { $0 + $1.protein }

        let prompt = """
        You are the user's brutally funny gym bro friend who roasts them about their \
        day — their meals, workouts, and choices. Think comedian energy: Kevin Hart, \
        Andrew Schulz, or a savage Twitter reply guy. Be SPECIFIC about their actual \
        food and workout data. Don't be generic.

        Rules:
        - Keep it SHORT. 1-3 sentences max for the roast body.
        - The headline should be 2-5 words, punchy, like a meme caption.
        - Pick ONE angle and commit to it. Don't try to roast everything.
        - If a meal sounds disgusting, weird, or sad, go after it.
        - If they ate way too much or way too little, call it out.
        - If their workout was pathetically short or they skipped it, destroy them.
        - If they ate something at a weird time (breakfast at 3pm, etc.), roast the timing.
        - If they ate the same thing twice, roast the lack of creativity.
        - If a meal has a photo (marked [HAS PHOTO]), you can reference "looking at your meal photo" for extra savagery. Set targetMealIndex to that meal's index number.
        - If no specific meal deserves a callout, set targetMealIndex to -1.
        - Use gen-z / gym bro language naturally (not forced): "bro", "ngl", "fr", "no cap", "down bad"
        - Be funny, not mean. The user should laugh, not cry.
        - Pick a fitting emoji for the vibe (skull 💀, clown 🤡, etc.)
        - Current macro streak: \(streak) days

        Today's data for \(userName.isEmpty ? "this person" : userName):

        MEALS (\(meals.count) logged, \(totalCal) total cal, goal: \(goalCalories) cal, \(totalPro)g protein, goal: \(goalProtein)g):
        \(mealDescriptions.isEmpty ? "Nothing logged. They literally didn't eat." : mealDescriptions)

        WORKOUTS:
        \(workoutDescriptions)

        Respond with ONLY a JSON object, no markdown, no explanation:
        {"headline": "...", "roastText": "...", "emoji": "💀", "targetMealIndex": -1}
        """

        let payload: [String: Any] = [
            "model": model,
            "maxTokens": 300,
            "messages": [["role": "user", "content": prompt]]
        ]

        let callResult = try await Functions.functions().httpsCallable("proxyClaude").call(payload)

        guard let responseDict = callResult.data as? [String: Any],
              let contentArr = responseDict["content"] as? [[String: Any]],
              let text = contentArr.first(where: { $0["type"] as? String == "text" })?["text"] as? String
        else {
            throw ClaudeServiceError.noContent
        }

        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let headline = json["headline"] as? String,
              let roastText = json["roastText"] as? String
        else {
            throw ClaudeServiceError.malformedJSON(String(text.prefix(200)))
        }

        let emoji = json["emoji"] as? String ?? "💀"
        let targetMealIndex = json["targetMealIndex"] as? Int ?? -1
        let dateKey = Self.todayKey()

        return DailyRoast(
            roastText: roastText,
            targetMealIndex: targetMealIndex,
            headline: headline,
            emoji: emoji,
            dateKey: dateKey
        )
    }

    static func todayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: Date())
    }
}
