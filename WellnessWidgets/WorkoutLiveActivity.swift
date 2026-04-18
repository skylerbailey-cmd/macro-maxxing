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

            return DynamicIsland {
                // ── Expanded (long press) ──────────────────────────────────
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(state.workoutName.isEmpty ? "Workout" : state.workoutName)
                            .font(.system(size: 13, weight: .bold))
                            .lineLimit(1)
                        Text(positionLabel(for: state))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    timerLabel(state: state, compact: true)
                        .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.center) {
                    if let name = currentItemName(for: state), !name.isEmpty {
                        Text(name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    perTypeBody(state: state, compact: true)
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

// MARK: - Per-type dispatch
//
// The popup UI is shaped around the workout's type. Each type gets its own
// action row + body; only the header (name + timer) is shared. The switch
// reads `state.workoutTypeRaw` (WorkoutType.rawValue) so the widget
// extension doesn't need to import MacroAdjustmentEngine.

private enum LiveWorkoutFlavor {
    case strength, cardio, hiit, yoga, other

    init(rawValue: String) {
        switch rawValue {
        case "Strength":            self = .strength
        case "Cardio":              self = .cardio
        case "HIIT":                self = .hiit
        case "Flexibility / Yoga":  self = .yoga
        default:                    self = .other
        }
    }
}

@ViewBuilder
private func perTypeBody(state: WorkoutActivityAttributes.ContentState,
                         compact: Bool) -> some View {
    switch LiveWorkoutFlavor(rawValue: state.workoutTypeRaw) {
    case .cardio:   cardioBody(state: state, compact: compact)
    case .hiit:     hiitBody(state: state, compact: compact)
    case .yoga:     yogaBody(state: state, compact: compact)
    case .strength, .other:
        strengthBody(state: state, compact: compact)
    }
}

/// Subtitle under the workout name — tells the user where they are in the
/// session in language that matches the active workout type.
private func positionLabel(for state: WorkoutActivityAttributes.ContentState) -> String {
    switch LiveWorkoutFlavor(rawValue: state.workoutTypeRaw) {
    case .cardio:
        return "Segment \(state.currentIndex + 1) of \(max(state.segments.count, 1))"
    case .hiit:
        if state.rounds.indices.contains(state.currentIndex) {
            let block = state.rounds[state.currentIndex]
            return "Block \(state.currentIndex + 1)/\(state.rounds.count) · Round \(block.currentRound)/\(block.rounds)"
        }
        return "Block \(state.currentIndex + 1) of \(max(state.rounds.count, 1))"
    case .yoga:
        return "Pose \(state.currentIndex + 1) of \(max(state.poses.count, 1))"
    case .strength, .other:
        return "Exercise \(state.currentIndex + 1) of \(max(state.exercises.count, 1))"
    }
}

/// Current item's label — rendered in the DI center region.
private func currentItemName(for state: WorkoutActivityAttributes.ContentState) -> String? {
    switch LiveWorkoutFlavor(rawValue: state.workoutTypeRaw) {
    case .cardio:
        return state.segments.indices.contains(state.currentIndex)
            ? state.segments[state.currentIndex].label
            : nil
    case .hiit:
        return state.rounds.indices.contains(state.currentIndex)
            ? state.rounds[state.currentIndex].name
            : nil
    case .yoga:
        return state.poses.indices.contains(state.currentIndex)
            ? state.poses[state.currentIndex].name
            : nil
    case .strength, .other:
        return WorkoutActivityAttributes.currentExercise(in: state)?.name
    }
}

// MARK: - Strength body

@ViewBuilder
private func strengthBody(state: WorkoutActivityAttributes.ContentState,
                          compact: Bool) -> some View {
    let current = WorkoutActivityAttributes.currentExercise(in: state)
    let lastSetIndex = max(0, (current?.sets.count ?? 1) - 1)
    VStack(spacing: compact ? 6 : 10) {
        actionRow(isPaused: state.isPaused, compact: compact)
        if let sets = current?.sets, sets.indices.contains(lastSetIndex) {
            currentSetRow(setIndex: lastSetIndex,
                          set:      sets[lastSetIndex],
                          compact:  compact)
        }
        pastSetsList(sets:    current?.sets ?? [],
                     current: lastSetIndex,
                     compact: compact)
    }
}

// MARK: - Cardio body

@ViewBuilder
private func cardioBody(state: WorkoutActivityAttributes.ContentState,
                        compact: Bool) -> some View {
    let current = state.segments.indices.contains(state.currentIndex)
        ? state.segments[state.currentIndex]
        : nil
    VStack(spacing: compact ? 6 : 10) {
        cardioActionRow(isPaused: state.isPaused, compact: compact)
        cardioStatsRow(segment: current, state: state, compact: compact)
        cardioSegmentList(state: state, compact: compact)
    }
}

@ViewBuilder
private func cardioActionRow(isPaused: Bool, compact: Bool) -> some View {
    HStack(spacing: compact ? 6 : 8) {
        pausePill(isPaused: isPaused, compact: compact)
        pillButton(title: "Lap",
                   systemImage: "flag.fill",
                   intent: WorkoutCardioLapIntent(),
                   tint: .white, compact: compact)
        pillButton(title: "Next",
                   systemImage: "arrow.right",
                   intent: WorkoutCardioNextSegmentIntent(),
                   tint: .green, compact: compact)
        pillButton(title: "End",
                   systemImage: "stop.fill",
                   intent: WorkoutEndIntent(),
                   tint: .red, compact: compact)
    }
}

@ViewBuilder
private func cardioStatsRow(segment: WorkoutActivityAttributes.LiveCardioSegment?,
                            state: WorkoutActivityAttributes.ContentState,
                            compact: Bool) -> some View {
    let totalDistance = state.segments.compactMap(\.distanceMiles).reduce(0, +)
    HStack(spacing: compact ? 8 : 14) {
        statTile(label: "Elapsed",
                 value: formatted(seconds: state.elapsedSeconds()),
                 tint:  .green, compact: compact)
        if totalDistance > 0 {
            statTile(label: "Distance",
                     value: distanceString(totalDistance),
                     tint:  .cyan, compact: compact)
        }
        if let seg = segment {
            statTile(label: "This Lap",
                     value: formatted(seconds: seg.durationSeconds),
                     tint:  .orange, compact: compact)
        }
    }
}

@ViewBuilder
private func cardioSegmentList(state: WorkoutActivityAttributes.ContentState,
                               compact: Bool) -> some View {
    if state.segments.count > 1 {
        VStack(spacing: compact ? 3 : 5) {
            ForEach(Array(state.segments.enumerated()), id: \.element.id) { idx, seg in
                HStack(spacing: 6) {
                    Text(seg.label.isEmpty ? "Segment \(idx + 1)" : seg.label)
                        .font(.system(size: compact ? 10 : 12,
                                      weight: idx == state.currentIndex ? .bold : .medium))
                        .foregroundStyle(idx == state.currentIndex ? .green : .white.opacity(0.70))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(formatted(seconds: seg.durationSeconds))
                        .font(.system(size: compact ? 10 : 12, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.70))
                    if let d = seg.distanceMiles, d > 0 {
                        Text(distanceString(d))
                            .font(.system(size: compact ? 10 : 12, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                .padding(.vertical, compact ? 2 : 4)
                .padding(.horizontal, compact ? 6 : 10)
                .background(idx == state.currentIndex
                            ? Color.green.opacity(0.15)
                            : Color.white.opacity(0.05),
                            in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// MARK: - HIIT body

@ViewBuilder
private func hiitBody(state: WorkoutActivityAttributes.ContentState,
                      compact: Bool) -> some View {
    let current = state.rounds.indices.contains(state.currentIndex)
        ? state.rounds[state.currentIndex]
        : nil
    VStack(spacing: compact ? 6 : 10) {
        hiitActionRow(isPaused: state.isPaused, compact: compact)
        if let block = current {
            hiitPhaseCard(block: block, compact: compact)
        }
    }
}

@ViewBuilder
private func hiitActionRow(isPaused: Bool, compact: Bool) -> some View {
    HStack(spacing: compact ? 6 : 8) {
        pausePill(isPaused: isPaused, compact: compact)
        pillButton(title: "Flip",
                   systemImage: "arrow.triangle.2.circlepath",
                   intent: WorkoutHIITTogglePhaseIntent(),
                   tint: .white, compact: compact)
        pillButton(title: "Skip",
                   systemImage: "forward.fill",
                   intent: WorkoutHIITNextRoundIntent(),
                   tint: .orange, compact: compact)
        pillButton(title: "End",
                   systemImage: "stop.fill",
                   intent: WorkoutEndIntent(),
                   tint: .red, compact: compact)
    }
}

@ViewBuilder
private func hiitPhaseCard(block: WorkoutActivityAttributes.LiveHIITRound,
                           compact: Bool) -> some View {
    let phaseLabel = block.inRest ? "REST" : "WORK"
    let phaseTint: Color = block.inRest ? .cyan : .orange
    let phaseSeconds = block.inRest ? block.restSeconds : block.workSeconds
    HStack(spacing: compact ? 10 : 14) {
        Text(phaseLabel)
            .font(.system(size: compact ? 11 : 13, weight: .black))
            .foregroundStyle(.black)
            .padding(.horizontal, compact ? 10 : 12)
            .padding(.vertical, compact ? 6 : 8)
            .background(phaseTint, in: Capsule())

        VStack(alignment: .leading, spacing: 1) {
            Text("Round \(block.currentRound) / \(block.rounds)")
                .font(.system(size: compact ? 11 : 13, weight: .bold))
                .foregroundStyle(.white)
            Text("\(phaseSeconds) sec")
                .font(.system(size: compact ? 18 : 24, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(phaseTint)
        }
        Spacer()
    }
    .padding(compact ? 8 : 12)
    .background(phaseTint.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
    .overlay(RoundedRectangle(cornerRadius: 10).stroke(phaseTint.opacity(0.35), lineWidth: 1))
}

// MARK: - Yoga body

@ViewBuilder
private func yogaBody(state: WorkoutActivityAttributes.ContentState,
                      compact: Bool) -> some View {
    let current = state.poses.indices.contains(state.currentIndex)
        ? state.poses[state.currentIndex]
        : nil
    VStack(spacing: compact ? 6 : 10) {
        yogaActionRow(isPaused: state.isPaused, compact: compact)
        if let pose = current {
            yogaPoseCard(pose: pose, compact: compact)
        }
    }
}

@ViewBuilder
private func yogaActionRow(isPaused: Bool, compact: Bool) -> some View {
    HStack(spacing: compact ? 6 : 8) {
        pausePill(isPaused: isPaused, compact: compact)
        pillButton(title: "Next Pose",
                   systemImage: "arrow.right",
                   intent: WorkoutYogaNextPoseIntent(),
                   tint: .mint, compact: compact)
        pillButton(title: "End",
                   systemImage: "stop.fill",
                   intent: WorkoutEndIntent(),
                   tint: .red, compact: compact)
    }
}

@ViewBuilder
private func yogaPoseCard(pose: WorkoutActivityAttributes.LivePose,
                          compact: Bool) -> some View {
    HStack(spacing: compact ? 10 : 14) {
        Image(systemName: "figure.flexibility")
            .font(.system(size: compact ? 18 : 24, weight: .bold))
            .foregroundStyle(.mint)
        VStack(alignment: .leading, spacing: 1) {
            Text(pose.name.isEmpty ? "Current Pose" : pose.name)
                .font(.system(size: compact ? 13 : 15, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
            if pose.holdSeconds > 0 {
                Text("Hold \(pose.holdSeconds) sec")
                    .font(.system(size: compact ? 11 : 13, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.65))
            } else {
                Text("Flow")
                    .font(.system(size: compact ? 11 : 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        Spacer()
    }
    .padding(compact ? 8 : 12)
    .background(Color.mint.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mint.opacity(0.35), lineWidth: 1))
}

// MARK: - Shared chrome

@ViewBuilder
private func pausePill(isPaused: Bool, compact: Bool) -> some View {
    Button(intent: WorkoutTogglePauseIntent()) {
        HStack(spacing: 4) {
            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                .font(.system(size: compact ? 10 : 11, weight: .bold))
            if !compact {
                Text(isPaused ? "Resume" : "Pause")
                    .font(.system(size: 12, weight: .semibold))
            }
        }
        .foregroundStyle(isPaused ? .black : .white)
        .padding(.vertical, compact ? 6 : 9)
        .padding(.horizontal, compact ? 10 : 0)
        .frame(maxWidth: .infinity)
        .background(isPaused ? Color.yellow : Color.white.opacity(0.14),
                    in: RoundedRectangle(cornerRadius: compact ? 14 : 10))
    }
    .buttonStyle(.plain)
}

@ViewBuilder
private func pillButton<I: AppIntent>(title: String,
                                      systemImage: String,
                                      intent: I,
                                      tint: Color,
                                      compact: Bool) -> some View {
    let bg: Color = {
        switch tint {
        case .red:    return Color.red.opacity(0.85)
        case .green:  return Color.green
        case .orange: return Color.orange.opacity(0.90)
        case .mint:   return Color.mint.opacity(0.90)
        default:      return Color.white.opacity(0.14)
        }
    }()
    let fg: Color = (tint == .red || tint == .green || tint == .orange || tint == .mint) ? .black : .white
    Button(intent: intent) {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: compact ? 10 : 11, weight: .bold))
            if !compact {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
        }
        .foregroundStyle(fg)
        .padding(.vertical, compact ? 6 : 9)
        .padding(.horizontal, compact ? 10 : 0)
        .frame(maxWidth: .infinity)
        .background(bg, in: RoundedRectangle(cornerRadius: compact ? 14 : 10))
    }
    .buttonStyle(.plain)
}

@ViewBuilder
private func statTile(label: String, value: String, tint: Color, compact: Bool) -> some View {
    VStack(spacing: 1) {
        Text(value)
            .font(.system(size: compact ? 14 : 20, weight: .black, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        Text(label.uppercased())
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.white.opacity(0.45))
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, compact ? 6 : 10)
    .padding(.horizontal, compact ? 6 : 10)
    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
}

private func distanceString(_ miles: Double) -> String {
    miles.truncatingRemainder(dividingBy: 1) == 0
        ? "\(Int(miles)) mi"
        : String(format: "%.2f mi", miles)
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

// MARK: - Past sets list

/// Read-only list of every set EXCEPT the current one, rendered below the
/// action row / editable current set. Preserves natural order (Set 1, 2…)
/// but skips whichever index is flagged as current.
@ViewBuilder
private func pastSetsList(sets:    [WorkoutActivityAttributes.LiveSet],
                          current: Int,
                          compact: Bool) -> some View {
    let past = Array(sets.enumerated()).filter { $0.offset != current }.reversed()
    if !past.isEmpty {
        VStack(spacing: compact ? 3 : 5) {
            ForEach(past, id: \.element.id) { idx, set in
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
                    .contentTransition(.numericText())
                    .transaction { $0.animation = .spring(duration: 0.12) }
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
                    .contentTransition(.numericText())
                    .transaction { $0.animation = .spring(duration: 0.12) }
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

// MARK: - Action row (pause + add set + next + end)

/// Top-of-popup row containing every control that should stay reachable
/// regardless of how many past sets are listed below. Uses the unified
/// pause/resume toggle intent so a single tap flips pause state.
@ViewBuilder
private func actionRow(isPaused: Bool, compact: Bool) -> some View {
    HStack(spacing: compact ? 6 : 8) {
        Button(intent: WorkoutTogglePauseIntent()) {
            HStack(spacing: 4) {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: compact ? 10 : 11, weight: .bold))
                if !compact {
                    Text(isPaused ? "Resume" : "Pause")
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .foregroundStyle(isPaused ? .black : .white)
            .padding(.vertical, compact ? 6 : 9)
            .padding(.horizontal, compact ? 10 : 0)
            .frame(maxWidth: .infinity)
            .background(isPaused ? Color.yellow : Color.white.opacity(0.14),
                        in: RoundedRectangle(cornerRadius: compact ? 14 : 10))
        }
        .buttonStyle(.plain)

        if compact {
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
        } else {
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: icon + name + timer
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
                    Text(positionLabel(for: state))
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.60))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    timerLabel(state: state, compact: false)
                    Text(state.isPaused ? "paused" : "elapsed")
                        .font(.system(size: 10))
                        .foregroundStyle(state.isPaused ? .yellow.opacity(0.85) : .white.opacity(0.50))
                }
            }

            // Current item label (exercise / segment / round / pose) —
            // read-only; iOS doesn't allow text fields in Live Activities.
            if let label = currentItemName(for: state), !label.isEmpty {
                Text(label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            } else {
                Text("Tap to edit in the app")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.50))
                    .lineLimit(1)
            }

            // Per-type body (actions on top, history below) handles the
            // rest of the layout.
            perTypeBody(state: state, compact: false)
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
