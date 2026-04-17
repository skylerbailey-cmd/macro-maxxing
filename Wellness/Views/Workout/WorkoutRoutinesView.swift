//
//  WorkoutRoutinesView.swift
//  Wellness
//
//  Manage workout routines — named groups of saved workouts.
//  Accessed from Settings → Body & Nutrition → Workout Routines.
//

import SwiftUI

// MARK: - Routines List

struct WorkoutRoutinesView: View {
    let userSettings: UserSettings

    @State private var routines: [WorkoutRoutine] = []
    @State private var showingNewRoutine = false
    @State private var newRoutineName    = ""

    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var accent: Color { ThemeStore.shared.accent }

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            if routines.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(routines) { routine in
                            NavigationLink {
                                RoutineDetailView(routine: routine, userID: userSettings.userID, userSettings: userSettings, onUpdate: { Task { await reload() } })
                            } label: {
                                routineCard(routine)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Workout Routines")
        .navigationBarTitleDisplayMode(.inline)
        .keyboardDoneToolbar()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingNewRoutine = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accent)
                }
            }
        }
        .alert("New Routine", isPresented: $showingNewRoutine) {
            TextField("Routine name", text: $newRoutineName)
            Button("Create") {
                let name = newRoutineName.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                WorkoutService.shared.addRoutine(
                    WorkoutRoutine(name: name, days: [PlanDay(label: "Day 1")]),
                    userID: userSettings.userID
                )
                newRoutineName = ""
                Task { await reload() }
            }
            Button("Cancel", role: .cancel) { newRoutineName = "" }
        } message: {
            Text("Give your routine a name — e.g. \"Push / Pull / Legs\"")
        }
        .task { await reload() }
    }

    private func reload() async {
        routines = await WorkoutService.shared.fetchRoutines(userID: userSettings.userID)
    }

    // MARK: - Card

    private func routineCard(_ routine: WorkoutRoutine) -> some View {
        let savedWorkouts = WorkoutService.shared.savedWorkouts
        let workouts = routine.allWorkoutIDs.compactMap { id in
            savedWorkouts.first { $0.id == id }
        }

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(routine.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(workouts.count) workout\(workouts.count == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.40))
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.30))
            }

            if !workouts.isEmpty {
                HStack(spacing: 6) {
                    ForEach(workouts.prefix(5)) { w in
                        HStack(spacing: 4) {
                            Image(systemName: w.workoutType.icon)
                                .font(.system(size: 10))
                            Text(w.name)
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accent.opacity(0.12), in: Capsule())
                    }
                    if workouts.count > 5 {
                        Text("+\(workouts.count - 5)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.40))
                    }
                }
            }
        }
        .padding(14)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.15), lineWidth: 1))
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundStyle(accent.opacity(0.35))
            Text("No Routines Yet")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Group your saved workouts into routines\nlike Push/Pull/Legs or Upper/Lower.")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
            Button {
                showingNewRoutine = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Routine")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }
}

// MARK: - Routine Detail

struct RoutineDetailView: View {
    @State var routine: WorkoutRoutine
    let userID: String
    let userSettings: UserSettings
    var onUpdate: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingAddWorkout      = false
    @State private var addingToDayIndex: Int? = nil
    @State private var showingRenameAlert     = false
    @State private var showingDeleteConfirm   = false
    @State private var renameText             = ""
    @State private var renamingDayIndex: Int? = nil
    @State private var dayRenameText          = ""

    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var accent: Color { ThemeStore.shared.accent }

    private var allSaved: [SavedWorkout] { WorkoutService.shared.savedWorkouts }

