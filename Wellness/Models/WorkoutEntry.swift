//
//  WorkoutEntry.swift
//  Wellness
//

import Foundation

// MARK: - Exercise

/// A single exercise within a workout — optional detail the user can attach
/// to any logged workout (e.g. "Bench Press · 3 × 10 @ 135 lb").
struct Exercise: Codable, Identifiable, Hashable {
    var id:     String  = UUID().uuidString
    var name:   String
    var sets:   Int
    var reps:   Int
    var weight: Double? = nil   // lb, optional
}

// MARK: - Workout Entry

struct WorkoutEntry: Identifiable {
    var workoutID:          String
    var name:               String
    var workoutType:        WorkoutType
    var durationMinutes:    Int
    var caloriesBurned:     Int
    var loggedAt:           Date
    var adjustmentApplied:  Bool
    var exercises:          [Exercise]

    var id: String { workoutID }

    init(workoutID:         String      = UUID().uuidString,
         name:              String,
         workoutType:       WorkoutType = .other,
         durationMinutes:   Int,
         caloriesBurned:    Int,
         loggedAt:          Date        = Date(),
         adjustmentApplied: Bool        = false,
         exercises:         [Exercise]  = []) {
        self.workoutID          = workoutID
        self.name               = name
        self.workoutType        = workoutType
        self.durationMinutes    = durationMinutes
        self.caloriesBurned     = caloriesBurned
        self.loggedAt           = loggedAt
        self.adjustmentApplied  = adjustmentApplied
        self.exercises          = exercises
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
    var exercises:       [Exercise]  = []

    init(id:              String      = UUID().uuidString,
         name:            String,
         workoutType:     WorkoutType = .other,
         durationMinutes: Int,
         caloriesBurned:  Int,
         exercises:       [Exercise]  = []) {
        self.id              = id
        self.name            = name
        self.workoutType     = workoutType
        self.durationMinutes = durationMinutes
        self.caloriesBurned  = caloriesBurned
        self.exercises       = exercises
    }

    // Tolerate legacy UserDefaults blobs that predate the `exercises` field.
    private enum CodingKeys: String, CodingKey {
        case id, name, workoutType, durationMinutes, caloriesBurned, exercises
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id              = try c.decodeIfPresent(String.self,       forKey: .id)              ?? UUID().uuidString
        self.name            = try c.decode(String.self,                forKey: .name)
        self.workoutType     = try c.decodeIfPresent(WorkoutType.self,  forKey: .workoutType)     ?? .other
        self.durationMinutes = try c.decodeIfPresent(Int.self,          forKey: .durationMinutes) ?? 0
        self.caloriesBurned  = try c.decodeIfPresent(Int.self,          forKey: .caloriesBurned)  ?? 0
        self.exercises       = try c.decodeIfPresent([Exercise].self,   forKey: .exercises)       ?? []
    }
}
