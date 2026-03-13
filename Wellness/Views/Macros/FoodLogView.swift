//
//  FoodLogView.swift
//  Wellness
//

import SwiftUI
import SwiftData

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
    @State private var showingAnalysisSheet  = false
    @State private var editingEntry: FoodEntry? = nil
    @State private var showingFuelLogPost    = false

    @Environment(\.modelContext) private var modelContext

    init(modelContext: ModelContext, selectedDate: Binding<Date>, userSettings: UserSettings) {
        _viewModel  = State(wrappedValue: FoodLogViewModel(
            modelContext: modelContext,
            selectedDate: selectedDate.wrappedValue
        ))
        _analyzeVM  = State(wrappedValue: AnalyzeViewModel(
            modelContext: modelContext,
            selectedDate: selectedDate.wrappedValue
        ))
        _selectedDate = selectedDate
        self.userSettings = userSettings
    }

    private var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }

    var body: some View {
        ZStack {
            Color.pageBg.ignoresSafeArea()

            VStack(spacing: 0) {
                DateNavigatorView(selectedDate: $selectedDate)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                ScrollView {
                    LazyVStack(spacing: 10) {
                        // Food entries or compact empty state
                        if viewModel.todayEntries.isEmpty {
                            emptyState
                        } else {
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
            }

            // FABs — only shown for today
            if isToday {
                VStack {
                    Spacer()
                    HStack {
                        CircleFAB(icon: "photo.on.rectangle", color: .macroBlue) {
                            viewModel.showingPhotoLibrary = true
                        }
                        Spacer()
                        CircleFAB(
                            icon: "camera.fill",
                            color: .purpleHi,
                            disabled: !UIImagePickerController.isSourceTypeAvailable(.camera)
                        ) {
                            viewModel.showingCamera = true
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }
        }
        .preferredColorScheme(.dark)
        .toolbar {
            if isToday && !viewModel.todayEntries.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFuelLogPost = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Post Fuel Log")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .tint(.purpleHi)
                }
            }
        }
        .onAppear {
            viewModel.selectedDate = selectedDate
            Task { viewModel.loadTodayEntries() }
        }
        .onChange(of: selectedDate) { _, newDate in
            viewModel.selectedDate   = newDate
            analyzeVM.selectedDate   = newDate
            analyzeVM.reset()
        }
        .onChange(of: viewModel.selectedImage) { _, newValue in
            if newValue != nil { showingAnalysisSheet = true }
        }
        .sheet(isPresented: $viewModel.showingCamera) {
            ImagePickerView(sourceType: .camera, selectedImage: $viewModel.selectedImage)
        }
        .sheet(isPresented: $viewModel.showingPhotoLibrary) {
            ImagePickerView(sourceType: .photoLibrary, selectedImage: $viewModel.selectedImage)
        }
        .sheet(item: $editingEntry) { entry in
            EditEntrySheet(entry: entry) { name, cal, pro, carb, fat in
                viewModel.updateEntry(entry, foodName: name,
                                      calories: cal, protein: pro,
                                      carbs: carb, fat: fat)
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
                userSettings: userSettings,
                modelContext: modelContext
            )
        }
    }

    // MARK: - Empty state (compact, inline in scroll)

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.15))
            Text("No food logged")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.35))
            Text("Tap the camera or photo button below to log a meal.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.22))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
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
                    Text("Tap Log Meals to get a personalised one-meal swap suggestion based on what you've logged today. Can only be run once per day.")
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
                    Text(analyzeVM.hasRunToday ? "Logged Today" : "Log Meals")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(analyzeVM.hasRunToday ? .gray : Color.purpleHi)
            .disabled(analyzeVM.state == .analyzing || analyzeVM.hasRunToday)
            .alert("Log Meals?", isPresented: $showLogMealsConfirm) {
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
}

// MARK: - Analysis Sheet

private struct AnalysisSheet: View {
    @Bindable var viewModel: FoodLogViewModel
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showSaveError     = false
    @State private var showVoiceRecorder = false
    @State private var speechRecognizer  = SpeechRecognizer()
    @State private var skeletonPulse     = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipped()
                            .cornerRadius(14)
                            .padding(.horizontal)
                    }

                    switch viewModel.analysisState {
                    case .idle:
                        if showVoiceRecorder {
                            voiceRecorderPrompt
                        } else {
                            analyzePrompt
                        }
                    case .analyzing:
                        skeletonEntryFields
                    case .result, .error:
                        entryFields
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Log Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        speechRecognizer.reset()
                        dismiss()
                    }
                }
            }
            .onDisappear { speechRecognizer.reset() }
        }
    }

    private var analyzePrompt: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("How do you want to log this?")
                    .font(.headline)
                Text("Analyze the photo, describe what you ate, or enter macros manually.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            VStack(spacing: 10) {
                Button {
                    Task { await viewModel.analyzeImage() }
                } label: {
                    Label("Analyze Photo", systemImage: "camera.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    showVoiceRecorder = true
                } label: {
                    Label("Describe What You Ate", systemImage: "mic.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(Color(red: 0.65, green: 0.45, blue: 1.00))
            }
            .padding(.horizontal)

            Button("Enter manually instead") {
                viewModel.analysisState = .result
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var voiceRecorderPrompt: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("Describe what you ate")
                    .font(.headline)
                Text("Say the food and portion size — Claude will use your description and the photo together.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            // Transcript bubble
            if !speechRecognizer.transcript.isEmpty {
                Text(speechRecognizer.transcript)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(red: 0.13, green: 0.10, blue: 0.22))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            // Error message
            if case .error(let msg) = speechRecognizer.status {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Mic button
            Button {
                if speechRecognizer.status == .recording {
                    speechRecognizer.stop()
                } else {
                    speechRecognizer.start()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(speechRecognizer.status == .recording
                              ? Color.red.opacity(0.85)
                              : Color(red: 0.65, green: 0.45, blue: 1.00).opacity(0.85))
                        .frame(width: 72, height: 72)
                    Image(systemName: speechRecognizer.status == .recording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)

            Text(micLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                // Analyze with voice button — shown when there's a transcript
                if speechRecognizer.status == .done && !speechRecognizer.transcript.isEmpty {
                    Button {
                        viewModel.voiceNote = speechRecognizer.transcript
                        Task { await viewModel.analyzeImageWithVoice() }
                    } label: {
                        Label("Analyze with Description", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }

                Button("Back") {
                    speechRecognizer.reset()
                    showVoiceRecorder = false
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var micLabel: String {
        switch speechRecognizer.status {
        case .idle:              return "Tap to start recording"
        case .requestingPermission: return "Requesting permission…"
        case .recording:         return "Listening… tap to stop"
        case .done:              return speechRecognizer.transcript.isEmpty ? "Nothing heard — try again" : "Tap to re-record"
        case .error:             return ""
        }
    }

    // MARK: - Skeleton (shown while API is in-flight)

    private var skeletonEntryFields: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.75)
                    .tint(Color.purpleHi)
                Text("Analyzing your photo…")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.50))
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                skeletonRow(label: "Food",     placeholder: "Identifying food…")
                skeletonRow(label: "Calories", placeholder: "—— kcal")
                skeletonRow(label: "Protein",  placeholder: "——g")
                skeletonRow(label: "Carbs",    placeholder: "——g")
                skeletonRow(label: "Fat",      placeholder: "——g")
            }
            .padding(.horizontal)
            .opacity(skeletonPulse ? 0.35 : 0.75)
            .animation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true),
                       value: skeletonPulse)
            .onAppear  { skeletonPulse = true  }
            .onDisappear { skeletonPulse = false }
        }
    }

    @ViewBuilder
    private func skeletonRow(label: String, placeholder: String) -> some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)
                .foregroundStyle(.primary)
            Spacer()
            Text(placeholder)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .cornerRadius(8)
    }

    private var entryFields: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Food")
                    .frame(width: 80, alignment: .leading)
                TextField("Food name", text: $viewModel.foodName)
                    .textFieldStyle(.roundedBorder)
            }
            MacroFieldView(label: "Calories", unit: "kcal", value: $viewModel.caloriesText)
            MacroFieldView(label: "Protein",  unit: "g",    value: $viewModel.proteinText)
            MacroFieldView(label: "Carbs",    unit: "g",    value: $viewModel.carbsText)
            MacroFieldView(label: "Fat",      unit: "g",    value: $viewModel.fatText)

            if case .error(let message) = viewModel.analysisState {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(message)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                .padding(.horizontal)
                Button {
                    Task { await viewModel.analyzeImage() }
                } label: {
                    Label("Retry Analysis", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
            }

            if showSaveError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text("Please fill in all macro fields (calories, protein, carbs, fat) before saving.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.10))
                .cornerRadius(10)
                .padding(.horizontal)
            }

            HStack(spacing: 12) {
                Button("Discard") { dismiss() }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                Button("Save") {
                    if viewModel.caloriesText.isEmpty || viewModel.proteinText.isEmpty ||
                       viewModel.carbsText.isEmpty   || viewModel.fatText.isEmpty {
                        showSaveError = true
                    } else if viewModel.saveEntry() {
                        showSaveError = false
                        onSaved()
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .padding(.top, 4)
        }
        .padding(.horizontal)
    }
}

// MARK: - Food Entry Row

private struct FoodEntryRow: View {
    let entry:    FoodEntry
    let onEdit:   () -> Void
    let onDelete: () -> Void
    var canEdit:  Bool = true

    var body: some View {
        HStack(spacing: 12) {
            if let data = entry.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipped()
                    .cornerRadius(10)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.white.opacity(0.30))
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.foodName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("\(Int(entry.calories)) kcal  ·  \(Int(entry.protein))g P  ·  \(Int(entry.carbs))g C  ·  \(Int(entry.fat))g F")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text(entry.loggedAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.30))

                if canEdit {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundStyle(.red.opacity(0.65))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(Color.cardBg)
        .cornerRadius(14)
        .contentShape(Rectangle())
        .onTapGesture { onEdit() }
    }
}

// MARK: - Edit Entry Sheet

private struct EditEntrySheet: View {
    let entry: FoodEntry
    let onSave: (String, Double, Double, Double, Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?

    @State private var foodName:     String
    @State private var caloriesText: String
    @State private var proteinText:  String
    @State private var carbsText:    String
    @State private var fatText:      String
    @State private var showEditError = false

    private enum Field: Hashable { case name, calories, protein, carbs, fat }

    init(entry: FoodEntry, onSave: @escaping (String, Double, Double, Double, Double) -> Void) {
        self.entry  = entry
        self.onSave = onSave
        _foodName     = State(initialValue: entry.foodName)
        _caloriesText = State(initialValue: String(format: "%.0f", entry.calories))
        _proteinText  = State(initialValue: String(format: "%.1f", entry.protein))
        _carbsText    = State(initialValue: String(format: "%.1f", entry.carbs))
        _fatText      = State(initialValue: String(format: "%.1f", entry.fat))
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
        onSave(foodName, cal, pro, carb, fat)
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

// MARK: - Circle FAB

private struct CircleFAB: View {
    let icon: String
    let color: Color
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(disabled ? Color.white.opacity(0.15) : color)
                .clipShape(Circle())
                .shadow(color: disabled ? .clear : color.opacity(0.55), radius: 10, y: 4)
        }
        .disabled(disabled)
    }
}

// MARK: - Fuel Log Post Sheet

private struct FuelLogPostSheet: View {
    let entries:      [FoodEntry]
    let userSettings: UserSettings
    let modelContext: ModelContext

    @Environment(\.dismiss) private var dismiss
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

                        // Optional message field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Add a message (optional)")
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
                                    .frame(minHeight: 90)
                                    .padding(10)
                                    .focused($focused)
                            }
                            .background(cardBg)
                            .cornerRadius(12)
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
                                        if let data = entry.imageData, let img = UIImage(data: data) {
                                            Image(uiImage: img)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 40, height: 40)
                                                .clipped()
                                                .cornerRadius(8)
                                        } else {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.07))
                                                .frame(width: 40, height: 40)
                                                .overlay {
                                                    Image(systemName: "fork.knife")
                                                        .font(.system(size: 14))
                                                        .foregroundStyle(.white.opacity(0.30))
                                                }
                                        }
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
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)

        let post = SocialPost(
            authorID:          userSettings.userID,
            authorUsername:    userSettings.username.isEmpty ? "me" : userSettings.username,
            authorDisplayName: userSettings.name,
            memeEmoji:         "🔥",
            memeHeadline:      "Today's Fuel Log 🔥",
            memeSub:           message,
            macroDate:         Date(),
            totalCalories: totalCalories, goalCalories: 0,
            totalProtein:  totalProtein,  goalProtein:  0,
            totalCarbs:    totalCarbs,    goalCarbs:    0,
            totalFat:      totalFat,      goalFat:      0
        )
        post.isCustomPost           = true
        post.authorAuraLevel        = userSettings.auraLevel
        post.authorAuraPoints       = userSettings.auraPoints
        post.authorLocation         = userSettings.location
        post.authorStreak           = userSettings.macroStreak
        post.isAuthorPrivate        = userSettings.isPrivateAccount
        post.authorProfileImageData = userSettings.profileImageData
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
                imageData: entry.imageData
            )
            fle.post = post
            modelContext.insert(fle)
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
