//
//  WorkoutLiveActivity.swift
//  WellnessWidgets
//
//  Interactive workout Live Activity. Shown on the lock screen and Dynamic
//  Island while a workout is in progress. The lock-screen banner stacks
//  every set of the current exercise, with reps and weight +/- controls on
//  the latest set. A pause/resume toggle freezes the elapsed timer, an
//  Add Set button appends a new row, a Next arrow advances the exercise,
//  and an End Workout button hands state back to the Log a Workout sheet.
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
                    HStack(spacing: 6) {
                        pauseButton(isPaused: state.isPaused, compact: true)
                        timerLabel(state: state, compact: true)
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
                    VStack(spacing: 6) {
                        stackedSetList(sets:    current?.sets ?? [],
                                       current: lastSetIndex,
                                       compact: true)
                        HStack(spacing: 6) {
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
                // Compact timer — freezes when paused.
                timerLabel(state: state, compact: true)

            } compactTrailing: {
                Image(systemName: state.isPaused
                                  ? "pause.fill"
                                  : workoutIcon(for: state.workoutTypeRaw))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(state.isPaused ? .yellow : .green)

            } minimal: {
                Image(systemName: state.isPaused
                                  ? "pause.fill"
                                  : workoutIcon(for: state.workoutTypeRaw))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(state.isPaused ? .yellow : .green)
            }
            .widgetURL(URL(string: "wellness://live-workout"))
            .keylineTint(state.isPaused ? .yellow : .green)
        }
    }
}

// MARK: - Timer label

