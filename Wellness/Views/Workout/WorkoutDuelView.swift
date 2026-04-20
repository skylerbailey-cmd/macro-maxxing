//
//  WorkoutDuelView.swift
//  Wellness
//
//  Shown in the "Duel" sub-tab of FoodLogView.
//

import SwiftUI

struct WorkoutDuelView: View {

    let userID:              String
    let selectedDate:        Date
    let isToday:             Bool
    let bodyWeightLbs:       Double
    let autoAdjustByDefault: Bool
    let userSettings:        UserSettings

    @State private var entries:          [WorkoutEntry] = []
    @State private var isLoading         = false
    @State private var showingRestDayConfirm = false
    @State private var isSavingRestDay   = false
    @State private var editingEntry:     WorkoutEntry?  = nil

    private var accent: Color { ThemeStore.shared.accent }
    private let cardBg  = Color(red: 0.11, green: 0.11, blue: 0.14)
    private let pageBg  = Color(red: 0.05, green: 0.05, blue: 0.07)

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .tint(accent)
                        .padding(.top, 60)
                } else if entries.isEmpty {
                    duelRestDayButton
                    emptyState
                } else {
                    totalCard
                        .padding(.bottom, 4)

                    Text("\(entries.count) Workout\(entries.count == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.30))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(entries) { entry in
                        WorkoutRow(entry: entry, accent: accent, cardBg: cardBg,
                                   onEdit: { editingEntry = entry },
                                   onDelete: {
                            Task {
                                await WorkoutService.shared.delete(workoutID: entry.workoutID, userID: userID)
                                entries.removeAll { $0.workoutID == entry.workoutID }
                                if isToday { MacroAdjustmentEngine.revert() }
                            }
                        })
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 100)
        }
        .task(id: selectedDate) { await load() }
        .onReceive(NotificationCenter.default.publisher(for: WorkoutService.workoutSavedNotification)) { _ in
            Task { await load() }
        }
        .sheet(item: $editingEntry) { entry in
            EditWorkoutSheet(entry: entry, onSave: { name, type, duration, calories, time, exercises in
                Task {
                    var updated = entry
                    updated.name            = name
                    updated.workoutType     = type
                    updated.durationMinutes = duration
                    updated.caloriesBurned  = calories
                    updated.loggedAt        = time
                    updated.exercises       = exercises
                    try? await WorkoutService.shared.save(entry: updated, userID: userID)
                    await load()
                }
            }, onDelete: {
                Task {
                    await WorkoutService.shared.delete(workoutID: entry.workoutID, userID: userID)
                    entries.removeAll { $0.workoutID == entry.workoutID }
                    if isToday { MacroAdjustmentEngine.revert() }
                }
            }, userID: userID)
        }
        .keyboardDoneToolbar()
    }

    // MARK: - Sub-views

    private var duelRestDayButton: some View {
        Button {
            Task {
                isSavingRestDay = true
                let entry = WorkoutEntry(name: "Rest Day", workoutType: .restDay,
                                         durationMinutes: 0, caloriesBurned: 0,
                                         loggedAt: selectedDate)
                try? await WorkoutService.shared.save(entry: entry, userID: userID)
                if isToday { MacroAdjustmentEngine.apply(for: .restDay, bodyWeightLbs: bodyWeightLbs) }
                await load()
                isSavingRestDay = false
            }
        } label: {
            HStack(spacing: 8) {
                if isSavingRestDay {
                    ProgressView().tint(.white).scaleEffect(0.8)
                } else {
                    Image(systemName: "moon.zzz.fill")
                        .foregroundStyle(.white.opacity(0.55))
                }
                Text(isSavingRestDay ? "Saving…" : "Log Rest Day")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(isSavingRestDay)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 40)
            ZStack {
                Circle()
                    .fill(accent.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 36))
                    .foregroundStyle(accent.opacity(0.45))
            }
            VStack(spacing: 6) {
                Text("No workouts logged")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                Text("Tap + and choose \"Log a Workout\" to get started")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.32))
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }

    private var totalCard: some View {
        let total    = entries.reduce(0) { $0 + $1.caloriesBurned }
        let totalMin = entries.reduce(0) { $0 + $1.durationMinutes }

        // Sum adjustments across every logged workout
        let combined: MacroAdjustment = entries.reduce(
            MacroAdjustment(caloriesDelta: 0, carbsDelta: 0, proteinDelta: 0, fatDelta: 0)
        ) { acc, entry in
            let a = MacroAdjustmentEngine.adjustment(for: entry.workoutType, bodyWeightLbs: bodyWeightLbs)
            return MacroAdjustment(
                caloriesDelta: acc.caloriesDelta + a.caloriesDelta,
                carbsDelta:    acc.carbsDelta    + a.carbsDelta,
                proteinDelta:  acc.proteinDelta  + a.proteinDelta,
                fatDelta:      acc.fatDelta      + a.fatDelta
            )
        }

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                statBlock(value: "\(total)", label: "Cal Burned", color: accent)
                Divider()
                    .frame(height: 40)
                    .background(.white.opacity(0.10))
                statBlock(value: formatMinutes(totalMin), label: "Total Time", color: .white.opacity(0.75))
            }
            .padding(.vertical, 16)

            if !combined.isEmpty {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(ThemeStore.shared.accent)
                        Text("Macro Goal Adjustments")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(ThemeStore.shared.accent)
                    }

                    HStack(spacing: 8) {
                        macroAdjChip(label: "Cal",  delta: combined.caloriesDelta, unit: "kcal")
                        macroAdjChip(label: "Carbs",delta: combined.carbsDelta,    unit: "g")
                        macroAdjChip(label: "Pro",  delta: combined.proteinDelta,  unit: "g")
                        macroAdjChip(label: "Fat",  delta: combined.fatDelta,      unit: "g")
                    }

                    Text("Applied to today's goals only · resets tomorrow")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.25))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.20), lineWidth: 1))
    }

    private func macroAdjChip(label: String, delta: Int, unit: String) -> some View {
        let positive = delta >= 0
        let color: Color = positive
            ? Color(red: 0.30, green: 0.90, blue: 0.55)
            : Color(red: 1.00, green: 0.45, blue: 0.45)
        let sign = positive ? "+" : ""
        return VStack(spacing: 2) {
            Text("\(sign)\(delta)\(unit)")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.40))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.20), lineWidth: 1))
    }

    private func statBlock(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.40))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func load() async {
        isLoading = true
        entries   = (try? await WorkoutService.shared.fetch(userID: userID, date: selectedDate)) ?? []
        isLoading = false
    }

    private func formatMinutes(_ min: Int) -> String {
        min >= 60 ? "\(min / 60)h \(min % 60)m" : "\(min)m"
    }
}

