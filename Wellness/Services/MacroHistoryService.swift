//
//  MacroHistoryService.swift
//  Wellness
//
//  Handles reading and writing daily macro snapshots to Firestore.
//  Subcollection path: users/{userID}/macroHistory/{dateString}
//

import Foundation
import FirebaseFirestore

final class MacroHistoryService {

    // MARK: - Singleton

    static let shared = MacroHistoryService()
    private init() {}

    // MARK: - Private refs

    private var db: Firestore { FirebaseManager.shared.db }

    // MARK: - Errors

    enum MacroHistoryError: LocalizedError {
        case noDataForDate

        var errorDescription: String? {
            switch self {
            case .noDataForDate: return "No macro history found for the requested date."
            }
        }
    }

    // MARK: - Helpers

    private func historyCollection(userID: String) -> CollectionReference {
        db.collection("users").document(userID).collection("macroHistory")
    }

    static func dateString(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.calendar   = Calendar.current
        return fmt.string(from: date)
    }

    // MARK: - 1. Save Daily Macros

    /// Saves (or overwrites) the macro snapshot for `date` at
    /// `users/{userID}/macroHistory/{dateString}`.
    /// Safe to call repeatedly — uses `setData` so it always reflects the latest totals.
    func saveDailyMacros(
        userID:       String,
        date:         Date,
        totalCalories: Int,
        totalProtein:  Double,
        totalCarbs:    Double,
        totalFat:      Double,
        goalCalories:  Int,
        goalProtein:   Double,
        goalCarbs:     Double,
        goalFat:       Double,
        mealCount:     Int,
        streakDay:     Int
    ) async throws {
        guard !userID.isEmpty else { return }

        let key     = Self.dateString(for: date)
        let snapshot = DailyMacros(
            dateString:    key,
            date:          date,
            totalCalories: totalCalories,
            totalProtein:  totalProtein,
            totalCarbs:    totalCarbs,
            totalFat:      totalFat,
            goalCalories:  goalCalories,
            goalProtein:   goalProtein,
            goalCarbs:     goalCarbs,
            goalFat:       goalFat,
            mealCount:     mealCount,
            streakDay:     streakDay
        )

        let data = try snapshot.firestoreData()
        try await historyCollection(userID: userID).document(key).setData(data)
        AppLogger.log("[MacroHistoryService] Saved macro snapshot for \(key)")
    }

    // MARK: - 2. Update Today's Macros

    /// Called automatically whenever a meal is logged or totals change.
    /// Recalculates completion and saves today's snapshot.
    /// Now properly async — callers must await to ensure writes are serialized.
    func updateTodaysMacros(
        userID:        String,
        totalCalories: Double,
        totalProtein:  Double,
        totalCarbs:    Double,
        totalFat:      Double,
        goalCalories:  Double,
        goalProtein:   Double,
        goalCarbs:     Double,
        goalFat:       Double,
        mealCount:     Int,
        streakDay:     Int
    ) async {
        AppLogger.log("[MacroHistoryService] updateTodaysMacros called — userID=\(userID.prefix(8)) totalCalories=\(totalCalories) goalCalories=\(goalCalories)")
        guard !userID.isEmpty else {
            AppLogger.log("[MacroHistoryService] updateTodaysMacros skipped — userID is empty")
            return
        }
        guard totalCalories > 0 else {
            AppLogger.log("[MacroHistoryService] updateTodaysMacros skipped — totalCalories is 0")
            return
        }

        do {
            try await saveDailyMacros(
                userID:        userID,
                date:          Date(),
                totalCalories: Int(totalCalories.rounded()),
                totalProtein:  totalProtein,
                totalCarbs:    totalCarbs,
                totalFat:      totalFat,
                goalCalories:  Int(goalCalories.rounded()),
                goalProtein:   goalProtein,
                goalCarbs:     goalCarbs,
                goalFat:       goalFat,
                mealCount:     mealCount,
                streakDay:     streakDay
            )
            AppLogger.log("[MacroHistoryService] updateTodaysMacros succeeded — wrote \(Int(totalCalories)) cal to macroHistory")
        } catch {
            AppLogger.log("[MacroHistoryService] updateTodaysMacros FAILED: \(error)")
        }
    }

    // MARK: - 3. Fetch Goals for a Single Day

    /// Returns the saved macro goals for a specific past date, or nil if no snapshot exists.
    func fetchDayGoals(userID: String, date: Date) async
        -> (calories: Double, protein: Double, carbs: Double, fat: Double)? {
        guard !userID.isEmpty else { return nil }
        let key = Self.dateString(for: date)
        guard let doc   = try? await historyCollection(userID: userID).document(key).getDocument(),
              let macros = DailyMacros(document: doc) else { return nil }
        return (Double(macros.goalCalories), macros.goalProtein, macros.goalCarbs, macros.goalFat)
    }

    // MARK: - 4. Fetch All Macro History

    /// Returns all macro history documents for the user, ordered newest first.
    /// No limit — captures full all-time history.
    ///
    /// Note: Firestore automatically indexes the `date` field on subcollections.
    /// If you see a missing-index error in the console, follow the link it provides.
    func fetchMacroHistory(userID: String) async throws -> [DailyMacros] {
        guard !userID.isEmpty else { return [] }

        let snapshot = try await historyCollection(userID: userID)
            .order(by: "date", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { DailyMacros(document: $0) }
    }

    // MARK: - 4. Fetch Macro History Range

    /// Returns macro history documents between `startDate` and `endDate` (inclusive),
    /// ordered newest first.
    func fetchMacroHistory(
        userID:    String,
        from startDate: Date,
        to   endDate:   Date
    ) async throws -> [DailyMacros] {
        guard !userID.isEmpty else { return [] }

        let start = Timestamp(date: Calendar.current.startOfDay(for: startDate))
        guard let dayAfterEnd = Calendar.current.date(byAdding: .day, value: 1, to: endDate) else { return [] }
        let end   = Timestamp(date: Calendar.current.startOfDay(for: dayAfterEnd))

        let snapshot = try await historyCollection(userID: userID)
            .whereField("date", isGreaterThanOrEqualTo: start)
            .whereField("date", isLessThan: end)
            .order(by: "date", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { DailyMacros(document: $0) }
    }
}
