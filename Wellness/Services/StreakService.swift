//
//  StreakService.swift
//  Wellness
//
//  Streak = consecutive calendar days (ending today) on which all four macro
//  goals were within the 85–115 % acceptable range.
//
//  Source of truth:
//    • Today      — passed in as `todayAllMet` (live, from HomeViewModel.macroGoalsMet)
//    • Past days  — UNION of:
//        1. Local `goalsMetDates` UserDefaults cache (set in real-time as goals are hit)
//        2. Firestore macroHistory/{date}.allGoalsMet (server-authoritative history)
//      A day counts if either source confirms it — this keeps the streak intact even
//      when Firestore history documents are missing or were written before allGoalsMet existed.
//

import Foundation
import FirebaseFirestore

enum StreakService {

    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        return f
    }()

    // MARK: - Core calculation

    /// Computes the current streak.
    ///
    /// - Parameters:
    ///   - todayAllMet: `true` if all four macro goals are currently within range today.
    ///   - userID: Firestore user ID used to fetch macro history.
    /// - Returns: Number of consecutive days (including today if `todayAllMet`) on which
    ///   all goals were met.
    static func compute(todayAllMet: Bool, userID: String) async -> Int {
        guard !userID.isEmpty else { return todayAllMet ? 1 : 0 }

        let today = Date()
        let cal   = Calendar.current

        // Fetch up to 90 days so long streaks are captured accurately.
        guard let start = cal.date(byAdding: .day, value: -90, to: today) else {
            return todayAllMet ? 1 : 0
        }

        let history = (try? await MacroHistoryService.shared.fetchMacroHistory(
            userID: userID, from: start, to: today)) ?? []

        let todayStr = fmt.string(from: today)

        // Seed metSet from the local cache — this preserves streaks earned before
        // Firestore history documents existed, and covers any Firestore gaps.
        let localRaw = UserDefaults.standard.string(forKey: "goalsMetDates") ?? ""
        var metSet = Set(localRaw.split(separator: ",").compactMap { s -> String? in
            let key = String(s)
            return key != todayStr ? key : nil   // never let local cache speak for today
        })

        // Merge Firestore history — any day Firestore confirms as met also counts.
        for day in history {
            guard let key = day.dateString, key != todayStr else { continue }
            if day.allGoalsMet { metSet.insert(key) }
        }

        // Walk backwards: today counts if todayAllMet, then check yesterday, day before, …
        var streak = todayAllMet ? 1 : 0
        var offset = 1
        while offset <= 90 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { break }
            if metSet.contains(fmt.string(from: day)) {
                streak += 1
            } else {
                break
            }
            offset += 1
        }

        return streak
    }

    // MARK: - Background entry point

    /// Called from the BGAppRefreshTask at ~12:01 AM.
    /// Recalculates the streak for the freshly started day (today not yet met)
    /// and syncs the result to Firestore.
    static func verifyAndResetInBackground() async {
        guard let userID = UserDefaults.standard.string(forKey: "cachedUserID"),
              !userID.isEmpty else { return }

        // At midnight, today has no logged meals yet — pass false for todayAllMet.
        let newStreak = await compute(todayAllMet: false, userID: userID)

        UserDefaults.standard.set(newStreak, forKey: "macroStreak")
        NotificationService.shared.scheduleStreakWarningIfNeeded(streak: newStreak)

        let db = Firestore.firestore()
        try? await db.collection("users").document(userID).updateData([
            "streakDays": newStreak
        ])
    }
}
