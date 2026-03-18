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
    @State private var showingAnalysisSheet  = false
    @State private var editingEntry: FoodEntry? = nil
    @State private var showingFuelLogPost    = false
    @State private var showingProfile        = false
    @State private var showingNotifications  = false

    @State private var logTab = 0     // 0 = Fuel, 1 = Duel

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

    var body: some View {
        ZStack {
            Color.pageBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header (nav bar is hidden)
                HStack {
                    Text("Fuel Log")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    HStack(spacing: 14) {
                        BellButton(showingNotifications: $showingNotifications, notificationState: notificationState)
                        Button { showingProfile = true } label: {
                            profileAvatarIcon
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

                DateNavigatorView(selectedDate: $selectedDate)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                // MARK: Fuel / Duel tab bar
                logTabBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                if logTab == 0 {
                    // MARK: Fuel tab — existing food log content
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            // Food entries or compact empty state
                            if viewModel.todayEntries.isEmpty {
                                emptyState
                            } else {
                                macroSummaryBanner

                                Text("\(viewModel.todayEntries.count) Meal\(viewModel.todayEntries.count == 1 ? "" : "s")")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.30))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 2)

                                ForEach(viewModel.todayEntries) { entry in
                                    FoodEntryRow(entry: entry,
                                                 onEdit:   isToday ? { editingEntry = entry } : {},
                                                 onDelete: { viewModel.deleteEntry(entry) },
                                                 canEdit:  isToday)
                                }
                            }

                            // Past-date read-only notice
                            if !isToday {
                                HStack(spacing: 6) {
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                    Text("Past dates are view-only. Navigate to today to log or edit.")
                                        .font(.caption)
                                }
                                .foregroundStyle(.white.opacity(0.30))
                                .padding(.vertical, 4)
                            }

                            // AI Coach section — always visible below the list
                            analyzeSection
                                .padding(.top, 8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 100)
                    }
                } else {
                    // MARK: Duel tab
                    duelTab
                }
            }

        }
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingNotifications) {
            NotificationsView(userSettings: userSettings, notificationState: notificationState)
        }
        .sheet(isPresented: $showingProfile) {
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
        .onAppear {
            viewModel.selectedDate = selectedDate
            Task { await viewModel.loadTodayEntries() }
        }
        .onChange(of: selectedDate) { _, newDate in
            viewModel.selectedDate   = newDate
            analyzeVM.selectedDate   = newDate
            analyzeVM.reset()
        }
        .onChange(of: viewModel.selectedImage) { _, newValue in
            if newValue != nil { showingAnalysisSheet = true }
        }
        .onChange(of: externalImage) { _, image in
            guard let img = image else { return }
            viewModel.selectedImage = img
            externalImage = nil
        }
        .sheet(isPresented: $viewModel.showingCamera) {
            ImagePickerView(sourceType: .camera, selectedImage: $viewModel.selectedImage)
        }
        .sheet(isPresented: $viewModel.showingPhotoLibrary) {
            ImagePickerView(sourceType: .photoLibrary, selectedImage: $viewModel.selectedImage)
        }
        .sheet(item: $editingEntry) { entry in
            EditEntrySheet(entry: entry) { name, cal, pro, carb, fat, time in
                viewModel.updateEntry(entry, foodName: name,
                                      calories: cal, protein: pro,
                                      carbs: carb, fat: fat,
                                      loggedAt: time)
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingAnalysisSheet, onDismiss: {
            viewModel.discardEntry()
        }) {
            AnalysisSheet(viewModel: viewModel, onSaved: {
                showingAnalysisSheet = false
            })
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showingFuelLogPost) {
            FuelLogPostSheet(
                entries:      viewModel.todayEntries,
                logDate:      selectedDate,
                userSettings: userSettings,
                modelContext: modelContext
            )
        }
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

    // MARK: - Macro summary banner

    @ViewBuilder
    private var macroSummaryBanner: some View {
        let entries = viewModel.todayEntries
        let cal  = entries.reduce(0.0) { $0 + $1.calories }
        let pro  = entries.reduce(0.0) { $0 + $1.protein }
        let carb = entries.reduce(0.0) { $0 + $1.carbs }
        let fat  = entries.reduce(0.0) { $0 + $1.fat }

        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(cal))")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("kcal")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.orange.opacity(0.80))
                }
                Text("\(entries.count) meal\(entries.count == 1 ? "" : "s") logged today")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.38))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1, height: 40)

            HStack(spacing: 0) {
                summaryMacroStat(value: pro,  label: "Protein", color: .macroBlue)
                summaryMacroStat(value: carb, label: "Carbs",   color: Color(red: 0.40, green: 0.90, blue: 0.72))
                summaryMacroStat(value: fat,  label: "Fat",     color: Color(red: 1.00, green: 0.50, blue: 0.72))
            }
            .padding(.leading, 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(red: 0.11, green: 0.08, blue: 0.20))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purpleHi.opacity(0.12), lineWidth: 1)
        )
    }

    private func summaryMacroStat(value: Double, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(Int(value))g")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.38))
        }
        .frame(maxWidth: .infinity)
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
                    Text("Tap Analyze Meals to get a personalised one-meal swap suggestion based on what you've logged today. Can only be run once per day.")
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
                    Text(analyzeVM.hasRunToday ? "Analyzed Today" : "Analyze Meals")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(analyzeVM.hasRunToday ? .gray : Color.purpleHi)
            .disabled(analyzeVM.state == .analyzing || analyzeVM.hasRunToday)
            .alert("Analyze Meals?", isPresented: $showLogMealsConfirm) {
                Button("Run It", role: .none) { Task { await analyzeVM.analyze() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will analyse everything you've logged today and give you one personalised meal suggestion. You can only run this once per day.")
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(16)
    }

    @ViewBuilder
    private func resultText(_ text: String) -> some View {
        if let attr = try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
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
        let cal = max(entry.calories, 1)
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
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?

    @State private var foodName:     String
    @State private var caloriesText: String
    @State private var proteinText:  String
    @State private var carbsText:    String
    @State private var fatText:      String
    @State private var loggedAt:     Date
    @State private var showEditError = false

    private enum Field: Hashable { case name, calories, protein, carbs, fat }

    init(entry: FoodEntry, onSave: @escaping (String, Double, Double, Double, Double, Date) -> Void) {
        self.entry  = entry
        self.onSave = onSave
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

        let post = SocialPost(
            authorID:          userSettings.userID,
            authorUsername:    userSettings.username.isEmpty ? "me" : userSettings.username,
            authorDisplayName: userSettings.name,
            memeEmoji:         "🔥",
            memeHeadline:      title.isEmpty ? fallbackLabel : title,
            memeSub:           message,
            macroDate:         logDate,
            totalCalories: totalCalories, goalCalories: 0,
            totalProtein:  totalProtein,  goalProtein:  0,
            totalCarbs:    totalCarbs,    goalCarbs:    0,
            totalFat:      totalFat,      goalFat:      0
        )
        post.isCustomPost           = true
        post.authorAuraLevel        = userSettings.auraLevel
        post.authorAuraPoints       = userSettings.auraPoints
        post.authorLocation         = locationManager.city.isEmpty ? userSettings.location : locationManager.city
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
        let locationName = locationManager.city.isEmpty ? userSettings.location : locationManager.city
        let latitude     = locationManager.coordinate?.latitude  ?? 0
        let longitude    = locationManager.coordinate?.longitude ?? 0
        let caption      = message
        let author: PostService.PostAuthor = PostService.PostAuthor(
            userID:              userSettings.userID,
            username:            userSettings.username.isEmpty ? "me" : userSettings.username,
            whoName:             userSettings.name,
            userProfilePhotoURL: "",
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
