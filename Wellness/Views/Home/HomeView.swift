//
//  HomeView.swift
//  Wellness
//

import SwiftUI
import SwiftData

// MARK: - Color palette

private extension Color {
    static let pageBg    = Color(red: 0.07, green: 0.05, blue: 0.12)
    static let cardBg    = Color(red: 0.13, green: 0.10, blue: 0.22)
    static let purpleHi  = Color(red: 0.65, green: 0.45, blue: 1.00)
    static let macroBlue = Color(red: 0.35, green: 0.75, blue: 1.00)
    static let macroMint = Color(red: 0.40, green: 0.90, blue: 0.72)
    static let macroRose = Color(red: 1.00, green: 0.50, blue: 0.72)
}

// MARK: - HomeView

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @Binding var selectedDate: Date
    @State private var showingWindowPicker = false
    @State private var selectedMacro: MacroType? = nil
    @State private var showingShare       = false
    @State private var showCelebration    = false
    @State private var pendingAuraGain: AuraGain? = nil
    @State private var showingSettings    = false
    @State private var showingProfile     = false
    @State private var brainstormAlert: BrainstormAlert? = nil

    private enum BrainstormAlert: Identifiable {
        case confirm, limitReached
        var id: Self { self }
    }

    init(modelContext: ModelContext, selectedDate: Binding<Date>, userSettings: UserSettings) {
        _viewModel    = State(wrappedValue: HomeViewModel(
            modelContext: modelContext,
            selectedDate: selectedDate.wrappedValue,
            userSettings: userSettings
        ))
        _selectedDate = selectedDate
    }

    // MARK: - Greeting

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = viewModel.userSettings.name.trimmingCharacters(in: .whitespaces)
        let timeGreeting: String
        switch hour {
        case 5..<12: timeGreeting = "Good Morning"
        case 12..<17: timeGreeting = "Good Afternoon"
        default: timeGreeting = "Good Evening"
        }
        return name.isEmpty ? timeGreeting : "\(timeGreeting), \(name)"
    }

    private var auraBadge: some View {
        let s = viewModel.userSettings
        return HStack(spacing: 6) {
            Text("⭐")
                .font(.system(size: 11))
            Text("Lv \(s.auraLevel)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 1.0, green: 0.80, blue: 0.20))
            if !s.auraTitle.isEmpty {
                Text("·")
                    .foregroundStyle(.white.opacity(0.30))
                Text(s.auraTitle)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.0))
            }
            Text("·")
                .foregroundStyle(.white.opacity(0.30))
            Text("\(s.auraPoints) aura pts")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.40))
        }
    }

    private var windowStartDate: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: viewModel.windowStartHour,
                    minute: viewModel.windowStartMinute,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { newDate in
                viewModel.windowStartHour   = Calendar.current.component(.hour,   from: newDate)
                viewModel.windowStartMinute = Calendar.current.component(.minute, from: newDate)
            }
        )
    }

    private func timeString(hour: Int, minute: Int) -> String {
        var comps = DateComponents()
        comps.hour = hour; comps.minute = minute
        guard let date = Calendar.current.date(from: comps) else { return "" }
        let f = DateFormatter(); f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    var body: some View {
        @Bindable var bvm      = viewModel
        @Bindable var settings = viewModel.userSettings
        
        let contentWithModifiers = mainContent
            .preferredColorScheme(.dark)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingShare) { shareSheet }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView(userSettings: viewModel.userSettings)
                }
            }
            .sheet(isPresented: $showingProfile) {
                NavigationStack {
                    ProfileView(
                        profileUserID:      viewModel.userSettings.userID,
                        profileUsername:    viewModel.userSettings.username,
                        profileDisplayName: viewModel.userSettings.name,
                        profileAuraLevel:   viewModel.userSettings.auraLevel,
                        profileAuraPoints:  viewModel.userSettings.auraPoints,
                        profileImageData:   viewModel.userSettings.profileImageData,
                        profileLocation:    viewModel.userSettings.location,
                        ownUserSettings:    viewModel.userSettings
                    )
                }
            }
            .onAppear { handleAppear() }
            .onChange(of: selectedDate) { _, newDate in handleDateChange(newDate) }
        
        let contentWithGoalChanges = contentWithModifiers
            .onChange(of: viewModel.userSettings.goalWeight) { _, newVal in handleGoalWeightChange(newVal) }
            .onChange(of: viewModel.userSettings.proteinPerLb) { _, _ in handleProteinPerLbChange() }
        let contentWithOverlays = contentWithGoalChanges
            .onChange(of: viewModel.userSettings.pendingAuraGain) { (_: AuraGain?, gain: AuraGain?) in
                if let gain { pendingAuraGain = gain }
            }
            .onChange(of: viewModel.macrosMetToday) { oldVal, newVal in handleMacrosMetChange(oldVal, newVal) }
            .overlay { auraPopupOverlay }
            .overlay { celebrationOverlay }
        
        return contentWithOverlays
            .sheet(isPresented: $showingWindowPicker) { windowPickerSheet() }
            .sheet(item: $selectedMacro) { macro in macroHistorySheet(macro: macro) }
    }
    
    // MARK: - Body Helpers
    
    private var mainContent: some View {
        ZStack {
            Color.pageBg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    greetingHeader
                    DateNavigatorView(selectedDate: $selectedDate)
                    goalsSection
                    if viewModel.userSettings.fastingEnabled {
                        eatingWindowCard
                    }
                    macrosSection
                    brainstormSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
    }
    
    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greetingText)
                .font(.title2.bold())
                .foregroundStyle(.white)
            if viewModel.userSettings.auraPoints > 0 {
                auraBadge
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 14) {
                Button { showingShare = true } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.00))
                }
                Button { showingSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.00))
                }
                Button { showingProfile = true } label: {
                    profileAvatarIcon
                }
            }
        }
    }

    private var profileAvatarIcon: some View {
        let purpl = Color(red: 0.65, green: 0.45, blue: 1.00)
        let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
        return Group {
            if let data = viewModel.userSettings.profileImageData,
               let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(purpl, lineWidth: 1.5))
            } else {
                ZStack {
                    Circle()
                        .fill(cardBg)
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(purpl, lineWidth: 1.5))
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(purpl)
                }
            }
        }
    }
    
    private var shareSheet: some View {
        ShareView(viewModel: viewModel)
            .presentationDetents([.large])
    }
    
    @ViewBuilder
    private var auraPopupOverlay: some View {
        if let gain = pendingAuraGain {
            AuraPopupView(
                gain:         gain,
                userSettings: viewModel.userSettings,
                onDismiss: {
                    pendingAuraGain = nil
                    viewModel.userSettings.pendingAuraGain = nil
                }
            )
            .transition(.opacity)
            .zIndex(3)
        }
    }

    @ViewBuilder
    private var celebrationOverlay: some View {
        if showCelebration {
            CelebrationView(
                macroGoalsMet: viewModel.macroGoalsMet,
                userName:      viewModel.userSettings.name,
                userSettings:  viewModel.userSettings,
                postData: CelebrationPostData(
                    totalCalories: viewModel.totalCalories, goalCalories: viewModel.goalCalories,
                    totalProtein:  viewModel.totalProtein,  goalProtein:  viewModel.goalProtein,
                    totalCarbs:    viewModel.totalCarbs,    goalCarbs:    viewModel.goalCarbs,
                    totalFat:      viewModel.totalFat,      goalFat:      viewModel.goalFat,
                    date:          viewModel.selectedDate
                ),
                onDismiss: { showCelebration = false }
            )
            .transition(.opacity)
        }
    }
    
    private func windowPickerSheet() -> some View {
        @Bindable var bvm = viewModel
        return WindowPickerSheet(
            windowStartDate: windowStartDate,
            windowDurationHours: $bvm.windowDurationHours
        )
        .presentationDetents([.medium])
    }
    
    private func macroHistorySheet(macro: MacroType) -> some View {
        MacroHistorySheet(macro: macro, goalValue: goalForMacro(macro))
            .presentationDetents([.medium, .large])
    }
    
    private func handleAppear() {
        viewModel.selectedDate = selectedDate
        // Defer the DB fetch to after the first frame so the UI renders immediately
        Task { viewModel.loadTodayTotals() }
    }
    
    private func handleDateChange(_ newDate: Date) {
        viewModel.selectedDate = newDate
        viewModel.resetBrainstorm()
    }
    
    private func handleGoalWeightChange(_ newVal: Double) {
        if newVal > 0 { viewModel.recalculateMacrosFromGoalWeight() }
    }
    
    private func handleProteinPerLbChange() {
        viewModel.recalculateMacrosFromGoalWeight()
    }
    
    private func handleMacrosMetChange(_ oldVal: Int, _ newVal: Int) {
        guard newVal == 4 && oldVal < 4 && Calendar.current.isDateInToday(viewModel.selectedDate) else { return }
        // Show at most once per calendar day
        guard !Calendar.current.isDateInToday(viewModel.userSettings.lastCelebrationDate) else { return }
        viewModel.userSettings.lastCelebrationDate = Date()
        showCelebration = true
    }

    private var goalsTitle: String {
        let current = viewModel.userSettings.currentWeight
        let goal    = viewModel.userSettings.goalWeight
        guard goal > 0, current > 0 else { return "Goals" }
        if goal > current   { return "Goals: Bulking" }
        if goal < current   { return "Goals: Cutting" }
        return "Goals: Maintaining"
    }

    // MARK: - Goals section

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(goalsTitle)
                .font(.title2.bold())
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                GoalKPICard(
                    title: "WEIGHT",
                    icon: "scalemass.fill",
                    iconColor: .purpleHi
                ) {
                    if viewModel.userSettings.goalWeight > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .lastTextBaseline, spacing: 3) {
                                Text(String(format: "%.1f", viewModel.userSettings.currentWeight))
                                    .font(.title3.bold()).foregroundStyle(.white)
                                Text("lbs").font(.caption).foregroundStyle(.white.opacity(0.45))
                            }
                            Text("Goal \(String(format: "%.0f", viewModel.userSettings.goalWeight)) lbs")
                                .font(.caption2).foregroundStyle(.white.opacity(0.35))
                        }
                    } else {
                        Text("Set goal")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.30))
                    }
                }

                // Streak — consecutive days with food logged
                GoalKPICard(title: "STREAK", icon: "flame.fill", iconColor: .orange) {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text("\(viewModel.macroStreak)")
                            .font(.title3.bold()).foregroundStyle(.white)
                        Text("days").font(.caption).foregroundStyle(.white.opacity(0.45))
                    }
                }

                // Macros met today
                GoalKPICard(
                    title: "MACROS",
                    icon: "checkmark.seal.fill",
                    iconColor: macrosKPIColor
                ) {
                    macroIndicatorGrid
                }
            }
        }
    }

    // 2×2 grid of colored dots — lights up when each macro goal is met
    private var macroIndicatorGrid: some View {
        let met    = viewModel.macroGoalsMet
        let colors: [Color] = [.orange, .macroBlue, .macroMint, .macroRose]
        return LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 6
        ) {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(met[i] ? colors[i] : colors[i].opacity(0.13))
                    .frame(width: 14, height: 14)
                    .shadow(color: met[i] ? colors[i].opacity(0.7) : .clear, radius: 4)
            }
        }
    }

    private var macrosKPIColor: Color {
        switch viewModel.macrosMetToday {
        case 4:    return .macroMint
        case 3:    return .macroBlue
        case 1, 2: return .orange
        default:   return .white.opacity(0.35)
        }
    }

    // MARK: - Eating window card

    private var eatingWindowCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Intermittent Fasting Window")
                        .font(.headline).foregroundStyle(.white)
                    Text(
                        "\(timeString(hour: viewModel.displayedWindowStartHour, minute: viewModel.displayedWindowStartMinute))" +
                        " – " +
                        "\(timeString(hour: viewModel.windowEndHour, minute: viewModel.windowEndMinute))" +
                        " · \(viewModel.displayedWindowDuration)h"
                    )
                    .font(.subheadline).foregroundStyle(.white.opacity(0.50))
                }
                Spacer()
                if viewModel.isSelectedDateToday {
                    Button("Edit") { showingWindowPicker = true }
                        .buttonStyle(.bordered).controlSize(.small).tint(.purpleHi)
                } else {
                    Text("Locked")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.30))
                }
            }
            FastingTimelineView(
                windowStart: viewModel.windowStartFractional,
                windowEnd: viewModel.windowEndFractional,
                mealLogTimes: viewModel.mealLogTimes
            )
        }
        .padding()
        .background(Color.cardBg)
        .cornerRadius(16)
    }

    // MARK: - Macros section

    private var macrosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's Macros")
                .font(.title2.bold()).foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                MacroGaugeCard(label: "Calories", value: viewModel.totalCalories,
                               goal: viewModel.goalCalories, unit: "kcal",
                               format: "%.0f", color: .orange,
                               action: { selectedMacro = .calories },
                               rangeText: caloriesRange)
                MacroGaugeCard(label: "Protein",  value: viewModel.totalProtein,
                               goal: viewModel.goalProtein,  unit: "g",
                               format: "%.0f", color: .macroBlue,
                               action: { selectedMacro = .protein },
                               rangeText: minRange(viewModel.goalProtein))
                MacroGaugeCard(label: "Carbs",    value: viewModel.totalCarbs,
                               goal: viewModel.goalCarbs,    unit: "g",
                               format: "%.0f", color: .macroMint,
                               action: { selectedMacro = .carbs },
                               rangeText: minRange(viewModel.goalCarbs))
                MacroGaugeCard(label: "Fat",      value: viewModel.totalFat,
                               goal: viewModel.goalFat,      unit: "g",
                               format: "%.0f", color: .macroRose,
                               action: { selectedMacro = .fat },
                               rangeText: minRange(viewModel.goalFat))
            }
        }
    }

    // Range helpers — displayed as "lo – hi" under each macro goal
    private var caloriesRange: String {
        "\(Int(viewModel.goalCalories * 0.85)) – \(Int(viewModel.goalCalories * 1.15))"
    }
    private func minRange(_ goal: Double) -> String {
        "\(Int(goal * 0.85)) – \(Int(goal * 1.15))"
    }

    // MARK: - Brainstorm section

    private var brainstormSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(red: 1.0, green: 0.80, blue: 0.20))
                Text("Brainstorm next meal")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            switch viewModel.brainstormState {
            case .idle:
                Text("See what to eat to hit your remaining macro goals for the rest of the day — specific meals and snacks suggested holistically.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.50))
                    .lineSpacing(2)

            case .loading:
                BrainstormSkeletonView()

            case .result(let text):
                brainstormResult(text)

            case .error(let msg):
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text(msg).font(.caption).foregroundStyle(.white.opacity(0.65))
                }
            }

            Button {
                if viewModel.userSettings.brainstormLimitReached {
                    brainstormAlert = .limitReached
                } else {
                    brainstormAlert = .confirm
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.userSettings.brainstormLimitReached ? "xmark.circle.fill" : "lightbulb.fill")
                    if viewModel.userSettings.brainstormLimitReached {
                        Text("Daily limit reached (2/2)")
                    } else {
                        Text(viewModel.brainstormState == .idle ? "Brainstorm next meal" : "Re-Brainstorm next meal")
                        Text("(\(viewModel.userSettings.brainstormUsesRemaining) left today)")
                            .opacity(0.65)
                    }
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.userSettings.brainstormLimitReached
                  ? Color.gray
                  : Color(red: 0.65, green: 0.45, blue: 1.0))
            .disabled(viewModel.brainstormState == .loading)
            .alert(item: $brainstormAlert) { alert in
                switch alert {
                case .confirm:
                    Alert(
                        title: Text("Brainstorm Next Meal"),
                        message: Text("Claude will suggest a specific meal based on your current macro balance. You have \(viewModel.userSettings.brainstormUsesRemaining) use\(viewModel.userSettings.brainstormUsesRemaining == 1 ? "" : "s") left today."),
                        primaryButton: .default(Text("Let's Go")) {
                            if viewModel.userSettings.consumeBrainstormUse() {
                                Task { await viewModel.brainstorm() }
                            }
                        },
                        secondaryButton: .cancel()
                    )
                case .limitReached:
                    Alert(
                        title: Text("Daily Limit Reached"),
                        message: Text("You've used both brainstorm suggestions for today. Come back tomorrow for 2 more."),
                        dismissButton: .default(Text("Got it"))
                    )
                }
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(16)
    }

    @ViewBuilder
    private func brainstormResult(_ text: String) -> some View {
        if let attr = try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) {
            Text(attr)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func goalForMacro(_ macro: MacroType) -> Double {
        switch macro {
        case .calories: return viewModel.goalCalories
        case .protein:  return viewModel.goalProtein
        case .carbs:    return viewModel.goalCarbs
        case .fat:      return viewModel.goalFat
        }
    }
}

