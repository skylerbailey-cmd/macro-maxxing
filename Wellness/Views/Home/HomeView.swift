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
    @Bindable var viewModel: HomeViewModel
    @State private var showingWindowPicker = false
    @State private var showingGoalSheet    = false

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
        ZStack {
            Color.pageBg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    goalsSection
                    eatingWindowCard
                    macrosSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { viewModel.loadTodayTotals() }
        .sheet(isPresented: $showingWindowPicker) {
            WindowPickerSheet(
                windowStartDate: windowStartDate,
                windowDurationHours: $viewModel.windowDurationHours
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingGoalSheet) {
            GoalWeightSheet(
                currentWeight: $viewModel.currentWeight,
                goalWeight: $viewModel.goalWeight
            )
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Goals section

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Goals")
                .font(.title2.bold())
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                // Weight — tappable to set goal weight
                GoalKPICard(
                    title: "WEIGHT",
                    icon: "scalemass.fill",
                    iconColor: .purpleHi,
                    action: { showingGoalSheet = true }
                ) {
                    if viewModel.goalWeight > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .lastTextBaseline, spacing: 3) {
                                Text(String(format: "%.1f", viewModel.currentWeight))
                                    .font(.title3.bold()).foregroundStyle(.white)
                                Text("lbs").font(.caption).foregroundStyle(.white.opacity(0.45))
                            }
                            Text("Goal \(String(format: "%.0f", viewModel.goalWeight)) lbs")
                                .font(.caption2).foregroundStyle(.white.opacity(0.35))
                        }
                    } else {
                        Text("Set goal")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.30))
                    }
                }

                // Macro streak
                GoalKPICard(title: "STREAK", icon: "flame.fill", iconColor: .orange) {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text("\(viewModel.macroStreak)")
                            .font(.title3.bold()).foregroundStyle(.white)
                        Text("days").font(.caption).foregroundStyle(.white.opacity(0.45))
                    }
                }

                // Days logged this week
                GoalKPICard(title: "LOGGED", icon: "calendar.badge.checkmark", iconColor: .macroMint) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .lastTextBaseline, spacing: 3) {
                            Text("\(viewModel.daysLoggedThisWeek)")
                                .font(.title3.bold()).foregroundStyle(.white)
                            Text("/ 7").font(.caption).foregroundStyle(.white.opacity(0.45))
                        }
                        HStack(spacing: 3) {
                            ForEach(0..<7, id: \.self) { i in
                                Circle()
                                    .fill(i < viewModel.daysLoggedThisWeek
                                          ? Color.macroMint
                                          : Color.white.opacity(0.12))
                                    .frame(width: 5, height: 5)
                            }
                        }
                    }
                }
            }
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
                               format: "%.0f", color: .orange)

                MacroGaugeCard(label: "Protein",  value: viewModel.totalProtein,
                               goal: viewModel.goalProtein,  unit: "g",
                               format: "%.0f", color: .macroBlue)

                MacroGaugeCard(label: "Carbs",    value: viewModel.totalCarbs,
                               goal: viewModel.goalCarbs,    unit: "g",
                               format: "%.0f", color: .macroMint)

                MacroGaugeCard(label: "Fat",      value: viewModel.totalFat,
                               goal: viewModel.goalFat,      unit: "g",
                               format: "%.0f", color: .macroRose)
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
                Button(action: action) { cardBody }
                    .buttonStyle(.plain)
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
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.cardBg)
        .cornerRadius(14)
    }
}

// MARK: - Macro Gauge Card (speedometer style)

private struct MacroGaugeCard: View {
    let label: String
    let value: Double
    let goal: Double
    let unit: String
    let format: String
    let color: Color

    /// 0–1 clamped, used to trim the arc
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }

    // The gauge uses 270° of a circle (75% of 360°).
    // Circle() starts at the 3-o'clock position going clockwise.
    // rotationEffect(.degrees(135)) shifts the start to ~7:30 o'clock (lower-left),
    // and the arc sweeps clockwise through the top to ~4:30 o'clock (lower-right).
    // This produces the classic car-speedometer shape, filling left → top → right.
    private let trackFraction: Double = 0.75
    private let lineWidth: CGFloat   = 11

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background track
                Circle()
                    .trim(from: 0, to: trackFraction)
                    .stroke(color.opacity(0.13),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(135))

                // Progress fill
                Circle()
                    .trim(from: 0, to: progress * trackFraction)
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: color.opacity(0.55), location: 0),
                                .init(color: color,               location: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                    .animation(.easeOut(duration: 0.55), value: progress)

                // Value text centred in the gauge opening
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
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Goal: \(String(format: format, goal)) \(unit)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.32))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.cardBg)
        .cornerRadius(16)
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
                    DatePicker("Start Time", selection: $windowStartDate,
                               displayedComponents: .hourAndMinute)
                }
                Section {
                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("8", text: $durationText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                        Text("hours")
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Common windows: 6, 8, 10, or 12 hours. The end time updates automatically.")
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

    @State private var currentText: String = ""
    @State private var goalText: String    = ""

    private var previewGoal: Double? {
        guard let v = Double(goalText), v > 0 else { return nil }
        return v
    }
    private var previewCalories: Double {
        guard let g = previewGoal else { return 0 }
        return max(g * 14, 1200)
    }
    private var previewProtein: Double {
        guard let g = previewGoal else { return 0 }
        return max(g * 0.8, 50)
    }
    private var previewFat: Double {
        guard previewGoal != nil else { return 0 }
        return max((previewCalories * 0.25) / 9, 30)
    }
    private var previewCarbs: Double {
        guard previewGoal != nil else { return 0 }
        return max((previewCalories - previewProtein * 4 - previewFat * 9) / 4, 50)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Weight") {
                    HStack {
                        Text("Current")
                        Spacer()
                        TextField("0", text: $currentText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("lbs")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Goal")
                        Spacer()
                        TextField("0", text: $goalText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("lbs")
                            .foregroundStyle(.secondary)
                    }
                }

                if previewGoal != nil {
                    Section {
                        HStack {
                            Text("Calories")
                            Spacer()
                            Text(String(format: "%.0f kcal", previewCalories))
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Protein")
                            Spacer()
                            Text(String(format: "%.0f g", previewProtein))
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Carbs")
                            Spacer()
                            Text(String(format: "%.0f g", previewCarbs))
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Fat")
                            Spacer()
                            Text(String(format: "%.0f g", previewFat))
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Estimated Daily Macro Goals")
                    } footer: {
                        Text("~14 kcal/lb goal weight · 0.8 g protein/lb · 25% calories from fat · remainder from carbs. Saving will update your macro goals.")
                    }
                }
            }
            .onAppear {
                currentText = currentWeight > 0 ? String(format: "%.1f", currentWeight) : ""
                goalText    = goalWeight > 0    ? String(format: "%.0f", goalWeight)    : ""
            }
            .navigationTitle("Weight & Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let cw = Double(currentText), cw > 0 { currentWeight = cw }
                        if let gw = Double(goalText),    gw > 0 { goalWeight    = gw }
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodEntry.self, configurations: config)
    let vm        = HomeViewModel(modelContext: container.mainContext)
    return NavigationStack {
        HomeView(viewModel: vm)
            .navigationTitle("Today")
    }
}
