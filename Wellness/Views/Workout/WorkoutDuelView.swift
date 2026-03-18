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

    @State private var entries:         [WorkoutEntry] = []
    @State private var isLoading        = false
    @State private var showingRestDayConfirm = false
    @State private var isSavingRestDay  = false

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

                    // Rest day quick-log (only shown when no rest day already logged)
                    if !entries.contains(where: { $0.workoutType == .restDay }) {
                        duelRestDayButton
                    }

                    Text("\(entries.count) Workout\(entries.count == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.30))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(entries) { entry in
                        WorkoutRow(entry: entry, accent: accent, cardBg: cardBg) {
                            Task {
                                await WorkoutService.shared.delete(workoutID: entry.workoutID, userID: userID)
                                entries.removeAll { $0.workoutID == entry.workoutID }
                            }
                        }
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
                MacroAdjustmentEngine.apply(for: .restDay, bodyWeightLbs: bodyWeightLbs)
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
        let total = entries.reduce(0) { $0 + $1.caloriesBurned }
        let totalMin = entries.reduce(0) { $0 + $1.durationMinutes }

        return HStack(spacing: 0) {
            statBlock(value: "\(total)", label: "Cal Burned", color: accent)
            Divider()
                .frame(height: 40)
                .background(.white.opacity(0.10))
            statBlock(value: formatMinutes(totalMin), label: "Total Time", color: .white.opacity(0.75))
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.20), lineWidth: 1))
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
    let entry:   WorkoutEntry
    let accent:  Color
    let cardBg:  Color
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
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
