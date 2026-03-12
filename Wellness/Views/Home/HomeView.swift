//
//  HomeView.swift
//  Wellness
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    @State private var showingWindowPicker = false

    // Proxy Date used by DatePicker — represents today at windowStart time
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
        comps.hour = hour
        comps.minute = minute
        guard let date = Calendar.current.date(from: comps) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: Eating Window Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Eating Window")
                                .font(.headline)
                            Text("\(timeString(hour: viewModel.windowStartHour, minute: viewModel.windowStartMinute)) – \(timeString(hour: viewModel.windowEndHour, minute: viewModel.windowEndMinute))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Edit") {
                            showingWindowPicker = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    FastingTimelineView(
                        windowStart: viewModel.windowStartFractional,
                        windowEnd: viewModel.windowEndFractional
                    )
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(14)

                // MARK: Today's Macros
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Macros")
                        .font(.headline)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MacroCard(
                            label: "Calories",
                            value: viewModel.totalCalories,
                            unit: "kcal",
                            color: .orange,
                            format: "%.0f"
                        )
                        MacroCard(
                            label: "Protein",
                            value: viewModel.totalProtein,
                            unit: "g",
                            color: .blue,
                            format: "%.1f"
                        )
                        MacroCard(
                            label: "Carbs",
                            value: viewModel.totalCarbs,
                            unit: "g",
                            color: .yellow,
                            format: "%.1f"
                        )
                        MacroCard(
                            label: "Fat",
                            value: viewModel.totalFat,
                            unit: "g",
                            color: .red,
                            format: "%.1f"
                        )
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .onAppear { viewModel.loadTodayTotals() }
        .sheet(isPresented: $showingWindowPicker) {
            WindowPickerSheet(windowStartDate: windowStartDate)
                .presentationDetents([.medium])
        }
    }
}

// MARK: - Macro Card

private struct MacroCard: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    let format: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color.opacity(0.85))
                    .frame(width: 10, height: 10)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(String(format: format, value))
                    .font(.title2.bold())
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Window Picker Sheet

private struct WindowPickerSheet: View {
    @Binding var windowStartDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Start Time",
                        selection: $windowStartDate,
                        displayedComponents: .hourAndMinute
                    )
                } footer: {
                    Text("The eating window is always 8 hours. The end time is calculated automatically.")
                }
            }
            .navigationTitle("Eating Window")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodEntry.self, configurations: config)
    let vm = HomeViewModel(modelContext: container.mainContext)
    return NavigationStack {
        HomeView(viewModel: vm)
            .navigationTitle("Today")
    }
}