/// Elapsed timer. Runs live when the workout is active; freezes at a static
/// value while paused.
@ViewBuilder
private func timerLabel(state: WorkoutActivityAttributes.ContentState,
                        compact: Bool) -> some View {
    if state.isPaused {
        Text(formatted(seconds: state.elapsedSeconds()))
            .font(.system(size: compact ? 14 : 20, weight: .black, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.yellow)
    } else {
        Text(timerInterval: state.effectiveStart...Date.distantFuture, countsDown: false)
            .font(.system(size: compact ? 14 : 20, weight: .black, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.green)
    }
}

private func formatted(seconds: Int) -> String {
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    let s = seconds % 60
    return h > 0
        ? String(format: "%d:%02d:%02d", h, m, s)
        : String(format: "%02d:%02d", m, s)
}

// MARK: - Pause / resume button

@ViewBuilder
private func pauseButton(isPaused: Bool, compact: Bool) -> some View {
    let size: CGFloat = compact ? 28 : 36
    if isPaused {
        Button(intent: WorkoutResumeIntent()) {
            Image(systemName: "play.fill")
                .font(.system(size: compact ? 11 : 14, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: size, height: size)
                .background(.yellow, in: Circle())
        }
        .buttonStyle(.plain)
    } else {
        Button(intent: WorkoutPauseIntent()) {
            Image(systemName: "pause.fill")
                .font(.system(size: compact ? 11 : 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(.white.opacity(0.14), in: Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stacked set list

/// Renders every set of the current exercise as a row. Earlier sets are
/// shown read-only; the latest ("current") set has `−`/`+` controls for
/// reps and weight.
@ViewBuilder
private func stackedSetList(sets:    [WorkoutActivityAttributes.LiveSet],
                            current: Int,
                            compact: Bool) -> some View {
    VStack(spacing: compact ? 3 : 5) {
        ForEach(Array(sets.enumerated()), id: \.element.id) { idx, set in
            if idx == current {
                currentSetRow(setIndex: idx, set: set, compact: compact)
            } else {
                historicalSetRow(setIndex: idx, set: set, compact: compact)
            }
        }
    }
}

@ViewBuilder
private func historicalSetRow(setIndex: Int,
                              set: WorkoutActivityAttributes.LiveSet,
                              compact: Bool) -> some View {
    HStack(spacing: 6) {
        Text("Set \(setIndex + 1)")
            .font(.system(size: compact ? 10 : 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.50))
            .frame(width: compact ? 40 : 50, alignment: .leading)
        Text("\(set.reps) reps")
            .font(.system(size: compact ? 11 : 13, weight: .medium, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white.opacity(0.75))
            .frame(maxWidth: .infinity, alignment: .leading)
        Text(weightString(set.weight))
            .font(.system(size: compact ? 11 : 13, weight: .medium, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white.opacity(0.75))
    }
    .padding(.vertical, compact ? 2 : 4)
    .padding(.horizontal, compact ? 6 : 10)
    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
}

@ViewBuilder
private func currentSetRow(setIndex: Int,
                           set: WorkoutActivityAttributes.LiveSet,
                           compact: Bool) -> some View {
    HStack(spacing: compact ? 6 : 8) {
        Text("Set \(setIndex + 1)")
            .font(.system(size: compact ? 10 : 12, weight: .bold))
            .foregroundStyle(.green)
            .frame(width: compact ? 40 : 50, alignment: .leading)

        // Reps stepper
        HStack(spacing: compact ? 4 : 6) {
            Button(intent: WorkoutDecrementRepsIntent(setIndex: setIndex)) {
                stepperGlyph("minus", compact: compact, filled: false)
            }
            .buttonStyle(.plain)

            VStack(spacing: 0) {
                Text("\(set.reps)")
                    .font(.system(size: compact ? 14 : 18, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text("reps")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.40))
            }
            .frame(minWidth: compact ? 30 : 38)

            Button(intent: WorkoutIncrementRepsIntent(setIndex: setIndex)) {
                stepperGlyph("plus", compact: compact, filled: true)
            }
            .buttonStyle(.plain)
        }

        // Weight stepper
        HStack(spacing: compact ? 4 : 6) {
            Button(intent: WorkoutDecrementWeightIntent(setIndex: setIndex)) {
                stepperGlyph("minus", compact: compact, filled: false)
            }
            .buttonStyle(.plain)

            VStack(spacing: 0) {
                Text(weightString(set.weight))
                    .font(.system(size: compact ? 13 : 17, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text("weight")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.40))
            }
            .frame(minWidth: compact ? 40 : 54)

            Button(intent: WorkoutIncrementWeightIntent(setIndex: setIndex)) {
                stepperGlyph("plus", compact: compact, filled: true)
            }
            .buttonStyle(.plain)
        }
    }
    .padding(.vertical, compact ? 4 : 8)
    .padding(.horizontal, compact ? 6 : 10)
    .background(.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.green.opacity(0.35), lineWidth: 1))
}

private func stepperGlyph(_ systemName: String, compact: Bool, filled: Bool) -> some View {
    let size: CGFloat = compact ? 24 : 32
    return Image(systemName: systemName)
        .font(.system(size: compact ? 11 : 14, weight: .bold))
        .foregroundStyle(filled ? .black : .white)
        .frame(width: size, height: size)
        .background(filled ? Color.green : .white.opacity(0.12), in: Circle())
}

private func weightString(_ weight: Double?) -> String {
    guard let w = weight, w > 0 else { return "BW" }
    return w.truncatingRemainder(dividingBy: 1) == 0
        ? "\(Int(w)) lb"
        : "\(w) lb"
}

// MARK: - Button helper

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
        .foregroundStyle(.white)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: icon + name + pause + timer
            HStack(spacing: 10) {
                Image(systemName: workoutIcon(for: state.workoutTypeRaw))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.green)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 9))

                VStack(alignment: .leading, spacing: 1) {
                    Text(state.workoutName.isEmpty ? "Live Workout" : state.workoutName)
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)
                    Text("Exercise \(state.currentIndex + 1) of \(max(state.exercises.count, 1))")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.60))
                }

                Spacer()

                pauseButton(isPaused: state.isPaused, compact: false)
                VStack(alignment: .trailing, spacing: 1) {
                    timerLabel(state: state, compact: false)
                    Text(state.isPaused ? "paused" : "elapsed")
                        .font(.system(size: 10))
                        .foregroundStyle(state.isPaused ? .yellow.opacity(0.85) : .white.opacity(0.50))
                }
            }

            // Current exercise name (read-only — iOS doesn't allow text fields here)
            Text(current?.name.isEmpty == false ? current!.name : "Tap to edit in the app")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(current?.name.isEmpty == false ? .white : .white.opacity(0.50))
                .lineLimit(1)

            // Stacked set list
            stackedSetList(sets:    current?.sets ?? [],
                           current: lastSetIndex,
                           compact: false)

            // Action buttons
            HStack(spacing: 8) {
                Button(intent: WorkoutAddSetIntent()) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Add Set")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button(intent: WorkoutNextExerciseIntent()) {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(.green, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button(intent: WorkoutEndIntent()) {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("End")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
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
