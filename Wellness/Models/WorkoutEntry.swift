//
//  WorkoutEntry.swift
//  Wellness
//

import Foundation

struct WorkoutEntry: Identifiable {
    var workoutID:       String
    var name:            String
    var workoutType:     WorkoutType
    var durationMinutes: Int
    var caloriesBurned:  Int
    var loggedAt:        Date

    var id: String { workoutID }

    init(workoutID:       String      = UUID().uuidString,
         name:            String,
         workoutType:     WorkoutType = .other,
         durationMinutes: Int,
         caloriesBurned:  Int,
         loggedAt:        Date        = Date()) {
        self.workoutID       = workoutID
        self.name            = name
        self.workoutType     = workoutType
        self.durationMinutes = durationMinutes
        self.caloriesBurned  = caloriesBurned
        self.loggedAt        = loggedAt
    }

    var formattedDuration: String {
        durationMinutes >= 60
            ? "\(durationMinutes / 60)h \(durationMinutes % 60)m"
            : "\(durationMinutes)m"
    }
}

// MARK: - Saved Workout Template

struct SavedWorkout: Codable, Identifiable {
    var id:              String      = UUID().uuidString
    var name:            String
    var workoutType:     WorkoutType = .other
    var durationMinutes: Int
    var caloriesBurned:  Int
}
