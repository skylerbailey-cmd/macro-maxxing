//
//  FoodLogView.swift
//  Wellness
//

import SwiftUI
import SwiftData
import CoreLocation

// MARK: - FoodLogView

struct FoodLogView: View {
    @State private var viewModel:    FoodLogViewModel
    @State private var analyzeVM:    AnalyzeViewModel
    @Binding var selectedDate: Date
    let userSettings: UserSettings
    @Binding var externalImage: UIImage?
    @Binding var openLogMealTrigger: Bool
    @Environment(NotificationState.self) private var notificationState
    @State private var showingTutorial        = false
    @State private var tutorialAnchors:       [String: Anchor<CGRect>] = [:]
    @State private var editingEntry: FoodEntry? = nil
    @State private var showingFuelLogPost    = false
    @State private var showingSettings       = false
    @State private var showingNotifications  = false

    // Meal Inspo post flow — captured from food confirmation
    @State private var showingMealInspoPost   = false
    @State private var createMealInspoPost    = false
    @State private var mealInspoImage:       UIImage? = nil
    @State private var mealInspoResult:      FoodRecognitionResult? = nil
    @State private var mealInspoScore:       Int = 0

    // Single active-sheet enum for the meal-logging flow
    @State private var activeMealSheet: MealSheet? = nil
    @State private var showingAIConsent = false
    @State private var showingAIPaywall = false
    @State private var aiSubscription = AISubscriptionStore.shared
    /// Pending meal sheet kind to open once the user subscribes (camera / photoLibrary).
    @State private var pendingMealSheetAfterSubscribe: MealSheet? = nil

    enum MealSheet: Identifiable {
        case camera
        case photoLibrary
        case analysis
        case confirmation

        var id: Int {
            switch self {
            case .camera:       return 0
            case .photoLibrary: return 1
            case .analysis:     return 2
            case .confirmation: return 3
            }
        }
    }

    // Timeline filter (replaces the old Fuel/Duel sub-tabs)

    // Workout entries for the selected day — fetched alongside food entries so
    // the unified timeline can show meals and workouts together.
    @State private var workoutEntries: [WorkoutEntry] = []
    @State private var editingWorkout: WorkoutEntry? = nil

    // Eating window state (mirrors UserDefaults written by HomeViewModel)
    @State private var wStartHour: Int = UserDefaults.standard.integer(forKey: "windowStartHour")
    @State private var wStartMin:  Int = UserDefaults.standard.integer(forKey: "windowStartMinute")
    @State private var wDuration:  Int = {
        let d = UserDefaults.standard.integer(forKey: "windowDurationHours")
        return d > 0 ? d : 16
    }()
    @State private var showingWindowPicker = false
    /// 0 = Meals, 1 = Workout
    @State private var logTab: Int = 0
    @Binding var openLogWorkoutTrigger: Bool

