//
//  WorkoutLiveActivityIntents.swift
//  Wellness
//
//  Live-Activity-backed App Intents that drive the interactive workout
//  popup from the lock screen and the Dynamic Island. Each intent reads the
//  current ContentState from the running Live Activity, mutates it, and
//  pushes the update back. The running app observes `activity.contentUpdates`
//  (see LiveWorkoutView) so changes made from outside the app stay in sync.
//
//  Shared with the WellnessWidgetsExtension target via a membership
//  exception in project.pbxproj.
//

import ActivityKit
import AppIntents
import Foundation

// MARK: - Helpers

@available(iOS 17.0, *)
private enum WorkoutLiveActivitySupport {

    /// The first active workout activity. Intents only drive one at a time.
    static var activity: Activity<WorkoutActivityAttributes>? {
        Activity<WorkoutActivityAttributes>.activities.first
    }

    /// Mutate the running activity's ContentState in place.
    static func mutate(_ transform: (inout WorkoutActivityAttributes.ContentState) -> Void) async {
        guard let activity = activity else { return }
        var state = activity.content.state
        transform(&state)
        await activity.update(ActivityContent(state: state, staleDate: nil))
    }
}

// MARK: - Increment reps

@available(iOS 17.0, *)
struct WorkoutIncrementRepsIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Increase Reps"
    static var description = IntentDescription("Add one rep to the current set.")

    @Parameter(title: "Set Index") var setIndex: Int

    init() { self.setIndex = -1 }
    init(setIndex: Int) { self.setIndex = setIndex }

    func perform() async throws -> some IntentResult {
        await WorkoutLiveActivitySupport.mutate { state in
            guard state.exercises.indices.contains(state.currentIndex) else { return }
            var ex = state.exercises[state.currentIndex]
            let idx = setIndex >= 0 ? setIndex : ex.sets.count - 1
            guard ex.sets.indices.contains(idx) else { return }
            ex.sets[idx].reps = min(999, ex.sets[idx].reps + 1)
            state.exercises[state.currentIndex] = ex
        }
        return .result()
    }
}

// MARK: - Decrement reps

@available(iOS 17.0, *)
struct WorkoutDecrementRepsIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Decrease Reps"
    static var description = IntentDescription("Remove one rep from the current set.")

    @Parameter(title: "Set Index") var setIndex: Int

    init() { self.setIndex = -1 }
    init(setIndex: Int) { self.setIndex = setIndex }

    func perform() async throws -> some IntentResult {
        await WorkoutLiveActivitySupport.mutate { state in
            guard state.exercises.indices.contains(state.currentIndex) else { return }
            var ex = state.exercises[state.currentIndex]
            let idx = setIndex >= 0 ? setIndex : ex.sets.count - 1
            guard ex.sets.indices.contains(idx) else { return }
            ex.sets[idx].reps = max(1, ex.sets[idx].reps - 1)
            state.exercises[state.currentIndex] = ex
        }
        return .result()
    }
}

// MARK: - Add set

@available(iOS 17.0, *)
struct WorkoutAddSetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Add Set"
    static var description = IntentDescription("Append a new set to the current exercise, copying the previous set's reps and weight.")

    init() {}

    func perform() async throws -> some IntentResult {
        await WorkoutLiveActivitySupport.mutate { state in
            guard state.exercises.indices.contains(state.currentIndex) else { return }
            var ex = state.exercises[state.currentIndex]
            let template = ex.sets.last
            ex.sets.append(
                WorkoutActivityAttributes.LiveSet(
                    reps:   template?.reps   ?? 10,
                    weight: template?.weight
                )
            )
            state.exercises[state.currentIndex] = ex
        }
        return .result()
    }
}

// MARK: - Next exercise

@available(iOS 17.0, *)
struct WorkoutNextExerciseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Next Exercise"
    static var description = IntentDescription("Advance to the next exercise in the workout, or add a new one.")

    init() {}

    func perform() async throws -> some IntentResult {
        await WorkoutLiveActivitySupport.mutate { state in
            if state.currentIndex >= state.exercises.count - 1 {
                // At the end — seed a fresh exercise using the latest set as a template.
                let template = state.exercises.last?.sets.last
                let seed = WorkoutActivityAttributes.LiveSet(
                    reps:   template?.reps   ?? 10,
                    weight: template?.weight
                )
                state.exercises.append(
                    WorkoutActivityAttributes.LiveExercise(name: "", sets: [seed])
                )
            }
            state.currentIndex = min(state.currentIndex + 1, state.exercises.count - 1)
        }
        return .result()
    }
}