// MARK: - Date Navigator (internal — shared with FoodLogView)

struct DateNavigatorView: View {
    @Binding var selectedDate: Date
    @State private var showingPicker = false

    private let calendar = Calendar.current

    private var isToday: Bool { calendar.isDateInToday(selectedDate) }

    private var displayText: String {
        if isToday { return "Today" }
        if calendar.isDateInYesterday(selectedDate) { return "Yesterday" }
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d"
        return f.string(from: selectedDate)
    }

    var body: some View {
        HStack(spacing: 0) {
            Button {
                guard let prev = calendar.date(byAdding: .day, value: -1, to: selectedDate) else { return }
                selectedDate = calendar.startOfDay(for: prev)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 38)
            }

            Button { showingPicker = true } label: {
                Text(displayText)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
            }

            Button {
                guard !isToday,
                      let next = calendar.date(byAdding: .day, value: 1, to: selectedDate) else { return }
                selectedDate = calendar.startOfDay(for: next)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isToday ? .white.opacity(0.20) : .white)
                    .frame(width: 44, height: 38)
            }
            .disabled(isToday)

            if !isToday {
                Button("Today") {
                    selectedDate = calendar.startOfDay(for: Date())
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.00))
                .buttonStyle(.plain)
                .padding(.leading, 6)
                .padding(.trailing, 12)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .padding(.leading, 4)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.13, green: 0.10, blue: 0.22))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: isToday)
        .sheet(isPresented: $showingPicker) {
            DatePickerSheet(selectedDate: $selectedDate)
                .presentationDetents([.medium])
        }
    }
}

private struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker("Select Date", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding(.horizontal)
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
                }
                .onChange(of: selectedDate) { _, newDate in
                    selectedDate = Calendar.current.startOfDay(for: newDate)
                }
        }
    }
}

// MARK: - Goal KPI Card

private struct GoalKPICard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    var action: (() -> Void)? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        Group {
            if let action {
                Button(action: action) { cardBody }.buttonStyle(.plain)
            } else {
                cardBody
            }
        }
    }

    @ViewBuilder
    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
                    .tracking(0.8)
                if action != nil {
                    Spacer()
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.28))
                }
            }
            content().frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cardBg)
        .cornerRadius(14)
    }
}

// MARK: - Macro Gauge Card

private struct MacroGaugeCard: View {
    let label: String
    let value: Double
    let goal: Double
    let unit: String
    let format: String
    let color: Color
    var action: (() -> Void)? = nil
    var rangeText: String? = nil

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }
    private let trackFraction: Double = 0.75
    private let lineWidth: CGFloat   = 11

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .trim(from: 0, to: trackFraction)
                    .stroke(color.opacity(0.13), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(135))
                Circle()
                    .trim(from: 0, to: progress * trackFraction)
                    .stroke(
                        LinearGradient(
                            stops: [.init(color: color.opacity(0.55), location: 0), .init(color: color, location: 1)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                    .animation(.easeOut(duration: 0.55), value: progress)
                VStack(spacing: 2) {
                    Text(String(format: format, value))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(unit)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.40))
                }
            }
            .frame(width: 112, height: 112)
            .padding(.top, 4)
            VStack(spacing: 3) {
                Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                Text("Goal: \(String(format: format, goal)) \(unit)")
                    .font(.caption2).foregroundStyle(.white.opacity(0.32))
                if let rangeText {
                    Text(rangeText)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.20))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.cardBg)
        .cornerRadius(16)
        .contentShape(Rectangle())
        .onTapGesture { action?() }
        .overlay(alignment: .topTrailing) {
            if action != nil {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(color.opacity(0.55))
                    .padding(8)
            }
        }
    }
}