    // Save today's meals as a meal plan day
    @State private var showSaveToPlanAlert = false
    @State private var savePlanName        = ""
    @State private var isSavingToPlan      = false

    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) private var locationManager

    init(modelContext: ModelContext, selectedDate: Binding<Date>, userSettings: UserSettings,
         externalImage: Binding<UIImage?> = .constant(nil),
         openLogMealTrigger: Binding<Bool> = .constant(false),
         openLogWorkoutTrigger: Binding<Bool> = .constant(false)) {
        _viewModel  = State(wrappedValue: FoodLogViewModel(
            selectedDate: selectedDate.wrappedValue,
            userID: userSettings.userID
        ))
        _analyzeVM  = State(wrappedValue: AnalyzeViewModel(
            userID:       userSettings.userID,
            selectedDate: selectedDate.wrappedValue
        ))
        _selectedDate           = selectedDate
        _externalImage          = externalImage
        _openLogMealTrigger     = openLogMealTrigger
        _openLogWorkoutTrigger  = openLogWorkoutTrigger
        self.userSettings       = userSettings
    }

    private var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }
    /// True for today and the past two days — Save Day button is shown.
    private var isRecentDay: Bool {
        let cal = Calendar.current
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: cal.startOfDay(for: Date()))!
        return selectedDate >= twoDaysAgo
    }
    /// Editing allowed for today and yesterday — anything older is view-only.
    private var isEditableDate: Bool {
        let cal = Calendar.current
        return cal.isDateInToday(selectedDate) || cal.isDateInYesterday(selectedDate)
    }

    var body: some View {
        mainContent
            .onPreferenceChange(TutorialAnchorKey.self) { tutorialAnchors = $0 }
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNotifications) {
                NotificationsView(userSettings: userSettings, notificationState: notificationState)
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack { SettingsView(userSettings: userSettings) }
            }
            // Surfaces the first sync failure of the session (once).
            // The per-row badge keeps signalling stranded meals after
            // the alert is dismissed, so the user can still act.
            .alert(
                "Couldn't sync meal",
                isPresented: Binding(
                    get: { viewModel.syncFailureAlert != nil },
                    set: { if !$0 { viewModel.syncFailureAlert = nil } }
                ),
                presenting: viewModel.syncFailureAlert
            ) { _ in
                Button("OK", role: .cancel) { viewModel.syncFailureAlert = nil }
            } message: { message in
                Text(message)
            }
            .alert("Save Day as Meal Plan", isPresented: $showSaveToPlanAlert) {
                TextField("Plan name (e.g. High Protein Day)", text: $savePlanName)
                Button("Save") {
                    let name = savePlanName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    Task { await saveTodayAsMealPlan(name: name) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("\(viewModel.todayEntries.count) meal\(viewModel.todayEntries.count == 1 ? "" : "s") from this day will be saved as a reusable day you can import into any meal plan.")
            }
            .onAppear(perform: handleOnAppear)
            .onReceive(NotificationCenter.default.publisher(for: .init("FoodEntryAdded"))) { _ in
                Task { await viewModel.loadTodayEntries() }
            }
            .onChange(of: selectedDate, handleDateChange)
            .onChange(of: viewModel.selectedImage) { _, newValue in
                guard newValue != nil else { return }
                // Always allow users to reach the analysis sheet so they can
                // log the meal manually. AI features inside the sheet are
                // gated by subscription/consent individually.
                activeMealSheet = .analysis
            }
            .onChange(of: viewModel.analysisState) { _, newState in
                if case .confirmed = newState {
                    // Only open the photo-confirmation sheet when there's an
                    // image to confirm. Text-only AI analysis (manual tab)
                    // populates the macro fields inline — no separate sheet.
                    guard viewModel.selectedImage != nil else { return }
                    activeMealSheet = nil
                    Task {
                        try? await Task.sleep(nanoseconds: 450_000_000)
                        activeMealSheet = .confirmation
                    }
                }
            }
            .onChange(of: externalImage, handleExternalImage)
            // `initial: true` fires the handler once when FoodLogView first
            // subscribes — covers the case where the FAB set the trigger to
            // `true` before this tab existed in the view hierarchy (tab
            // switch + flag flip happen in the same runloop pass).
            .onChange(of: openLogMealTrigger, initial: true) { _, trigger in
                if trigger {
                    activeMealSheet = .analysis
                    openLogMealTrigger = false
                }
            }
            .onChange(of: openLogWorkoutTrigger, initial: true) { _, trigger in
                if trigger {
                    logTab = 1
                    openLogWorkoutTrigger = false
                }
            }
            .onChange(of: viewModel.showingCamera) { _, show in
                if show { activeMealSheet = .camera }
            }
            .onChange(of: viewModel.showingPhotoLibrary) { _, show in
                if show { activeMealSheet = .photoLibrary }
            }
            .sheet(item: $activeMealSheet, onDismiss: handleMealSheetDismiss) { sheet in
                switch sheet {
                case .camera:
                    ImagePickerView(sourceType: .camera, selectedImage: $viewModel.selectedImage)
                case .photoLibrary:
                    ImagePickerView(sourceType: .photoLibrary, selectedImage: $viewModel.selectedImage)
                case .analysis:
                    analysisSheet
                case .confirmation:
                    confirmationSheet
                }
            }
            .sheet(item: $editingEntry) { entry in
                editSheet(for: entry)
            }
            .sheet(isPresented: $showingFuelLogPost) {
                fuelLogPostSheet
            }
            .sheet(isPresented: $showingMealInspoPost) {
                if let result = mealInspoResult {
                    NewPostView(
                        userSettings:          userSettings,
                        preSelectedLabel:      .mealInspo,
                        prePopulatedPhoto:     mealInspoImage,
                        prePopulatedCalories:  result.calories,
                        prePopulatedProtein:   result.protein,
                        prePopulatedCarbs:     result.carbs,
                        prePopulatedFat:       result.fat,
                        prePopulatedMealScore: mealInspoScore,
                        prePopulatedFoodName:  result.foodName
                    )
                }
            }
            .sheet(isPresented: $showingWindowPicker) {
                windowPickerSheet
            }
            .sheet(isPresented: $showingAIConsent) {
                AIConsentSheet(
                    onAgree: {
                        userSettings.aiConsentGiven = true
                        activeMealSheet = .analysis
                    },
                    onDecline: {
                        // Switch to manual entry mode — user can still log food without AI
                        viewModel.analysisState = .result
                    }
                )
            }
            .sheet(isPresented: $showingAIPaywall) {
                AISubscriptionPaywallView(
                    onSubscribed: {
                        showingAIPaywall = false
                    },
                    onDismiss: {
                        showingAIPaywall = false
                    }
                )
            }
            .onChange(of: wDuration) { _, newVal in
                UserDefaults.standard.set(newVal, forKey: "windowDurationHours")
                saveWindowToFirestore()
            }
            .keyboardDoneToolbar()
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ZStack {
            Color.pageBg.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                DateNavigatorView(selectedDate: $selectedDate)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                // Meals | Workout segment picker
                logTabPicker
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                if logTab == 0 {
                    ConditionalBannerAd(isEnabled: RemoteConfigService.shared.logTabBannerEnabled)
                    dayViewContent
                } else {
                    embeddedWorkoutTab
                }
            }

            if logTab == 0 { tutorialOverlay }
        }
    }

    private var logTabPicker: some View {
        HStack(spacing: 0) {
            ForEach([("Meals", 0), ("Workout", 1)], id: \.1) { label, idx in
                Button {
                    withAnimation(.spring(duration: 0.2)) { logTab = idx }
                } label: {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(logTab == idx ? .black : .white.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(logTab == idx ? ThemeStore.shared.accent : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .animation(.spring(duration: 0.2), value: logTab)
            }
        }
        .padding(4)
        .background(Capsule().fill(Color.cardBg))
    }

    private var embeddedWorkoutTab: some View {
        LogWorkoutSheet(
            userID:              userSettings.userID,
            selectedDate:        selectedDate,
            bodyWeightLbs:       userSettings.currentWeight,
            autoAdjustByDefault: userSettings.autoAdjustMacrosForWorkout,
            userSettings:        userSettings,
            onSaved:             { Task { await loadWorkouts() } },
            isEmbedded:          true,
            onClose:             { withAnimation { logTab = 0 } }
        )
        .environment(locationManager)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Fuel Log")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            headerButtons
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var headerButtons: some View {
        HStack(spacing: 14) {
            Button { showingTutorial = true } label: {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Help")
            .accessibilityHint("Shows the Fuel Log tutorial")

            BellButton(showingNotifications: $showingNotifications, notificationState: notificationState)

            Button { showingSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(ThemeStore.shared.accent)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens settings")
        }
    }

    // MARK: - Day View Content

    private var dayViewContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                timelineSection
                    .padding(.top, 6)

                if !isEditableDate {
                    pastDateNotice
                }

            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 100)
        }
        .task(id: selectedDate) { await loadWorkouts() }
        .onReceive(NotificationCenter.default.publisher(for: WorkoutService.workoutSavedNotification)) { _ in
            Task { await loadWorkouts() }
        }
        .sheet(item: $editingWorkout) { entry in
            EditWorkoutSheet(entry: entry, onSave: { name, type, duration, calories, time, exercises in
                Task {
                    var updated = entry
                    updated.name            = name
                    updated.workoutType     = type
                    updated.durationMinutes = duration
                    updated.caloriesBurned  = calories
                    updated.loggedAt        = time
                    updated.exercises       = exercises
                    try? await WorkoutService.shared.save(entry: updated, userID: userSettings.userID)
                    await loadWorkouts()
                }
            }, onDelete: {
                Task {
                    await WorkoutService.shared.delete(workoutID: entry.workoutID, userID: userSettings.userID)
                    workoutEntries.removeAll { $0.workoutID == entry.workoutID }
                    if isToday { MacroAdjustmentEngine.revert() }
                }
            })
        }
    }

    private func loadWorkouts() async {
        workoutEntries = (try? await WorkoutService.shared.fetch(userID: userSettings.userID, date: selectedDate)) ?? []
    }

    // MARK: - Timeline (unified meals + workouts)

    /// One entry in the merged timeline — sorted by `loggedAt` descending.
    private enum TimelineItem: Identifiable {
        case meal(FoodEntry)
        case workout(WorkoutEntry)

        var id: String {
            switch self {
            case .meal(let e):    return "m-\(e.id.uuidString)"
            case .workout(let e): return "w-\(e.workoutID)"
            }
        }
        var loggedAt: Date {
            switch self {
            case .meal(let e):    return e.loggedAt
            case .workout(let e): return e.loggedAt
            }
        }
    }

    private var timelineItems: [TimelineItem] {
        let meals    = viewModel.todayEntries.map(TimelineItem.meal)
        let workouts = workoutEntries.map(TimelineItem.workout)
        return (meals + workouts).sorted { $0.loggedAt > $1.loggedAt }
    }

    /// Timeline layout:
    ///  - Both meals AND workouts present → grouped with MEALS / WORKOUTS headers.
    ///  - Only one type present → flat list (no header needed to "separate" one thing).
    ///  - Neither present → empty state.
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isToday && userSettings.fastingEnabled {
                eatingWindowCard
            }

            if timelineItems.isEmpty {
                timelineEmptyState
            } else {
                timelineCountLabel
                    .tutorialAnchor("log.tabBar")

                if !viewModel.todayEntries.isEmpty, !workoutEntries.isEmpty {
                    groupedTimeline
                } else {
                    ForEach(timelineItems) { item in
                        timelineRow(item)
                    }
                }
            }
        }
    }

    /// Both-types view — meals section first, workouts second. Each
    /// section is sorted newest → oldest within itself.
    private var groupedTimeline: some View {
        let meals    = viewModel.todayEntries.sorted { $0.loggedAt > $1.loggedAt }
        let workouts = workoutEntries.sorted        { $0.loggedAt > $1.loggedAt }
        return VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "MEALS", count: meals.count)
            ForEach(meals) { entry in
                timelineRow(.meal(entry))
            }

            sectionHeader(title: "WORKOUTS", count: workouts.count)
                .padding(.top, 6)
            ForEach(workouts) { entry in
                timelineRow(.workout(entry))
            }
        }
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.45))
            Text("\(count)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.50))
                .padding(.horizontal, 6)
                .padding(.vertical, 1.5)
                .background(Color.white.opacity(0.06), in: Capsule())
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func timelineRow(_ item: TimelineItem) -> some View {
        switch item {
        case .meal(let entry):
            FoodEntryRow(entry: entry,
                         onEdit:      isEditableDate ? { editingEntry = entry } : {},
                         onDelete:    { viewModel.deleteEntry(entry) },
                         onDuplicate: isEditableDate ? { viewModel.duplicateEntry(entry) } : nil,
                         canEdit:     isEditableDate,
                         syncState:   viewModel.syncState(for: entry),
                         onRetry:     { viewModel.retrySync(entry) })
        case .workout(let entry):
            WorkoutRow(
                entry:  entry,
                accent: ThemeStore.shared.accent,
                cardBg: Color.cardBg,
                onEdit:   { if isEditableDate { editingWorkout = entry } },
                onDelete: {
                    Task {
                        await WorkoutService.shared.delete(workoutID: entry.workoutID, userID: userSettings.userID)
                        workoutEntries.removeAll { $0.workoutID == entry.workoutID }
                        if isToday { MacroAdjustmentEngine.revert() }
                    }
                }
            )
        }
    }

    private var timelineCountLabel: some View {
        let meals    = viewModel.todayEntries.count
        let workouts = workoutEntries.count
        let accent   = ThemeStore.shared.accent
        return HStack(alignment: .center, spacing: 0) {
            Text("\(meals) meal\(meals == 1 ? "" : "s") · \(workouts) workout\(workouts == 1 ? "" : "s")")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.30))
            Spacer()
            if isRecentDay && !viewModel.todayEntries.isEmpty {
                Button {
                    savePlanName = ""
                    showSaveToPlanAlert = true
                } label: {
                    HStack(spacing: 4) {
                        if isSavingToPlan {
                            ProgressView().scaleEffect(0.65).tint(accent)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Save Meal Plan")
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                    .foregroundStyle(accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(accent.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isSavingToPlan)
            }
        }
        .padding(.top, 2)
    }

    private var timelineEmptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.purpleHi.opacity(0.10))
                    .frame(width: 72, height: 72)
                Image(systemName: "sparkles")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.purpleHi.opacity(0.45))
            }
            VStack(spacing: 4) {
                Text("Nothing logged yet")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                Text("Tap the + button below to log one.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.32))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var pastDateNotice: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.caption)
            Text("Dates older than yesterday are view-only.")
                .font(.caption)
        }
        .foregroundStyle(.white.opacity(0.30))
        .padding(.vertical, 4)
    }
    
    // MARK: - Tutorial Overlay
    
    @ViewBuilder
    private var tutorialOverlay: some View {
        if showingTutorial {
            TutorialOverlayView(steps: TutorialSteps.log, anchors: tutorialAnchors, onDismiss: {
                withAnimation(.easeOut(duration: 0.25)) { showingTutorial = false }
            })
            .transition(.opacity.animation(.easeInOut(duration: 0.25)))
            .zIndex(100)
        }
    }
    
    // MARK: - Sheet Views

    private func editSheet(for entry: FoodEntry) -> some View {
        EditEntrySheet(entry: entry, onSave: { name, cal, pro, carb, fat, time in
            viewModel.updateEntry(entry, foodName: name,
                                  calories: cal, protein: pro,
                                  carbs: carb, fat: fat,
                                  loggedAt: time)
        }, onDelete: {
            viewModel.deleteEntry(entry)
        }, onDuplicate: isEditableDate ? {
            viewModel.duplicateEntry(entry)
        } : nil)
        .presentationDetents([.medium])
    }
    
    private var analysisSheet: some View {
        AnalysisSheet(viewModel: viewModel, userSettings: userSettings, onSaved: {
            activeMealSheet = nil
        }, onMealInspoPost: { image, result, score in
            mealInspoImage  = image
            mealInspoResult = result
            mealInspoScore  = score
            activeMealSheet = nil
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                showingMealInspoPost = true
            }
        })
        .presentationDetents([.large])
    }

    @ViewBuilder
    private var confirmationSheet: some View {
        if let image = viewModel.selectedImage,
           viewModel.recognitionResult != nil {
            FoodConfirmationView(
                image: image,
                recognitionResult: Binding(
                    get: { viewModel.recognitionResult ?? FoodRecognitionResult(
                        foodName: "", calories: 0, protein: 0, carbs: 0, fat: 0,
                        portionGrams: 0, tier: 0, source: "", confidence: 0,
                        needsUserConfirmation: true
                    )},
                    set: { viewModel.recognitionResult = $0 }
                ),
                saveMeal: $viewModel.saveMeal,
                createMealInspoPost: $createMealInspoPost,
                onConfirm: { result in
                    // Capture data for meal inspo post before clearing
                    let wantsPost = createMealInspoPost
                    if wantsPost {
                        mealInspoImage  = image
                        mealInspoResult = result
                        mealInspoScore  = Self.computeMealScore(
                            calories: result.calories,
                            protein:  result.protein,
                            carbs:    result.carbs,
                            fat:      result.fat
                        )
                    }

                    viewModel.confirmResult(result)
                    viewModel.saveEntry()
                    activeMealSheet = nil
                    // Merge-safe reload — pending local entries won't disappear
                    Task { await viewModel.loadTodayEntries() }

                    // Open NewPostView after the confirmation sheet dismisses
                    if wantsPost {
                        createMealInspoPost = false
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            showingMealInspoPost = true
                        }
                    }
                },
                onEscalate: {
                    Task { await viewModel.escalateAnalysis() }
                },
                onCancel: {
                    activeMealSheet = nil
                    viewModel.discardEntry()
                }
            )
            .presentationDetents([.large])
        }
    }
    
    private var fuelLogPostSheet: some View {
        FuelLogPostSheet(
            entries:      viewModel.todayEntries,
            logDate:      selectedDate,
            userSettings: userSettings,
            modelContext: modelContext
        )
    }
    
    private var windowPickerSheet: some View {
        WindowPickerSheet(
            windowStartDate: windowStartDate,
            windowDurationHours: $wDuration
        )
        .presentationDetents([.medium])
    }
    
    // MARK: - Lifecycle Handlers
    
    private func handleOnAppear() {
        viewModel.userID = userSettings.userID
        viewModel.selectedDate = selectedDate
        // Fetch from Firestore — merge logic in loadTodayEntries preserves
        // any pending local entries that haven't synced yet.
        Task { await viewModel.loadTodayEntries() }
        // Refresh eating window state from UserDefaults
        wStartHour = UserDefaults.standard.integer(forKey: "windowStartHour")
        wStartMin  = UserDefaults.standard.integer(forKey: "windowStartMinute")
        let d = UserDefaults.standard.integer(forKey: "windowDurationHours")
        wDuration  = d > 0 ? d : 16
        // Refresh AI subscription state so paid/locked buttons render correctly.
        Task {
            await aiSubscription.loadProduct()
            await aiSubscription.refreshEntitlement()
        }
    }
    
    private func handleDateChange(_ oldDate: Date, _ newDate: Date) {
        viewModel.selectedDate   = newDate
        analyzeVM.selectedDate   = newDate
        analyzeVM.reset()
    }
    
    private func handleMealSheetDismiss() {
        // Sync the ViewModel flags back when the sheet closes
        viewModel.showingCamera = false
        viewModel.showingPhotoLibrary = false
        // If we dismissed from analysis without moving to confirmation, discard
        // (confirmation sets activeMealSheet to nil then re-opens, so it won't be .analysis here)
        if activeMealSheet == nil && viewModel.selectedImage != nil {
            // Check if we're NOT about to open confirmation (handled by the delayed dispatch)
            if case .confirmed = viewModel.analysisState { } else {
                viewModel.discardEntry()
            }
        }
    }

    private func handleExternalImage(_ oldImage: UIImage?, _ image: UIImage?) {
        guard let img = image else { return }
        viewModel.selectedImage = img
        externalImage = nil
        // The onChange(of: viewModel.selectedImage) handler checks consent
        // and opens either the consent sheet or the analysis sheet.
    }

    // MARK: - Meal Score Helper

    /// Computes the 0–100 meal score from raw macros using the user's goal ratios.
    static func computeMealScore(calories: Int, protein: Double, carbs: Double, fat: Double) -> Int {
        guard calories >= 300 else { return 0 }
        let ud = UserDefaults.standard
        func g(_ key: String, fallback: Double) -> Double {
            ud.object(forKey: key) != nil ? ud.double(forKey: key) : fallback
        }
        let pCal  = g("goalProtein", fallback: 150) * 4
        let cCal  = g("goalCarbs",   fallback: 200) * 4
        let fCal  = g("goalFat",     fallback:  65) * 9
        let total = pCal + cCal + fCal
        guard total > 0 else { return 50 }
        let goalP = pCal / total, goalC = cCal / total, goalF = fCal / total
        let cal = Double(calories)
        let actualP = (protein * 4) / cal
        let actualC = (carbs   * 4) / cal
        let actualF = (fat     * 9) / cal
        let dev = abs(actualP - goalP) + abs(actualC - goalC) + abs(actualF - goalF)
        return max(0, min(100, Int(((1.0 - dev / 2.0) * 100).rounded())))
    }

    // MARK: - Save Day as Meal Plan

    @MainActor
    private func saveTodayAsMealPlan(name: String) async {
        guard !viewModel.todayEntries.isEmpty else { return }
        isSavingToPlan = true
        defer { isSavingToPlan = false }

        var savedMealIDs: [String] = []
        for entry in viewModel.todayEntries {
            // Create a saved-meal copy of each entry and persist to Firestore.
            let copy = FoodEntry(
                loggedAt: Date(),
                userID:   userSettings.userID,
                foodName: entry.foodName,
                calories: entry.calories,
                protein:  entry.protein,
                carbs:    entry.carbs,
                fat:      entry.fat
            )
            copy.isSavedMeal = true
            if let result = try? await FoodEntryService.shared.save(
                entry: copy, imageData: nil, existingPhotoURL: entry.photoURL
            ) {
                savedMealIDs.append(result.docID)
            }
        }

        guard !savedMealIDs.isEmpty else { return }
        let day  = PlanDay(label: "Day 1", itemIDs: savedMealIDs)
        let plan = MealPlan(name: name, days: [day])
        FoodEntryService.shared.addMealPlan(plan, userID: userSettings.userID)
    }

    // MARK: - FAB with label

    private func fabWithLabel(icon: String, label: String, color: Color, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(disabled ? Color.white.opacity(0.08) : color.opacity(0.85))
                    .clipShape(Circle())
                    .shadow(color: disabled ? .clear : color.opacity(0.45), radius: 10, y: 4)
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(disabled ? 0.20 : 0.50))
            }
        }
        .disabled(disabled)
        .buttonStyle(.plain)
    }

    // MARK: - Log Meals (AI Nutrition Coach) section

    @State private var showLogMealsConfirm = false

    private var analyzeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.purpleHi)
                Text("AI Nutrition Coach")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            // Description / result
            switch analyzeVM.state {
            case .idle:
                if analyzeVM.hasRunToday {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green.opacity(0.75))
                        Text("Already logged today. Come back tomorrow for a fresh suggestion.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.50))
                    }
                } else {
                    Text("Reviews your full day — every meal, macro distribution, workout timing — and gives you a personalized nutritionist-level debrief with actionable advice. Once per day.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.50))
                        .lineSpacing(2)
                }

            case .analyzing:
                CoachSkeletonView()

            case .result(let text):
                resultText(text)

            case .error(let msg):
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text(msg).font(.caption).foregroundStyle(.white.opacity(0.65))
                }
            }

            // Button
            Button {
                if !aiSubscription.isSubscribed {
                    showingAIPaywall = true
                } else if !userSettings.aiConsentGiven {
                    showingAIConsent = true
                } else {
                    showLogMealsConfirm = true
                }
            } label: {
                // Gold background drawn directly on the label (plain button
                // style) so the .shimmering overlay sits on top of the gold
                // instead of getting swallowed by .borderedProminent's own
                // shape/clipping.
                let done = analyzeVM.hasRunToday && aiSubscription.isSubscribed
                let background: Color = done ? .gray : .premiumGold
                HStack(spacing: 6) {
                    if !aiSubscription.isSubscribed {
                        Image(systemName: "sparkles")
                        Text(aiSubscription.isEligibleForIntroOffer
                             ? "Try AI Free for 3 Days"
                             : "Unlock AI Nutrition Coach")
                    } else if analyzeVM.hasRunToday {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Done for Today")
                    } else {
                        Image(systemName: "wand.and.stars")
                        Text("Get My Recommendation")
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(background, in: RoundedRectangle(cornerRadius: 10))
                .shimmering(cornerRadius: 10)
            }
            .buttonStyle(.plain)
            .disabled(aiSubscription.isSubscribed && (analyzeVM.state == .analyzing || analyzeVM.hasRunToday))
            .alert("Get My Recommendation?", isPresented: $showLogMealsConfirm) {
                Button("Let's Go", role: .none) {
                    let doAnalyze = { Task { await analyzeVM.analyze() } }
                    if RemoteConfigService.shared.nutritionCoachAdRequired {
                        AdManager.shared.showRewarded(onReward: { _ = doAnalyze() })
                    } else {
                        _ = doAnalyze()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Reviews your full day of meals, macros, and workouts to give you a personalized nutrition debrief. Once per day.")
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(16)
        .overlay(
            ShootingStarBorder(
                cornerRadius: 16,
                color: ThemeStore.shared.accent,
                lineWidth: 1.5,
                duration: 3.2,
                reversed: true
            )
        )
    }

    @ViewBuilder
    private func resultText(_ text: String) -> some View {
        // Insert paragraph breaks before bold section headers that run together
        let processed = text.replacingOccurrences(
            of: #"([.!?;—])\s*(\d*\.?\s*\*\*[A-Z])"#,
            with: "$1\n\n$2",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        let paragraphs = processed
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                if let attr = try? AttributedString(
                    markdown: paragraph,
                    options: AttributedString.MarkdownParsingOptions(
                        interpretedSyntax: .full
                    )
                ) {
                    Text(attr)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.80))
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(paragraph)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.80))
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Eating window helpers

    private func saveWindowToFirestore() {
        let uid = userSettings.userID
        guard !uid.isEmpty else { return }
        let h = wStartHour, m = wStartMin, d = wDuration
        Task {
            try? await UserProfileService.shared.updateProfile(
                userID: uid,
                fields: [
                    "windowStartHour":     h,
                    "windowStartMinute":   m,
                    "windowDurationHours": d
                ]
            )
        }
    }

    private func timeString(hour: Int, minute: Int) -> String {
        var comps = DateComponents()
        comps.hour = hour; comps.minute = minute
        guard let date = Calendar.current.date(from: comps) else { return "" }
        let f = DateFormatter(); f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    private var windowStartDate: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: wStartHour, minute: wStartMin, second: 0, of: Date()
                ) ?? Date()
            },
            set: { newDate in
                wStartHour = Calendar.current.component(.hour,   from: newDate)
                wStartMin  = Calendar.current.component(.minute, from: newDate)
                UserDefaults.standard.set(wStartHour, forKey: "windowStartHour")
                UserDefaults.standard.set(wStartMin,  forKey: "windowStartMinute")
                saveWindowToFirestore()
            }
        )
    }

    @ViewBuilder
    private var eatingWindowCard: some View {
        if userSettings.fastingEnabled {
            let startFrac = Double(wStartHour) + Double(wStartMin) / 60.0
            let endFrac   = startFrac + Double(wDuration)
            let endHour   = Int(endFrac) % 24
            let endMin    = Int((endFrac - Double(Int(endFrac))) * 60)
            let mealTimes = viewModel.todayEntries.map { e -> Double in
                let cal = Calendar.current
                return Double(cal.component(.hour,   from: e.loggedAt))
                     + Double(cal.component(.minute, from: e.loggedAt)) / 60.0
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9)
                                .fill(Color.purpleHi.opacity(0.18))
                                .frame(width: 30, height: 30)
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.purpleHi)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Eating Window")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                            Text("\(timeString(hour: wStartHour, minute: wStartMin)) – \(timeString(hour: endHour, minute: endMin)) · \(wDuration)h")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.45))
                        }
                    }
                    Spacer()
                    if isToday {
                        Button("Edit") { showingWindowPicker = true }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.purpleHi)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.purpleHi.opacity(0.14))
                            .cornerRadius(8)
                    } else {
                        Text("Locked")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.25))
                    }
                }
                FastingTimelineView(
                    windowStart: startFrac,
                    windowEnd:   endFrac.truncatingRemainder(dividingBy: 24),
                    mealLogTimes: mealTimes
                )
            }
            .padding(16)
            .background(Color.cardBg)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.purpleHi.opacity(0.18), lineWidth: 1)
            )
        }
    }

}

