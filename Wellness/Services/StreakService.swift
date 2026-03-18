//
//  StreakService.swift
//  Wellness
//
//  Shared streak recalculation logic used by both HomeViewModel (foreground)
//  and the BGAppRefreshTask (background). Reads/writes UserDefaults and Firestore
//  so the streak stays accurate even when the app is never opened.
//

import Foundation
import FirebaseFirestore
import UserNotifications

enum StreakService {

    // MARK: - UserDefaults keys (must match UserSettings)

    private static let goalsMetKey  = "goalsMetDates"   // comma-sep "yyyy-MM-dd"
    private static let streakKey    = "macroStreak"

    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: - Core calculation

    /// Recalculates the streak purely from the device-local `goalsMetDates` set.
    /// Does NOT read or write Firestore.
    static func recalculate() -> Int {
        let ud  = UserDefaults.standard
        let raw = ud.string(forKey: goalsMetKey) ?? ""
        let met = Set(raw.split(separator: ",").map { String($0) })

        let cal = Calendar.current
        var streak = 0
        var offset = 1
        while offset <= 365 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: Date()) else { break }
            if met.contains(fmt.string(from: day)) { streak += 1 } else { break }
            offset += 1
        }
        // Count today if goals were already met
        if met.contains(fmt.string(from: Date())) { streak += 1 }
        return streak
    }

    // MARK: - Background entry point

    /// Called from the BGAppRefreshTask at 12:01 AM.
    /// Recalculates the streak, persists it locally, and syncs to Firestore.
    static func verifyAndResetInBackground() async {
        let newStreak = recalculate()

        // Write to UserDefaults so the next app launch reads the correct value
        UserDefaults.standard.set(newStreak, forKey: streakKey)

        // Schedule tonight's streak warning if the user still has a streak to protect.
        // This fires even when the app is never opened during the day.
        NotificationService.shared.scheduleStreakWarningIfNeeded(streak: newStreak)

        // Sync to Firestore so leaderboards and profiles reflect the reset
        guard let userID = UserDefaults.standard.string(forKey: "cachedUserID"),
              !userID.isEmpty else { return }

        let db = Firestore.firestore()
        try? await db.collection("users").document(userID).updateData([
            "streakDays": newStreak
        ])
    }
}
