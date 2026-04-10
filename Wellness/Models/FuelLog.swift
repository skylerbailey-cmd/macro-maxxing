//
//  FuelLog.swift
//  Wellness
//
//  Firestore-backed daily fuel log.
//  Document path: users/{userID}/fuelLog/{dateString}
//  where dateString is formatted "yyyy-MM-dd"
//

import Foundation
import FirebaseFirestore

// MARK: - FuelLogMeal

/// A single meal entry nested inside a daily FuelLog document.
struct FuelLogMeal: Codable, Identifiable {

    /// Unique ID for this meal — used to find and remove it from the meals array.
    var mealID:    String
    var foodName:  String
    var calories:  Int
    var protein:   Double
    var carbs:     Double
    var fat:       Double
    /// Firebase Storage download URL, or empty string if no photo was attached.
    var photoURL:  String
    /// When the meal was logged.
    var timestamp: Timestamp

    var id: String { mealID }
    var timestampDate: Date { timestamp.dateValue() }

    init(
        mealID:    String   = UUID().uuidString,
        foodName:  String,
        calories:  Int,
        protein:   Double,
        carbs:     Double,
        fat:       Double,
        photoURL:  String   = "",
        timestamp: Date     = Date()
    ) {
        self.mealID    = mealID
        self.foodName  = foodName
        self.calories  = calories
        self.protein   = protein
        self.carbs     = carbs
        self.fat       = fat
        self.photoURL  = photoURL
        self.timestamp = Timestamp(date: timestamp)
    }
}

// MARK: - FuelLog

/// The daily fuel log document. Contains all meals for one calendar day
/// plus pre-computed totals so the app never needs to re-sum client-side.
struct FuelLog: Codable, Identifiable {

    /// Document ID — the "yyyy-MM-dd" date string. Set manually from document ID on read.
    var dateString: String?

    /// The calendar date this log represents.
    var date: Timestamp

    /// All meals logged for this day, ordered oldest → newest by timestamp.
    var meals: [FuelLogMeal]

    // MARK: Totals (kept in sync by FuelLogService after every mutation)

    var totalCalories: Int
    var totalProtein:  Double
    var totalCarbs:    Double
    var totalFat:      Double

    var id: String { dateString ?? "unknown-\(date.seconds)" }
    var dateValue: Date { date.dateValue() }

    // MARK: - Init

    init(dateString: String, date: Date, meals: [FuelLogMeal] = []) {
        self.dateString    = dateString
        self.date          = Timestamp(date: date)
        self.meals         = meals
        self.totalCalories = meals.reduce(0) { $0 + $1.calories }
        self.totalProtein  = meals.reduce(0) { $0 + $1.protein }
        self.totalCarbs    = meals.reduce(0) { $0 + $1.carbs }
        self.totalFat      = meals.reduce(0) { $0 + $1.fat }
    }

    // MARK: - Helpers

    /// Recomputes and returns updated totals from the current meals array.
    mutating func recalculateTotals() {
        totalCalories = meals.reduce(0) { $0 + $1.calories }
        totalProtein  = meals.reduce(0) { $0 + $1.protein }
        totalCarbs    = meals.reduce(0) { $0 + $1.carbs }
        totalFat      = meals.reduce(0) { $0 + $1.fat }
    }
}

// MARK: - Firestore Helpers

extension FuelLog {

    init?(document: DocumentSnapshot) {
        guard document.exists else { return nil }
        do {
            self = try Firestore.Decoder().decode(FuelLog.self, from: document.data() ?? [:])
        } catch {
            AppLogger.log("[FuelLog] Decode error – \(document.documentID): \(error)")
            return nil
        }
    }

    func firestoreData() throws -> [String: Any] {
        try Firestore.Encoder().encode(self)
    }
}