// MARK: - WorkoutRow

// MARK: - EditWorkoutSheet

struct EditWorkoutSheet: View {
    let entry:    WorkoutEntry
    let onSave:   (String, WorkoutType, Int, Int, Date, [Exercise]) -> Void
    var onDelete: (() -> Void)? = nil
    var userID:   String = ""

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?

    @State private var name:             String
    @State private var workoutType:      WorkoutType
    @State private var durationText:     String
    @State private var caloriesText:     String
    @State private var loggedAt:         Date
    @State private var exercises:        [Exercise]
    @State private var showSaveError     = false
    @State private var showSavedConfirm  = false

    private enum Field: Hashable { case name, duration, calories }

    init(entry: WorkoutEntry,
         onSave: @escaping (String, WorkoutType, Int, Int, Date, [Exercise]) -> Void,
         onDelete: (() -> Void)? = nil,
         userID: String = "") {
        self.entry    = entry
        self.onSave   = onSave
        self.onDelete = onDelete
        self.userID   = userID
        _name         = State(initialValue: entry.name)
        _workoutType  = State(initialValue: entry.workoutType)
        _durationText = State(initialValue: String(entry.durationMinutes))
        _caloriesText = State(initialValue: String(entry.caloriesBurned))
        _loggedAt     = State(initialValue: entry.loggedAt)
        _exercises    = State(initialValue: entry.exercises)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Workout name", text: $name)
                            .multilineTextAlignment(.trailing)
                            .focused($focus, equals: .name)
                            .submitLabel(.next)
                            .onSubmit { focus = .duration }
                    }
                    Picker("Type", selection: $workoutType) {
                        ForEach(WorkoutType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                }
                Section("Stats") {
                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("0", text: $durationText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .focused($focus, equals: .duration)
                            .submitLabel(.next)
                            .onSubmit { focus = .calories }
                        Text("min").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Calories Burned")
                        Spacer()
                        TextField("0", text: $caloriesText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .focused($focus, equals: .calories)
                            .submitLabel(.done)
                            .onSubmit { focus = nil }
                        Text("kcal").foregroundStyle(.secondary)
                    }
                }
                Section {
                    if exercises.isEmpty {
                        Text("No exercises — tap below to add sets & reps.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach($exercises) { $ex in
                            exerciseEditRow(exercise: $ex)
                        }
                        .onDelete { offsets in
                            exercises.remove(atOffsets: offsets)
                        }
                    }
                    Button {
                        exercises.append(Exercise(name: "", sets: [ExerciseSet(reps: 10)]))
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Exercises (optional)")
                }

                Section("Time Logged") {
                    DatePicker("Time", selection: $loggedAt, displayedComponents: .hourAndMinute)
                }
                if showSaveError {
                    Section {
                        Label("Duration and calories must be valid numbers.", systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                if !userID.isEmpty {
                    Section {
                        Button {
                            let cleaned: [Exercise] = exercises.compactMap { ex in
                                let trimmed = ex.name.trimmingCharacters(in: .whitespaces)
                                guard !trimmed.isEmpty else { return nil }
                                return Exercise(id: ex.id, name: trimmed, sets: ex.sets)
                            }
                            let template = SavedWorkout(
                                name:            name.trimmingCharacters(in: .whitespaces),
                                workoutType:     workoutType,
                                durationMinutes: Int(durationText) ?? 0,
                                caloriesBurned:  Int(caloriesText) ?? 0,
                                exercises:       cleaned
                            )
                            Task {
                                await WorkoutService.shared.addSavedWorkout(template, userID: userID)
                                showSavedConfirm = true
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Label("Save Workout", systemImage: "bookmark.fill")
                                Spacer()
                            }
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                if let onDelete {
                    Section {
                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Entry")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Saved!", isPresented: $showSavedConfirm) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This workout has been saved as a template. You can use it to quickly log the same workout in the future.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let dur = Int(durationText), let cal = Int(caloriesText) else {
                            showSaveError = true
                            return
                        }
                        // Strip blank-name exercises and normalize set counts/reps.
                        let cleaned: [Exercise] = exercises.compactMap { ex in
                            let trimmed = ex.name.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return nil }
                            let src = ex.sets.isEmpty ? [ExerciseSet(reps: 1)] : ex.sets
                            let sets = src.map { s in
                                ExerciseSet(id: s.id, reps: max(1, s.reps), weight: s.weight)
                            }
                            return Exercise(id: ex.id, name: trimmed, sets: sets)
                        }
                        onSave(name, workoutType, dur, cal, loggedAt, cleaned)
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Exercise edit row (Form-style)

    @ViewBuilder
    private func exerciseEditRow(exercise: Binding<Exercise>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Exercise name", text: exercise.name)
                .font(.system(size: 15, weight: .semibold))

            ForEach(Array(exercise.wrappedValue.sets.enumerated()), id: \.element.id) { idx, _ in
                setEditRow(exercise: exercise, setIndex: idx)
            }

            Button {
                let prev = exercise.wrappedValue.sets.last
                exercise.wrappedValue.sets.append(
                    ExerciseSet(reps: prev?.reps ?? 10, weight: prev?.weight)
                )
            } label: {
                Label("Add Set", systemImage: "plus.circle")
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func setEditRow(exercise: Binding<Exercise>, setIndex: Int) -> some View {
        let repsBinding = Binding<String>(
            get: { String(exercise.wrappedValue.sets[setIndex].reps) },
            set: { newVal in
                if let n = Int(newVal.filter { $0.isNumber }), n > 0 {
                    exercise.wrappedValue.sets[setIndex].reps = n
                } else if newVal.isEmpty {
                    exercise.wrappedValue.sets[setIndex].reps = 0
                }
            }
        )
        let weightBinding = Binding<String>(
            get: {
                if let w = exercise.wrappedValue.sets[setIndex].weight {
                    return w.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(w)) : String(w)
                }
                return ""
            },
            set: { newVal in
                let t = newVal.trimmingCharacters(in: .whitespaces)
                if t.isEmpty {
                    exercise.wrappedValue.sets[setIndex].weight = nil
                } else if let d = Double(t) {
                    exercise.wrappedValue.sets[setIndex].weight = d
                }
            }
        )

        HStack(spacing: 8) {
            Text("Set \(setIndex + 1)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)
            TextField("Reps", text: repsBinding)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 48)
                .padding(6)
                .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
            Text("reps").font(.caption).foregroundStyle(.secondary)
            TextField("lb", text: weightBinding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 60)
                .padding(6)
                .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
            Text("lb").font(.caption).foregroundStyle(.secondary)
            Spacer()
            Button {
                guard exercise.wrappedValue.sets.count > 1 else { return }
                exercise.wrappedValue.sets.remove(at: setIndex)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red.opacity(exercise.wrappedValue.sets.count > 1 ? 0.7 : 0.25))
            }
            .buttonStyle(.plain)
            .disabled(exercise.wrappedValue.sets.count <= 1)
        }
    }
}

// MARK: - WorkoutRow

struct WorkoutRow: View {
    let entry:    WorkoutEntry
    let accent:   Color
    let cardBg:   Color
    let onEdit:   () -> Void
    let onDelete: () -> Void

    @State private var isExpanded = false

    private var hasExercises: Bool { !entry.exercises.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(entry.formattedDuration) · \(entry.caloriesBurned) cal burned")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.45))
                    if let loc = entry.location, loc.isValid {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 10, weight: .semibold))
                            Text(loc.name)
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(accent.opacity(0.85))
                    }
                    if !entry.taggedFriends.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10, weight: .semibold))
                            Text(entry.taggedFriends.map { "@\($0.username)" }.joined(separator: ", "))
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(accent.opacity(0.85))
                    }
                    if hasExercises {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                isExpanded.toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("\(entry.exercises.count) exercise\(entry.exercises.count == 1 ? "" : "s")")
                                    .font(.system(size: 11, weight: .semibold))
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(accent)
                        }
                        .buttonStyle(.plain)
                        // Keep this tap to the exercises toggle only — don't trigger edit.
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(entry.loggedAt.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.30))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.20))
                }
            }
            .padding(14)
            .contentShape(Rectangle())
            .onTapGesture { onEdit() }

