//
//  WorkoutDuelView.swift
//  Wellness
//
//  Shown in the "Duel" sub-tab of FoodLogView.
//

import SwiftUI

struct WorkoutDuelView: View {

    let userID:              String
    let selectedDate:        Date
    let isToday:             Bool
    let bodyWeightLbs:       Double
    let autoAdjustByDefault: Bool
    let userSettings:        UserSettings

    @State private var entries:          [WorkoutEntry] = []
    @State private var isLoading         = false
    @State private var showingRestDayConfirm = false
    @State private var isSavingRestDay   = false
    @State private var editingEntry:     WorkoutEntry?  = nil

    private let accent  = Color(red: 0.30, green: 0.90, blue: 0.55)
    private let cardBg  = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let pageBg  = Color(red: 0.07, green: 0.05, blue: 0.12)

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .tint(accent)
                        .padding(.top, 60)
                } else if entries.isEmpty {
                    duelRestDayButton
                    emptyState
                } else {
                    totalCard
                        .padding(.bottom, 4)

                    Text("\(entries.count) Workout\(entries.count == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.30))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(entries) { entry in
                        WorkoutRow(entry: entry, accent: accent, cardBg: cardBg,
                                   onEdit: { editingEntry = entry },
                                   onDelete: {
                            Task {
                                await WorkoutService.shared.delete(workoutID: entry.workoutID, userID: userID)
                                entries.removeAll { $0.workoutID == entry.workoutID }
                                if isToday { MacroAdjustmentEngine.revert() }
                            }
                        })
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 100)
        }
        .task(id: selectedDate) { await load() }
        .onReceive(NotificationCenter.default.publisher(for: WorkoutService.workoutSavedNotification)) { _ in
            Task { await load() }
        }
        .sheet(item: $editingEntry) { entry in
            LogWorkoutSheet(
                userID:              userID,
                selectedDate:        selectedDate,
                bodyWeightLbs:       bodyWeightLbs,
                autoAdjustByDefault: autoAdjustByDefault,
                userSettings:        userSettings,
                editingEntry:        entry,
                onSaved:             { Task { await load() } }
            )
        }
    }

    // MARK: - Sub-views

    private var duelRestDayButton: some View {
        Button {
            Task {
                isSavingRestDay = true
                let entry = WorkoutEntry(name: "Rest Day", workoutType: .restDay,
                                         durationMinutes: 0, caloriesBurned: 0,
                                         loggedAt: selectedDate)
                try? await WorkoutService.shared.save(entry: entry, userID: userID)
                if isToday { MacroAdjustmentEngine.apply(for: .restDay, bodyWeightLbs: bodyWeightLbs) }
                await load()
                isSavingRestDay = false
            }
        } label: {
            HStack(spacing: 8) {
                if isSavingRestDay {
                    ProgressView().tint(.white).scaleEffect(0.8)
                } else {
                    Image(systemName: "moon.zzz.fill")
                        .foregroundStyle(.white.opacity(0.55))
                }
                Text(isSavingRestDay ? "Saving…" : "Log Rest Day")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(isSavingRestDay)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 40)
            ZStack {
                Circle()
                    .fill(accent.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 36))
                    .foregroundStyle(accent.opacity(0.45))
            }
            VStack(spacing: 6) {
                Text("No workouts logged")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                Text("Tap + and choose \"Log a Workout\" to get started")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.32))
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }

    private var totalCard: some View {
        let total    = entries.reduce(0) { $0 + $1.caloriesBurned }
        let totalMin = entries.reduce(0) { $0 + $1.durationMinutes }

        // Sum adjustments across every logged workout
        let combined: MacroAdjustment = entries.reduce(
            MacroAdjustment(caloriesDelta: 0, carbsDelta: 0, proteinDelta: 0, fatDelta: 0)
        ) { acc, entry in
            let a = MacroAdjustmentEngine.adjustment(for: entry.workoutType, bodyWeightLbs: bodyWeightLbs)
            return MacroAdjustment(
                caloriesDelta: acc.caloriesDelta + a.caloriesDelta,
                carbsDelta:    acc.carbsDelta    + a.carbsDelta,
                proteinDelta:  acc.proteinDelta  + a.proteinDelta,
                fatDelta:      acc.fatDelta      + a.fatDelta
            )
        }

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                statBlock(value: "\(total)", label: "Cal Burned", color: accent)
                Divider()
                    .frame(height: 40)
                    .background(.white.opacity(0.10))
                statBlock(value: formatMinutes(totalMin), label: "Total Time", color: .white.opacity(0.75))
            }
            .padding(.vertical, 16)

            if !combined.isEmpty {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.80, blue: 0.20))
                        Text("Macro Goal Adjustments")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.80, blue: 0.20))
                    }

                    HStack(spacing: 8) {
                        macroAdjChip(label: "Cal",  delta: combined.caloriesDelta, unit: "kcal")
                        macroAdjChip(label: "Carbs",delta: combined.carbsDelta,    unit: "g")
                        macroAdjChip(label: "Pro",  delta: combined.proteinDelta,  unit: "g")
                        macroAdjChip(label: "Fat",  delta: combined.fatDelta,      unit: "g")
                    }

                    Text("Applied to today's goals only · resets tomorrow")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.25))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.20), lineWidth: 1))
    }

    private func macroAdjChip(label: String, delta: Int, unit: String) -> some View {
        let positive = delta >= 0
        let color: Color = positive
            ? Color(red: 0.30, green: 0.90, blue: 0.55)
            : Color(red: 1.00, green: 0.45, blue: 0.45)
        let sign = positive ? "+" : ""
        return VStack(spacing: 2) {
            Text("\(sign)\(delta)\(unit)")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.40))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.20), lineWidth: 1))
    }

    private func statBlock(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.40))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func load() async {
        isLoading = true
        entries   = (try? await WorkoutService.shared.fetch(userID: userID, date: selectedDate)) ?? []
        isLoading = false
    }

    private func formatMinutes(_ min: Int) -> String {
        min >= 60 ? "\(min / 60)h \(min % 60)m" : "\(min)m"
    }
}

// MARK: - WorkoutRow

private struct WorkoutRow: View {
    let entry:    WorkoutEntry
    let accent:   Color
    let cardBg:   Color
    let onEdit:   () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: "flame.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(entry.formattedDuration) · \(entry.caloriesBurned) cal burned")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            Text(entry.loggedAt.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.30))
        }
        .padding(14)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.06), lineWidth: 1))
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
