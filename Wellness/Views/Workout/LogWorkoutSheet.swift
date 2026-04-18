//
//  LogWorkoutSheet.swift
//  Wellness
//

import ActivityKit
import SwiftUI

struct LogWorkoutSheet: View {

    let userID:              String
    let selectedDate:        Date
    let bodyWeightLbs:       Double
    let autoAdjustByDefault: Bool
    let userSettings:        UserSettings
    let editingEntry:        WorkoutEntry?   // non-nil = edit mode
    let onSaved:             () -> Void
    /// When true, the sheet saves a template only (no workout logged,
    /// no macro adjustment, no post-workout prompt). Title and button
    /// text change to reflect "Save Workout" instead of "Log Workout".
    var saveTemplateMode:    Bool = false
    /// Called with the new SavedWorkout when `saveTemplateMode` is true.
    var onSavedTemplate:     ((SavedWorkout) -> Void)? = nil
    /// When true renders without a NavigationStack for embedding in FoodLogView.
    var isEmbedded:          Bool = false
    /// Called instead of dismiss() in embedded mode.
    var onClose:             (() -> Void)? = nil
    /// When true hides date/time, gym, friends, save toggle, and apply-adjustment
    /// toggle — intended for the "Edit Saved Workout" flow from routines.
    var savedWorkoutMode:    Bool = false

    @Environment(\.dismiss) private var dismiss

    // Form fields
    @State private var workoutName    = ""
    @State private var workoutType    = WorkoutType.strength
    @State private var durationText   = ""
    @State private var caloriesText   = ""
    @State private var logDate:         Date
    @State private var logTime:        Date
    @State private var saveAsTemplate = false
    @State private var applyAdjustment: Bool

    // Optional per-exercise detail (name / sets / reps / weight)
    @State private var exercises: [Exercise] = []

    // Optional tagged gym/place. nil means untagged.
    @State private var selectedGym: WorkoutLocation? = nil
    @State private var showingGymPicker = false

    // Optional tagged friends on the workout. Populated via FriendTagPickerView.
    @State private var taggedFriends: [TaggedFriend] = []
    @State private var showingFriendPicker = false

    /// True once the calories field holds a specific value the user (or AI /
    /// saved template / prefill) wants preserved. While this is false, the
    /// calories field tracks the live estimate as duration or type change.
    @State private var caloriesEdited: Bool = false

    // Voice / AI
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var aiState: AIState = .idle
    @State private var editableTranscript = ""
    @State private var aiSubscription = AISubscriptionStore.shared
    @State private var showingAIPaywall = false

    // Saved templates
    @State private var savedWorkouts: [SavedWorkout] = []
    @State private var workoutToDelete: SavedWorkout? = nil

    // Live workout timer / Live Activity
    @State private var workoutStartTime: Date? = nil
    @State private var liveActivity: Activity<WorkoutActivityAttributes>? = nil
    /// Set to true once we've drained an "End Workout" payload into the form
    /// so we don't loop when the content-updates stream redelivers.
    @State private var didConsumeLiveFinish = false
    /// Snapshot of the running activity's ContentState, kept in sync with
    /// `activity.contentUpdates` so SwiftUI re-renders the Workout Active
    /// banner when pause/resume fire from the Dynamic Island.
    @State private var liveSnapshot: WorkoutActivityAttributes.ContentState? = nil

    // Feedback
    @State private var isSaving   = false
    @State private var saveError: String? = nil

    // Post workout prompt
    @State private var showingPostPrompt    = false
    @State private var savedWorkoutName     = ""
    @State private var savedWorkoutType     = WorkoutType.strength
    @State private var savedDuration        = 0
    @State private var savedCalories        = 0
    @State private var savedGym:             WorkoutLocation? = nil
    @State private var savedTaggedFriends:   [TaggedFriend]   = []
    @State private var savedExercises:       [Exercise]       = []

    // MARK: - Sub-types

    enum AIState: Equatable { case idle, analyzing, error(String) }

    // MARK: - Colors

    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var accent: Color { ThemeStore.shared.accent }
    private var gold: Color { ThemeStore.shared.accent }

    // MARK: - Init

    init(userID: String, selectedDate: Date, bodyWeightLbs: Double, autoAdjustByDefault: Bool,
         userSettings: UserSettings, editingEntry: WorkoutEntry? = nil,
         onSaved: @escaping () -> Void,
         saveTemplateMode: Bool = false,
         onSavedTemplate: ((SavedWorkout) -> Void)? = nil,
         isEmbedded: Bool = false,
         onClose: (() -> Void)? = nil,
         savedWorkoutMode: Bool = false) {
        self.userID              = userID
        self.selectedDate        = selectedDate
        self.bodyWeightLbs       = bodyWeightLbs
        self.autoAdjustByDefault = autoAdjustByDefault
        self.userSettings        = userSettings
        self.editingEntry        = editingEntry
        self.onSaved             = onSaved
        self.saveTemplateMode    = saveTemplateMode
        self.onSavedTemplate     = onSavedTemplate
        self.isEmbedded          = isEmbedded
        self.onClose             = onClose
        self.savedWorkoutMode    = savedWorkoutMode
        if let e = editingEntry {
            _workoutName     = State(initialValue: e.name)
            _workoutType     = State(initialValue: e.workoutType)
            _durationText    = State(initialValue: "\(e.durationMinutes)")
            _caloriesText    = State(initialValue: "\(e.caloriesBurned)")
            _logDate         = State(initialValue: Calendar.current.startOfDay(for: e.loggedAt))
            _logTime         = State(initialValue: e.loggedAt)
            _applyAdjustment = State(initialValue: e.adjustmentApplied)
            _exercises       = State(initialValue: e.exercises)
            _selectedGym     = State(initialValue: e.location)
            _taggedFriends   = State(initialValue: e.taggedFriends)
            _caloriesEdited  = State(initialValue: true)
        } else {
            let oneHourAgo = Date().addingTimeInterval(-60 * 60)
            _logDate         = State(initialValue: selectedDate)
            _logTime         = State(initialValue: oneHourAgo)
            _applyAdjustment = State(initialValue: autoAdjustByDefault)
        }
    }

