//
//  WorkoutActivityAttributes.swift
//  Wellness
//
//  Shared between the main app target and the WellnessWidgets extension.
//  After adding the Widget Extension target in Xcode, select this file in the
//  File Inspector and tick WellnessWidgets under Target Membership.
//
//  The ContentState carries the FULL in-progress workout so Live Activity
//  intents (running in the widget extension) can mutate it without needing
//  an App Group. When the user taps "End Workout" from the Live Activity
//  the intent flips `isFinished = true` and the app, on next foreground,
//  pulls state from the activity into the Log a Workout sheet.
//

import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {

    /// A single set inside an exercise. Carried verbatim between the app and
    /// the Live Activity UI.
    struct LiveSet: Codable, Hashable, Identifiable {
        var id:     String
        var reps:   Int
        var weight: Double?   // nil = bodyweight

        init(id: String = UUID().uuidString, reps: Int, weight: Double? = nil) {
            self.id     = id
            self.reps   = reps
            self.weight = weight
        }
    }

    /// A single exercise with its ordered list of sets.
    struct LiveExercise: Codable, Hashable, Identifiable {
        var id:   String
        var name: String
        var sets: [LiveSet]

        init(id: String = UUID().uuidString, name: String, sets: [LiveSet]) {
            self.id   = id
            self.name = name
            self.sets = sets
        }
    }

    /// Dynamic state — updated while the session is running.
    struct ContentState: Codable, Hashable {
        var workoutName:     String
        var workoutTypeRaw:  String                // WorkoutType.rawValue
        var startedAt:       Date
        /// Index into `exercises` of the exercise the user is currently working.
        var currentIndex:    Int
        /// Full list of exercises in the active workout.
        var exercises:       [LiveExercise]
        /// Flipped to true when the user taps "End Workout" from the Live
        /// Activity. The app picks this up on foreground, drains state into
        /// the Log a Workout sheet, then ends the activity.
        var isFinished:      Bool

        init(workoutName:    String,
             workoutTypeRaw: String,
             startedAt:      Date,
             currentIndex:   Int = 0,
             exercises:      [LiveExercise] = [],
             isFinished:     Bool = false) {
            self.workoutName    = workoutName
            self.workoutTypeRaw = workoutTypeRaw
            self.startedAt      = startedAt
            self.currentIndex   = currentIndex
            self.exercises      = exercises
            self.isFinished     = isFinished
        }

        // Tolerate older Live Activity payloads that used a flatter shape
        // (currentExercise / sets / exerciseNumber / totalExercises).
        private enum CodingKeys: String, CodingKey {
            case workoutName, workoutTypeRaw, startedAt, currentIndex, exercises, isFinished
            // Legacy fields:
            case currentExercise, sets, exerciseNumber, totalExercises
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.workoutName    = (try? c.decode(String.self, forKey: .workoutName)) ?? ""
            self.workoutTypeRaw = (try? c.decode(String.self, forKey: .workoutTypeRaw)) ?? ""
            self.startedAt      = (try? c.decode(Date.self,   forKey: .startedAt)) ?? Date()
            self.isFinished     = (try? c.decode(Bool.self,   forKey: .isFinished)) ?? false

            if let list = try? c.decode([LiveExercise].self, forKey: .exercises) {
                self.exercises    = list
                self.currentIndex = (try? c.decode(Int.self, forKey: .currentIndex)) ?? 0
            } else {
                // Legacy single-exercise payload.
                let name = (try? c.decode(String.self, forKey: .currentExercise)) ?? ""
                let sets = (try? c.decode([LiveSet].self, forKey: .sets)) ?? []
                let num  = (try? c.decode(Int.self, forKey: .exerciseNumber)) ?? 1
                let tot  = max(num, (try? c.decode(Int.self, forKey: .totalExercises)) ?? num)
                var list = Array(repeating: LiveExercise(name: "", sets: []), count: max(tot, 1))
                let idx = max(0, min(num - 1, list.count - 1))
                list[idx] = LiveExercise(name: name, sets: sets)
                self.exercises    = list
                self.currentIndex = idx
            }
        }
    }

    /// The current exercise, or nil if `currentIndex` is out of bounds.
    static func currentExercise(in state: ContentState) -> LiveExercise? {
        guard state.exercises.indices.contains(state.currentIndex) else { return nil }
        return state.exercises[state.currentIndex]
    }
}