// MARK: - Previous exercise

@available(iOS 17.0, *)
struct WorkoutPreviousExerciseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Previous Exercise"
    static var description = IntentDescription("Go back to the previous exercise.")

    init() {}

    func perform() async throws -> some IntentResult {
        await WorkoutLiveActivitySupport.mutate { state in
            state.currentIndex = max(0, state.currentIndex - 1)
        }
        return .result()
    }
}

// MARK: - Increment weight (by 5 lb)

@available(iOS 17.0, *)
struct WorkoutIncrementWeightIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Add Weight"
    static var description = IntentDescription("Add 5 lb to the current set.")

    @Parameter(title: "Set Index") var setIndex: Int

    init() { self.setIndex = -1 }
    init(setIndex: Int) { self.setIndex = setIndex }

    func perform() async throws -> some IntentResult {
        await WorkoutLiveActivitySupport.mutate { state in
            guard state.exercises.indices.contains(state.currentIndex) else { return }
            var ex = state.exercises[state.currentIndex]
            let idx = setIndex >= 0 ? setIndex : ex.sets.count - 1
            guard ex.sets.indices.contains(idx) else { return }
            let current = ex.sets[idx].weight ?? 0
            ex.sets[idx].weight = min(9999, current + 5)
            state.exercises[state.currentIndex] = ex
        }
        return .result()
    }
}

// MARK: - Decrement weight (by 5 lb)

@available(iOS 17.0, *)
struct WorkoutDecrementWeightIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Remove Weight"
    static var description = IntentDescription("Subtract 5 lb from the current set. Drops to bodyweight at 0.")

    @Parameter(title: "Set Index") var setIndex: Int

    init() { self.setIndex = -1 }
    init(setIndex: Int) { self.setIndex = setIndex }

    func perform() async throws -> some IntentResult {
        await WorkoutLiveActivitySupport.mutate { state in
            guard state.exercises.indices.contains(state.currentIndex) else { return }
            var ex = state.exercises[state.currentIndex]
            let idx = setIndex >= 0 ? setIndex : ex.sets.count - 1
            guard ex.sets.indices.contains(idx) else { return }
            let current = ex.sets[idx].weight ?? 0
            let next = current - 5
            // 0 drops to nil (= bodyweight); negative is clamped to nil.
            ex.sets[idx].weight = next <= 0 ? nil : next
            state.exercises[state.currentIndex] = ex
        }
        return .result()
    }
}

// MARK: - Pause

@available(iOS 17.0, *)
struct WorkoutPauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Workout"
    static var description = IntentDescription("Pause the workout timer.")

    init() {}

    func perform() async throws -> some IntentResult {
        await WorkoutLiveActivitySupport.mutate { state in
            guard state.pausedAt == nil else { return }
            state.pausedAt = Date()
        }
        return .result()
    }
}

// MARK: - Toggle pause / resume

/// Unified pause/resume toggle. Using a single intent on the pause button
/// avoids re-swapping the `Button(intent:)` instance every time the state
/// flips, which was leaving taps unhandled on some devices.
@available(iOS 17.0, *)
struct WorkoutTogglePauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause or Resume Workout"
    static var description = IntentDescription("Toggle the workout timer between paused and running.")

    init() {}

    func perform() async throws -> some IntentResult {
        await WorkoutLiveActivitySupport.mutate { state in
            if let paused = state.pausedAt {
                state.accumulatedPaused += Date().timeIntervalSince(paused)
                state.pausedAt = nil
            } else {
                state.pausedAt = Date()
            }
        }
        return .result()
    }
}

// MARK: - Resume

@available(iOS 17.0, *)
struct WorkoutResumeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume Workout"
    static var description = IntentDescription("Resume the paused workout timer.")

    init() {}

    func perform() async throws -> some IntentResult {
        await WorkoutLiveActivitySupport.mutate { state in
            guard let paused = state.pausedAt else { return }
            state.accumulatedPaused += Date().timeIntervalSince(paused)
            state.pausedAt = nil
        }
        return .result()
    }
}

