//
//  LogWorkoutSheet.swift
//  Wellness
//

import SwiftUI

struct LogWorkoutSheet: View {

    let userID:              String
    let selectedDate:        Date
    let bodyWeightLbs:       Double
    let autoAdjustByDefault: Bool
    let userSettings:        UserSettings
    let editingEntry:        WorkoutEntry?   // non-nil = edit mode
    let onSaved:             () -> Void

    @Environment(\.dismiss) private var dismiss

    // Entry mode
    @State private var mode: Mode = .manual

    // Form fields
    @State private var workoutName    = ""
    @State private var workoutType    = WorkoutType.strength
    @State private var durationText   = ""
    @State private var caloriesText   = ""
    @State private var logTime:        Date
    @State private var saveAsTemplate = false
    @State private var applyAdjustment: Bool

    // Voice / AI
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var aiState: AIState = .idle

    // Saved templates
    @State private var savedWorkouts: [SavedWorkout] = []

    // Feedback
    @State private var isSaving   = false
    @State private var saveError: String? = nil

    // Post workout prompt
    @State private var showingPostPrompt    = false
    @State private var savedWorkoutName     = ""
    @State private var savedWorkoutType     = WorkoutType.strength
    @State private var savedDuration        = 0
    @State private var savedCalories        = 0

    // MARK: - Sub-types

    enum Mode { case manual, voice }
    enum AIState: Equatable { case idle, analyzing, error(String) }