// MARK: - Analysis Sheet

struct AnalysisSheet: View {
    @Bindable var viewModel: FoodLogViewModel
    let userSettings: UserSettings
    let onSaved: () -> Void
    var onMealInspoPost: ((UIImage?, FoodRecognitionResult, Int) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var mode: EntryMode    = .photo
    @State private var speechRecognizer  = SpeechRecognizer()
    @State private var skeletonPulse     = false
    @State private var showSaveError     = false
    @State private var createMealInspoPost = false

    // In-sheet image picker source (for the two-square selector)
    @State private var pickerSource: ImageSourceKind? = nil

    // AI gating (paywall + consent) — checked per AI action so users can still
    // log the meal manually without encountering a paywall.
    @State private var aiSubscription     = AISubscriptionStore.shared
    @State private var showingAIPaywall   = false
    @State private var showingAIConsent   = false
    @State private var pendingAIAction: PendingAIAction? = nil

    enum EntryMode { case photo, voice, manual }
    enum PendingAIAction { case analyze, analyzeWithVoice, reanalyze, analyzeFromText }

    enum ImageSourceKind: Int, Identifiable {
        case camera, photoLibrary
        var id: Int { rawValue }
        var sourceType: UIImagePickerController.SourceType {
            self == .camera ? .camera : .photoLibrary
        }
    }

    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var accent: Color { ThemeStore.shared.accent }
    private var gold: Color { Color.premiumGold }

    private var hasPhoto: Bool { viewModel.selectedImage != nil }
    private var showFields: Bool {
        if mode == .manual || viewModel.analysisState == .result {
            return true
        }
        if case .confirmed = viewModel.analysisState {
            return true
        }
        if case .error = viewModel.analysisState {
            return true
        }
        return false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Food photo — or two picker squares if no image yet
                        if let image = viewModel.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 190)
                                .clipped()
                                .cornerRadius(16)
                        } else {
                            photoSourceSquares
                        }

