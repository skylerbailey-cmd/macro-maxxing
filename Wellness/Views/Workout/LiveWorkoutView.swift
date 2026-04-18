//
//  LiveWorkoutView.swift
//  Wellness
//
//  Live, in-session workout tracker. Launched from `LogWorkoutSheet` via
//  the "Start Workout" button. Lets the user step through one exercise at a
//  time — set name, add sets with reps/weight — and ticks a live elapsed
//  timer. Tapping "End Workout" returns the collected exercises, the
//  (possibly updated) workout name, and the elapsed duration to the parent
//  sheet so the Log a Workout form is pre-populated.
//

import SwiftUI
import Combine
import ActivityKit

struct LiveWorkoutView: View {

    // MARK: - Inputs

    let initialWorkoutName: String
    let initialWorkoutType: WorkoutType
    let initialExercises:   [Exercise]
    /// Returned on End Workout with: workout name, exercises, elapsed minutes,
    /// and the moment the session started. Parent decides how to merge.
    let onFinish: (_ workoutName: String,
                   _ exercises: [Exercise],
                   _ elapsedMinutes: Int,
                   _ startedAt: Date) -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - Session state

    @State private var workoutName:  String
    @State private var exercises:    [Exercise]
    @State private var currentIndex: Int = 0

    /// The instant the user tapped "Start Workout". Drives both the live
    /// timer and the auto-computed duration sent back to the parent.
    @State private var startedAt: Date = Date()
    @State private var now:       Date = Date()
    @State private var showingEndConfirm = false

    /// Handle to the running Live Activity (nil if ActivityKit is unavailable
    /// or the user has denied Live Activity permission).
    @State private var liveActivity: Activity<WorkoutActivityAttributes>?

    /// Fires once per second to refresh the live elapsed-time label.
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Colors

    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var accent: Color { ThemeStore.shared.accent }

    // MARK: - Init

