//
//  FoodEntry.swift
//  Wellness
//

import Foundation
import SwiftData

@Model final class FoodEntry {
    var id: UUID
    var loggedAt: Date
    var userID: String = ""   // owning account — empty for pre-auth legacy entries
    var foodName: String
    var calories: Double
    var protein: Double   // grams
    var carbs: Double     // grams
    var fat: Double       // grams
    @Attribute(.externalStorage) var imageData: Data?

    /// Firestore document ID under users/{userID}/foodEntries — empty until synced.
    var firebaseEntryID: String = ""
    /// Firebase Storage download URL for the food photo — empty if no photo or not yet uploaded.
    var photoURL: String = ""
    /// True when the user opted to save this entry as a reusable saved meal.
    var isSavedMeal: Bool = false

    init(
        id: UUID = UUID(),
        loggedAt: Date = Date(),
        userID: String = "",
        foodName: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        imageData: Data? = nil
    ) {
        self.id = id
        self.loggedAt = loggedAt
        self.userID = userID
        self.foodName = foodName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.imageData = imageData
    }
}
