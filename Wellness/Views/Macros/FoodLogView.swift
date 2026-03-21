//
//  FoodLogView.swift
//  Wellness
//

import SwiftUI
import SwiftData
import CoreLocation

// MARK: - Color palette (matches HomeView)

private extension Color {
    static let pageBg    = Color(red: 0.07, green: 0.05, blue: 0.12)
    static let cardBg    = Color(red: 0.13, green: 0.10, blue: 0.22)
    static let purpleHi  = Color(red: 0.65, green: 0.45, blue: 1.00)
    static let macroBlue = Color(red: 0.35, green: 0.75, blue: 1.00)
}

// MARK: - FoodLogView

struct FoodLogView: View {
    @State private var viewModel:    FoodLogViewModel
    @State private var analyzeVM:    AnalyzeViewModel
    @Binding var selectedDate: Date
    let userSettings: UserSettings
    @Binding var externalImage: UIImage?
    @Environment(NotificationState.self) private var notificationState
    @State private var showingTutorial        = false
    @State private var tutorialAnchors:       [String: Anchor<CGRect>] = [:]
    @State private var showingAnalysisSheet  = false
    @State private var showingConfirmation   = false
    @State private var editingEntry: FoodEntry? = nil
    @State private var showingFuelLogPost    = false
    @State private var showingProfile        = false
    @State private var showingNotifications  = false

    @State private var logTab = 0     // 0 = Fuel, 1 = Duel

    // Eating window state (mirrors UserDefaults written by HomeViewModel)
    @State private var wStartHour: Int = UserDefaults.standard.integer(forKey: "windowStartHour")
    @State private var wStartMin:  Int = UserDefaults.standard.integer(forKey: "windowStartMinute")
    @State private var wDuration:  Int = {
        let d = UserDefaults.standard.integer(forKey: "windowDurationHours")
        return d > 0 ? d : 16
    }()
    @State private var showingWindowPicker = false

    @Environment(\.modelContext) private var modelContext

    init(modelContext: ModelContext, selectedDate: Binding<Date>, userSettings: UserSettings,
         externalImage: Binding<UIImage?> = .constant(nil)) {
        _viewModel  = State(wrappedValue: FoodLogViewModel(
            selectedDate: selectedDate.wrappedValue,
            userID: userSettings.userID
        ))
        _analyzeVM  = State(wrappedValue: AnalyzeViewModel(
            userID:       userSettings.userID,
            selectedDate: selectedDate.wrappedValue
        ))
        _selectedDate  = selectedDate
        _externalImage = externalImage
        self.userSettings = userSettings
    }