    var body: some View {
        List {
            ForEach(Array(routine.days.enumerated()), id: \.element.id) { dayIdx, day in
                Section {
                    let resolved = day.itemIDs.compactMap { id in allSaved.first { $0.id == id } }
                    ForEach(resolved) { workout in
                        workoutRow(workout)
                    }
                    .onMove { from, to in
                        routine.days[dayIdx].itemIDs.move(fromOffsets: from, toOffset: to)
                        save()
                    }
                    .onDelete { offsets in
                        routine.days[dayIdx].itemIDs.remove(atOffsets: offsets)
                        save()
                    }

                    Button {
                        addingToDayIndex = dayIdx
                        showingAddWorkout = true
                    } label: {
                        Label("Add Workout", systemImage: "plus.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                } header: {
                    HStack {
                        Button {
                            renamingDayIndex = dayIdx
                            dayRenameText = day.label
                        } label: {
                            HStack(spacing: 4) {
                                Text(day.label.uppercased())
                                    .font(.system(size: 11, weight: .black))
                                    .tracking(1.5)
                                Image(systemName: "pencil")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.30))
                            }
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Button(role: .destructive) {
                            routine.days.remove(at: dayIdx)
                            save()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(.red.opacity(0.60))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowBackground(cardBg)
            }

            // Add day button
            Section {
                Button {
                    let nextNum = routine.days.count + 1
                    routine.days.append(PlanDay(label: "Day \(nextNum)"))
                    save()
                } label: {
                    Label("Add Day", systemImage: "plus.circle")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(accent)
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(pageBg.ignoresSafeArea())
        .environment(\.editMode, .constant(.active))
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        renameText = routine.name
                        showingRenameAlert = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("Delete Routine", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.60))
                }
            }
        }
        .sheet(isPresented: $showingAddWorkout) {
            AddWorkoutToRoutineSheet(
                existingIDs: [],
                userSettings: userSettings,
                onAdd: { selectedIDs in
                    if let idx = addingToDayIndex, idx < routine.days.count {
                        routine.days[idx].itemIDs.append(contentsOf: selectedIDs)
                    }
                    save()
                }
            )
        }
        .alert("Rename Routine", isPresented: $showingRenameAlert) {
            TextField("Name", text: $renameText)
            Button("Save") {
                let name = renameText.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                routine.name = name
                save()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete this routine?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                WorkoutService.shared.deleteRoutine(id: routine.id, userID: userID)
                onUpdate()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This won't delete the saved workouts — just the routine grouping.")
        }
        .alert("Rename Day", isPresented: Binding(
            get: { renamingDayIndex != nil },
            set: { if !$0 { renamingDayIndex = nil } }
        )) {
            TextField("Day label", text: $dayRenameText)
            Button("Save") {
                let label = dayRenameText.trimmingCharacters(in: .whitespaces)
                guard !label.isEmpty, let idx = renamingDayIndex, idx < routine.days.count else { return }
                routine.days[idx].label = label
                save()
                renamingDayIndex = nil
            }
            Button("Cancel", role: .cancel) { renamingDayIndex = nil }
        } message: {
            Text("Rename this day — e.g. \"Monday\" or \"Push\"")
        }
    }

    private func workoutRow(_ workout: SavedWorkout) -> some View {
        HStack(spacing: 10) {
            Image(systemName: workout.workoutType.icon)
                .font(.system(size: 12))
                .foregroundStyle(accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Text(workout.workoutType.rawValue)
                        .font(.system(size: 11))
                    if !workout.exercises.isEmpty {
                        Text("\(workout.exercises.count) exercises")
                            .font(.system(size: 11))
                    }
                    if workout.durationMinutes > 0 {
                        Text("\(workout.durationMinutes)m")
                            .font(.system(size: 11))
                    }
                }
                .foregroundStyle(.white.opacity(0.40))
            }
        }
    }

    private func save() {
        WorkoutService.shared.updateRoutine(routine, userID: userID)
        onUpdate()
    }
}

// MARK: - Add Workout to Routine Sheet

private struct AddWorkoutToRoutineSheet: View {
    let existingIDs:  Set<String>
    let userSettings: UserSettings
    let onAdd: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selected:       Set<String>    = []
    @State private var workouts:       [SavedWorkout] = []
    @State private var showingCreate   = false
    @State private var editingWorkout: SavedWorkout?  = nil
    @State private var deleteConfirm:  SavedWorkout?  = nil

    private var accent: Color { ThemeStore.shared.accent }
    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)

    var body: some View {
        mainContent
            .sheet(isPresented: $showingCreate) { createSheet }
            .sheet(item: $editingWorkout) { workout in editSheet(workout) }
            .alert("Delete this saved workout?", isPresented: Binding(
                get: { deleteConfirm != nil },
                set: { if !$0 { deleteConfirm = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let w = deleteConfirm {
                        WorkoutService.shared.deleteSavedWorkout(id: w.id)
                        workouts = WorkoutService.shared.savedWorkouts
                        selected.remove(w.id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This can't be undone.")
            }
    }

    private var mainContent: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 8) {
                        Button { showingCreate = true } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(accent)
                                Text("Create New Saved Workout")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .padding(12)
                            .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.25), lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        if workouts.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "dumbbell")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white.opacity(0.20))
                                Text("No saved workouts yet")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.40))
                            }
                            .padding(.top, 40)
                        }

