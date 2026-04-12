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

    /// Writes today's fasting window snapshot into the macroHistory
    /// document without touching the macro fields. Call this every
    /// time macros are reloaded so the snapshot stays current.
    ///
    /// Historical note: this used to read meal timestamps out of the
    /// `fuelLog` Firestore collection to classify meals as inside vs.
    /// outside the eating window. That collection is no longer
    /// written to (FoodEntryService took over, writing to
    /// `foodEntries`), so the classification counts were always 0/0
    /// and none of the resulting fields are consumed by any view.
    /// The meal-count fields are still encoded into the snapshot
    /// (always zero) so old documents keep decoding cleanly — if
    /// we want real in-window/out-of-window stats later, source
    /// them from `foodEntries` here.
    func logTodaysWindow(
        userID:         String,
        startHour:      Int,
        startMinute:    Int,
        durationHours:  Int,
        fastingEnabled: Bool
    ) async {
        guard !userID.isEmpty else { return }

        let today      = Date()
        let cal        = Calendar.current
        let startOfDay = cal.startOfDay(for: today)

        // Compute exact eating window start/end as Dates
        let windowStartTime = startOfDay
            .addingTimeInterval(Double(startHour) * 3600 + Double(startMinute) * 60)
        let windowEndTime   = windowStartTime
            .addingTimeInterval(Double(durationHours) * 3600)

        let snapshot = FastingSnapshot(
            fastingEnabled:      fastingEnabled,
            windowStartTime:     Timestamp(date: windowStartTime),
            windowEndTime:       Timestamp(date: windowEndTime),
            windowDurationHours: Double(durationHours),
            fastingHours:        24.0 - Double(durationHours),
            firstMealTime:       nil,
            lastMealTime:        nil,
            mealsWithinWindow:   0,
            mealsOutsideWindow:  0,
            isCompleted:         false,
            isLocked:            false
        )

        do {
            let encoded = try Firestore.Encoder().encode(snapshot)
            try await todayDocRef(userID: userID).setData(["fasting": encoded], merge: true)
        } catch {
            AppLogger.log("[FastingWindowService] logTodaysWindow failed: \(error.localizedDescription)")
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
            AppLogger.log("[FastingWindowService] Locked \(snapshot.documents.count) past window(s)")
        } catch {
            AppLogger.log("[FastingWindowService] lockPastWindows failed: \(error.localizedDescription)")
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
            AppLogger.log("[FastingWindowService] Marked today's window as completed")
        } catch {
            AppLogger.log("[FastingWindowService] markWindowCompleted failed: \(error.localizedDescription)")
        }
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