// MARK: - End workout

@available(iOS 17.0, *)
struct WorkoutEndIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "End Workout"
    static var description = IntentDescription("Stop the workout and hand the exercise list to the Log a Workout screen.")

    /// `true` tells the system to open the containing app after the intent
    /// finishes so the Log a Workout sheet can scoop up the state.
    static var openAppWhenRun: Bool = true

    init() {}

    func perform() async throws -> some IntentResult {
        await WorkoutLiveActivitySupport.mutate { state in
            // If we're ending from a paused state, bake the current pause
            // into accumulatedPaused so elapsed calculations are final.
            if let paused = state.pausedAt {
                state.accumulatedPaused += Date().timeIntervalSince(paused)
                state.pausedAt = nil
            }
            state.isFinished = true
        }
        return .result()
    }
}

// MARK: - Cardio: lap / next segment

@available(iOS 17.0, *)
struct WorkoutCardioLapIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Lap"
    static var description = IntentDescription("Snap a lap and add a fresh segment to the cardio workout.")

    init() {}

    func perform() async throws -> some IntentResult {
        await WorkoutLiveActivitySupport.mutate { state in
            let template = state.segments.last
            state.segments.append(
                WorkoutActivityAttributes.LiveCardioSegment(
                    label:           "Segment \(state.segments.count + 1)",
                    durationSeconds: 0,
                    distanceMiles:   template?.distanceMiles == nil ? nil : 0
                )
            )
            state.currentIndex = state.segments.count - 1
        }
        return .result()
    }
}

@available(iOS 17.0, *)
struct WorkoutCardioNextSegmentIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Next Segment"
    static var description = IntentDescription("Advance to the next cardio segment.")

    init() {}

    func perform() async throws -> some IntentResult {
        await WorkoutLiveActivitySupport.mutate { state in
            if state.currentIndex >= state.segments.count - 1 {
                state.segments.append(
                    WorkoutActivityAttributes.LiveCardioSegment(
                        label:           "Segment \(state.segments.count + 1)",
                        durationSeconds: 0
                    )
                )
            }
            state.currentIndex = min(state.currentIndex + 1, state.segments.count - 1)
        }
        return .result()
    }
}

// MARK: - HIIT: advance round, toggle work/rest

@available(iOS 17.0, *)
struct WorkoutHIITNextRoundIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Next Round"
    static var description = IntentDescription("Advance to the next round of the current HIIT block.")

    init() {}

    func perform() async throws -> some IntentResult {
        await WorkoutLiveActivitySupport.mutate { state in
            guard state.rounds.indices.contains(state.currentIndex) else { return }
            var block = state.rounds[state.currentIndex]
            if block.currentRound >= block.rounds {
                // Last round of this block — advance to next block if any.
                state.currentIndex = min(state.currentIndex + 1, state.rounds.count - 1)
            } else {
                block.currentRound += 1
                block.inRest        = false
                state.rounds[state.currentIndex] = block
            }
        }
        return .result()
    }
}

@available(iOS 17.0, *)
struct WorkoutHIITTogglePhaseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Toggle Work / Rest"
    static var description = IntentDescription("Flip between the work and rest phase of the current HIIT round.")

    init() {}

    func perform() async throws -> some IntentResult {
        await WorkoutLiveActivitySupport.mutate { state in
            guard state.rounds.indices.contains(state.currentIndex) else { return }
            state.rounds[state.currentIndex].inRest.toggle()
        }
        return .result()
    }
}

// MARK: - Yoga: next pose

@available(iOS 17.0, *)
struct WorkoutYogaNextPoseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Next Pose"
    static var description = IntentDescription("Advance to the next yoga pose.")

    init() {}

    func perform() async throws -> some IntentResult {
        await WorkoutLiveActivitySupport.mutate { state in
            if state.currentIndex >= state.poses.count - 1 {
                state.poses.append(
                    WorkoutActivityAttributes.LivePose(name: "", holdSeconds: 0)
                )
            }
            state.currentIndex = min(state.currentIndex + 1, state.poses.count - 1)
        }
        return .result()
    }
}