    // MARK: - Colors

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let accent = Color(red: 0.30, green: 0.90, blue: 0.55)
    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)

    // MARK: - Init

    init(userID: String, selectedDate: Date, bodyWeightLbs: Double, autoAdjustByDefault: Bool,
         userSettings: UserSettings, editingEntry: WorkoutEntry? = nil,
         onSaved: @escaping () -> Void) {
        self.userID              = userID
        self.selectedDate        = selectedDate
        self.bodyWeightLbs       = bodyWeightLbs
        self.autoAdjustByDefault = autoAdjustByDefault
        self.userSettings        = userSettings
        self.editingEntry        = editingEntry
        self.onSaved             = onSaved
        if let e = editingEntry {
            _workoutName     = State(initialValue: e.name)
            _workoutType     = State(initialValue: e.workoutType)
            _durationText    = State(initialValue: "\(e.durationMinutes)")
            _caloriesText    = State(initialValue: "\(e.caloriesBurned)")
            _logTime         = State(initialValue: e.loggedAt)
            _applyAdjustment = State(initialValue: e.adjustmentApplied)
        } else {
            _logTime         = State(initialValue: Date())
            _applyAdjustment = State(initialValue: autoAdjustByDefault)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Saved workouts quick-select
                        if !savedWorkouts.isEmpty {
                            savedWorkoutsSection
                        }

                        // Mode picker
                        modePicker

                        // Entry form
                        if mode == .manual {
                            manualForm
                        } else {
                            voiceForm
                        }

                        // Workout type grid (always visible)
                        workoutTypeGrid

                        // Macro adjustment preview
                        macroAdjustmentCard

                        // Toggles
                        if editingEntry == nil { saveToggle }
                        adjustToggle

                        // Save button
                        saveButton

                        // Rest day button (new workouts only)
                        if editingEntry == nil { restDayButton }

                        if let err = saveError {
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle(editingEntry != nil ? "Edit Workout" : "Log a Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .preferredColorScheme(.dark)
            .onAppear { savedWorkouts = WorkoutService.shared.savedWorkouts }
            .sheet(isPresented: $showingPostPrompt, onDismiss: { onSaved(); dismiss() }) {
                PostWorkoutSheet(
                    userSettings:    userSettings,
                    workoutName:     savedWorkoutName,
                    workoutType:     savedWorkoutType,
                    durationMinutes: savedDuration,
                    caloriesBurned:  savedCalories
                )
            }
        }
    }

    // MARK: - Saved Workouts

    private var savedWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Saved Workouts")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(savedWorkouts) { saved in
                        savedChip(saved)
                    }
                }
            }
        }
    }

    private func savedChip(_ saved: SavedWorkout) -> some View {
        Button {
            workoutName  = saved.name
            workoutType  = saved.workoutType
            durationText = "\(saved.durationMinutes)"
            caloriesText = "\(saved.caloriesBurned)"
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(saved.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(saved.durationMinutes)m · \(saved.caloriesBurned) cal")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.50))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                WorkoutService.shared.deleteSavedWorkout(id: saved.id)
                savedWorkouts = WorkoutService.shared.savedWorkouts
            } label: { Label("Delete", systemImage: "trash") }
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        HStack(spacing: 0) {
            modeTab(label: "Manual", icon: "keyboard",  tag: .manual)
            modeTab(label: "Voice",  icon: "mic.fill",  tag: .voice)
        }
        .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 1))
    }

    private func modeTab(label: String, icon: String, tag: Mode) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { mode = tag }
            if tag == .manual { speechRecognizer.reset() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                Text(label).font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(mode == tag ? .black : .white.opacity(0.45))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                mode == tag
                    ? RoundedRectangle(cornerRadius: 10).fill(gold)
                    : RoundedRectangle(cornerRadius: 10).fill(Color.clear)
            )
            .padding(3)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: mode)
    }

    // MARK: - Manual Form

    private var manualForm: some View {
        VStack(spacing: 14) {
            field(label: "Workout Name", placeholder: "e.g. Upper Body, 5 Mile Run", text: $workoutName)
            HStack(spacing: 14) {
                field(label: "Duration (min)",  placeholder: "45",  text: $durationText, keyboardType: .numberPad)
                field(label: "Calories Burned", placeholder: "350", text: $caloriesText, keyboardType: .numberPad)
            }
            timePickerRow
        }
    }

    private func field(label: String, placeholder: String, text: Binding<String>,
                       keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .padding(12)
                .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.20), lineWidth: 1))
        }
    }

    // MARK: - Voice Form

    private var voiceForm: some View {
        VStack(spacing: 18) {
            Button {
                if speechRecognizer.status == .recording { speechRecognizer.stop() }
                else { speechRecognizer.start() }
            } label: {
                ZStack {
                    Circle()
                        .fill(speechRecognizer.status == .recording ? accent.opacity(0.20) : cardBg)
                        .frame(width: 80, height: 80)
                        .overlay(Circle().stroke(
                            speechRecognizer.status == .recording ? accent : .white.opacity(0.15),
                            lineWidth: 2))
                    Image(systemName: speechRecognizer.status == .recording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(speechRecognizer.status == .recording ? accent : .white.opacity(0.65))
                }
            }
            .buttonStyle(.plain)

            Text(micHint)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)

            if !speechRecognizer.transcript.isEmpty {
                Text(speechRecognizer.transcript)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.80))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.20), lineWidth: 1))
            }

            if speechRecognizer.status == .done && !speechRecognizer.transcript.isEmpty {
                analyzeButton
            }

            if case .error(let msg) = speechRecognizer.status {
                Text(msg).font(.caption).foregroundStyle(.red).multilineTextAlignment(.center)
            }

            if !workoutName.isEmpty && mode == .voice {
                parsedSummary
            }
        }
    }

    private var micHint: String {
        switch speechRecognizer.status {
        case .idle:                 return "Tap the mic and describe your workout"
        case .requestingPermission: return "Requesting permission…"
        case .recording:            return "Listening… tap to stop"
        case .done:                 return "Done recording"
        case .error:                return ""
        }
    }

    private var analyzeButton: some View {
        Button { Task { await analyzeTranscript() } } label: {
            HStack(spacing: 8) {
                if aiState == .analyzing { ProgressView().tint(accent) }
                else { Image(systemName: "sparkles") }
                Text(aiState == .analyzing ? "Analyzing…" : "Generate with AI")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(aiState == .analyzing ? .white.opacity(0.45) : .black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(aiState == .analyzing ? cardBg : accent, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(aiState == .analyzing)
    }

    private var parsedSummary: some View {
        VStack(spacing: 14) {
            Divider().background(.white.opacity(0.10))
            Text("AI Filled In")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.40))
                .frame(maxWidth: .infinity, alignment: .leading)
            field(label: "Workout Name", placeholder: "e.g. Upper Body", text: $workoutName)
            HStack(spacing: 14) {
                field(label: "Duration (min)",  placeholder: "45",  text: $durationText, keyboardType: .numberPad)
                field(label: "Calories Burned", placeholder: "350", text: $caloriesText, keyboardType: .numberPad)
            }
            timePickerRow
        }
    }

    private var timePickerRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Time Completed")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
            DatePicker("", selection: $logTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .colorScheme(.dark)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.20), lineWidth: 1))
        }
    }

    // MARK: - Workout Type Grid

    private var workoutTypeGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Workout Type")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                      spacing: 10) {
                ForEach(WorkoutType.allCases, id: \.self) { type in
                    workoutTypeChip(type)
                }
            }
        }
    }

    private func workoutTypeChip(_ type: WorkoutType) -> some View {
        let selected = workoutType == type
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { workoutType = type }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? .black : accent.opacity(0.70))
                Text(type.shortLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(selected ? .black : .white.opacity(0.65))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                selected ? accent : cardBg,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                selected ? .clear : accent.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Macro Adjustment Card

    private var macroAdjustmentCard: some View {
        let adj     = MacroAdjustmentEngine.adjustment(for: workoutType, bodyWeightLbs: bodyWeightLbs)
        let preview = MacroAdjustmentEngine.preview(for: workoutType, bodyWeightLbs: bodyWeightLbs)
        let base    = MacroAdjustmentEngine.baseGoals()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(gold)
                Text("Macro Adjustment")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text(workoutType.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accent)
            }

            if adj.isEmpty {
                Text("No macro changes for this workout type.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.40))
            } else {
                HStack(spacing: 0) {
                    adjustRow(label: "Calories", base: Int(base.calories), adjusted: Int(preview.calories), delta: adj.caloriesDelta, unit: "kcal")
                    Divider().frame(height: 32).background(.white.opacity(0.10))
                    adjustRow(label: "Carbs",    base: Int(base.carbs),    adjusted: Int(preview.carbs),    delta: adj.carbsDelta,    unit: "g")
                    Divider().frame(height: 32).background(.white.opacity(0.10))
                    adjustRow(label: "Protein",  base: Int(base.protein),  adjusted: Int(preview.protein),  delta: adj.proteinDelta,  unit: "g")
                    Divider().frame(height: 32).background(.white.opacity(0.10))
                    adjustRow(label: "Fat",      base: Int(base.fat),      adjusted: Int(preview.fat),      delta: adj.fatDelta,      unit: "g")
                }
                .frame(maxWidth: .infinity)

                Text("Based on ISSN & ACSM guidelines. Applied to today's goals only — resets tomorrow.")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.28))
            }
        }
        .padding(14)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(gold.opacity(0.20), lineWidth: 1))
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: workoutType)
    }

    private func adjustRow(label: String, base: Int, adjusted: Int, delta: Int, unit: String) -> some View {
        let color: Color = delta > 0 ? accent : delta < 0 ? Color(red: 1, green: 0.45, blue: 0.45) : .white.opacity(0.40)
        return VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.35))
            Text("\(adjusted)\(unit)")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(delta == 0 ? "—" : (delta > 0 ? "+\(delta)" : "\(delta)"))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Toggles

    private var saveToggle: some View {
        Toggle(isOn: $saveAsTemplate) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Save as Saved Workout")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Quick-select this workout next time")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.40))
            }
        }
        .tint(accent)
        .padding(14)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
    }

    private var adjustToggle: some View {
        Toggle(isOn: $applyAdjustment) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Apply macro adjustments")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Update today's macro goals for this workout type")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.40))
            }
        }
        .tint(gold)
        .padding(14)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Save Button

    private var canSave: Bool {
        !workoutName.trimmingCharacters(in: .whitespaces).isEmpty
            && (Int(durationText) ?? 0) > 0
            && (Int(caloriesText) ?? 0) >= 0
    }

    private var saveButton: some View {
        Button { Task { await saveWorkout() } } label: {
            HStack(spacing: 8) {
                if isSaving { ProgressView().tint(.black) }
                else { Image(systemName: "checkmark") }
                Text(isSaving ? "Saving…" : editingEntry != nil ? "Save Changes" : "Log Workout")
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(canSave ? accent : accent.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(!canSave || isSaving)
    }

    // MARK: - Rest Day Button

    private var restDayButton: some View {
        Button { Task { await logRestDay() } } label: {
            HStack(spacing: 8) {
                Image(systemName: "moon.zzz.fill")
                Text("Log Rest Day")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white.opacity(0.70))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
    }

    // MARK: - Actions

    private func analyzeTranscript() async {
        guard !speechRecognizer.transcript.isEmpty else { return }
        aiState = .analyzing
        do {
            let result = try await ClaudeAnalysisService().parseWorkout(transcript: speechRecognizer.transcript)
            workoutName  = result.name
            workoutType  = result.workoutType
            durationText = "\(result.durationMinutes)"
            caloriesText = "\(result.caloriesBurned)"
            aiState = .idle
        } catch {
            aiState = .error(error.localizedDescription)
        }
    }

    /// Preserves the year/month/day from `date` but applies the hour/minute from `time`.
    private func combinedDate(date: Date, time: Date) -> Date {
        let cal  = Calendar.current
        let ymd  = cal.dateComponents([.year, .month, .day], from: date)
        let hm   = cal.dateComponents([.hour, .minute], from: time)
        var merged = DateComponents()
        merged.year   = ymd.year
        merged.month  = ymd.month
        merged.day    = ymd.day
        merged.hour   = hm.hour
        merged.minute = hm.minute
        merged.second = 0
        return cal.date(from: merged) ?? date
    }

    private func saveWorkout() async {
        let name     = workoutName.trimmingCharacters(in: .whitespaces)
        let duration = Int(durationText) ?? 0
        let calories = Int(caloriesText) ?? 0
        guard !name.isEmpty, duration > 0 else { return }

        isSaving  = true
        saveError = nil

        // Combine the selected calendar date with the user-chosen time
        let loggedAt = combinedDate(date: selectedDate, time: logTime)

        // Preserve the original workoutID when editing so Firestore overwrites the same document
        let entry = WorkoutEntry(
            workoutID:          editingEntry?.workoutID ?? UUID().uuidString,
            name:               name,
            workoutType:        workoutType,
            durationMinutes:    duration,
            caloriesBurned:     calories,
            loggedAt:           loggedAt,
            adjustmentApplied:  applyAdjustment
        )
        do {
            try await WorkoutService.shared.save(entry: entry, userID: userID)

            if saveAsTemplate {
                WorkoutService.shared.addSavedWorkout(
                    SavedWorkout(name: name, workoutType: workoutType,
                                 durationMinutes: duration, caloriesBurned: calories)
                )
            }

            if Calendar.current.isDateInToday(selectedDate) {
                if applyAdjustment {
                    // Re-applies for the (possibly changed) workout type — safe to call on new or edited entries
                    MacroAdjustmentEngine.apply(for: workoutType, bodyWeightLbs: bodyWeightLbs)
                } else if editingEntry != nil {
                    // Editing with adjustment OFF: restore base goals
                    MacroAdjustmentEngine.revert()
                }
            }

            savedWorkoutName  = name
            savedWorkoutType  = workoutType
            savedDuration     = duration
            savedCalories     = calories
            isSaving          = false
            // Skip the post prompt when editing an existing workout
            if editingEntry != nil {
                onSaved()
                dismiss()
            } else {
                userSettings.awardAura(points: 25)
                showingPostPrompt = true
            }
        } catch {
            isSaving  = false
            saveError = "Failed to save. Please try again."
        }
    }

    private func logRestDay() async {
        isSaving  = true
        saveError = nil

        let entry = WorkoutEntry(name: "Rest Day", workoutType: .restDay,
                                 durationMinutes: 0, caloriesBurned: 0,
                                 loggedAt: combinedDate(date: selectedDate, time: Date()))
        do {
            try await WorkoutService.shared.save(entry: entry, userID: userID)

            if applyAdjustment {
                MacroAdjustmentEngine.apply(for: .restDay, bodyWeightLbs: bodyWeightLbs)
            }

            isSaving = false
            onSaved()
            dismiss()
        } catch {
            isSaving  = false
            saveError = "Failed to save rest day. Please try again."
        }
    }
}