    init(initialWorkoutName: String,
         initialWorkoutType: WorkoutType = .strength,
         initialExercises:   [Exercise],
         onFinish: @escaping (_ workoutName: String,
                              _ exercises: [Exercise],
                              _ elapsedMinutes: Int,
                              _ startedAt: Date) -> Void) {
        self.initialWorkoutName = initialWorkoutName
        self.initialWorkoutType = initialWorkoutType
        self.initialExercises   = initialExercises
        self.onFinish           = onFinish
        // Seed with the passed-in list, or a single empty exercise so the
        // first screen already has a row ready to edit.
        let seed = initialExercises.isEmpty
            ? [Exercise(name: "", sets: [ExerciseSet(reps: 10)])]
            : initialExercises
        _workoutName = State(initialValue: initialWorkoutName)
        _exercises   = State(initialValue: seed)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        elapsedCard
                        workoutNameField
                        exerciseNavigator
                        currentExerciseCard
                        endWorkoutButton
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Live Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        endLiveActivity()
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.65))
                }
            }
            .preferredColorScheme(.dark)
            .onAppear { startLiveActivity() }
            .onReceive(timer) { tick in
                now = tick
                updateLiveActivity()
            }
            .alert("End Workout?", isPresented: $showingEndConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("End Workout") { finish() }
            } message: {
                Text("This will return to the log screen with your exercises and duration filled in.")
            }
            .keyboardDoneToolbar()
        }
    }

    // MARK: - Elapsed time

    private var elapsedCard: some View {
        VStack(spacing: 4) {
            Text("Elapsed")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
            Text(elapsedString)
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.25), lineWidth: 1))
    }

    private var elapsedString: String {
        let seconds = max(0, Int(now.timeIntervalSince(startedAt)))
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }

    private var elapsedMinutes: Int {
        max(1, Int((now.timeIntervalSince(startedAt) / 60.0).rounded()))
    }

    // MARK: - Workout name

    private var workoutNameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Workout Name")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
            TextField("e.g. Upper Body, Leg Day", text: $workoutName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .padding(12)
                .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.20), lineWidth: 1))
        }
    }

    // MARK: - Exercise navigator

    private var exerciseNavigator: some View {
        HStack(spacing: 10) {
            Button { goPrevious() } label: {
                navArrow(systemName: "chevron.left", enabled: currentIndex > 0)
            }
            .buttonStyle(.plain)
            .disabled(currentIndex <= 0)

            VStack(spacing: 2) {
                Text("Exercise \(currentIndex + 1) of \(exercises.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text(currentIndex == exercises.count - 1
                     ? "Tap → to start the next one"
                     : "Tap ← / → to switch")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .frame(maxWidth: .infinity)

            Button { goNext() } label: {
                navArrow(systemName: "chevron.right", enabled: true)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 1))
    }

    private func navArrow(systemName: String, enabled: Bool) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(enabled ? .black : .white.opacity(0.30))
            .frame(width: 44, height: 44)
            .background(enabled ? accent : cardBg, in: Circle())
            .overlay(Circle().stroke(enabled ? .clear : .white.opacity(0.10), lineWidth: 1))
    }

    private func goPrevious() {
        guard currentIndex > 0 else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            currentIndex -= 1
        }
    }

    /// Advance to the next exercise, appending a fresh one if we're on the
    /// last. New exercises inherit the reps (and weight) of the previous
    /// exercise's final set, mirroring the Add Set behavior in the log sheet.
    private func goNext() {
        if currentIndex >= exercises.count - 1 {
            let template = exercises[currentIndex].sets.last
            let seedSet = ExerciseSet(reps: template?.reps ?? 10, weight: template?.weight)
            exercises.append(Exercise(name: "", sets: [seedSet]))
        }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            currentIndex = min(currentIndex + 1, exercises.count - 1)
        }
    }

    // MARK: - Current exercise card

    private var currentExerciseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                TextField("Exercise name", text: $exercises[currentIndex].name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(pageBg, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.08), lineWidth: 1))

                if exercises.count > 1 {
                    Button { deleteCurrentExercise() } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.55))
                            .padding(12)
                            .background(pageBg, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.08), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Column headers
            HStack(spacing: 8) {
                Text("Set")
                    .frame(width: 40, alignment: .leading)
                Text("Reps")
                    .frame(width: 64, alignment: .center)
                Text("Weight (lb)")
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer().frame(width: 28)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white.opacity(0.40))

            VStack(spacing: 6) {
                ForEach(Array(exercises[currentIndex].sets.enumerated()), id: \.element.id) { idx, _ in
                    setRow(setIndex: idx)
                }
            }

            Button { addSet() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Add Set")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(accent.opacity(0.30), style: StrokeStyle(lineWidth: 1, dash: [4])))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.20), lineWidth: 1))
    }

    private func setRow(setIndex: Int) -> some View {
        let repsBinding = Binding<String>(
            get: { String(exercises[currentIndex].sets[setIndex].reps) },
            set: { newVal in
                if let n = Int(newVal.filter { $0.isNumber }), n > 0 {
                    exercises[currentIndex].sets[setIndex].reps = n
                } else if newVal.isEmpty {
                    exercises[currentIndex].sets[setIndex].reps = 0
                }
            }
        )
        let weightBinding = Binding<String>(
            get: {
                if let w = exercises[currentIndex].sets[setIndex].weight {
                    return w.truncatingRemainder(dividingBy: 1) == 0
                        ? String(Int(w)) : String(w)
                }
                return ""
            },
            set: { newVal in
                let t = newVal.trimmingCharacters(in: .whitespaces)
                if t.isEmpty {
                    exercises[currentIndex].sets[setIndex].weight = nil
                } else if let d = Double(t) {
                    exercises[currentIndex].sets[setIndex].weight = d
                }
            }
        )

        return HStack(spacing: 8) {
            Text("\(setIndex + 1)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 40, alignment: .leading)

            TextField("10", text: repsBinding)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 64)
                .padding(.vertical, 10)
                .background(pageBg, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.08), lineWidth: 1))

            TextField("lb", text: weightBinding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(pageBg, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.08), lineWidth: 1))

            Button {
                guard exercises[currentIndex].sets.count > 1 else { return }
                exercises[currentIndex].sets.remove(at: setIndex)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(exercises[currentIndex].sets.count > 1 ? 0.35 : 0.15))
                    .frame(width: 28)
            }
            .buttonStyle(.plain)
            .disabled(exercises[currentIndex].sets.count <= 1)
        }
    }

    private func addSet() {
        let template = exercises[currentIndex].sets.last
        exercises[currentIndex].sets.append(
            ExerciseSet(reps: template?.reps ?? 10, weight: template?.weight)
        )
    }

    private func deleteCurrentExercise() {
        guard exercises.count > 1 else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            exercises.remove(at: currentIndex)
            currentIndex = min(currentIndex, exercises.count - 1)
        }
    }

    // MARK: - End workout

    private var endWorkoutButton: some View {
        Button { showingEndConfirm = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "stop.fill")
                Text("End Workout")
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(accent, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    /// Hand the session data back to the parent and dismiss. Empty exercises
    /// (blank name) are dropped; empty set lists are normalized like the log
    /// sheet does on save.
    // MARK: - Live Activity

    private func liveActivityState() -> WorkoutActivityAttributes.ContentState {
        let liveExercises = exercises.map { ex in
            WorkoutActivityAttributes.LiveExercise(
                id:   ex.id,
                name: ex.name.trimmingCharacters(in: .whitespaces),
                sets: ex.sets.map {
                    WorkoutActivityAttributes.LiveSet(id: $0.id, reps: $0.reps, weight: $0.weight)
                }
            )
        }
        return WorkoutActivityAttributes.ContentState(
            workoutName:    workoutName.trimmingCharacters(in: .whitespaces),
            workoutTypeRaw: initialWorkoutType.rawValue,
            startedAt:      startedAt,
            currentIndex:   max(0, min(currentIndex, max(0, exercises.count - 1))),
            exercises:      liveExercises,
            isFinished:     false
        )
    }

    private func startLiveActivity() {
        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            print("[LiveActivity] areActivitiesEnabled = false — check Settings > Wellness > Live Activities")
            return
        }
        let state = liveActivityState()
        do {
            liveActivity = try Activity<WorkoutActivityAttributes>.request(
                attributes: WorkoutActivityAttributes(),
                content: .init(state: state, staleDate: nil)
            )
            print("[LiveActivity] started: \(liveActivity?.id ?? "nil")")
        } catch {
            print("[LiveActivity] request failed: \(error)")
        }
    }

    private func updateLiveActivity() {
        guard let activity = liveActivity else { return }
        let state = liveActivityState()
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    private func endLiveActivity() {
        guard let activity = liveActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        liveActivity = nil
    }

    // MARK: - Finish

    private func finish() {
        endLiveActivity()
        let cleaned: [Exercise] = exercises.compactMap { ex in
            let trimmed = ex.name.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            let normalized = ex.sets.isEmpty
                ? [ExerciseSet(reps: 1)]
                : ex.sets.map { ExerciseSet(id: $0.id, reps: max(1, $0.reps), weight: $0.weight) }
            return Exercise(id: ex.id, name: trimmed, sets: normalized)
        }
        onFinish(workoutName.trimmingCharacters(in: .whitespaces),
                 cleaned,
                 elapsedMinutes,
                 startedAt)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    LiveWorkoutView(initialWorkoutName: "", initialExercises: []) { _, _, _, _ in }
}