                        // Saved meals quick-select
                        if !viewModel.savedMeals.isEmpty {
                            savedMealsSection
                        }

                        // Mode picker
                        modePicker

                        // Mode-specific action area
                        switch mode {
                        case .photo:
                            photoContent
                        case .voice:
                            voiceContent
                        case .manual:
                            EmptyView()
                        }

                        // Skeleton
                        if viewModel.analysisState == .analyzing {
                            skeletonFields
                        }

                        // Entry fields
                        if showFields && viewModel.analysisState != .analyzing {
                            // Tier indicator + re-scan option
                            if viewModel.analysisTier == .local {
                                HStack(spacing: 8) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 11))
                                        Text("Identified locally")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundStyle(Color(red: 0.35, green: 1.0, blue: 0.60))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(red: 0.35, green: 1.0, blue: 0.60).opacity(0.12), in: Capsule())

                                    Spacer()

                                    Button {
                                        requestAI(action: .reanalyze)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 10))
                                            Text("Not right? Try AI scan")
                                                .font(.system(size: 11, weight: .semibold))
                                        }
                                        .foregroundStyle(accent)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            entryFields
                            saveToggle
                            mealInspoToggle
                            saveButton
                        }

                        if showSaveError {
                            Text("Fill in all macro fields before saving.")
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
            .navigationTitle(viewModel.savedMealOnlyMode ? "New Saved Meal" : "Log Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        speechRecognizer.reset()
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.65))
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                // Default to Manual; switch to Photo only when a photo is attached
                mode = hasPhoto ? .photo : .manual
                if mode == .manual { viewModel.analysisState = .result }
                Task { await viewModel.loadSavedMeals() }
            }
            .onDisappear { speechRecognizer.reset() }
            .sheet(isPresented: $showingAIPaywall) {
                AISubscriptionPaywallView(
                    onSubscribed: {
                        showingAIPaywall = false
                        // Resume whichever AI action the user tried to run.
                        if userSettings.aiConsentGiven {
                            if let action = pendingAIAction {
                                pendingAIAction = nil
                                runAI(action: action)
                            }
                        } else {
                            showingAIConsent = true
                        }
                    },
                    onDismiss: {
                        showingAIPaywall = false
                        pendingAIAction = nil
                    }
                )
            }
            .sheet(isPresented: $showingAIConsent) {
                AIConsentSheet(
                    onAgree: {
                        userSettings.aiConsentGiven = true
                        showingAIConsent = false
                        if let action = pendingAIAction {
                            pendingAIAction = nil
                            runAI(action: action)
                        }
                    },
                    onDecline: {
                        showingAIConsent = false
                        pendingAIAction = nil
                    }
                )
            }
            .sheet(item: $pickerSource) { source in
                ImagePickerView(
                    sourceType: source.sourceType,
                    selectedImage: $viewModel.selectedImage
                )
            }
            .onChange(of: viewModel.selectedImage) { _, newImage in
                // When an image is picked inside the sheet, switch to Photo mode
                // and reset analysis state so the "Analyze Photo" button shows.
                if newImage != nil {
                    mode = .photo
                    if case .confirmed = viewModel.analysisState { } else {
                        viewModel.analysisState = .idle
                    }
                }
            }
            .keyboardDoneToolbar()
        }
    }

    // MARK: - Photo Source Squares

    private var photoSourceSquares: some View {
        HStack(spacing: 12) {
            photoSourceSquare(
                icon: "camera.fill",
                label: "Camera",
                disabled: !UIImagePickerController.isSourceTypeAvailable(.camera)
            ) {
                pickerSource = .camera
            }
            photoSourceSquare(
                icon: "photo.on.rectangle",
                label: "Photos"
            ) {
                pickerSource = .photoLibrary
            }
        }
        .frame(height: 190)
    }

    private func photoSourceSquare(icon: String, label: String,
                                   disabled: Bool = false,
                                   action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(disabled ? accent.opacity(0.25) : accent)
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(disabled ? .white.opacity(0.30) : .white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(cardBg, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        accent.opacity(disabled ? 0.10 : 0.35),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    // MARK: - AI Gating

    private func requestAI(action: PendingAIAction) {
        if !aiSubscription.isSubscribed {
            pendingAIAction = action
            showingAIPaywall = true
        } else if !userSettings.aiConsentGiven {
            pendingAIAction = action
            showingAIConsent = true
        } else {
            runAI(action: action)
        }
    }

    private func runAI(action: PendingAIAction) {
        Task {
            switch action {
            case .analyze:          await viewModel.analyzeImage()
            case .analyzeWithVoice: await viewModel.analyzeImageWithVoice()
            case .reanalyze:        await viewModel.reanalyzeWithClaude()
            case .analyzeFromText:  await viewModel.analyzeFromText()
            }
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        HStack(spacing: 0) {
            modeTab(label: "Manual", icon: "keyboard",            tag: .manual)
            modeTab(label: "Voice",  icon: "mic.fill",            tag: .voice)
            if hasPhoto {
                modeTab(label: "Photo",  icon: "camera.viewfinder", tag: .photo)
            }
        }
        .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 1))
    }

    private func modeTab(label: String, icon: String, tag: EntryMode) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                mode = tag
                if tag == .manual { viewModel.analysisState = .result }
            }
            speechRecognizer.reset()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
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

    // MARK: - Photo Content

    private var photoContent: some View {
        Group {
            if viewModel.analysisState == .idle {
                VStack(spacing: 12) {
                    // Optional text hint for the AI
                    HStack(spacing: 8) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 13))
                            .foregroundStyle(accent.opacity(0.60))
                        TextField("Add details (e.g. \"2 eggs with toast\")", text: $viewModel.voiceNote)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    }
                    .padding(12)
                    .background(cardBg, in: RoundedRectangle(cornerRadius: 10))

                    Button {
                        let hasVoiceNote = !viewModel.voiceNote.trimmingCharacters(in: .whitespaces).isEmpty
                        requestAI(action: hasVoiceNote ? .analyzeWithVoice : .analyze)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Analyze Photo")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(accent, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Voice Content

    private var voiceContent: some View {
        VStack(spacing: 16) {
            // Mic button
            Button {
                if speechRecognizer.status == .recording { speechRecognizer.stop() }
                else { speechRecognizer.start() }
            } label: {
                ZStack {
                    Circle()
                        .fill(speechRecognizer.status == .recording
                              ? accent.opacity(0.20) : cardBg)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle().stroke(
                                speechRecognizer.status == .recording ? accent : .white.opacity(0.15),
                                lineWidth: 2
                            )
                        )
                    Image(systemName: speechRecognizer.status == .recording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(
                            speechRecognizer.status == .recording ? accent : .white.opacity(0.65)
                        )
                }
            }
            .buttonStyle(.plain)

            Text(voiceMicHint)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)

            // Transcript bubble
            if !speechRecognizer.transcript.isEmpty {
                Text(speechRecognizer.transcript)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.80))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.20), lineWidth: 1)
                    )
            }

            // Error from speech
            if case .error(let msg) = speechRecognizer.status {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            // Analyze button
            if speechRecognizer.status == .done && !speechRecognizer.transcript.isEmpty
                && viewModel.analysisState == .idle {
                Button {
                    viewModel.voiceNote = speechRecognizer.transcript
                    requestAI(action: hasPhoto ? .analyzeWithVoice : .analyze)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Generate with AI")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accent, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var voiceMicHint: String {
        switch speechRecognizer.status {
        case .idle:                 return "Tap the mic and describe what you ate"
        case .requestingPermission: return "Requesting permission…"
        case .recording:            return "Listening… tap to stop"
        case .done:                 return speechRecognizer.transcript.isEmpty
                                        ? "Nothing heard — try again" : "Tap to re-record"
        case .error:                return ""
        }
    }

    // MARK: - Skeleton

    private var skeletonFields: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ProgressView().tint(accent).scaleEffect(0.80)
                Text("Analyzing…")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.45))
            }

            VStack(spacing: 10) {
                skeletonRow("Food",     "Identifying food…")
                skeletonRow("Calories", "—— kcal")
                skeletonRow("Protein",  "——g")
                skeletonRow("Carbs",    "——g")
                skeletonRow("Fat",      "——g")
            }
            .opacity(skeletonPulse ? 0.30 : 0.70)
            .animation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true),
                       value: skeletonPulse)
            .onAppear   { skeletonPulse = true  }
            .onDisappear { skeletonPulse = false }
        }
    }

    private func skeletonRow(_ label: String, _ placeholder: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.40))
                .frame(width: 72, alignment: .leading)
            Spacer()
            Text(placeholder)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Entry Fields

    private var entryFields: some View {
        VStack(spacing: 12) {
            HStack(alignment: .bottom, spacing: 8) {
                macroField(label: "Food", placeholder: "Food name", text: $viewModel.foodName, unit: nil, keyboard: .default)
                // AI generate button — sends the typed food name to Haiku for
                // macro estimation. Gated behind the subscription paywall.
                let isEmpty = viewModel.foodName.trimmingCharacters(in: .whitespaces).isEmpty
                let gold = Color(red: 1.00, green: 0.75, blue: 0.20)
                Button {
                    requestAI(action: .analyzeFromText)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                        Text("AI")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(isEmpty ? .white.opacity(0.20) : gold)
                    .frame(width: 52)
                    .padding(.vertical, 12)
                    .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isEmpty ? Color.white.opacity(0.06) : gold.opacity(0.40),
                                    lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isEmpty || viewModel.analysisState == .analyzing)
            }
            macroField(label: "Calories", placeholder: "0",         text: $viewModel.caloriesText,  unit: "kcal", keyboard: .decimalPad)
            HStack(spacing: 12) {
                macroField(label: "Protein", placeholder: "0", text: $viewModel.proteinText, unit: "g", keyboard: .decimalPad)
                macroField(label: "Carbs",   placeholder: "0", text: $viewModel.carbsText,   unit: "g", keyboard: .decimalPad)
                macroField(label: "Fat",     placeholder: "0", text: $viewModel.fatText,     unit: "g", keyboard: .decimalPad)
            }

            if case .error(let msg) = viewModel.analysisState {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.red)
                    Spacer()
                    Button {
                        Task { await viewModel.analyzeImage() }
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(accent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func macroField(label: String, placeholder: String, text: Binding<String>,
                            unit: String?, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.40))
                if let unit {
                    Text(unit)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.25))
                }
            }
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.20), lineWidth: 1))
        }
    }

    // MARK: - Save Toggle

    private var saveToggle: some View {
        Group {
            if !viewModel.isFromSavedMeal {
                Toggle(isOn: $viewModel.saveMeal) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Save as Saved Meal")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Quick-select this meal next time")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.40))
                    }
                }
                .tint(accent)
                .padding(14)
                .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Meal Inspo Toggle

    private var mealInspoToggle: some View {
        Toggle(isOn: $createMealInspoPost) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Create Meal Inspo Post")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text("After logging, a post will open so you can share this meal on your feed")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.40))
            }
        }
        .tint(PostLabel.mealInspo.color)
        .padding(14)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Save Button

    private var canSave: Bool {
        !viewModel.caloriesText.isEmpty && !viewModel.proteinText.isEmpty &&
        !viewModel.carbsText.isEmpty   && !viewModel.fatText.isEmpty
    }

    private var saveButton: some View {
        Button {
            if canSave {
                showSaveError = false
                if viewModel.saveEntry() {
                    if createMealInspoPost {
                        let result = FoodRecognitionResult(
                            foodName: viewModel.foodName,
                            calories: Int(viewModel.caloriesText) ?? 0,
                            protein: Double(viewModel.proteinText) ?? 0,
                            carbs: Double(viewModel.carbsText) ?? 0,
                            fat: Double(viewModel.fatText) ?? 0,
                            portionGrams: 0, tier: 0, source: "manual", confidence: 1.0,
                            needsUserConfirmation: false
                        )
                        let score = FoodLogView.computeMealScore(
                            calories: result.calories,
                            protein:  result.protein,
                            carbs:    result.carbs,
                            fat:      result.fat
                        )
                        onMealInspoPost?(viewModel.selectedImage, result, score)
                    }
                    onSaved()
                }
            } else {
                showSaveError = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                Text(viewModel.savedMealOnlyMode ? "Save Meal" : "Log Food")
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(canSave ? accent : accent.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Saved Meals Section

    private var savedMealsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Saved Meals")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.sortedSavedMeals) { meal in
                        savedMealChip(meal)
                    }
                }
            }
        }
    }

    private func savedMealChip(_ meal: FoodEntry) -> some View {
        Button {
            viewModel.populateFromSavedMeal(meal)
            viewModel.analysisState = .result
        } label: {
            HStack(spacing: 10) {
                if let url = URL(string: meal.photoURL), !meal.photoURL.isEmpty {
                    CachedAsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Color.white.opacity(0.05)
                    }
                    .id(meal.photoURL)
                    .frame(width: 38, height: 38)
                    .clipped()
                    .cornerRadius(8)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(accent.opacity(0.12))
                            .frame(width: 38, height: 38)
                        Image(systemName: "fork.knife")
                            .font(.system(size: 14))
                            .foregroundStyle(accent.opacity(0.60))
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.foodName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(Int(meal.calories)) cal · \(String(format: "%.0f", meal.protein))p")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(accent.opacity(0.20), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                viewModel.deleteSavedMeal(meal)
            } label: {
                Label("Delete Saved Meal", systemImage: "trash")
            }
        }
    }
}

