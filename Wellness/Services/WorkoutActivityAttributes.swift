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

    // MARK: - Cardio / HIIT / Yoga payloads
    //
    // Mirrors of the app-side structs in Models/WorkoutItem.swift. Kept
    // independent (and shared via project.pbxproj membershipExceptions)
    // so the widget extension doesn't have to import Wellness types.

    struct LiveCardioSegment: Codable, Hashable, Identifiable {
        var id:              String
        var label:           String
        var durationSeconds: Int
        var distanceMiles:   Double?

        init(id:              String = UUID().uuidString,
             label:           String,
             durationSeconds: Int,
             distanceMiles:   Double? = nil) {
            self.id              = id
            self.label           = label
            self.durationSeconds = durationSeconds
            self.distanceMiles   = distanceMiles
        }
    }

    struct LiveHIITRound: Codable, Hashable, Identifiable {
        var id:           String
        var name:         String
        var workSeconds:  Int
        var restSeconds:  Int
        var rounds:       Int
        /// Which round (1-based) the user is currently on — bumped by
        /// WorkoutHIITNextRoundIntent.
        var currentRound: Int
        /// True when resting, false when in the work phase. Toggled by
        /// WorkoutHIITTogglePhaseIntent.
        var inRest:       Bool

        init(id:           String = UUID().uuidString,
             name:         String,
             workSeconds:  Int,
             restSeconds:  Int,
             rounds:       Int,
             currentRound: Int  = 1,
             inRest:       Bool = false) {
            self.id           = id
            self.name         = name
            self.workSeconds  = workSeconds
            self.restSeconds  = restSeconds
            self.rounds       = rounds
            self.currentRound = currentRound
            self.inRest       = inRest
        }
    }

    struct LivePose: Codable, Hashable, Identifiable {
        var id:          String
        var name:        String
        var holdSeconds: Int

        init(id:          String = UUID().uuidString,
             name:        String,
             holdSeconds: Int = 0) {
            self.id          = id
            self.name        = name
            self.holdSeconds = holdSeconds
        }
    }

    /// Dynamic state — updated while the session is running.
    struct ContentState: Codable, Hashable {
        var workoutName:     String
        var workoutTypeRaw:  String                // WorkoutType.rawValue
        var startedAt:       Date
        /// Index into the active payload (`exercises` / `segments` /
        /// `rounds` / `poses`) of the thing the user is currently working.
        var currentIndex:    Int
        /// Strength-track payload.
        var exercises:       [LiveExercise]
        /// Cardio-track payload.
        var segments:        [LiveCardioSegment]
        /// HIIT-track payload.
        var rounds:          [LiveHIITRound]
        /// Yoga / flexibility payload.
        var poses:           [LivePose]
        /// Flipped to true when the user taps "End Workout" from the Live
        /// Activity. The app picks this up on foreground, drains state into
        /// the Log a Workout sheet, then ends the activity.
        var isFinished:      Bool
        /// When non-nil, the workout is paused; the displayed timer should
        /// freeze at `pausedAt − startedAt − accumulatedPaused`.
        var pausedAt:        Date?
        /// Total seconds the workout has been paused so far. When the user
        /// resumes, we bump this by `now − pausedAt` and clear `pausedAt`.
        var accumulatedPaused: TimeInterval

        // MARK: Rest timer
        //
        // Timestamp of the last "Log Set" or "Next Exercise" action.
        // The Dynamic Island shows a running rest timer since this date
        // so the user can track how long they've been resting between sets.
        // `nil` means no set has been logged yet — no rest timer shown.
        var lastSetLoggedAt: Date? = nil

        // MARK: Staged set (Dynamic Island "Log Set" flow)
        //
        // The staged set is the set being configured on the Dynamic Island
        // with +/- reps and weight. It is NOT part of the exercise's sets
        // array until the user taps "Log Set", which commits it.
        var stagedReps:   Int     = 10
        var stagedWeight: Double? = nil

        init(workoutName:    String,
             workoutTypeRaw: String,
             startedAt:      Date,
             currentIndex:   Int = 0,
             exercises:      [LiveExercise]      = [],
             segments:       [LiveCardioSegment] = [],
             rounds:         [LiveHIITRound]     = [],
             poses:          [LivePose]          = [],
             isFinished:     Bool                = false,
             pausedAt:       Date?               = nil,
             accumulatedPaused: TimeInterval     = 0) {
            self.workoutName       = workoutName
            self.workoutTypeRaw    = workoutTypeRaw
            self.startedAt         = startedAt
            self.currentIndex      = currentIndex
            self.exercises         = exercises
            self.segments          = segments
            self.rounds            = rounds
            self.poses             = poses
            self.isFinished        = isFinished
            self.pausedAt          = pausedAt
            self.accumulatedPaused = accumulatedPaused
        }

        // Tolerate older Live Activity payloads that used a flatter shape
        // (currentExercise / sets / exerciseNumber / totalExercises) and
        // payloads from before the per-type arrays were added.
        private enum CodingKeys: String, CodingKey {
            case workoutName, workoutTypeRaw, startedAt, currentIndex
            case exercises, segments, rounds, poses
            case isFinished, pausedAt, accumulatedPaused, lastSetLoggedAt
            case stagedReps, stagedWeight
            // Legacy fields:
            case currentExercise, sets, exerciseNumber, totalExercises
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(workoutName,       forKey: .workoutName)
            try c.encode(workoutTypeRaw,    forKey: .workoutTypeRaw)
            try c.encode(startedAt,         forKey: .startedAt)
            try c.encode(currentIndex,      forKey: .currentIndex)
            try c.encode(exercises,         forKey: .exercises)
            try c.encode(segments,          forKey: .segments)
            try c.encode(rounds,            forKey: .rounds)
            try c.encode(poses,             forKey: .poses)
            try c.encode(isFinished,        forKey: .isFinished)
            try c.encodeIfPresent(pausedAt, forKey: .pausedAt)
            try c.encode(accumulatedPaused, forKey: .accumulatedPaused)
            try c.encodeIfPresent(lastSetLoggedAt, forKey: .lastSetLoggedAt)
            try c.encode(stagedReps, forKey: .stagedReps)
            try c.encodeIfPresent(stagedWeight, forKey: .stagedWeight)
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.workoutName       = (try? c.decode(String.self, forKey: .workoutName)) ?? ""
            self.workoutTypeRaw    = (try? c.decode(String.self, forKey: .workoutTypeRaw)) ?? ""
            self.startedAt         = (try? c.decode(Date.self,   forKey: .startedAt)) ?? Date()
            self.isFinished        = (try? c.decode(Bool.self,   forKey: .isFinished)) ?? false
            self.pausedAt          = try? c.decode(Date.self,    forKey: .pausedAt)
            self.accumulatedPaused = (try? c.decode(TimeInterval.self, forKey: .accumulatedPaused)) ?? 0
            self.lastSetLoggedAt  = try? c.decode(Date.self, forKey: .lastSetLoggedAt)
            self.stagedReps       = (try? c.decode(Int.self,    forKey: .stagedReps))   ?? 10
            self.stagedWeight     = try? c.decode(Double.self,  forKey: .stagedWeight)
            self.segments          = (try? c.decode([LiveCardioSegment].self, forKey: .segments)) ?? []
            self.rounds            = (try? c.decode([LiveHIITRound].self,     forKey: .rounds))   ?? []
            self.poses             = (try? c.decode([LivePose].self,          forKey: .poses))    ?? []

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

        /// Effective start used to drive `Text(timerInterval:)` so the
        /// auto-counting timer reads correctly once paused time is excluded.
        /// We shift the perceived start forward by the total paused seconds.
        var effectiveStart: Date {
            startedAt.addingTimeInterval(accumulatedPaused)
        }

        /// Seconds elapsed, ignoring pause time. Used to show a static
        /// elapsed label while the workout is paused.
        func elapsedSeconds(now: Date = Date()) -> Int {
            let end = pausedAt ?? now
            let raw = end.timeIntervalSince(startedAt) - accumulatedPaused
            return max(0, Int(raw))
        }

        var isPaused: Bool { pausedAt != nil }
    }

    /// The current exercise, or nil if `currentIndex` is out of bounds.
    static func currentExercise(in state: ContentState) -> LiveExercise? {
        guard state.exercises.indices.contains(state.currentIndex) else { return nil }
        return state.exercises[state.currentIndex]
    }
}