// MARK: - Window Picker Sheet

private struct WindowPickerSheet: View {
    @Binding var windowStartDate: Date
    @Binding var windowDurationHours: Int
    @Environment(\.dismiss) private var dismiss
    @State private var durationText: String = "8"

    var body: some View {
        NavigationStack {
            Form {
                Section("Start Time") {
                    DatePicker("Start Time", selection: $windowStartDate, displayedComponents: .hourAndMinute)
                }
                Section {
                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("8", text: $durationText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                        Text("hours").foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Common windows: 6, 8, 10, or 12 hours.")
                }
            }
            .onAppear { durationText = "\(windowDurationHours)" }
            .navigationTitle("Intermittent Fasting Window")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if let hours = Int(durationText), hours >= 1, hours <= 23 {
                            windowDurationHours = hours
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}


/// MARK: - Brainstorm skeleton

private struct BrainstormSkeletonView: View {
    @State private var pulse = false

    private let purpl = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let lines = ["████████████████████", "████████████", "██████████████████"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ProgressView().scaleEffect(0.7).tint(purpl)
                Text("Claude is thinking…")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.40))
            }
            VStack(alignment: .leading, spacing: 6) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.subheadline)
                        .foregroundStyle(purpl.opacity(0.25))
                        .redacted(reason: .placeholder)
                }
            }
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
        HomeView(
            modelContext: container.mainContext,
            selectedDate: .constant(Calendar.current.startOfDay(for: Date())),
            userSettings: UserSettings()
        )
    }
}
