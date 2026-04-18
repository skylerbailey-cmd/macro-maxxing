//
//  WorkoutLiveActivity.swift
//  WellnessWidgets
//
//  Interactive workout Live Activity. Shown on the lock screen and Dynamic
//  Island while a workout is in progress. The lock-screen banner exposes
//  +/- buttons for reps, an Add Set button, a Next Exercise arrow, and an
//  End Workout button. All of these are `LiveActivityIntent`s that mutate
//  the activity's ContentState in place (see WorkoutLiveActivityIntents.swift).
//

import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Live Activity widget

struct WorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LockScreenView(state: context.state)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            let state = context.state
            let current = WorkoutActivityAttributes.currentExercise(in: state)
            let lastSetIndex = max(0, (current?.sets.count ?? 1) - 1)
            let reps = current?.sets.last?.reps ?? 0

            return DynamicIsland {
                // ── Expanded (long press) ──────────────────────────────────
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(state.workoutName.isEmpty ? "Workout" : state.workoutName)
                            .font(.system(size: 13, weight: .bold))
                            .lineLimit(1)
                        Text("Exercise \(state.currentIndex + 1) of \(max(state.exercises.count, 1))")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(timerInterval: state.startedAt...Date.distantFuture, countsDown: false)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.green)
                        Text("elapsed")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.center) {
                    if let ex = current, !ex.name.isEmpty {
                        Text(ex.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        repsControlBar(reps: reps, setNumber: lastSetIndex + 1, compact: true)
                        HStack(spacing: 8) {
                            compactActionButton(title: "Add Set",
                                                systemImage: "plus",
                                                intent: WorkoutAddSetIntent())
                            compactActionButton(title: "Next",
                                                systemImage: "arrow.right",
                                                intent: WorkoutNextExerciseIntent())
                            compactActionButton(title: "End",
                                                systemImage: "stop.fill",
                                                intent: WorkoutEndIntent(),
                                                tint: .red)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                }

            } compactLeading: {
                Text(timerInterval: state.startedAt...Date.distantFuture, countsDown: false)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.green)

            } compactTrailing: {
                Image(systemName: workoutIcon(for: state.workoutTypeRaw))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.green)

            } minimal: {
                Image(systemName: workoutIcon(for: state.workoutTypeRaw))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.green)
            }
            .widgetURL(URL(string: "wellness://live-workout"))
            .keylineTint(.green)
        }
    }
}

// MARK: - Shared control helpers

/// Horizontal `[-] N reps [+]` bar used on the lock screen + Dynamic Island.
@ViewBuilder
private func repsControlBar(reps: Int, setNumber: Int, compact: Bool) -> some View {
    HStack(spacing: compact ? 8 : 12) {
        Text("Set \(setNumber)")
            .font(.system(size: compact ? 11 : 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.55))
            .frame(minWidth: 44, alignment: .leading)

        Button(intent: WorkoutDecrementRepsIntent(setIndex: -1)) {
            Image(systemName: "minus")
                .font(.system(size: compact ? 14 : 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: compact ? 32 : 38, height: compact ? 32 : 38)
                .background(.white.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)

        VStack(spacing: 0) {
            Text("\(reps)")
                .font(.system(size: compact ? 20 : 26, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
            Text("reps")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)

        Button(intent: WorkoutIncrementRepsIntent(setIndex: -1)) {
            Image(systemName: "plus")
                .font(.system(size: compact ? 14 : 16, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: compact ? 32 : 38, height: compact ? 32 : 38)
                .background(.green, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

/// Pill button used in the expanded Dynamic Island bottom region.
@ViewBuilder
private func compactActionButton<I: AppIntent>(title: String,
                                               systemImage: String,
                                               intent: I,
                                               tint: Color = .white) -> some View {
    Button(intent: intent) {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .bold))
            Text(title)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(tint == .red ? .white : .white)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background((tint == .red ? Color.red.opacity(0.85) : Color.white.opacity(0.14)),
                    in: Capsule())
    }
    .buttonStyle(.plain)
}

// MARK: - Helpers

/// Maps a WorkoutType raw value to its SF Symbol without importing MacroAdjustmentEngine.
private func workoutIcon(for rawValue: String) -> String {
    switch rawValue {
    case "Strength":         return "dumbbell.fill"
    case "Cardio":           return "figure.run"
    case "HIIT":             return "bolt.heart.fill"
    case "Flexibility / Yoga": return "figure.flexibility"
    case "Rest Day":         return "moon.zzz.fill"
    default:                 return "figure.mixed.cardio"
    }
}

// MARK: - Lock Screen banner

private struct LockScreenView: View {
    let state: WorkoutActivityAttributes.ContentState

    private var current: WorkoutActivityAttributes.LiveExercise? {
        WorkoutActivityAttributes.currentExercise(in: state)
    }

    private var lastSetIndex: Int {
        max(0, (current?.sets.count ?? 1) - 1)
    }

    private var reps: Int {
        current?.sets.last?.reps ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: icon + name + timer
            HStack(spacing: 12) {
                Image(systemName: workoutIcon(for: state.workoutTypeRaw))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.green)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(state.workoutName.isEmpty ? "Live Workout" : state.workoutName)
                        .font(.system(size: 15, weight: .bold))
                        .lineLimit(1)
                    Text("Exercise \(state.currentIndex + 1) of \(max(state.exercises.count, 1))")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.60))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(timerInterval: state.startedAt...Date.distantFuture, countsDown: false)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.green)
                    Text("elapsed")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.50))
                }
            }

            // Current exercise name
            Text(current?.name.isEmpty == false ? current!.name : "Tap Next to start an exercise")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(current?.name.isEmpty == false ? .white : .white.opacity(0.50))
                .lineLimit(1)

            // Reps control bar
            repsControlBar(reps: reps, setNumber: lastSetIndex + 1, compact: false)
                .padding(10)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))

            // Action buttons
            HStack(spacing: 10) {
                Button(intent: WorkoutAddSetIntent()) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add Set")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button(intent: WorkoutNextExerciseIntent()) {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.green, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }

            Button(intent: WorkoutEndIntent()) {
                HStack(spacing: 6) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("End Workout")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(.black)
        .foregroundStyle(.white)
    }
}

// MARK: - Widget bundle

@main
struct WellnessWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivityWidget()
    }
}
