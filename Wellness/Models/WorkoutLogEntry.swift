//
//  WorkoutLogEntry.swift
//  Wellness
//
//  SwiftData model for workout entries attached to a SocialPost.
//

import Foundation
import SwiftData

@Model final class WorkoutLogEntry {
    var workoutName:     String = ""
    var workoutType:     String = ""   // WorkoutType.rawValue
    var durationMinutes: Int    = 0
    var caloriesBurned:  Int    = 0
    var loggedAt:        Date   = Date()
    var sortOrder:       Int    = 0

    var post: SocialPost?

    init(workoutName: String, workoutType: String, durationMinutes: Int,
         caloriesBurned: Int, loggedAt: Date, sortOrder: Int) {
        self.workoutName     = workoutName
        self.workoutType     = workoutType
        self.durationMinutes = durationMinutes
        self.caloriesBurned  = caloriesBurned
        self.loggedAt        = loggedAt
        self.sortOrder       = sortOrder
    }

    var formattedDuration: String {
        durationMinutes >= 60
            ? "\(durationMinutes / 60)h \(durationMinutes % 60)m"
            : "\(durationMinutes)m"
    }
}
