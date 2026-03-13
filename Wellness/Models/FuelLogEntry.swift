//
//  FuelLogEntry.swift
//  Wellness
//

import Foundation
import SwiftData

@Model final class FuelLogEntry {
    var foodName:  String = ""
    var calories:  Double = 0
    var protein:   Double = 0
    var carbs:     Double = 0
    var fat:       Double = 0
    var loggedAt:  Date   = Date()
    var sortOrder: Int    = 0

    @Attribute(.externalStorage) var imageData: Data? = nil

    var post: SocialPost?

    init(foodName: String, calories: Double, protein: Double,
         carbs: Double, fat: Double, loggedAt: Date,
         sortOrder: Int, imageData: Data?) {
        self.foodName  = foodName
        self.calories  = calories
        self.protein   = protein
        self.carbs     = carbs
        self.fat       = fat
        self.loggedAt  = loggedAt
        self.sortOrder = sortOrder
        self.imageData = imageData
    }
}