            if isExpanded && hasExercises {
                VStack(alignment: .leading, spacing: 10) {
                    Divider().background(.white.opacity(0.08))
                        .padding(.bottom, 2)
                    ForEach(entry.exercises) { ex in
                        exerciseDetail(ex)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.06), lineWidth: 1))
        .contextMenu {
            Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(w)) : String(format: "%.1f", w)
    }

    @ViewBuilder
    private func exerciseDetail(_ ex: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ex.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.90))

            if ex.hasUniformSets, let first = ex.sets.first {
                // Compact form when every set has identical reps & weight.
                HStack(spacing: 4) {
                    Text("\(ex.sets.count) × \(first.reps)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(accent.opacity(0.90))
                    if let w = first.weight {
                        Text("@ \(formatWeight(w)) lb")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                }
                .padding(.leading, 8)
            } else {
                // Per-set detail for varying sets (e.g. pyramid).
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(ex.sets.enumerated()), id: \.element.id) { idx, s in
                        HStack(spacing: 6) {
                            Text("Set \(idx + 1)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.35))
                                .frame(width: 40, alignment: .leading)
                            Text("\(s.reps) reps")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(accent.opacity(0.90))
                            if let w = s.weight {
                                Text("@ \(formatWeight(w)) lb")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                            Spacer()
                        }
                    }
                }
                .padding(.leading, 8)
            }
        }
    }
}
