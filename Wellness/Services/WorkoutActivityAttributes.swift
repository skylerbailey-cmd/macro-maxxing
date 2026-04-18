//
//  WorkoutActivityAttributes.swift
//  Wellness
//
//  Shared between the main app target and the WellnessWidgets extension.
//  After adding the Widget Extension target in Xcode, select this file in the
//  File Inspector and tick WellnessWidgets under Target Membership.
//

import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {

    /// A single set, mirrored from ExerciseSet for Codable transport.
    struct LiveSet: Codable, Hashable {
        let reps:   Int
        let weight: Double?   // nil = bodyweight
    }

    /// Dynamic state — updated while the session is running.
    struct ContentState: Codable, Hashable {
        var workoutName:     String
        var workoutTypeRaw:  String      // WorkoutType.rawValue — avoids coupling the widget to MacroAdjustmentEngine
        var currentExercise: String
        var exerciseNumber:  Int
        var totalExercises:  Int
        /// Sets for the current exercise.
        var sets:            [LiveSet]
        var startedAt:       Date
    }
}