    private var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }
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
            .sheet(isPresented: $showingProfile) {
                profileSheet
            }
            .onAppear(perform: handleOnAppear)
            .onChange(of: selectedDate, handleDateChange)
            .onChange(of: viewModel.selectedImage) { _, newValue in
                if newValue != nil { showingAnalysisSheet = true }
            }
            .onChange(of: viewModel.analysisState) { _, newState in
                if case .confirmed = newState {
                    showingAnalysisSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showingConfirmation = true
                    }
                }
            }
            .onChange(of: externalImage, handleExternalImage)
            .sheet(isPresented: $viewModel.showingCamera) {
                ImagePickerView(sourceType: .camera, selectedImage: $viewModel.selectedImage)
            }
            .sheet(isPresented: $viewModel.showingPhotoLibrary) {
                ImagePickerView(sourceType: .photoLibrary, selectedImage: $viewModel.selectedImage)
            }
            .sheet(item: $editingEntry) { entry in
                editSheet(for: entry)
            }
            .sheet(isPresented: $showingAnalysisSheet, onDismiss: {
                if !showingConfirmation { viewModel.discardEntry() }
            }) {
                analysisSheet
            }
            .sheet(isPresented: $showingConfirmation, onDismiss: {
                viewModel.discardEntry()
            }) {
                confirmationSheet
            }
            .sheet(isPresented: $showingFuelLogPost) {
                fuelLogPostSheet
            }
            .sheet(isPresented: $showingWindowPicker) {
                windowPickerSheet
            }
            .onChange(of: wDuration) { _, newVal in
                UserDefaults.standard.set(newVal, forKey: "windowDurationHours")
                saveWindowToFirestore()
            }
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
                
                logTabBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .tutorialAnchor("log.tabBar")
                
                tabContent
            }
            
            tutorialOverlay
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
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
            
            BellButton(showingNotifications: $showingNotifications, notificationState: notificationState)
            
            Button { showingProfile = true } label: {
                profileAvatarIcon
            }
        }
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        if logTab == 0 {
            fuelTabContent
        } else {
            duelTab
        }
    }
    
    private var fuelTabContent: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if isToday && userSettings.fastingEnabled {
                    eatingWindowCard
                }

                foodEntriesContent
                
                if !isEditableDate {
                    pastDateNotice
                }
                
                analyzeSection
                    .padding(.top, 8)
                    .tutorialAnchor("log.nutritionCoach")
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 100)
        }
    }
    
    @ViewBuilder
    private var foodEntriesContent: some View {
        if viewModel.todayEntries.isEmpty {
            emptyState
        } else {
            Text("\(viewModel.todayEntries.count) Meal\(viewModel.todayEntries.count == 1 ? "" : "s")")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.30))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)
            
            ForEach(viewModel.todayEntries) { entry in
                FoodEntryRow(entry: entry,
                             onEdit:   isEditableDate ? { editingEntry = entry } : {},
                             onDelete: { viewModel.deleteEntry(entry) },
                             canEdit:  isEditableDate)
            }
        }
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
    
    private var profileSheet: some View {
        NavigationStack {
            ProfileView(
                profileUserID:      userSettings.userID,
                profileUsername:    userSettings.username,
                profileDisplayName: userSettings.name,
                profileAuraLevel:   userSettings.auraLevel,
                profileAuraPoints:  userSettings.auraPoints,
                profileImageData:   userSettings.profileImageData,
                profileLocation:    userSettings.location,
                ownUserSettings:    userSettings,
                isDismissable:      true
            )
        }
    }
    
    private func editSheet(for entry: FoodEntry) -> some View {
        EditEntrySheet(entry: entry, onSave: { name, cal, pro, carb, fat, time in
            viewModel.updateEntry(entry, foodName: name,
                                  calories: cal, protein: pro,
                                  carbs: carb, fat: fat,
                                  loggedAt: time)
        }, onDelete: {
            viewModel.deleteEntry(entry)
        })
        .presentationDetents([.medium])
    }
    
    private var analysisSheet: some View {
        AnalysisSheet(viewModel: viewModel, onSaved: {
            showingAnalysisSheet = false
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
                onConfirm: { result in
                    viewModel.confirmResult(result)
                    viewModel.saveEntry()
                    showingConfirmation = false
                    // Don't reload from Firestore immediately — saveEntry() already
                    // inserted the entry optimistically. Reload after a short delay
                    // to pick up the Firestore write (photo URL, entry ID).
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        await viewModel.loadTodayEntries()
                    }
                },
                onEscalate: {
                    Task { await viewModel.escalateAnalysis() }
                },
                onCancel: {
                    showingConfirmation = false
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
        viewModel.selectedDate = selectedDate
        // Only fetch from Firestore if the list is empty (first load).
        // If entries already exist (optimistic insert from saveEntry), skip
        // the immediate reload to avoid overwriting with stale Firestore data.
        if viewModel.todayEntries.isEmpty {
            Task { await viewModel.loadTodayEntries() }
        } else {
            // Refresh in the background after a delay to sync Firestore state
            Task {
                try? await Task.sleep(for: .seconds(2))
                await viewModel.loadTodayEntries()
            }
        }
        // Refresh eating window state from UserDefaults
        wStartHour = UserDefaults.standard.integer(forKey: "windowStartHour")
        wStartMin  = UserDefaults.standard.integer(forKey: "windowStartMinute")
        let d = UserDefaults.standard.integer(forKey: "windowDurationHours")
        wDuration  = d > 0 ? d : 16
    }
    
    private func handleDateChange(_ oldDate: Date, _ newDate: Date) {
        viewModel.selectedDate   = newDate
        analyzeVM.selectedDate   = newDate
        analyzeVM.reset()
    }
    
    private func handleExternalImage(_ oldImage: UIImage?, _ image: UIImage?) {
        guard let img = image else { return }
        viewModel.selectedImage = img
        externalImage = nil
    }

    private var profileAvatarIcon: some View {
        let purpl  = Color.purpleHi
        let cardBg = Color.cardBg
        return Group {
            if let data = userSettings.profileImageData, let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg)
                    .resizable().scaledToFill()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(purpl, lineWidth: 1.5))
            } else {
                ZStack {
                    Circle().fill(cardBg).frame(width: 30, height: 30)
                        .overlay(Circle().stroke(purpl, lineWidth: 1.5))
                    Image(systemName: "person.fill").font(.system(size: 14)).foregroundStyle(purpl)
                }
            }
        }
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

    // MARK: - Empty state (compact, inline in scroll)

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.purpleHi.opacity(0.10))
                    .frame(width: 84, height: 84)
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.purpleHi.opacity(0.45))
            }
            VStack(spacing: 6) {
                Text("No fuel logged")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                Text("Tap Camera or Library below\nto log your first meal.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.32))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
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
                showLogMealsConfirm = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: analyzeVM.hasRunToday ? "checkmark.circle.fill" : "wand.and.stars")
                    Text(analyzeVM.hasRunToday ? "Done for Today" : "Get My Recommendation")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(analyzeVM.hasRunToday ? .gray : Color.purpleHi)
            .disabled(analyzeVM.state == .analyzing || analyzeVM.hasRunToday)
            .alert("Get My Recommendation?", isPresented: $showLogMealsConfirm) {
                Button("Let's Go", role: .none) { Task { await analyzeVM.analyze() } }
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
                color: Color(red: 1.0, green: 0.80, blue: 0.20),
                lineWidth: 1.5,
                duration: 3.2,
                reversed: true
            )
        )
    }

    @ViewBuilder
    private func resultText(_ text: String) -> some View {
        if let attr = try? AttributedString(
            markdown: text,
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
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.80))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
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
            .background(Color(red: 0.11, green: 0.08, blue: 0.20))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.purpleHi.opacity(0.18), lineWidth: 1)
            )
        }
    }

    // MARK: - Fuel / Duel tab bar

    private var logTabBar: some View {
        HStack(spacing: 0) {
            logTabButton(title: "Fuel",  tag: 0)
            logTabButton(title: "Duel",  tag: 1)
        }
        .background(Color.cardBg)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.purpleHi.opacity(0.15), lineWidth: 1))
    }

    private func logTabButton(title: String, tag: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { logTab = tag }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(logTab == tag ? .black : .white.opacity(0.45))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    logTab == tag
                        ? Color.purpleHi
                        : Color.clear,
                    in: Capsule()
                )
                .padding(3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Duel tab

    private var duelTab: some View {
        WorkoutDuelView(
            userID:              userSettings.userID,
            selectedDate:        selectedDate,
            isToday:             isToday,
            bodyWeightLbs:       userSettings.currentWeight,
            autoAdjustByDefault: userSettings.autoAdjustMacrosForWorkout,
            userSettings:        userSettings
        )
    }
}

