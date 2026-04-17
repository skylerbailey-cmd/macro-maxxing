//
//  WorkoutEntry.swift
//  Wellness
//

import Foundation

// MARK: - Exercise Set

/// One set within an exercise — reps, and an optional weight in pounds.
struct ExerciseSet: Codable, Identifiable, Hashable {
    var id:     String  = UUID().uuidString
    var reps:   Int
    var weight: Double? = nil

    init(id: String = UUID().uuidString, reps: Int, weight: Double? = nil) {
        self.id     = id
        self.reps   = reps
        self.weight = weight
    }

    private enum CodingKeys: String, CodingKey { case id, reps, weight }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id     = try c.decodeIfPresent(String.self, forKey: .id)   ?? UUID().uuidString
        self.reps   = try c.decodeIfPresent(Int.self,    forKey: .reps) ?? 1
        self.weight = try c.decodeIfPresent(Double.self, forKey: .weight)
    }
}

// MARK: - Exercise

/// A single exercise within a workout — optional detail the user can attach
/// to any logged workout. Each set has its own reps and optional weight, so
/// users can record pyramid/ramping schemes like 10×135, 8×145, 6×155.
struct Exercise: Codable, Identifiable, Hashable {
    var id:   String  = UUID().uuidString
    var name: String
    var sets: [ExerciseSet]

    init(id: String = UUID().uuidString, name: String, sets: [ExerciseSet]) {
        self.id   = id
        self.name = name
        self.sets = sets
    }

    /// Convenience for creating a simple exercise with N identical sets.
    init(id: String = UUID().uuidString, name: String, setCount: Int, reps: Int, weight: Double? = nil) {
        self.id   = id
        self.name = name
        self.sets = (0..<max(1, setCount)).map { _ in ExerciseSet(reps: reps, weight: weight) }
    }

    /// Every set has the same reps AND weight — lets the UI collapse to the
    /// compact "3 × 10 @ 135 lb" form.
    var hasUniformSets: Bool {
        guard let first = sets.first else { return true }
        return sets.allSatisfy { $0.reps == first.reps && $0.weight == first.weight }
    }

    private enum CodingKeys: String, CodingKey {
        // new
        case id, name, sets
        // legacy (flat) fields — only used when decoding older payloads
        case reps, weight
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id   = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.name = try c.decode(String.self, forKey: .name)

        if let newSets = try? c.decode([ExerciseSet].self, forKey: .sets) {
            self.sets = newSets
        } else if let count = try? c.decode(Int.self, forKey: .sets) {
            // Legacy shape: { sets: Int, reps: Int, weight: Double? }
            let reps   = (try? c.decodeIfPresent(Int.self,    forKey: .reps))   ?? 1
            let weight = (try? c.decodeIfPresent(Double.self, forKey: .weight)) ?? nil
            self.sets = (0..<max(1, count)).map { _ in ExerciseSet(reps: reps, weight: weight) }
        } else {
            self.sets = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,   forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(sets, forKey: .sets)
    }
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
    /// Optional gym/location tag. `nil` when the user didn't tag a place.
    var location:           WorkoutLocation?
    /// Friends tagged on this workout. Empty = untagged.
    var taggedFriends:      [TaggedFriend]

    var id: String { workoutID }

    init(workoutID:         String      = UUID().uuidString,
         name:              String,
         workoutType:       WorkoutType = .other,
         durationMinutes:   Int,
         caloriesBurned:    Int,
         loggedAt:          Date        = Date(),
         adjustmentApplied: Bool        = false,
         exercises:         [Exercise]  = [],
         location:          WorkoutLocation? = nil,
         taggedFriends:     [TaggedFriend]   = []) {
        self.workoutID          = workoutID
        self.name               = name
        self.workoutType        = workoutType
        self.durationMinutes    = durationMinutes
        self.caloriesBurned     = caloriesBurned
        self.loggedAt           = loggedAt
        self.adjustmentApplied  = adjustmentApplied
        self.exercises          = exercises
        self.location           = location
        self.taggedFriends      = taggedFriends
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

// MARK: - Workout Routine

/// A single day within a routine or meal plan — holds an ordered list of item IDs.
struct PlanDay: Codable, Identifiable, Hashable {
    var id:      String   = UUID().uuidString
    var label:   String                         // "Day 1", "Monday", etc.
    var itemIDs: [String] = []
}

/// A named group of saved workouts organized by day.
struct WorkoutRoutine: Codable, Identifiable {
    var id:        String     = UUID().uuidString
    var name:      String
    var days:      [PlanDay]  = []
    var createdAt: Date       = Date()

    /// Flat list of all workout IDs across all days (for backward compat + card previews).
    var allWorkoutIDs: [String] { days.flatMap(\.itemIDs) }
}
