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
    @State private var showingGoalSheet    = false
    @State private var selectedMacro: MacroType? = nil
    @State private var showingShare       = false
    @State private var showCelebration    = false

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
        ZStack {
            Color.pageBg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting
                    Text(greetingText)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    DateNavigatorView(selectedDate: $selectedDate)

                    goalsSection
                    if viewModel.userSettings.fastingEnabled {
                        eatingWindowCard
                    }
                    macrosSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingShare = true } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.00))
                }
            }
        }
        .sheet(isPresented: $showingShare) {
            ShareView(viewModel: viewModel)
                .presentationDetents([.large])
        }
        .onAppear {
            viewModel.selectedDate = selectedDate
            // Defer the DB fetch to after the first frame so the UI renders immediately
            Task { viewModel.loadTodayTotals() }
        }
        .onChange(of: selectedDate) { _, newDate in
            viewModel.selectedDate = newDate
        }
        .onChange(of: viewModel.userSettings.goalWeight) { _, newVal in
            if newVal > 0 { viewModel.recalculateMacrosFromGoalWeight() }
        }
        .onChange(of: viewModel.userSettings.proteinPerLb) { _, _ in
            viewModel.recalculateMacrosFromGoalWeight()
        }
        .onChange(of: viewModel.macrosMetToday) { oldVal, newVal in
            // Only celebrate when all 4 are newly hit on today's date
            if newVal == 4 && oldVal < 4 && Calendar.current.isDateInToday(viewModel.selectedDate) {
                showCelebration = true
            }
        }
        .overlay {
            if showCelebration {
                CelebrationView { showCelebration = false }
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $showingWindowPicker) {
            WindowPickerSheet(
                windowStartDate: windowStartDate,
                windowDurationHours: $bvm.windowDurationHours
            )
            .presentationDetents([.medium])
        }
        .sheet(item: $selectedMacro) { macro in
            MacroHistorySheet(macro: macro, goalValue: goalForMacro(macro))
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingGoalSheet) {
            GoalWeightSheet(
                currentWeight: $settings.currentWeight,
                goalWeight: $settings.goalWeight
            )
            .presentationDetents([.medium])
        }
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
                // Weight — tappable
                GoalKPICard(
                    title: "WEIGHT",
                    icon: "scalemass.fill",
                    iconColor: .purpleHi,
                    action: { showingGoalSheet = true }
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
                    Text("Eating Window")
                        .font(.headline).foregroundStyle(.white)
                    Text(
                        "\(timeString(hour: viewModel.windowStartHour, minute: viewModel.windowStartMinute))" +
                        " – " +
                        "\(timeString(hour: viewModel.windowEndHour, minute: viewModel.windowEndMinute))" +
                        " · \(viewModel.windowDurationHours)h"
                    )
                    .font(.subheadline).foregroundStyle(.white.opacity(0.50))
                }
                Spacer()
                Button("Edit") { showingWindowPicker = true }
                    .buttonStyle(.bordered).controlSize(.small).tint(.purpleHi)
            }
            FastingTimelineView(
                windowStart: viewModel.windowStartFractional,
                windowEnd: viewModel.windowEndFractional
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
                               rangeText: minRange(viewModel.goalProtein, unit: "g"))
                MacroGaugeCard(label: "Carbs",    value: viewModel.totalCarbs,
                               goal: viewModel.goalCarbs,    unit: "g",
                               format: "%.0f", color: .macroMint,
                               action: { selectedMacro = .carbs },
                               rangeText: minRange(viewModel.goalCarbs, unit: "g"))
                MacroGaugeCard(label: "Fat",      value: viewModel.totalFat,
                               goal: viewModel.goalFat,      unit: "g",
                               format: "%.0f", color: .macroRose,
                               action: { selectedMacro = .fat },
                               rangeText: minRange(viewModel.goalFat, unit: "g"))
            }
        }
    }

    // Range helpers matching macroGoalsMet logic
    private var caloriesRange: String {
        let lo = Int(viewModel.goalCalories * 0.85)
        let hi = Int(viewModel.goalCalories * 1.15)
        return "\(lo) – \(hi) kcal"
    }
    private func minRange(_ goal: Double, unit: String) -> String {
        "min \(Int(goal * 0.85))\(unit)"
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
            .navigationTitle("Eating Window")
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

// MARK: - Goal Weight Sheet

private struct GoalWeightSheet: View {
    @Binding var currentWeight: Double
    @Binding var goalWeight: Double
    @Environment(\.dismiss) private var dismiss

    @State private var currentVal: Double = 160
    @State private var goalVal:    Double = 160

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Weight") {
                    sliderRow("Current Weight", value: $currentVal) { editing in
                        if !editing { currentWeight = currentVal }
                    }
                    sliderRow("Goal Weight", value: $goalVal) { editing in
                        if !editing { goalWeight = goalVal }
                    }
                }
            }
            .onAppear {
                currentVal = currentWeight > 0 ? currentWeight : 160
                goalVal    = goalWeight    > 0 ? goalWeight    : 160
            }
            .navigationTitle("Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        currentWeight = currentVal
                        goalWeight    = goalVal
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sliderRow(_ label: String, value: Binding<Double>,
                            onEditingChanged: @escaping (Bool) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                Spacer()
                Text("\(Int(value.wrappedValue)) lbs")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: 100...300, step: 1, onEditingChanged: onEditingChanged)
                .tint(Color(red: 0.65, green: 0.45, blue: 1.0))
        }
        .padding(.vertical, 4)
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