    // MARK: - Body

    var body: some View {
        if isEmbedded {
            embeddedBody
        } else {
            sheetBody
        }
    }

    // MARK: - Embedded body (no NavigationStack — hosted inside FoodLogView)

    private var embeddedBody: some View {
        ZStack {
            pageBg.ignoresSafeArea()
            formContent
        }
        .onAppear { loadOnAppear() }
        .commonSheetModifiers(
            showingAIPaywall: $showingAIPaywall,
            workoutToDelete: $workoutToDelete,
            savedWorkouts: $savedWorkouts,
            showingPostPrompt: $showingPostPrompt,
            analyzeTranscript: { Task { await analyzeTranscript() } },
            onPostDismiss: { onSaved(); close() },
            postWorkoutView: postPromptSheet
        )
    }

    // MARK: - Sheet body (original NavigationStack presentation)

    private var sheetBody: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()
                formContent
            }
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { close() }
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .preferredColorScheme(.dark)
            .onAppear { loadOnAppear() }
            .commonSheetModifiers(
                showingAIPaywall: $showingAIPaywall,
                workoutToDelete: $workoutToDelete,
                savedWorkouts: $savedWorkouts,
                showingPostPrompt: $showingPostPrompt,
                analyzeTranscript: { Task { await analyzeTranscript() } },
                onPostDismiss: { onSaved(); close() },
                postWorkoutView: postPromptSheet
            )
            .keyboardDoneToolbar()
        }
    }

    // MARK: - Shared helpers

    private var titleText: String {
        if savedWorkoutMode { return editingEntry != nil ? "Edit Saved Workout" : "New Saved Workout" }
        return saveTemplateMode ? "New Saved Workout" : editingEntry != nil ? "Edit Workout" : "Log a Workout"
    }

    private func close() {
        endLiveActivity()
        if let c = onClose { c() } else { dismiss() }
    }

    private func loadOnAppear() {
        savedWorkouts = WorkoutService.shared.savedWorkouts
        Task {
            await aiSubscription.loadProduct()
            await aiSubscription.refreshEntitlement()
        }
        reattachRunningLiveActivity()
    }

    /// If a Live Activity is already running (e.g. the user tapped End from
    /// the lock screen and iOS re-opened the app, or they just foregrounded
    /// without ending), adopt it so its contentUpdates land in this sheet.
    private func reattachRunningLiveActivity() {
        guard liveActivity == nil,
              let running = Activity<WorkoutActivityAttributes>.activities.first
        else { return }
        liveActivity         = running
        workoutStartTime     = running.content.state.startedAt
        didConsumeLiveFinish = false
        mergeLiveActivityState(running.content.state)
        if running.content.state.isFinished {
            didConsumeLiveFinish = true
            consumeLiveActivityFinish(state: running.content.state)
            endLiveActivity()
        } else {
            observeLiveActivity()
        }
    }

    private var formContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !savedWorkouts.isEmpty { savedWorkoutsSection }
                if editingEntry == nil && !saveTemplateMode && !savedWorkoutMode { startWorkoutButton }
                voiceAssistCard
                manualForm
                macroAdjustmentCard
                if editingEntry == nil && !savedWorkoutMode { saveToggle }
                if !savedWorkoutMode { adjustToggle }
                saveButton
                if editingEntry == nil && !savedWorkoutMode { restDayButton }
                if let err = saveError {
                    Text(err).font(.caption).foregroundStyle(.red).multilineTextAlignment(.center)
                }
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .onChange(of: exercises)   { _, _ in pushFormToLiveActivity() }
        .onChange(of: workoutName) { _, _ in pushFormToLiveActivity() }
        .onChange(of: workoutType) { _, _ in pushFormToLiveActivity() }
    }

    private var postPromptSheet: some View {
        PostWorkoutSheet(
            userSettings:    userSettings,
            workoutName:     savedWorkoutName,
            workoutType:     savedWorkoutType,
            durationMinutes: savedDuration,
            caloriesBurned:  savedCalories,
            gym:             savedGym,
            taggedFriends:   savedTaggedFriends,
            exercises:       savedExercises
        )
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
            workoutName    = saved.name
            workoutType    = saved.workoutType
            durationText   = "\(saved.durationMinutes)"
            caloriesText   = "\(saved.caloriesBurned)"
            caloriesEdited = true
            exercises      = saved.exercises
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
                workoutToDelete = saved
            } label: { Label("Delete", systemImage: "trash") }
        }
    }

    // MARK: - Manual Form

    private var manualForm: some View {
        VStack(spacing: 14) {
            field(label: "Workout Name", placeholder: "e.g. Upper Body, 5 Mile Run", text: $workoutName)
            workoutTypeGrid
            HStack(spacing: 14) {
                field(label: "Duration (min)",  placeholder: "45",  text: $durationText, keyboardType: .numberPad)
                field(label: "Calories Burned", placeholder: "\(estimatedCaloriesPlaceholder)", text: caloriesFieldBinding, keyboardType: .numberPad)
            }
            exercisesSection
            if !savedWorkoutMode { gymRow }
            if !savedWorkoutMode { friendsRow }
            if !savedWorkoutMode { timePickerRow }
        }
        .onChange(of: workoutType)  { _, newType in
            autoFillCaloriesIfNeeded()
            if newType == .restDay {
                if workoutName.trimmingCharacters(in: .whitespaces).isEmpty {
                    workoutName = "Rest Day"
                }
                durationText  = "0"
                caloriesText  = "0"
                caloriesEdited = true
                exercises     = []
            }
        }
        .onChange(of: durationText) { _, _ in autoFillCaloriesIfNeeded() }
    }

    /// Inline gym tag row — compact card that shows "Tag a gym" when empty,
    /// or the selected gym's name (and optional address) when set. Tap opens
    /// the `GymPickerView` sheet.
    private var gymRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Gym / Location")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))

            Button { showingGymPicker = true } label: {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(accent.opacity(0.16))
                            .frame(width: 28, height: 28)
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                    if let gym = selectedGym {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(gym.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            if !gym.address.isEmpty {
                                Text(gym.address)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.45))
                                    .lineLimit(1)
                            }
                        }
                    } else {
                        Text("Tag a gym")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(accent.opacity(0.20), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showingGymPicker) {
            GymPickerView(current: selectedGym) { picked in
                selectedGym = picked
            }
            .presentationDetents([.large])
        }
    }

    /// Inline friends-tag row — shows a compact "people" icon + either the
    /// comma-separated list of tagged friend display names or a "Tag friends"
    /// CTA. Tap opens the `FriendTagPickerView` multi-select sheet.
    private var friendsRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tag Friends")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))

            Button { showingFriendPicker = true } label: {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(accent.opacity(0.16))
                            .frame(width: 28, height: 28)
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                    if taggedFriends.isEmpty {
                        Text("Tag friends")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                    } else {
                        Text(taggedFriendsSummary)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(accent.opacity(0.20), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showingFriendPicker) {
            FriendTagPickerView(
                currentUserID:    userID,
                initialSelection: taggedFriends,
                onDone: { picked in taggedFriends = picked }
            )
            .presentationDetents([.large])
        }
    }

    /// Condensed label — "@alice", "@alice & @bob", "@alice, @bob & 3 others".
    private var taggedFriendsSummary: String {
        let tags = taggedFriends
        let handles = tags.map { "@\($0.username)" }
        switch handles.count {
        case 0: return ""
        case 1: return handles[0]
        case 2: return "\(handles[0]) & \(handles[1])"
        default:
            let extras = handles.count - 2
            return "\(handles[0]), \(handles[1]) & \(extras) other\(extras == 1 ? "" : "s")"
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

    // MARK: - Voice / AI Assist

    /// Compact voice-input card. Tapping the mic records a description of the
    /// workout; "Generate with AI" parses it and fills in the manual form below.
    private var voiceAssistCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                WorkoutMicButton(
                    isRecording: speechRecognizer.status == .recording,
                    onTap: {
                        if speechRecognizer.status == .recording { speechRecognizer.stop() }
                        else { speechRecognizer.start() }
                    }
                )

                Text(micHint)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !editableTranscript.isEmpty || !speechRecognizer.transcript.isEmpty {
                TextEditor(text: $editableTranscript)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.85))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 70, maxHeight: 140)
                    .padding(10)
                    .background(pageBg, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.20), lineWidth: 1))
            }

            if speechRecognizer.status == .done && !editableTranscript.isEmpty {
                analyzeButton
            }

            if case .error(let msg) = speechRecognizer.status {
                Text(msg).font(.caption).foregroundStyle(.red).multilineTextAlignment(.center)
            }

            if case .error(let msg) = aiState {
                Text(msg).font(.caption).foregroundStyle(.red).multilineTextAlignment(.center)
            }
        }
        .padding(14)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 1))
        .onChange(of: speechRecognizer.transcript) { _, newValue in
            editableTranscript = newValue
        }
    }

    private var micHint: String {
        switch speechRecognizer.status {
        case .idle:                 return "Tap the mic and have AI log your entire workout"
        case .requestingPermission: return "Requesting permission…"
        case .recording:            return "Listening… tap to stop"
        case .done:                 return "Done recording"
        case .error:                return ""
        }
    }

    private var analyzeButton: some View {
        Button {
            if aiSubscription.isSubscribed {
                Task { await analyzeTranscript() }
            } else {
                showingAIPaywall = true
            }
        } label: {
            HStack(spacing: 8) {
                if aiState == .analyzing {
                    ProgressView().tint(accent)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(aiState == .analyzing
                     ? "Analyzing…"
                     : (aiSubscription.isSubscribed
                        ? "Generate with AI"
                        : (aiSubscription.isEligibleForIntroOffer
                           ? "Try AI Free for 3 Days"
                           : "Unlock AI Workout Logging")))
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

    private var timePickerRow: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Time Started")
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
            VStack(alignment: .leading, spacing: 6) {
                Text("Date")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                DatePicker("", selection: $logDate, displayedComponents: .date)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.20), lineWidth: 1))
            }
        }
    }

    // MARK: - Exercises (optional)

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Exercises")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                Text("optional")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.30))
                Spacer()
            }

            if !exercises.isEmpty {
                VStack(spacing: 8) {
                    ForEach(exercises) { ex in
                        if let idx = exercises.firstIndex(where: { $0.id == ex.id }) {
                            exerciseRow(index: idx)
                        }
                    }
                }
            }

            Button {
                exercises.append(Exercise(name: "", sets: [ExerciseSet(reps: 10)]))
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add Exercise")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(accent.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [4])))
            }
            .buttonStyle(.plain)
        }
    }

    private func exerciseRow(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: exercise name + delete-exercise button
            HStack(spacing: 8) {
                TextField("Exercise name", text: $exercises[index].name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(pageBg, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.08), lineWidth: 1))

                Button {
                    exercises.remove(at: index)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(10)
                }
                .buttonStyle(.plain)
            }

            // Set rows
            VStack(spacing: 6) {
                ForEach(Array(exercises[index].sets.enumerated()), id: \.element.id) { setIdx, _ in
                    setRow(exerciseIndex: index, setIndex: setIdx)
                }
            }

            // Add Set button
            Button {
                // Copy the previous set's values so adding a new set is fast.
                let template = exercises[index].sets.last
                exercises[index].sets.append(
                    ExerciseSet(reps: template?.reps ?? 10, weight: template?.weight)
                )
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Add Set")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(accent.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.15), lineWidth: 1))
    }

    /// One set-row within an exercise: "Set N · [reps] × [lb]  [trash]"
    private func setRow(exerciseIndex: Int, setIndex: Int) -> some View {
        let repsBinding = Binding<String>(
            get: { String(exercises[exerciseIndex].sets[setIndex].reps) },
            set: { newVal in
                if let n = Int(newVal.filter { $0.isNumber }), n > 0 {
                    exercises[exerciseIndex].sets[setIndex].reps = n
                } else if newVal.isEmpty {
                    exercises[exerciseIndex].sets[setIndex].reps = 0
                }
            }
        )
        let weightBinding = Binding<String>(
            get: {
                if let w = exercises[exerciseIndex].sets[setIndex].weight {
                    return w.truncatingRemainder(dividingBy: 1) == 0
                        ? String(Int(w)) : String(w)
                }
                return ""
            },
            set: { newVal in
                let t = newVal.trimmingCharacters(in: .whitespaces)
                if t.isEmpty {
                    exercises[exerciseIndex].sets[setIndex].weight = nil
                } else if let d = Double(t) {
                    exercises[exerciseIndex].sets[setIndex].weight = d
                }
            }
        )

        return HStack(spacing: 8) {
            Text("Set \(setIndex + 1)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.40))
                .frame(width: 40, alignment: .leading)

            TextField("10", text: repsBinding)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48)
                .padding(.vertical, 8)
                .background(pageBg, in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.08), lineWidth: 1))
            Text("reps")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.40))

            TextField("lb", text: weightBinding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56)
                .padding(.vertical, 8)
                .background(pageBg, in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.08), lineWidth: 1))
            Text("lb")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.40))

            Spacer()

            Button {
                guard exercises[exerciseIndex].sets.count > 1 else { return }
                exercises[exerciseIndex].sets.remove(at: setIndex)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(exercises[exerciseIndex].sets.count > 1 ? 0.35 : 0.15))
            }
            .buttonStyle(.plain)
            .disabled(exercises[exerciseIndex].sets.count <= 1)
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
                    adjustRow(label: "Calories", base: Int(base.calories), adjusted: Int(preview.calories), delta: adj.caloriesDelta, unit: "kcal", macroColor: .orange)
                    Divider().frame(height: 32).background(.white.opacity(0.10))
                    adjustRow(label: "Carbs",    base: Int(base.carbs),    adjusted: Int(preview.carbs),    delta: adj.carbsDelta,    unit: "g",    macroColor: .macroMint)
                    Divider().frame(height: 32).background(.white.opacity(0.10))
                    adjustRow(label: "Protein",  base: Int(base.protein),  adjusted: Int(preview.protein),  delta: adj.proteinDelta,  unit: "g",    macroColor: .macroBlue)
                    Divider().frame(height: 32).background(.white.opacity(0.10))
                    adjustRow(label: "Fat",      base: Int(base.fat),      adjusted: Int(preview.fat),      delta: adj.fatDelta,      unit: "g",    macroColor: .macroRose)
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

    private func adjustRow(label: String, base: Int, adjusted: Int, delta: Int, unit: String, macroColor: Color) -> some View {
        let deltaColor: Color = delta > 0 ? macroColor : delta < 0 ? Color(red: 1, green: 0.45, blue: 0.45) : .white.opacity(0.40)
        return VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(macroColor)
            Text("\(adjusted)\(unit)")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(delta == 0 ? "—" : (delta > 0 ? "+\(delta)" : "\(delta)"))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(deltaColor)
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

    // MARK: - Start Workout Button

    /// Opens the live in-session tracker. The tracker lets the user step
    private var startWorkoutButton: some View {
        Group {
            if let startTime = workoutStartTime {
                let isPaused = liveSnapshot?.isPaused ?? false
                let accent: Color = isPaused ? .yellow : .green
                HStack(spacing: 12) {
                    Image(systemName: isPaused ? "pause.fill" : "timer")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(accent)
                        .frame(width: 36, height: 36)
                        .background(accent.opacity(0.15), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isPaused ? "Paused" : "Workout Active")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(accent)
                        if isPaused, let state = liveSnapshot {
                            Text(elapsedString(seconds: state.elapsedSeconds()))
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .monospacedDigit()
                        } else {
                            let pausedFor = liveSnapshot?.accumulatedPaused ?? 0
                            let effectiveStart = startTime.addingTimeInterval(pausedFor)
                            TimelineView(.periodic(from: effectiveStart, by: 1)) { ctx in
                                Text(elapsed(from: effectiveStart, to: ctx.date))
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .monospacedDigit()
                            }
                        }
                    }
                    Spacer()
                    Button { toggleLivePause() } label: {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 36, height: 36)
                            .background(accent, in: Circle())
                    }
                    .buttonStyle(.plain)
                    Text(isPaused ? "PAUSE" : "LIVE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accent, in: Capsule())
                }
                .padding(14)
                .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.30), lineWidth: 1))
            } else {
                Button {
                    let t = Date()
                    workoutStartTime = t
                    logTime = t
                    logDate = Calendar.current.startOfDay(for: t)
                    startLiveActivity(at: t)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 15, weight: .bold))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Start Workout")
                                .font(.system(size: 15, weight: .bold))
                            Text("Start a live timer and Live Activity")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.black.opacity(0.65))
                        }
                        Spacer()
                    }
                    .foregroundStyle(.black)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(accent, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func elapsed(from start: Date, to now: Date) -> String {
        let secs = max(0, Int(now.timeIntervalSince(start)))
        return String(format: "%d:%02d", secs / 60, secs % 60)
    }

    private func startLiveActivity(at start: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // Seed at least one empty exercise so the Live Activity controls
        // (reps +/-, Add Set, Next) have something to operate on.
        if exercises.isEmpty {
            exercises = [Exercise(name: "", sets: [ExerciseSet(reps: 10)])]
        }

        let state = currentLiveActivityState(startedAt: start, isFinished: false)
        do {
            liveActivity = try Activity.request(
                attributes: WorkoutActivityAttributes(),
                content:    .init(state: state, staleDate: nil)
            )
            liveSnapshot         = state
            didConsumeLiveFinish = false
            observeLiveActivity()
            print("[LiveActivity] started: \(liveActivity?.id ?? "?")")
        } catch {
            print("[LiveActivity] request failed: \(error)")
        }
    }

    private func endLiveActivity() {
        guard let activity = liveActivity else { return }
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
        liveActivity = nil
    }

    /// Send current form state to the running activity so edits made in the
    /// app (exercise name, reps, weight, sets, workout name, workout type)
    /// appear on the lock screen and Dynamic Island immediately. Preserves
    /// the activity's own non-form fields — `currentIndex`, pause state —
    /// so they aren't clobbered when the form doesn't know about them.
    private func pushFormToLiveActivity() {
        guard let activity = liveActivity,
              let snap = liveSnapshot,
              !snap.isFinished
        else { return }
        var state = currentLiveActivityState(startedAt: snap.startedAt,
                                             isFinished: false)
        state.currentIndex      = min(max(0, snap.currentIndex),
                                      max(0, state.exercises.count - 1))
        state.pausedAt          = snap.pausedAt
        state.accumulatedPaused = snap.accumulatedPaused
        // Skip when nothing changed — breaks the echo loop between an
        // intent-driven update → mergeLiveActivityState → onChange → here.
        if state == snap { return }
        liveSnapshot = state
        let snapshot = state
        Task { await activity.update(ActivityContent(state: snapshot, staleDate: nil)) }
    }

    /// Flip pause on the running activity. Mirrors WorkoutPauseIntent /
    /// WorkoutResumeIntent so the in-app button and the Live Activity
    /// button drive the same state.
    private func toggleLivePause() {
        guard let activity = liveActivity else { return }
        var state = activity.content.state
        if let paused = state.pausedAt {
            state.accumulatedPaused += Date().timeIntervalSince(paused)
            state.pausedAt = nil
        } else {
            state.pausedAt = Date()
        }
        let snapshot = state
        Task { await activity.update(ActivityContent(state: snapshot, staleDate: nil)) }
    }

    /// "MM:SS" / "H:MM:SS" formatter used by the paused banner.
    private func elapsedString(seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }

    /// Build a ContentState from the current form fields.
    private func currentLiveActivityState(startedAt: Date,
                                          isFinished: Bool) -> WorkoutActivityAttributes.ContentState {
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
            workoutTypeRaw: workoutType.rawValue,
            startedAt:      startedAt,
            currentIndex:   0,
            exercises:      liveExercises,
            isFinished:     isFinished
        )
    }

    /// Subscribe to content updates from the running activity so changes
    /// made via Live Activity intents (reps +/-, Add Set, Next Exercise,
    /// End Workout) flow back into the form.
    private func observeLiveActivity() {
        guard let activity = liveActivity else { return }
        let updates = activity.contentUpdates
        Task { @MainActor in
            for await content in updates {
                mergeLiveActivityState(content.state)
                if content.state.isFinished && !didConsumeLiveFinish {
                    didConsumeLiveFinish = true
                    consumeLiveActivityFinish(state: content.state)
                    endLiveActivity()
                    break
                }
            }
        }
    }

    /// Copy non-terminal ContentState updates into the form's exercises
    /// list and workout name — so reps / added sets / next-exercise taps
    /// done from the lock screen or Dynamic Island appear here in real time.
    private func mergeLiveActivityState(_ state: WorkoutActivityAttributes.ContentState) {
        liveSnapshot = state
        if !state.workoutName.isEmpty { workoutName = state.workoutName }
        exercises = state.exercises.map { liveEx in
            Exercise(
                id:   liveEx.id,
                name: liveEx.name,
                sets: liveEx.sets.map { ExerciseSet(id: $0.id, reps: $0.reps, weight: $0.weight) }
            )
        }
    }

    /// Called once, when the Live Activity reports `isFinished = true`. Drops
    /// the "Workout Active" banner, writes the final elapsed duration into
    /// the form, and re-fills the calorie estimate.
    private func consumeLiveActivityFinish(state: WorkoutActivityAttributes.ContentState) {
        let minutes = max(1, Int((Date().timeIntervalSince(state.startedAt) / 60.0).rounded()))
        durationText    = "\(minutes)"
        caloriesEdited  = false
        autoFillCaloriesIfNeeded()
        workoutStartTime = nil
    }

    // MARK: - Save Button

    private var canSave: Bool {
        let name = !workoutName.trimmingCharacters(in: .whitespaces).isEmpty
        let dur  = (Int(durationText) ?? 0)
        let cal  = (Int(caloriesText) ?? 0) >= 0
        // Rest days don't need a duration — everything else does.
        if workoutType == .restDay { return name && cal }
        return name && dur > 0 && cal
    }

    private var saveButton: some View {
        Button { Task { saveTemplateMode ? saveTemplate() : await saveWorkout() } } label: {
            HStack(spacing: 8) {
                if isSaving { ProgressView().tint(.black) }
                else { Image(systemName: "checkmark") }
                Text(isSaving ? "Saving…" : saveTemplateMode ? "Save Workout" : editingEntry != nil ? "Save Changes" : "Log Workout")
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
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                workoutName   = "Rest Day"
                workoutType   = .restDay
                durationText  = "0"
                caloriesText  = "0"
                exercises     = []
                selectedGym   = nil
                taggedFriends = []
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "moon.zzz.fill")
                Text("Rest Day")
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

    // MARK: - Calorie Estimation

    /// MET value for a workout type. Mid-range figures from the ACSM
    /// Compendium of Physical Activities. These double as the activity
    /// factor in the BMR-based calculation below — 1 MET is by definition
    /// the resting kcal-per-kg-per-hour rate, so multiplying MET by
    /// (BMR / 24) gives a personalized kcal/hour estimate.
    private func metValue(for type: WorkoutType) -> Double {
        switch type {
        case .strength:    return 5.5
        case .cardio:      return 7.5
        case .hiit:        return 9.0
        case .flexibility: return 2.5
        case .restDay:     return 0
        case .other:       return 5.0
        }
    }

    /// Resting kcal/hour from Mifflin-St Jeor BMR, or nil if the profile
    /// is missing height — in which case the caller falls back to a
    /// pure weight-based MET estimate.
    ///
    /// Formula mirrors `HomeViewModel.recalculateMacrosFromGoalWeight` so
    /// the two calorie codepaths stay in sync. Age defaults to 20 via
    /// `ageInYears`; gender falls back to the midpoint offset (-78) when
    /// unset, same as the goal-weight calculation.
    private var restingKcalPerHour: Double? {
        let heightIn = userSettings.heightInches
        guard heightIn > 0 else { return nil }
        let weightKg = max(40, bodyWeightLbs) * 0.453592
        let heightCm = Double(heightIn) * 2.54
        let age      = Double(userSettings.ageInYears)
        let g        = userSettings.gender
        let genderOffset: Double = g == "male" ? 5.0 : g == "female" ? -161.0 : -78.0
        let bmr      = 10.0 * weightKg + 6.25 * heightCm - 5.0 * age + genderOffset
        return max(bmr, 800) / 24.0
    }

    /// kcal estimate for a workout. Uses Mifflin-St Jeor BMR × activity
    /// factor when the user's profile has height (and weight), so that
    /// age, sex, and height all feed in. Falls back to the simpler
    /// MET × body-weight formula for profiles missing height.
    private func estimateCalories(type: WorkoutType, durationMinutes: Int) -> Int {
        guard durationMinutes > 0, type != .restDay else { return 0 }
        let met   = metValue(for: type)
        let hours = Double(durationMinutes) / 60.0
        let kcalPerHour: Double
        if let resting = restingKcalPerHour {
            // BMR/24 is 1-MET energy expenditure for this specific body.
            kcalPerHour = met * resting
        } else {
            let kg = max(40, bodyWeightLbs) / 2.20462
            kcalPerHour = met * kg
        }
        return Int((kcalPerHour * hours).rounded())
    }

    /// Placeholder text for the Calories field: shows the live estimate once a duration is entered.
    private var estimatedCaloriesPlaceholder: String {
        if let mins = Int(durationText), mins > 0 {
            return "\(estimateCalories(type: workoutType, durationMinutes: mins))"
        }
        return "350"
    }

    /// Keeps the Calories field in sync with the live estimate as long as the
    /// user hasn't manually overridden it. Once `caloriesEdited` is true (user
    /// typed a value, AI filled it, a saved template set it, or an existing
    /// entry loaded it), auto-updates stop.
    private func autoFillCaloriesIfNeeded() {
        guard !caloriesEdited,
              let mins = Int(durationText), mins > 0,
              workoutType != .restDay else { return }
        caloriesText = "\(estimateCalories(type: workoutType, durationMinutes: mins))"
    }

    /// Binding for the Calories TextField that flips `caloriesEdited` on any
    /// user edit so the live estimate stops tracking. Clearing the field
    /// resumes tracking.
    private var caloriesFieldBinding: Binding<String> {
        Binding(
            get: { caloriesText },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                caloriesText   = newValue
                caloriesEdited = !trimmed.isEmpty
                // When the user clears the field, immediately resume tracking
                // the live estimate so the placeholder is replaced.
                if trimmed.isEmpty { autoFillCaloriesIfNeeded() }
            }
        )
    }

    // MARK: - Actions

    private func analyzeTranscript() async {
        guard !editableTranscript.isEmpty else { return }
        let isFirstGeneration = exercises.isEmpty
        aiState = .analyzing
        do {
            let result = try await ClaudeAnalysisService().parseWorkout(transcript: editableTranscript)
            if isFirstGeneration {
                // First generation: populate all fields from scratch
                workoutName    = result.name
                workoutType    = result.workoutType
                durationText   = "\(result.durationMinutes)"
                caloriesText   = "\(result.caloriesBurned)"
                caloriesEdited = true
                if !result.exercises.isEmpty {
                    exercises = result.exercises
                }
                // Default start time to (now − duration) so the picker reflects when
                // the workout actually began. Only for new entries; don't overwrite
                // a user-edited start time on an existing workout.
                if editingEntry == nil, result.durationMinutes > 0 {
                    logTime = Date().addingTimeInterval(-Double(result.durationMinutes) * 60)
                }
            } else {
                // Subsequent generation: append exercises, accumulate duration & calories
                if !result.exercises.isEmpty {
                    exercises.append(contentsOf: result.exercises)
                }
                let existingDuration = Int(durationText) ?? 0
                let existingCalories = Int(caloriesText) ?? 0
                durationText   = "\(existingDuration + result.durationMinutes)"
                caloriesText   = "\(existingCalories + result.caloriesBurned)"
                caloriesEdited = true
            }
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

    /// Save-template-only mode: creates a SavedWorkout without logging anything.
    private func saveTemplate() {
        let name = workoutName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let cleanedExercises: [Exercise] = exercises.compactMap { ex in
            let trimmed = ex.name.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            let sets = ex.sets.isEmpty ? [ExerciseSet(reps: 1)] : ex.sets.map { ExerciseSet(id: $0.id, reps: max(1, $0.reps), weight: $0.weight) }
            return Exercise(id: ex.id, name: trimmed, sets: sets)
        }

        let template = SavedWorkout(
            name:            name,
            workoutType:     workoutType,
            durationMinutes: Int(durationText) ?? 0,
            caloriesBurned:  Int(caloriesText) ?? 0,
            exercises:       cleanedExercises
        )
        onSavedTemplate?(template)
        close()
    }

    private func saveWorkout() async {
        let name     = workoutName.trimmingCharacters(in: .whitespaces)
        let duration = Int(durationText) ?? 0
        let calories = Int(caloriesText) ?? 0
        guard !name.isEmpty, (duration > 0 || workoutType == .restDay) else { return }

        isSaving  = true
        saveError = nil

        // Combine the user-chosen date with the user-chosen time
        let loggedAt = combinedDate(date: logDate, time: logTime)

        // Drop half-filled exercise rows (blank name) and normalize empty set counts.
        let cleanedExercises: [Exercise] = exercises.compactMap { ex in
            let trimmedName = ex.name.trimmingCharacters(in: .whitespaces)
            guard !trimmedName.isEmpty else { return nil }
            let normalizedSets: [ExerciseSet] = {
                let src = ex.sets.isEmpty ? [ExerciseSet(reps: 1)] : ex.sets
                return src.map { s in
                    ExerciseSet(id: s.id, reps: max(1, s.reps), weight: s.weight)
                }
            }()
            return Exercise(id: ex.id, name: trimmedName, sets: normalizedSets)
        }

        // Preserve the original workoutID when editing so Firestore overwrites the same document
        let entry = WorkoutEntry(
            workoutID:          editingEntry?.workoutID ?? UUID().uuidString,
            name:               name,
            workoutType:        workoutType,
            durationMinutes:    duration,
            caloriesBurned:     calories,
            loggedAt:           loggedAt,
            adjustmentApplied:  applyAdjustment,
            exercises:          cleanedExercises,
            location:           selectedGym,
            taggedFriends:      taggedFriends
        )
        do {
            try await WorkoutService.shared.save(entry: entry, userID: userID)

            if saveAsTemplate {
                WorkoutService.shared.addSavedWorkout(
                    SavedWorkout(name: name, workoutType: workoutType,
                                 durationMinutes: duration, caloriesBurned: calories,
                                 exercises: cleanedExercises)
                )
            }

            if Calendar.current.isDateInToday(logDate) {
                if applyAdjustment {
                    // Re-applies for the (possibly changed) workout type — safe to call on new or edited entries
                    MacroAdjustmentEngine.apply(for: workoutType, bodyWeightLbs: bodyWeightLbs)
                } else if editingEntry != nil {
                    // Editing with adjustment OFF: restore base goals
                    MacroAdjustmentEngine.revert()
                }
            }

            endLiveActivity()
            savedWorkoutName  = name
            savedWorkoutType  = workoutType
            savedDuration     = duration
            savedCalories     = calories
            savedGym           = selectedGym
            savedTaggedFriends = taggedFriends
            savedExercises     = cleanedExercises
            isSaving           = false
            // Skip the post prompt when editing an existing workout
            if editingEntry != nil {
                onSaved()
                close()
            } else {
                showingPostPrompt = true
            }
        } catch {
            isSaving  = false
            saveError = "Failed to save. Please try again."
        }
    }

}

// MARK: - Shared sheet modifiers

private struct CommonSheetModifiers<PostView: View>: ViewModifier {
    @Binding var showingAIPaywall:  Bool
    @Binding var workoutToDelete:   SavedWorkout?
    @Binding var savedWorkouts:     [SavedWorkout]
    @Binding var showingPostPrompt: Bool
    let analyzeTranscript: () -> Void
    let onPostDismiss:     () -> Void
    let postWorkoutView:   PostView

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showingAIPaywall) {
                AISubscriptionPaywallView(
                    onSubscribed: { showingAIPaywall = false; analyzeTranscript() },
                    onDismiss:    { showingAIPaywall = false }
                )
            }
            .alert("Delete Saved Workout?", isPresented: Binding(
                get: { workoutToDelete != nil },
                set: { if !$0 { workoutToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) { workoutToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let w = workoutToDelete {
                        WorkoutService.shared.deleteSavedWorkout(id: w.id)
                        savedWorkouts = WorkoutService.shared.savedWorkouts
                        workoutToDelete = nil
                    }
                }
            } message: {
                if let w = workoutToDelete { Text("Delete \"\(w.name)\"? This cannot be undone.") }
            }
            .sheet(isPresented: $showingPostPrompt, onDismiss: onPostDismiss) {
                postWorkoutView
            }
    }
}

extension View {
    fileprivate func commonSheetModifiers<PostView: View>(
        showingAIPaywall:  Binding<Bool>,
        workoutToDelete:   Binding<SavedWorkout?>,
        savedWorkouts:     Binding<[SavedWorkout]>,
        showingPostPrompt: Binding<Bool>,
        analyzeTranscript: @escaping () -> Void,
        onPostDismiss:     @escaping () -> Void,
        postWorkoutView:   PostView
    ) -> some View {
        self.modifier(CommonSheetModifiers(
            showingAIPaywall:  showingAIPaywall,
            workoutToDelete:   workoutToDelete,
            savedWorkouts:     savedWorkouts,
            showingPostPrompt: showingPostPrompt,
            analyzeTranscript: analyzeTranscript,
            onPostDismiss:     onPostDismiss,
            postWorkoutView:   postWorkoutView
        ))
    }
}

// MARK: - Pulsing Mic Button

private struct WorkoutMicButton: View {
    let isRecording: Bool
    let onTap: () -> Void

    @State private var pulse = false

    private let gold = Color(red: 1.0, green: 0.84, blue: 0.30)   // #FFD64D

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Outer pulse ring — always in hierarchy so layout never shifts
                Circle()
                    .stroke(gold.opacity(pulse ? 0.10 : 0.55), lineWidth: 1.5)
                    .frame(width: 56, height: 56)

                // Gold circle border
                Circle()
                    .stroke(gold, lineWidth: 1.8)
                    .frame(width: 44, height: 44)

                // Filled tint when recording
                Circle()
                    .fill(gold.opacity(isRecording ? 0.20 : 0.0))
                    .frame(width: 44, height: 44)

                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(gold)
            }
            .frame(width: 58, height: 58)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
