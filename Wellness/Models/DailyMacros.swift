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

    /// Document ID — the "yyyy-MM-dd" date string. Set manually from document ID on read.
    var dateString: String?

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

    // MARK: - Fasting Window

    /// Fasting window snapshot for this day. Nil if logTodaysWindow has not been called yet.
    /// Stored as a nested Firestore map — existing documents without this field decode fine.
    var fasting: FastingSnapshot?

    // MARK: - Identifiable

    var id: String { dateString ?? "unknown-\(date.seconds)" }

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
        self.dateString        = dateString
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

        // Mirror HomeViewModel.macroGoalsMet thresholds: all four must be within 85–115 %
        let calMet     = goalCalories > 0
            && Double(totalCalories) >= Double(goalCalories) * 0.85
            && Double(totalCalories) <= Double(goalCalories) * 1.15
        let proteinMet = goalProtein > 0
            && totalProtein >= goalProtein * 0.85
            && totalProtein <= goalProtein * 1.15
        let carbsMet   = goalCarbs   > 0
            && totalCarbs   >= goalCarbs   * 0.85
            && totalCarbs   <= goalCarbs   * 1.15
        let fatMet     = goalFat     > 0
            && totalFat     >= goalFat     * 0.85
            && totalFat     <= goalFat     * 1.15
        self.allGoalsMet = calMet && proteinMet && carbsMet && fatMet
    }
}

// MARK: - FastingSnapshot

/// Fasting window data for one calendar day. Stored as a nested map inside
/// the macroHistory document under the key "fasting".
struct FastingSnapshot: Codable {

    // MARK: Window definition (from user preferences on that day)

    /// Whether fasting tracking was enabled on this day.
    var fastingEnabled: Bool

    /// Exact date+time the eating window opened (e.g., today at 9:00 AM).
    var windowStartTime: Timestamp

    /// Exact date+time the eating window closed (e.g., today at 5:00 PM).
    var windowEndTime: Timestamp

    /// Length of the eating window in hours (e.g., 8.0).
    var windowDurationHours: Double

    /// Length of the fasting period in hours (24 − windowDurationHours).
    var fastingHours: Double

    // MARK: Actual eating behavior

    /// Time of the first meal logged today. Nil if no meals were logged.
    var firstMealTime: Timestamp?

    /// Time of the last meal logged today. Nil if no meals were logged.
    var lastMealTime: Timestamp?

    /// Number of meals logged inside the eating window.
    var mealsWithinWindow: Int

    /// Number of meals logged outside the eating window.
    /// > 0 means the user broke their fast early or ate after the window closed.
    var mealsOutsideWindow: Int

    // MARK: Status

    /// True when all meals were logged within the eating window and fasting was enabled.
    /// Auto-computed by FastingWindowService; can also be set manually via markWindowCompleted.
    var isCompleted: Bool

    /// True once the calendar day has passed. Set by lockPastWindows on app launch.
    /// Locked windows can no longer be edited.
    var isLocked: Bool

    // MARK: Computed helpers

    var windowStartDate: Date { windowStartTime.dateValue() }
    var windowEndDate:   Date { windowEndTime.dateValue() }
    var firstMealDate:   Date? { firstMealTime?.dateValue() }
    var lastMealDate:    Date? { lastMealTime?.dateValue() }

    // MARK: Decodable (tolerant of partial / historical documents)

    private enum CodingKeys: String, CodingKey {
        case fastingEnabled
        case windowStartTime
        case windowEndTime
        case windowDurationHours
        case fastingHours
        case firstMealTime
        case lastMealTime
        case mealsWithinWindow
        case mealsOutsideWindow
        case isCompleted
        case isLocked
    }

    init(
        fastingEnabled: Bool,
        windowStartTime: Timestamp,
        windowEndTime: Timestamp,
        windowDurationHours: Double,
        fastingHours: Double,
        firstMealTime: Timestamp? = nil,
        lastMealTime: Timestamp? = nil,
        mealsWithinWindow: Int,
        mealsOutsideWindow: Int,
        isCompleted: Bool,
        isLocked: Bool
    ) {
        self.fastingEnabled = fastingEnabled
        self.windowStartTime = windowStartTime
        self.windowEndTime = windowEndTime
        self.windowDurationHours = windowDurationHours
        self.fastingHours = fastingHours
        self.firstMealTime = firstMealTime
        self.lastMealTime = lastMealTime
        self.mealsWithinWindow = mealsWithinWindow
        self.mealsOutsideWindow = mealsOutsideWindow
        self.isCompleted = isCompleted
        self.isLocked = isLocked
    }

    /// Custom decoder that tolerates partial documents. Historical
    /// `macroHistory/{date}` documents were written before every field on
    /// this struct existed — in particular `fastingEnabled` was added
    /// later. Swift's synthesized `Decodable` requires every non-optional
    /// key to be present, which caused every historical day to fail to
    /// decode. Use `decodeIfPresent` + sensible defaults so old documents
    /// load cleanly and any missing fields get neutral values.
    ///
    /// NOTE: the window start/end defaults must be a *valid* Firestore
    /// Timestamp. `Date.distantPast` (year -4712) is outside Firestore's
    /// valid range (0001-01-01 … 9999-12-31) and crashes the Timestamp
    /// constructor with "seconds out of range". Use Unix epoch 0
    /// (1970-01-01) as a safe sentinel instead — it's a valid Timestamp
    /// and an obvious "no data" value for calling code.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let epoch = Timestamp(seconds: 0, nanoseconds: 0)
        self.fastingEnabled      = try c.decodeIfPresent(Bool.self,      forKey: .fastingEnabled)      ?? false
        self.windowStartTime     = try c.decodeIfPresent(Timestamp.self, forKey: .windowStartTime)     ?? epoch
        self.windowEndTime       = try c.decodeIfPresent(Timestamp.self, forKey: .windowEndTime)       ?? epoch
        self.windowDurationHours = try c.decodeIfPresent(Double.self,    forKey: .windowDurationHours) ?? 0
        self.fastingHours        = try c.decodeIfPresent(Double.self,    forKey: .fastingHours)        ?? 0
        self.firstMealTime       = try c.decodeIfPresent(Timestamp.self, forKey: .firstMealTime)
        self.lastMealTime        = try c.decodeIfPresent(Timestamp.self, forKey: .lastMealTime)
        self.mealsWithinWindow   = try c.decodeIfPresent(Int.self,       forKey: .mealsWithinWindow)   ?? 0
        self.mealsOutsideWindow  = try c.decodeIfPresent(Int.self,       forKey: .mealsOutsideWindow)  ?? 0
        self.isCompleted         = try c.decodeIfPresent(Bool.self,      forKey: .isCompleted)         ?? false
        self.isLocked            = try c.decodeIfPresent(Bool.self,      forKey: .isLocked)            ?? false
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
            AppLogger.log("[DailyMacros] Decode error – \(document.documentID): \(error)")
            return nil
        }
    }

    /// Encodes this DailyMacros to a Firestore-compatible dictionary.
    func firestoreData() throws -> [String: Any] {
        try Firestore.Encoder().encode(self)
    }
}