                        ForEach(workouts) { workout in
                            let alreadyAdded = existingIDs.contains(workout.id)
                            let isSelected   = selected.contains(workout.id)
                            Button {
                                if isSelected { selected.remove(workout.id) }
                                else          { selected.insert(workout.id) }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20))
                                        .foregroundStyle(isSelected ? accent : .white.opacity(0.25))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(workout.name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white)
                                        HStack(spacing: 4) {
                                            Image(systemName: workout.workoutType.icon)
                                                .font(.system(size: 10))
                                            Text(workout.workoutType.rawValue)
                                                .font(.system(size: 11))
                                            if workout.durationMinutes > 0 {
                                                Text("· \(workout.durationMinutes)m")
                                                    .font(.system(size: 11))
                                            }
                                            if !workout.exercises.isEmpty {
                                                Text("· \(workout.exercises.count) exercises")
                                                    .font(.system(size: 11))
                                            }
                                        }
                                        .foregroundStyle(.white.opacity(0.40))
                                    }
                                    Spacer()
                                    if alreadyAdded {
                                        Text("Added")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white.opacity(0.30))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.white.opacity(0.08), in: Capsule())
                                    }
                                }
                                .padding(12)
                                .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .disabled(alreadyAdded)
                            .opacity(alreadyAdded ? 0.50 : 1)
                            .contextMenu {
                                Button { editingWorkout = workout } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Button(role: .destructive) { deleteConfirm = workout } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDoneToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add \(selected.count > 0 ? "(\(selected.count))" : "")") {
                        onAdd(Array(selected))
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(selected.isEmpty)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear { workouts = WorkoutService.shared.savedWorkouts }
        }
    }

    private var createSheet: some View {
        LogWorkoutSheet(
            userID:              "",
            selectedDate:        Date(),
            bodyWeightLbs:       0,
            autoAdjustByDefault: false,
            userSettings:        userSettings,
            onSaved:             {},
            saveTemplateMode:    true,
            onSavedTemplate:     { template in
                WorkoutService.shared.addSavedWorkout(template)
                workouts = WorkoutService.shared.savedWorkouts
            }
        )
    }

    private func editSheet(_ workout: SavedWorkout) -> some View {
        LogWorkoutSheet(
            userID:              "",
            selectedDate:        Date(),
            bodyWeightLbs:       0,
            autoAdjustByDefault: false,
            userSettings:        userSettings,
            editingEntry:        WorkoutEntry(
                workoutID:       workout.id,
                name:            workout.name,
                workoutType:     workout.workoutType,
                durationMinutes: workout.durationMinutes,
                caloriesBurned:  workout.caloriesBurned,
                exercises:       workout.exercises
            ),
            onSaved:             {},
            saveTemplateMode:    true,
            onSavedTemplate:     { updated in
                WorkoutService.shared.updateSavedWorkout(updated)
                workouts = WorkoutService.shared.savedWorkouts
            }
        )
    }
}

// MARK: - Create Saved Workout Sheet (legacy — replaced by LogWorkoutSheet saveTemplateMode)

private struct CreateSavedWorkoutSheet: View {
    let onCreate: (SavedWorkout) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name         = ""
    @State private var workoutType  = WorkoutType.strength
    @State private var durationText = ""
    @State private var caloriesText = ""

    private var accent: Color { ThemeStore.shared.accent }
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    field("Workout Name", text: $name, keyboard: .default)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Type").font(.system(size: 11, weight: .semibold)).foregroundStyle(.white.opacity(0.45))
                        Picker("Type", selection: $workoutType) {
                            ForEach(WorkoutType.allCases.filter { $0 != .restDay }, id: \.self) { type in
                                Label(type.rawValue, systemImage: type.icon).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(accent)
                    }

                    HStack(spacing: 12) {
                        field("Duration (min)", text: $durationText, keyboard: .numberPad)
                        field("Calories",       text: $caloriesText, keyboard: .numberPad)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea())
            .navigationTitle("New Saved Workout")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDoneToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let w = SavedWorkout(
                            name: name.trimmingCharacters(in: .whitespaces),
                            workoutType: workoutType,
                            durationMinutes: Int(durationText) ?? 0,
                            caloriesBurned: Int(caloriesText) ?? 0
                        )
                        onCreate(w)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(!canSave)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func field(_ label: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 11, weight: .semibold)).foregroundStyle(.white.opacity(0.45))
            TextField(label, text: text)
                .keyboardType(keyboard)
                .padding(10)
                .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Edit Saved Workout Sheet

private struct EditSavedWorkoutSheet: View {
    let workout:  SavedWorkout
    let onUpdate: (SavedWorkout) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name         = ""
    @State private var workoutType  = WorkoutType.strength
    @State private var durationText = ""
    @State private var caloriesText = ""

    private var accent: Color { ThemeStore.shared.accent }
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    field("Workout Name", text: $name, keyboard: .default)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Type").font(.system(size: 11, weight: .semibold)).foregroundStyle(.white.opacity(0.45))
                        Picker("Type", selection: $workoutType) {
                            ForEach(WorkoutType.allCases.filter { $0 != .restDay }, id: \.self) { type in
                                Label(type.rawValue, systemImage: type.icon).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(accent)
                    }

                    HStack(spacing: 12) {
                        field("Duration (min)", text: $durationText, keyboard: .numberPad)
                        field("Calories",       text: $caloriesText, keyboard: .numberPad)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea())
            .navigationTitle("Edit Saved Workout")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDoneToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = workout
                        updated.name            = name.trimmingCharacters(in: .whitespaces)
                        updated.workoutType     = workoutType
                        updated.durationMinutes = Int(durationText) ?? 0
                        updated.caloriesBurned  = Int(caloriesText) ?? 0
                        onUpdate(updated)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(!canSave)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                name         = workout.name
                workoutType  = workout.workoutType
                durationText = workout.durationMinutes > 0 ? "\(workout.durationMinutes)" : ""
                caloriesText = workout.caloriesBurned > 0  ? "\(workout.caloriesBurned)"  : ""
            }
        }
    }

    private func field(_ label: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 11, weight: .semibold)).foregroundStyle(.white.opacity(0.45))
            TextField(label, text: text)
                .keyboardType(keyboard)
                .padding(10)
                .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)
        }
    }
}
