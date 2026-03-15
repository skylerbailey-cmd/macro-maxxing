//
//  DailyMacros.swift
//  Wellness
//
//  Firestore-backed daily macro snapshot.
//  Subcollection: users/{userID}/macroHistory/{dateString}
//  where dateString is formatted "yyyy-MM-dd"
//

import Foundation
import FirebaseFirestore

struct DailyMacros: Codable, Identifiable {

    // MARK: - Identity

    /// Document ID — the "yyyy-MM-dd" date string. Set by Firestore on read.
    @DocumentID var dateString: String?

    /// The calendar date this snapshot represents. Stored as a Firestore Timestamp
    /// so it can be used for ordering and range queries.
    var date: Timestamp

    // MARK: - Totals

    var totalCalories: Int
    var totalProtein:  Double
    var totalCarbs:    Double
    var totalFat:      Double

    // MARK: - Goals

    var goalCalories: Int
    var goalProtein:  Double
    var goalCarbs:    Double
    var goalFat:      Double

    // MARK: - Derived

    /// 0–100. Average of per-macro completion rates (each capped at 100%).
    /// Computed from totals vs goals and stored so charts can read it directly.
    var completionPercentage: Double

    /// True if all four macros were within the acceptable range for the day.
    /// Mirrors the HomeViewModel.macroGoalsMet logic (85 %–115 % for calories, ≥ 85 % for the rest).
    var allGoalsMet: Bool

    /// Number of individual food entries logged on this day.
    var mealCount: Int

    /// The user's macro streak value at the end of this day.
    var streakDay: Int

    // MARK: - Identifiable

    var id: String { dateString ?? UUID().uuidString }

    // MARK: - Computed helpers

    var dateValue: Date { date.dateValue() }

    // MARK: - Init

    init(
        dateString:           String,
        date:                 Date,
        totalCalories:        Int,
        totalProtein:         Double,
        totalCarbs:           Double,
        totalFat:             Double,
        goalCalories:         Int,
        goalProtein:          Double,
        goalCarbs:            Double,
        goalFat:              Double,
        mealCount:            Int,
        streakDay:            Int
    ) {
        self._dateString       = DocumentID(wrappedValue: dateString)
        self.date              = Timestamp(date: date)
        self.totalCalories     = totalCalories
        self.totalProtein      = totalProtein
        self.totalCarbs        = totalCarbs
        self.totalFat          = totalFat
        self.goalCalories      = goalCalories
        self.goalProtein       = goalProtein
        self.goalCarbs         = goalCarbs
        self.goalFat           = goalFat
        self.mealCount         = mealCount
        self.streakDay         = streakDay

        // Completion percentage — average of per-macro ratios capped at 100 %
        let calRate     = goalCalories > 0 ? min(Double(totalCalories) / Double(goalCalories), 1.0) : 0
        let proteinRate = goalProtein  > 0 ? min(totalProtein / goalProtein, 1.0) : 0
        let carbsRate   = goalCarbs    > 0 ? min(totalCarbs   / goalCarbs,   1.0) : 0
        let fatRate     = goalFat      > 0 ? min(totalFat     / goalFat,     1.0) : 0
        self.completionPercentage = (calRate + proteinRate + carbsRate + fatRate) / 4.0 * 100.0

        // Mirror HomeViewModel.macroGoalsMet thresholds
        let calMet     = goalCalories > 0
            && Double(totalCalories) >= Double(goalCalories) * 0.85
            && Double(totalCalories) <= Double(goalCalories) * 1.15
        let proteinMet = goalProtein > 0 && totalProtein >= goalProtein * 0.85
        let carbsMet   = goalCarbs   > 0 && totalCarbs   >= goalCarbs   * 0.85
        let fatMet     = goalFat     > 0 && totalFat     >= goalFat     * 0.85
        self.allGoalsMet = calMet && proteinMet && carbsMet && fatMet
    }
}

// MARK: - Firestore Helpers

extension DailyMacros {

    /// Decodes a DailyMacros from a Firestore DocumentSnapshot.
    init?(document: DocumentSnapshot) {
        guard document.exists else { return nil }
        do {
            self = try Firestore.Decoder().decode(DailyMacros.self, from: document.data() ?? [:])
        } catch {
            print("[DailyMacros] Decode error – \(document.documentID): \(error)")
            return nil
        }
    }

    /// Encodes this DailyMacros to a Firestore-compatible dictionary.
    func firestoreData() throws -> [String: Any] {
        try Firestore.Encoder().encode(self)
    }
}
