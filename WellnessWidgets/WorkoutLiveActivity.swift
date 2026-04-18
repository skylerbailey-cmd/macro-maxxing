//
//  WorkoutLiveActivity.swift
//  WellnessWidgets
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Live Activity widget

struct WorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // ── Expanded (long press) ──────────────────────────────────
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: workoutIcon(for: context.state.workoutTypeRaw))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(context.state.workoutName.isEmpty ? "Workout" : context.state.workoutName)
                                .font(.system(size: 13, weight: .bold))
                                .lineLimit(1)
                            Text("Exercise \(context.state.exerciseNumber) of \(context.state.totalExercises)")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(timerInterval: context.state.startedAt...Date.distantFuture, countsDown: false)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.green)
                        Text("elapsed")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        if !context.state.currentExercise.isEmpty {
                            Text(context.state.currentExercise)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        // Set rows
                        let sets = context.state.sets
                        if !sets.isEmpty {
                            HStack(spacing: 0) {
                                Text("Set")
                                    .frame(width: 36, alignment: .leading)
                                Text("Reps")
                                    .frame(width: 50, alignment: .center)
                                Text("Weight")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)

                            ForEach(Array(sets.enumerated()), id: \.offset) { idx, set in
                                HStack(spacing: 0) {
                                    Text("\(idx + 1)")
                                        .frame(width: 36, alignment: .leading)
                                        .foregroundStyle(.secondary)
                                    Text("\(set.reps)")
                                        .frame(width: 50, alignment: .center)
                                        .foregroundStyle(.white)
                                    if let w = set.weight {
                                        Text(w.truncatingRemainder(dividingBy: 1) == 0
                                             ? "\(Int(w)) lb" : "\(w) lb")
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .foregroundStyle(.white)
                                    } else {
                                        Text("BW")
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .monospacedDigit()
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                }

            } compactLeading: {
                Text(timerInterval: context.state.startedAt...Date.distantFuture, countsDown: false)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.green)

            } compactTrailing: {
                Image(systemName: workoutIcon(for: context.state.workoutTypeRaw))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.green)

            } minimal: {
                Image(systemName: workoutIcon(for: context.state.workoutTypeRaw))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.green)
            }
            .widgetURL(URL(string: "wellness://live-workout"))
            .keylineTint(.green)
        }
    }
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
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: icon + name + timer
            HStack(spacing: 12) {
                Image(systemName: workoutIcon(for: context.state.workoutTypeRaw))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.green)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.workoutName.isEmpty ? "Live Workout" : context.state.workoutName)
                        .font(.system(size: 15, weight: .bold))
                        .lineLimit(1)
                    Text("Exercise \(context.state.exerciseNumber) of \(context.state.totalExercises)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(timerInterval: context.state.startedAt...Date.distantFuture, countsDown: false)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.green)
                    Text("elapsed")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            // Divider
            Rectangle()
                .fill(.white.opacity(0.10))
                .frame(height: 1)

            // Current exercise name
            if !context.state.currentExercise.isEmpty {
                Text(context.state.currentExercise)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(16)
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
