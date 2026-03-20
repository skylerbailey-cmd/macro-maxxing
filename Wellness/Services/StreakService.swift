//
//  StreakService.swift
//  Wellness
//
//  Delegates streak computation to the `computeStreak` Firebase Cloud Function.
//  The function walks `users/{uid}/foodEntries` server-side, applies shielded
//  dates, and writes `streakDays` back to the user document before returning.
//

import Foundation
import FirebaseFunctions

enum StreakService {

    /// Calls the `computeStreak` Cloud Function and returns the streak count.
    /// The function also writes `streakDays` to Firestore, so no additional
    /// Firestore write is needed on the iOS side.
    static func computeHistoricalStreak(
        userID:        String,
        goalCalories:  Double,
        goalProtein:   Double,
        goalCarbs:     Double,
        goalFat:       Double,
        shieldedDates: Set<String> = []
    ) async -> Int {
        guard !userID.isEmpty else { return 0 }
        guard goalCalories > 0, goalProtein > 0, goalCarbs > 0, goalFat > 0 else {
            print("[StreakService] Goals not set — skipping streak calculation")
            return 0
        }

        let timeZone = TimeZone.current.identifier // e.g. "America/New_York"

        let payload: [String: Any] = [
            "goalCalories":  goalCalories,
            "goalProtein":   goalProtein,
            "goalCarbs":     goalCarbs,
            "goalFat":       goalFat,
            "shieldedDates": Array(shieldedDates),
            "timeZone":      timeZone,
        ]

        do {
            let functions = Functions.functions()
            let result    = try await functions.httpsCallable("computeStreak").call(payload)
            guard let data  = result.data as? [String: Any],
                  let count = data["streakDays"] as? Int else {
                print("[StreakService] Unexpected response format")
                return 0
            }
            print("[StreakService] computeHistoricalStreak = \(count) (server)")
            return count
        } catch {
            print("[StreakService] Cloud Function error: \(error.localizedDescription)")
            return 0
        }
    }
}