// MARK: - Food Entry Row

private struct FoodEntryRow: View {
    let entry:       FoodEntry
    let onEdit:      () -> Void
    let onDelete:    () -> Void
    var onDuplicate: (() -> Void)? = nil
    var canEdit:     Bool = true
    /// Sync status for the row — .failed gets a visible warning badge and
    /// an action sheet offering "Try again" / "Delete". .pending and
    /// .synced render identically (no visible badge for pending — the
    /// user doesn't need to know about in-flight retries).
    var syncState:   FoodEntrySyncState = .synced
    var onRetry:     (() -> Void)? = nil

    @State private var showScoreInfo = false
    @State private var showingSyncFailureActions = false

    var body: some View {
        if canEdit {
            rowContent
                .contentShape(Rectangle())
                .onTapGesture {
                    if syncState == .failed {
                        showingSyncFailureActions = true
                    } else {
                        onEdit()
                    }
                }
                .contextMenu {
                    Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
                    if let onDuplicate {
                        Button { onDuplicate() } label: { Label("Duplicate", systemImage: "doc.on.doc") }
                    }
                    if syncState == .failed, let onRetry {
                        Button { onRetry() } label: { Label("Retry upload", systemImage: "arrow.clockwise") }
                    }
                    Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
                }
                .confirmationDialog(
                    "This meal didn't upload",
                    isPresented: $showingSyncFailureActions,
                    titleVisibility: .visible
                ) {
                    if let onRetry {
                        Button("Try again") { onRetry() }
                    }
                    Button("Edit details") { onEdit() }
                    Button("Delete meal", role: .destructive) { onDelete() }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("The meal is saved on this device but didn't sync to the cloud. Try again when you have a stable connection.")
                }
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            Group {
                if let data = entry.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else if !entry.photoURL.isEmpty, let url = URL(string: entry.photoURL) {
                    CachedAsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Color.white.opacity(0.06)
                            .overlay {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white.opacity(0.25))
                            }
                    }
                    .id(entry.photoURL)
                } else {
                    Color.white.opacity(0.06)
                        .overlay {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 20))
                                .foregroundStyle(.white.opacity(0.25))
                        }
                }
            }
            .frame(width: 62, height: 62)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(entry.foodName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if syncState == .failed {
                        // Tappable warning badge — makes a stranded meal
                        // obvious at a glance. Tapping the row surfaces
                        // the Retry / Delete action sheet.
                        Image(systemName: "exclamationmark.icloud.fill")
                            .font(.caption)
                            .foregroundStyle(Color.orange)
                            .accessibilityLabel("Not uploaded — tap for options")
                    }
                    Spacer()
                    scoreCircle
                    Text(entry.loggedAt, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.28))
                }
                HStack(spacing: 5) {
                    macroBadge("\(Int(entry.calories)) kcal", color: .orange)
                    macroBadge("\(Int(entry.protein))g P",    color: Color(red: 0.35, green: 0.75, blue: 1.00))
                    macroBadge("\(Int(entry.carbs))g C",      color: Color(red: 0.40, green: 0.90, blue: 0.72))
                    macroBadge("\(Int(entry.fat))g F",        color: Color(red: 1.00, green: 0.50, blue: 0.72))
                }
            }
        }
        .padding(14)
        .background(Color.cardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private func macroBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.13))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    // MARK: - Meal Score

    /// Goal macro ratios as caloric percentages, derived from UserDefaults goals.
    private var goalRatios: (protein: Double, carbs: Double, fat: Double) {
        let ud = UserDefaults.standard
        func g(_ key: String, fallback: Double) -> Double {
            ud.object(forKey: key) != nil ? ud.double(forKey: key) : fallback
        }
        let pCal  = g("goalProtein", fallback: 150) * 4
        let cCal  = g("goalCarbs",   fallback: 200) * 4
        let fCal  = g("goalFat",     fallback:  65) * 9
        let total = pCal + cCal + fCal
        guard total > 0 else { return (0.26, 0.49, 0.25) }
        return (pCal / total, cCal / total, fCal / total)
    }

    /// 0–100 score: how closely the meal's macro distribution matches the user's goal ratios.
    private var mealScore: Int {
        guard entry.calories >= 300 else { return 0 }
        let goal    = goalRatios
        let cal     = entry.calories
        let actualP = (entry.protein * 4) / cal
        let actualC = (entry.carbs   * 4) / cal
        let actualF = (entry.fat     * 9) / cal
        // Sum of absolute deviations; max possible is 2.0 (proportions sum to 1)
        let dev   = abs(actualP - goal.protein) + abs(actualC - goal.carbs) + abs(actualF - goal.fat)
        return max(0, min(100, Int(((1.0 - dev / 2.0) * 100).rounded())))
    }

    @ViewBuilder
    private var scoreCircle: some View {
        if entry.calories >= 300 {
            let score = mealScore
            let color: Color = score >= 75 ? Color(red: 0.25, green: 0.85, blue: 0.50)
                             : score >= 50 ? Color(red: 1.00, green: 0.75, blue: 0.20)
                             :               Color(red: 1.00, green: 0.35, blue: 0.35)
            Button { showScoreInfo = true } label: {
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.30), lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                    Text("\(score)")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(color)
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showScoreInfo) {
                MealScoreInfoSheet(entry: entry, score: score, goalRatios: goalRatios)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Meal Score Info Sheet

private struct MealScoreInfoSheet: View {
    let entry:      FoodEntry
    let score:      Int
    let goalRatios: (protein: Double, carbs: Double, fat: Double)

    private var purpleHi: Color { ThemeStore.shared.accent }
    private let cardBg   = Color(red: 0.11, green: 0.11, blue: 0.14)
    private let pageBg   = Color(red: 0.05, green: 0.05, blue: 0.07)

    private var scoreColor: Color {
        score >= 75 ? Color(red: 0.25, green: 0.85, blue: 0.50)
      : score >= 50 ? Color(red: 1.00, green: 0.75, blue: 0.20)
      :               Color(red: 1.00, green: 0.35, blue: 0.35)
    }

    private var mealRatios: (protein: Double, carbs: Double, fat: Double) {
        let cal = max(entry.protein * 4 + entry.carbs * 4 + entry.fat * 9, 1)
        return ((entry.protein * 4) / cal,
                (entry.carbs   * 4) / cal,
                (entry.fat     * 9) / cal)
    }

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // Score badge
                    ZStack {
                        Circle()
                            .stroke(scoreColor.opacity(0.35), lineWidth: 3)
                            .frame(width: 72, height: 72)
                        Text("\(score)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(scoreColor)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 6) {
                        Text("Meal Score")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Text("How closely this meal's macro distribution matches your personal goals.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    // Ratio comparison table
                    VStack(spacing: 0) {
                        ratioHeader
                        Divider().background(Color.white.opacity(0.08))
                        ratioRow(label: "Protein", meal: mealRatios.protein, goal: goalRatios.protein,
                                 color: Color(red: 0.35, green: 0.75, blue: 1.00))
                        Divider().background(Color.white.opacity(0.06))
                        ratioRow(label: "Carbs",   meal: mealRatios.carbs,   goal: goalRatios.carbs,
                                 color: Color(red: 0.40, green: 0.90, blue: 0.72))
                        Divider().background(Color.white.opacity(0.06))
                        ratioRow(label: "Fat",     meal: mealRatios.fat,     goal: goalRatios.fat,
                                 color: Color(red: 1.00, green: 0.50, blue: 0.72))
                    }
                    .background(cardBg)
                    .cornerRadius(14)
                    .padding(.horizontal)

                    // Tips card
                    VStack(alignment: .leading, spacing: 10) {
                        Label("How to score higher", systemImage: "bolt.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(purpleHi)

                        Text("A score of **100** means this meal's caloric ratio of protein, carbs, and fat perfectly matches your goals. The closer each macro is to your target percentage, the higher the score.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.65))
                            .lineSpacing(3)

                        Text("Scores are only shown for meals over 300 calories, since smaller snacks don't reflect a full macro balance.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.40))
                            .lineSpacing(2)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBg)
                    .cornerRadius(14)
                    .padding(.horizontal)

                    Spacer().frame(height: 8)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var ratioHeader: some View {
        HStack {
            Text("Macro")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("This Meal")
                .frame(width: 80, alignment: .center)
            Text("Your Goal")
                .frame(width: 80, alignment: .center)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white.opacity(0.40))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func ratioRow(label: String, meal: Double, goal: Double, color: Color) -> some View {
        let diff = meal - goal
        return HStack {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 7, height: 7)
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(Int((meal * 100).rounded()))%")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 80, alignment: .center)

            HStack(spacing: 4) {
                Text("\(Int((goal * 100).rounded()))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
                if abs(diff) >= 0.03 {
                    Image(systemName: diff > 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(diff > 0 ? Color(red: 1.00, green: 0.35, blue: 0.35)
                                                   : Color(red: 0.35, green: 0.75, blue: 1.00))
                }
            }
            .frame(width: 80, alignment: .center)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Edit Entry Sheet

private struct EditEntrySheet: View {
    let entry: FoodEntry
    let onSave: (String, Double, Double, Double, Double, Date) -> Void
    var onDelete: (() -> Void)? = nil
    var onDuplicate: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?

    @State private var foodName:     String
    @State private var caloriesText: String
    @State private var proteinText:  String
    @State private var carbsText:    String
    @State private var fatText:      String
    @State private var loggedAt:     Date
    @State private var showEditError    = false
    @State private var showDeleteConfirm = false
    @State private var isReanalyzing    = false
    @State private var targetCalories: Double = 0

    private enum Field: Hashable { case name, calories, protein, carbs, fat }
    private enum MacroKind { case protein, carbs, fat }

    init(entry: FoodEntry, onSave: @escaping (String, Double, Double, Double, Double, Date) -> Void, onDelete: (() -> Void)? = nil, onDuplicate: (() -> Void)? = nil) {
        self.entry       = entry
        self.onSave      = onSave
        self.onDelete    = onDelete
        self.onDuplicate = onDuplicate
        _foodName        = State(initialValue: entry.foodName)
        _caloriesText    = State(initialValue: String(format: "%.0f", entry.calories))
        _proteinText     = State(initialValue: String(format: "%.1f", entry.protein))
        _carbsText       = State(initialValue: String(format: "%.1f", entry.carbs))
        _fatText         = State(initialValue: String(format: "%.1f", entry.fat))
        _loggedAt        = State(initialValue: entry.loggedAt)
        _targetCalories  = State(initialValue: entry.calories)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Food name", text: $foodName)
                            .multilineTextAlignment(.trailing)
                            .focused($focus, equals: .name)
                            .submitLabel(.next)
                            .onSubmit { focus = .calories }
                    }
                    Button {
                        Task { await reanalyze() }
                    } label: {
                        HStack(spacing: 6) {
                            if isReanalyzing {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text("Reanalyze with AI")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ThemeStore.shared.accent)
                    }
                    .disabled(foodName.trimmingCharacters(in: .whitespaces).isEmpty || isReanalyzing)
                }
                Section("Macros") {
                    macroRow("Calories", unit: "kcal", text: $caloriesText, field: .calories, next: .protein)
                    macroSliderRow("Protein", unit: "g", text: $proteinText, kind: .protein, field: .protein, next: .carbs)
                    macroSliderRow("Carbs",   unit: "g", text: $carbsText,   kind: .carbs,   field: .carbs,   next: .fat)
                    macroSliderRow("Fat",     unit: "g", text: $fatText,     kind: .fat,     field: .fat,     next: nil)
                }
                Section("Time Logged") {
                    DatePicker("Time", selection: $loggedAt, displayedComponents: .hourAndMinute)
                }
                if showEditError {
                    Section {
                        Label(
                            "All macro fields (calories, protein, carbs, fat) must be filled in with valid numbers before saving.",
                            systemImage: "exclamationmark.circle.fill"
                        )
                        .foregroundStyle(.red)
                        .font(.caption)
                    }
                }
                if onDuplicate != nil || onDelete != nil {
                    Section {
                        if let onDuplicate {
                            Button {
                                onDuplicate()
                                dismiss()
                            } label: {
                                HStack {
                                    Spacer()
                                    Label("Duplicate Meal", systemImage: "doc.on.doc")
                                    Spacer()
                                }
                            }
                        }
                        if onDelete != nil {
                            Button(role: .destructive) {
                                showDeleteConfirm = true
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
            }
            .confirmationDialog("Delete this entry?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
            .onChange(of: caloriesText) { _, _ in if showEditError && isValid { showEditError = false } }
            .onChange(of: proteinText)  { _, _ in if showEditError && isValid { showEditError = false } }
            .onChange(of: carbsText)    { _, _ in if showEditError && isValid { showEditError = false } }
            .onChange(of: fatText)      { _, _ in if showEditError && isValid { showEditError = false } }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if isValid { save() } else { showEditError = true }
                    }
                }
            }
            .keyboardDoneToolbar()
        }
    }

    private var isValid: Bool {
        Double(caloriesText) != nil &&
        Double(proteinText)  != nil &&
        Double(carbsText)    != nil &&
        Double(fatText)      != nil
    }

    private func save() {
        guard let cal = Double(caloriesText),
              let pro = Double(proteinText),
              let carb = Double(carbsText),
              let fat = Double(fatText) else { return }
        onSave(foodName, cal, pro, carb, fat, loggedAt)
        dismiss()
    }

    private func reanalyze() async {
        let name = foodName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        isReanalyzing = true
        defer { isReanalyzing = false }

        // Use Sonnet to estimate macros based on the edited food name
        let result = await FoodRecognitionManager.shared.recognizeFoodByName(name)
        if result.calories > 0 {
            caloriesText = String(format: "%.0f", Double(result.calories))
            proteinText  = String(format: "%.1f", result.protein)
            carbsText    = String(format: "%.1f", result.carbs)
            fatText      = String(format: "%.1f", result.fat)
            if !result.foodName.isEmpty { foodName = result.foodName }
        }
    }

    @ViewBuilder
    private func macroRow(_ label: String, unit: String,
                           text: Binding<String>,
                           field: Field, next: Field?) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .focused($focus, equals: field)
                .submitLabel(next == nil ? .done : .next)
                .onSubmit { focus = next }
                .onChange(of: text.wrappedValue) { _, _ in
                    if let cal = Double(caloriesText), cal > 0 {
                        targetCalories = cal
                    }
                }
            Text(unit).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func macroSliderRow(_ label: String, unit: String,
                                 text: Binding<String>, kind: MacroKind,
                                 field: Field, next: Field?) -> some View {
        let tint: Color = {
            switch kind {
            case .protein: return .blue
            case .carbs:   return .green
            case .fat:     return .orange
            }
        }()
        let current = Double(text.wrappedValue) ?? 0
        let maxVal: Double = {
            let target = targetCalories > 0 ? targetCalories : (Double(caloriesText) ?? 0)
            guard target > 0 else { return 100 }
            switch kind {
            case .protein, .carbs: return target / 4
            case .fat:             return target / 9
            }
        }()
        let upper = max(maxVal, 0.1)

        VStack(spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                TextField("0", text: text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .focused($focus, equals: field)
                    .submitLabel(next == nil ? .done : .next)
                    .onSubmit { focus = next }
                Text(unit).foregroundStyle(.secondary)
            }
            Slider(
                value: Binding(
                    get: { min(max(0, current), upper) },
                    set: { adjustMacro(kind: kind, newValue: $0) }
                ),
                in: 0...upper
            )
            .tint(tint)
        }
    }

    private func adjustMacro(kind: MacroKind, newValue: Double) {
        let target = targetCalories > 0 ? targetCalories : (Double(caloriesText) ?? 0)
        guard target > 0 else { return }

        let p = Double(proteinText) ?? 0
        let c = Double(carbsText)   ?? 0
        let f = Double(fatText)     ?? 0

        var newP = p, newC = c, newF = f

        switch kind {
        case .protein:
            newP = newValue
            let remaining = max(0, target - 4 * newP)
            let other = 4 * c + 9 * f
            if other > 0.01 {
                let scale = remaining / other
                newC = c * scale; newF = f * scale
            } else {
                newC = (remaining / 2) / 4; newF = (remaining / 2) / 9
            }
        case .carbs:
            newC = newValue
            let remaining = max(0, target - 4 * newC)
            let other = 4 * p + 9 * f
            if other > 0.01 {
                let scale = remaining / other
                newP = p * scale; newF = f * scale
            } else {
                newP = (remaining / 2) / 4; newF = (remaining / 2) / 9
            }
        case .fat:
            newF = newValue
            let remaining = max(0, target - 9 * newF)
            let other = 4 * p + 4 * c
            if other > 0.01 {
                let scale = remaining / other
                newP = p * scale; newC = c * scale
            } else {
                newP = (remaining / 2) / 4; newC = (remaining / 2) / 4
            }
        }

        proteinText = String(format: "%.1f", newP)
        carbsText   = String(format: "%.1f", newC)
        fatText     = String(format: "%.1f", newF)
    }
}

// MARK: - Fuel Log Post Sheet

private struct FuelLogPostSheet: View {
    let entries:      [FoodEntry]
    let logDate:      Date
    let userSettings: UserSettings
    let modelContext: ModelContext

    @Environment(\.dismiss) private var dismiss
    @Environment(LocationManager.self) private var locationManager
    @State private var titleText   = ""
    @State private var messageText = ""
    @FocusState private var focused: Bool

    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var purpl: Color { ThemeStore.shared.accent }

    // Totals
    private var totalCalories: Double { entries.reduce(0) { $0 + $1.calories } }
    private var totalProtein:  Double { entries.reduce(0) { $0 + $1.protein  } }
    private var totalCarbs:    Double { entries.reduce(0) { $0 + $1.carbs    } }
    private var totalFat:      Double { entries.reduce(0) { $0 + $1.fat      } }

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {

                        // Status / title (replaces the hardcoded header in the feed)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Status")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.50))
                            TextField("", text: $titleText, prompt:
                                Text("e.g. \"ate clean all day fr\"")
                                    .foregroundStyle(.white.opacity(0.28))
                            )
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(cardBg)
                            .cornerRadius(12)
                            .onChange(of: titleText) { _, v in
                                if v.count > 80 { titleText = String(v.prefix(80)) }
                            }
                            HStack {
                                Spacer()
                                Text("\(titleText.count)/80")
                                    .font(.system(size: 11))
                                    .foregroundStyle(titleText.count >= 80 ? .red : titleText.count >= 64 ? Color.orange : .white.opacity(0.25))
                            }
                        }

                        // Message / caption (shown below the status in the feed)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Message (optional)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.50))
                            ZStack(alignment: .topLeading) {
                                if messageText.isEmpty {
                                    Text("Talk your talk. tell the feed how today went.")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.28))
                                        .padding(14)
                                }
                                TextEditor(text: $messageText)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 80)
                                    .padding(10)
                                    .focused($focused)
                                    .onChange(of: messageText) { _, v in
                                        if v.count > 300 { messageText = String(v.prefix(300)) }
                                    }
                            }
                            .background(cardBg)
                            .cornerRadius(12)
                            HStack {
                                Spacer()
                                Text("\(messageText.count)/300")
                                    .font(.system(size: 11))
                                    .foregroundStyle(messageText.count >= 300 ? .red : messageText.count >= 240 ? Color.orange : .white.opacity(0.25))
                            }
                        }

                        // Fuel log preview
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Today's Fuel Log")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.bottom, 10)

                            ForEach(entries) { entry in
                                VStack(spacing: 0) {
                                    HStack(spacing: 10) {
                                        Group {
                                            if let data = entry.imageData, let img = UIImage(data: data) {
                                                Image(uiImage: img)
                                                    .resizable()
                                                    .scaledToFill()
                                            } else if !entry.photoURL.isEmpty, let url = URL(string: entry.photoURL) {
                                                CachedAsyncImage(url: url) { img in
                                                    img.resizable().scaledToFill()
                                                } placeholder: {
                                                    Color.white.opacity(0.07)
                                                        .overlay { Image(systemName: "fork.knife").font(.system(size: 14)).foregroundStyle(.white.opacity(0.30)) }
                                                }
                                                .id(entry.photoURL)
                                            } else {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.white.opacity(0.07))
                                                    .overlay {
                                                        Image(systemName: "fork.knife")
                                                            .font(.system(size: 14))
                                                            .foregroundStyle(.white.opacity(0.30))
                                                    }
                                            }
                                        }
                                        .frame(width: 40, height: 40)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(entry.foodName)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.white)
                                            Text("\(Int(entry.calories)) kcal · \(Int(entry.protein))g P · \(Int(entry.carbs))g C · \(Int(entry.fat))g F")
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.45))
                                        }
                                        Spacer()
                                        Text(entry.loggedAt, style: .time)
                                            .font(.caption2)
                                            .foregroundStyle(.white.opacity(0.25))
                                    }
                                    .padding(.vertical, 8)

                                    if entry.id != entries.last?.id {
                                        Divider()
                                            .background(Color.white.opacity(0.08))
                                    }
                                }
                            }

                            // Totals row
                            Divider()
                                .background(purpl.opacity(0.40))
                                .padding(.top, 4)

                            HStack {
                                Text("Total")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(Int(totalCalories)) kcal · \(Int(totalProtein))g P · \(Int(totalCarbs))g C · \(Int(totalFat))g F")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(purpl)
                            }
                            .padding(.top, 8)
                        }
                        .padding(14)
                        .background(cardBg)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Post Fuel Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { submit() }
                        .fontWeight(.bold)
                        .foregroundStyle(ThemeStore.shared.accent)
                }
            }
        }
    }

    private func submit() {
        let title   = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let fbPostID = UUID().uuidString   // shared ID for SwiftData ↔ Firestore link

        let isToday = Calendar.current.isDateInToday(logDate)
        let fallbackLabel: String = {
            if isToday { return "Today's Fuel Log" }
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM d"
            return "\(fmt.string(from: logDate)) Fuel Log"
        }()

        let ud = UserDefaults.standard
        func g(_ key: String, fallback: Double) -> Double {
            ud.object(forKey: key) != nil ? ud.double(forKey: key) : fallback
        }
        let post = SocialPost(
            authorID:          userSettings.userID,
            authorUsername:    userSettings.username.isEmpty ? "me" : userSettings.username,
            authorDisplayName: userSettings.name,
            memeEmoji:         "🔥",
            memeHeadline:      title.isEmpty ? fallbackLabel : title,
            memeSub:           message,
            macroDate:         logDate,
            totalCalories: totalCalories, goalCalories: g("goalCalories", fallback: 2000),
            totalProtein:  totalProtein,  goalProtein:  g("goalProtein", fallback: 150),
            totalCarbs:    totalCarbs,    goalCarbs:    g("goalCarbs", fallback: 200),
            totalFat:      totalFat,      goalFat:      g("goalFat", fallback: 65)
        )
        post.isCustomPost           = true
        post.authorAuraLevel        = userSettings.auraLevel
        post.authorAuraPoints       = userSettings.auraPoints
        post.authorLocation         = userSettings.postLocation(gpsCity: locationManager.city)
        post.authorLatitude         = locationManager.coordinate?.latitude  ?? 0
        post.authorLongitude        = locationManager.coordinate?.longitude ?? 0
        post.authorStreak           = userSettings.macroStreak
        post.isAuthorPrivate        = userSettings.isPrivateAccount
        post.authorProfileImageData = userSettings.profileImageData
        post.firebasePostID         = fbPostID
        modelContext.insert(post)

        // Attach a FuelLogEntry for each food item so the feed renders the visual table
        for (index, entry) in entries.enumerated() {
            let fle = FuelLogEntry(
                foodName:  entry.foodName,
                calories:  entry.calories,
                protein:   entry.protein,
                carbs:     entry.carbs,
                fat:       entry.fat,
                loggedAt:  entry.loggedAt,
                sortOrder: index,
                imageData: entry.imageData,
                photoURL:  entry.photoURL
            )
            fle.post = post
            modelContext.insert(fle)
        }

        // Mirror to Firebase in the background
        let locationName = userSettings.postLocation(gpsCity: locationManager.city)
        let latitude     = locationManager.coordinate?.latitude  ?? 0
        let longitude    = locationManager.coordinate?.longitude ?? 0
        let caption      = message
        let author: PostService.PostAuthor = PostService.PostAuthor(
            userID:              userSettings.userID,
            username:            userSettings.username.isEmpty ? "me" : userSettings.username,
            whoName:             userSettings.name,
            userProfilePhotoURL: userSettings.profilePhotoURL,
            auraLevel:           userSettings.auraLevel,
            auraPoints:          userSettings.auraPoints,
            auraTitle:           userSettings.auraTitle,
            streak:              userSettings.macroStreak,
            memeType:            "",
            isPublic:            !userSettings.isPrivateAccount,
            isProSubscriber:     AISubscriptionStore.shared.isSubscribed
        )
        let firestoreFuelItems = entries.enumerated().map { i, e in
            FeedFuelLogItem(
                foodName:  e.foodName,
                calories:  e.calories,
                protein:   e.protein,
                carbs:     e.carbs,
                fat:       e.fat,
                photoURL:  e.photoURL,
                sortOrder: i
            )
        }

        Task {
            // Collect food-item photos (up to 4) to upload alongside the post.
            // Try local imageData first; fall back to downloading from photoURL.
            var entryPhotos: [UIImage] = []
            for entry in entries.prefix(4) {
                if let data = entry.imageData, let img = UIImage(data: data) {
                    entryPhotos.append(img)
                } else if !entry.photoURL.isEmpty, let url = URL(string: entry.photoURL),
                          let (data, _) = try? await URLSession.shared.data(from: url),
                          let img = UIImage(data: data) {
                    entryPhotos.append(img)
                }
            }
            do {
                try await PostService.shared.createCustomPost(
                    photos:       entryPhotos,
                    author:       author,
                    title:        title.isEmpty ? fallbackLabel : title,
                    caption:      caption,
                    locationName: locationName,
                    latitude:     latitude,
                    longitude:    longitude,
                    postLabel:    PostLabel.fuelLog.rawValue,
                    calories:     Int(totalCalories),
                    protein:      totalProtein,
                    carbs:        totalCarbs,
                    fat:          totalFat,
                    goalCalories: Int(g("goalCalories", fallback: 2000)),
                    goalProtein:  g("goalProtein", fallback: 150),
                    goalCarbs:    g("goalCarbs", fallback: 200),
                    goalFat:      g("goalFat", fallback: 65),
                    currentWeight: userSettings.showWeightOnPosts ? userSettings.currentWeight : 0,
                    goalWeight:    userSettings.showWeightOnPosts ? userSettings.goalWeight    : 0,
                    fuelLogItems: firestoreFuelItems,
                    postID:       fbPostID
                )
            } catch {
                AppLogger.log("Failed to mirror fuel log post to Firebase: \(error)")
            }
        }

        dismiss()
    }
}

/// MARK: - Coach skeleton

struct CoachSkeletonView: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 8) {
            ProgressView().scaleEffect(0.7).tint(Color.purpleHi)
            VStack(alignment: .leading, spacing: 4) {
                Text("████████████████████")
                    .redacted(reason: .placeholder)
                Text("████████████")
                    .redacted(reason: .placeholder)
            }
            .font(.subheadline)
            .foregroundStyle(Color.purpleHi.opacity(0.20))
        }
        .opacity(pulse ? 0.4 : 1.0)
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }
}

// MARK: - Preview

#Preview {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodEntry.self, configurations: config)
    return NavigationStack {
        FoodLogView(
            modelContext: container.mainContext,
            selectedDate: .constant(Calendar.current.startOfDay(for: Date())),
            userSettings: UserSettings()
        )
        .navigationTitle("Food Log")
    }
}
