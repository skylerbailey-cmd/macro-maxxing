//
//  StreakService.swift
//  Wellness
//
//  Streak = consecutive calendar days (ending yesterday) on which all four macro
//  goals were within the 85–115% acceptable range.
//
//  Rules:
//   • The check runs once per day on app launch, against YESTERDAY's macroHistory doc.
//   • If lastStreakCheckDate already equals today → skip entirely (already ran).
//   • If yesterday's macroHistory document doesn't exist → missed day, streak resets to 0.
//   • If it exists, all four macros must be within 85–115% of their stored goal.
//     Any single failure resets the streak to 0.
//   • longestStreak is updated if the new streak exceeds the all-time record.
//   • All three fields (streakDays, longestStreak, lastStreakCheckDate) are written
//     to Firestore atomically in a single batch commit.
//
//  Retroactive repair:
//   • recalculateStreakFromHistory runs once on app launch when streakDays == 0
//     AND lastStreakCheckDate is empty (i.e. the new streak system has never run).
//   • It fetches the full macroHistory, walks backwards from yesterday, and counts
//     consecutive successful days so any existing streak is correctly recovered.
//   • After the repair, lastStreakCheckDate is set to today and the normal
//     daily checkAndUpdateStreak takes over going forward.
//

import Foundation
import FirebaseFirestore

enum StreakService {

    private static var db: Firestore { Firestore.firestore() }

    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        return f
    }()

    // MARK: - 1. Check and update streak

    /// Runs the daily streak check against yesterday's macroHistory document.
    ///
    /// - Returns: `(streak, longest)` with the updated values, or `nil` if the
    ///   check was skipped because it already ran today.
    ///
    /// The caller is responsible for updating local state (UserSettings, HomeViewModel)
    /// with the returned values and calling `checkStreakMilestones` as needed.
    @discardableResult
    static func checkAndUpdateStreak(
        userID:         String,
        currentStreak:  Int,
        currentLongest: Int,
        lastCheckDate:  String
    ) async -> (streak: Int, longest: Int)? {
        guard !userID.isEmpty else { return nil }

        let today = fmt.string(from: Date())

        // Skip if the check already ran today.
        guard lastCheckDate != today else {
            print("[StreakService] Skipping — check already ran today (\(today))")
            return nil
        }

        // Fetch yesterday's macroHistory document.
        let yesterday    = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayKey = fmt.string(from: yesterday)

        let historyRef = db
            .collection("users").document(userID)
            .collection("macroHistory").document(yesterdayKey)

        let newStreak: Int
        do {
            let doc = try await historyRef.getDocument()
            if doc.exists, let macros = DailyMacros(document: doc) {
                newStreak = macros.allGoalsMet ? currentStreak + 1 : 0
                print("[StreakService] \(yesterdayKey) allGoalsMet=\(macros.allGoalsMet) → streak \(currentStreak)→\(newStreak)")
            } else {
                // No document for yesterday = missed day.
                newStreak = 0
                print("[StreakService] No macroHistory doc for \(yesterdayKey) → streak reset to 0")
            }
        } catch {
            // Network / permission failure — skip update so we don't reset a valid streak.
            print("[StreakService] Fetch error for \(yesterdayKey): \(error.localizedDescription) — skipping update")
            return nil
        }

        let newLongest = max(currentLongest, newStreak)

        // Atomic batch write: streakDays, longestStreak, lastStreakCheckDate.
        let userRef = db.collection("users").document(userID)
        let batch   = db.batch()
        batch.setData([
            "streakDays":          newStreak,
            "longestStreak":       newLongest,
            "lastStreakCheckDate": today
        ], forDocument: userRef, merge: true)

        do {
            try await batch.commit()
            print("[StreakService] Wrote streakDays=\(newStreak) longestStreak=\(newLongest) lastCheck=\(today)")
        } catch {
            print("[StreakService] Batch write failed: \(error.localizedDescription)")
            // Still return the computed values so local state stays correct even if Firestore failed.
        }

        return (streak: newStreak, longest: newLongest)
    }

    // MARK: - 2. Retroactive repair

    /// Fetches the full macroHistory, walks backwards from yesterday, and counts
    /// consecutive days where all four macros were within 85–115% of their stored goals.
    ///
    /// Call this once on app launch when `streakDays == 0 && lastStreakCheckDate.isEmpty`
    /// to repair any streak that existed before the new daily-check system was in place.
    ///
    /// After this returns, the caller should set `lastStreakCheckDate = today` so the
    /// normal `checkAndUpdateStreak` takes over from the following day onwards.
    ///
    /// - Returns: `(streak, longest)` — the repaired streak and updated all-time best.
    static func recalculateStreakFromHistory(
        userID:         String,
        currentLongest: Int
    ) async -> (streak: Int, longest: Int) {
        guard !userID.isEmpty else { return (0, currentLongest) }

        // Fetch full history ordered newest first.
        let history = (try? await MacroHistoryService.shared.fetchMacroHistory(userID: userID)) ?? []
        guard !history.isEmpty else {
            print("[StreakService] recalculateStreakFromHistory: no history found")
            return (0, currentLongest)
        }

        // Build a date-string keyed lookup for O(1) access.
        var docsByDate: [String: DailyMacros] = [:]
        for doc in history {
            if let key = doc.dateString { docsByDate[key] = doc }
        }

        // Walk backwards from yesterday until a gap or failed day is found.
        var streak = 0
        var offset = 1
        let today  = Date()
        let cal    = Calendar.current

        while true {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { break }
            let key = fmt.string(from: day)
            guard let macros = docsByDate[key], macros.allGoalsMet else {
                print("[StreakService] recalculateStreakFromHistory: streak broken at \(key) (doc missing or goals not met)")
                break
            }
            streak += 1
            offset += 1
        }

        let longest    = max(currentLongest, streak)
        let todayStr   = fmt.string(from: today)

        // Atomic batch write so Firestore and local state stay in sync.
        let userRef = db.collection("users").document(userID)
        let batch   = db.batch()
        batch.setData([
            "streakDays":          streak,
            "longestStreak":       longest,
            "lastStreakCheckDate": todayStr
        ], forDocument: userRef, merge: true)

        do {
            try await batch.commit()
            print("[StreakService] recalculateStreakFromHistory: repaired streak=\(streak) longest=\(longest)")
        } catch {
            print("[StreakService] recalculateStreakFromHistory batch write failed: \(error.localizedDescription)")
        }

        return (streak: streak, longest: longest)
    }

    // MARK: - 3. Fetch current streak

    /// Reads and returns `streakDays` from the user's Firestore document.
    static func fetchCurrentStreak(userID: String) async -> Int {
        guard !userID.isEmpty else { return 0 }
        let doc = try? await db.collection("users").document(userID).getDocument()
        return doc?.data()?["streakDays"] as? Int ?? 0
    }

    // MARK: - 3. Fetch longest streak

    /// Reads and returns `longestStreak` from the user's Firestore document.
    static func fetchLongestStreak(userID: String) async -> Int {
        guard !userID.isEmpty else { return 0 }
        let doc = try? await db.collection("users").document(userID).getDocument()
        return doc?.data()?["longestStreak"] as? Int ?? 0
    }
}
