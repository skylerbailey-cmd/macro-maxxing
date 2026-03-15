//
//  FastingWindowService.swift
//  Wellness
//
//  Manages fasting window snapshots stored inside macroHistory documents.
//  Path: users/{userID}/macroHistory/{dateString}  →  field: "fasting" (nested map)
//

import Foundation
import FirebaseFirestore

final class FastingWindowService {

    // MARK: - Singleton

    static let shared = FastingWindowService()
    private init() {}

    // MARK: - Private refs

    private var db: Firestore { FirebaseManager.shared.db }

    private func historyCollection(userID: String) -> CollectionReference {
        db.collection("users").document(userID).collection("macroHistory")
    }

    private func todayDocRef(userID: String) -> DocumentReference {
        historyCollection(userID: userID).document(MacroHistoryService.dateString(for: Date()))
    }

    // MARK: - 1. Log Today's Window

    /// Builds a FastingSnapshot from the current window preferences and logged meal times,
    /// then merges it into today's macroHistory document (creating the document if needed).
    ///
    /// Call this every time macros are reloaded so the fasting snapshot stays current.
    ///
    /// - Parameters:
    ///   - startHour:       Eating window open hour (0–23)
    ///   - startMinute:     Eating window open minute (0–59)
    ///   - durationHours:   Eating window length in whole hours
    ///   - fastingEnabled:  Whether fasting tracking is on
    ///   - mealLogTimes:    Fractional hours of each logged meal (e.g. 12.5 = 12:30 PM)
    func logTodaysWindow(
        userID:         String,
        startHour:      Int,
        startMinute:    Int,
        durationHours:  Int,
        fastingEnabled: Bool,
        mealLogTimes:   [Double]
    ) async {
        guard !userID.isEmpty else { return }

        let today       = Date()
        let cal         = Calendar.current
        let startOfDay  = cal.startOfDay(for: today)

        // Compute exact start and end timestamps for the eating window
        let windowStartTime = startOfDay
            .addingTimeInterval(Double(startHour) * 3600 + Double(startMinute) * 60)
        let windowEndTime   = windowStartTime
            .addingTimeInterval(Double(durationHours) * 3600)

        let startFrac = Double(startHour) + Double(startMinute) / 60.0
        let endFrac   = startFrac + Double(durationHours)

        // Classify meals as within or outside the eating window
        var within = 0, outside = 0
        for t in mealLogTimes {
            if isWithinWindow(mealFrac: t, startFrac: startFrac, endFrac: endFrac) {
                within  += 1
            } else {
                outside += 1
            }
        }

        // Reconstruct first/last meal timestamps from fractional hours
        let firstMealTime: Timestamp? = mealLogTimes.min().map {
            Timestamp(date: fractionalHourToDate($0, on: today))
        }
        let lastMealTime: Timestamp? = mealLogTimes.max().map {
            Timestamp(date: fractionalHourToDate($0, on: today))
        }

        let snapshot = FastingSnapshot(
            fastingEnabled:      fastingEnabled,
            windowStartTime:     Timestamp(date: windowStartTime),
            windowEndTime:       Timestamp(date: windowEndTime),
            windowDurationHours: Double(durationHours),
            fastingHours:        24.0 - Double(durationHours),
            firstMealTime:       firstMealTime,
            lastMealTime:        lastMealTime,
            mealsWithinWindow:   within,
            mealsOutsideWindow:  outside,
            isCompleted:         fastingEnabled && !mealLogTimes.isEmpty && outside == 0,
            isLocked:            false
        )

        do {
            let encoded = try Firestore.Encoder().encode(snapshot)
            // Merge so we don't overwrite the macro fields in the same document
            try await todayDocRef(userID: userID).setData(
                ["fasting": encoded],
                merge: true
            )
        } catch {
            print("[FastingWindowService] logTodaysWindow failed: \(error.localizedDescription)")
        }
    }

    // MARK: - 2. Fetch Window History

    /// Returns all macroHistory documents ordered by date descending.
    /// Each document includes the `fasting` field if it was ever written.
    func fetchWindowHistory(userID: String) async throws -> [DailyMacros] {
        guard !userID.isEmpty else { return [] }
        let snapshot = try await historyCollection(userID: userID)
            .order(by: "date", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { DailyMacros(document: $0) }
    }

    // MARK: - 3. Lock Past Windows

    /// Sets `fasting.isLocked = true` on every macroHistory document before today.
    /// Uses Firestore dot-notation so only isLocked is changed — other fasting fields are untouched.
    /// Call this on app launch to prevent past windows from being edited.
    func lockPastWindows(userID: String) async {
        guard !userID.isEmpty else { return }

        let todayStart = Timestamp(date: Calendar.current.startOfDay(for: Date()))

        do {
            let snapshot = try await historyCollection(userID: userID)
                .whereField("date", isLessThan: todayStart)
                .getDocuments()

            guard !snapshot.documents.isEmpty else { return }

            // Batch up to 500 writes at a time (Firestore limit)
            let chunks = snapshot.documents.chunked(into: 400)
            for chunk in chunks {
                let batch = db.batch()
                for doc in chunk {
                    batch.updateData(["fasting.isLocked": true], forDocument: doc.reference)
                }
                try await batch.commit()
            }
            print("[FastingWindowService] Locked \(snapshot.documents.count) past window(s)")
        } catch {
            print("[FastingWindowService] lockPastWindows failed: \(error.localizedDescription)")
        }
    }

    // MARK: - 4. Mark Window Completed

    /// Manually marks today's fasting window as completed.
    /// Use this when the user explicitly confirms they stayed within their window.
    func markWindowCompleted(userID: String) async {
        guard !userID.isEmpty else { return }
        do {
            try await todayDocRef(userID: userID)
                .updateData(["fasting.isCompleted": true])
            print("[FastingWindowService] Marked today's window as completed")
        } catch {
            print("[FastingWindowService] markWindowCompleted failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    /// Returns true if `mealFrac` falls inside the eating window.
    /// Handles windows that cross midnight (e.g., 8 PM – 4 AM).
    private func isWithinWindow(mealFrac: Double, startFrac: Double, endFrac: Double) -> Bool {
        if endFrac <= 24 {
            return mealFrac >= startFrac && mealFrac < endFrac
        } else {
            // Window crosses midnight
            return mealFrac >= startFrac || mealFrac < (endFrac - 24)
        }
    }

    /// Converts a fractional hour (e.g. 13.5 = 1:30 PM) back to a Date on the given day.
    private func fractionalHourToDate(_ fractionalHour: Double, on date: Date) -> Date {
        let hour   = Int(fractionalHour)
        let minute = Int((fractionalHour - Double(hour)) * 60)
        var comps  = Calendar.current.dateComponents([.year, .month, .day], from: date)
        comps.hour   = hour
        comps.minute = minute
        comps.second = 0
        return Calendar.current.date(from: comps) ?? date
    }
}

// MARK: - Array chunking helper

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