// MARK: - Analysis Sheet

private struct AnalysisSheet: View {
    @Bindable var viewModel: FoodLogViewModel
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var mode: EntryMode    = .photo
    @State private var speechRecognizer  = SpeechRecognizer()
    @State private var skeletonPulse     = false
    @State private var showSaveError     = false

    enum EntryMode { case photo, voice, manual }

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let accent = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)

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

                        // Food photo
                        if let image = viewModel.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 190)
                                .clipped()
                                .cornerRadius(16)
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
                                        Task { await viewModel.reanalyzeWithClaude() }
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
            .navigationTitle("Log Food")
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
                Button {
                    Task { await viewModel.analyzeImage() }
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
                    Task {
                        if hasPhoto { await viewModel.analyzeImageWithVoice() }
                        else        { await viewModel.analyzeImage() }
                    }
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
            macroField(label: "Food",     placeholder: "Food name", text: $viewModel.foodName,      unit: nil,    keyboard: .default)
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

    // MARK: - Save Button

    private var canSave: Bool {
        !viewModel.caloriesText.isEmpty && !viewModel.proteinText.isEmpty &&
        !viewModel.carbsText.isEmpty   && !viewModel.fatText.isEmpty
    }

    private var saveButton: some View {
        Button {
            if canSave {
                showSaveError = false
                if viewModel.saveEntry() { onSaved() }
            } else {
                showSaveError = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                Text("Log Food")
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
                    ForEach(viewModel.savedMeals) { meal in
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
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                        } else {
                            Color.white.opacity(0.05)
                        }
                    }
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
    }
}

// MARK: - Food Entry Row

private struct FoodEntryRow: View {
    let entry:    FoodEntry
    let onEdit:   () -> Void
    let onDelete: () -> Void
    var canEdit:  Bool = true

    @State private var showScoreInfo = false

    var body: some View {
        if canEdit {
            rowContent
                .contentShape(Rectangle())
                .onTapGesture { onEdit() }
                .contextMenu {
                    Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
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
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            Color.white.opacity(0.06)
                                .overlay {
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.white.opacity(0.25))
                                }
                        }
                    }
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

    private let purpleHi = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let cardBg   = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let pageBg   = Color(red: 0.07, green: 0.05, blue: 0.12)

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

    private enum Field: Hashable { case name, calories, protein, carbs, fat }

    init(entry: FoodEntry, onSave: @escaping (String, Double, Double, Double, Double, Date) -> Void, onDelete: (() -> Void)? = nil) {
        self.entry    = entry
        self.onSave   = onSave
        self.onDelete = onDelete
        _foodName     = State(initialValue: entry.foodName)
        _caloriesText = State(initialValue: String(format: "%.0f", entry.calories))
        _proteinText  = State(initialValue: String(format: "%.1f", entry.protein))
        _carbsText    = State(initialValue: String(format: "%.1f", entry.carbs))
        _fatText      = State(initialValue: String(format: "%.1f", entry.fat))
        _loggedAt     = State(initialValue: entry.loggedAt)
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
                }
                Section("Macros") {
                    macroRow("Calories", unit: "kcal", text: $caloriesText, field: .calories, next: .protein)
                    macroRow("Protein",  unit: "g",    text: $proteinText,  field: .protein,  next: .carbs)
                    macroRow("Carbs",    unit: "g",    text: $carbsText,    field: .carbs,    next: .fat)
                    macroRow("Fat",      unit: "g",    text: $fatText,      field: .fat,      next: nil)
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
                if onDelete != nil {
                    Section {
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
            Text(unit).foregroundStyle(.secondary)
        }
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

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)

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
                                                AsyncImage(url: url) { phase in
                                                    if case .success(let img) = phase {
                                                        img.resizable().scaledToFill()
                                                    } else {
                                                        Color.white.opacity(0.07)
                                                            .overlay { Image(systemName: "fork.knife").font(.system(size: 14)).foregroundStyle(.white.opacity(0.30)) }
                                                    }
                                                }
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
                        .foregroundStyle(Color(red: 1.00, green: 0.80, blue: 0.20))
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
            isPublic:            !userSettings.isPrivateAccount
        )
        // Collect food-item photos (up to 4) to upload alongside the post
        let entryPhotos: [UIImage] = entries
            .compactMap { $0.imageData.flatMap { UIImage(data: $0) } }

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
                    fuelLogItems: firestoreFuelItems,
                    postID:       fbPostID
                )
            } catch {
                print("Failed to mirror fuel log post to Firebase: \(error)")
            }
        }

        dismiss()
    }
}

/// MARK: - Coach skeleton

private struct CoachSkeletonView: View {
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
