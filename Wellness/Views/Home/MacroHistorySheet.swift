//
//  MacroHistorySheet.swift
//  Wellness
//

import SwiftUI
import SwiftData
import Charts

// MARK: - MacroType

enum MacroType: String, CaseIterable, Identifiable {
    case calories, protein, carbs, fat

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .calories: return "Calories"
        case .protein:  return "Protein"
        case .carbs:    return "Carbs"
        case .fat:      return "Fat"
        }
    }

    var unit: String { self == .calories ? "kcal" : "g" }

    var color: Color {
        switch self {
        case .calories: return Color(red: 1.00, green: 0.55, blue: 0.15)
        case .protein:  return Color(red: 0.35, green: 0.75, blue: 1.00)
        case .carbs:    return Color(red: 0.40, green: 0.90, blue: 0.72)
        case .fat:      return Color(red: 1.00, green: 0.50, blue: 0.72)
        }
    }

    func extract(from entry: FoodEntry) -> Double {
        switch self {
        case .calories: return entry.calories
        case .protein:  return entry.protein
        case .carbs:    return entry.carbs
        case .fat:      return entry.fat
        }
    }
}

// MARK: - MacroHistorySheet

struct MacroHistorySheet: View {
    let macro:     MacroType
    let goalValue: Double

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    enum Period: String, CaseIterable {
        case days   = "Days"
        case weeks  = "Weeks"
        case months = "Months"
    }

    @State private var period:     Period = .days
    @State private var dataPoints: [DataPoint] = []

    struct DataPoint: Identifiable {
        let id    = UUID()
        let date:  Date
        let value: Double
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Period selector
                Picker("Period", selection: $period) {
                    ForEach(Period.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if dataPoints.allSatisfy({ $0.value == 0 }) {
                    Spacer()
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary.opacity(0.4))
                    Text("No data logged yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    chartView
                        .padding(.horizontal)
                }
            }
            .padding(.top, 16)
            .navigationTitle("\(macro.displayName) History")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: period, initial: true) { _, _ in loadData() }
        }
    }

    // MARK: - Chart

    private var chartView: some View {
        Chart {
            // Dashed goal line
            RuleMark(y: .value("Goal", goalValue))
                .foregroundStyle(macro.color.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("Goal")
                        .font(.caption2)
                        .foregroundStyle(macro.color.opacity(0.75))
                }

            // Area under line
            ForEach(dataPoints) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value(macro.displayName, point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [macro.color.opacity(0.25), macro.color.opacity(0.03)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Line
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value(macro.displayName, point.value)
                )
                .foregroundStyle(macro.color)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
            }

            // Dots
            ForEach(dataPoints) { point in
                PointMark(
                    x: .value("Date", point.date),
                    y: .value(macro.displayName, point.value)
                )
                .foregroundStyle(macro.color)
                .symbolSize(40)
            }
        }
        .chartXAxis {
            AxisMarks(values: dataPoints.map { $0.date }) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(Color.white.opacity(0.12))
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(xLabel(for: date))
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.55))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(Color.white.opacity(0.12))
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(yLabel(v))
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.55))
                    }
                }
            }
        }
        .chartYScale(domain: yDomain)
        .frame(height: 260)
    }

    // MARK: - Data loading

    private func loadData() {
        let calendar = Calendar.current
        let today    = calendar.startOfDay(for: Date())

        switch period {

        case .days:
            guard let start = calendar.date(byAdding: .day, value: -6, to: today),
                  let end   = calendar.date(byAdding: .day, value:  1, to: today) else { return }
            let all = fetchEntries(from: start, to: end)
            dataPoints = (0..<7).compactMap { offset in
                guard let day    = calendar.date(byAdding: .day, value: -(6 - offset), to: today),
                      let dayEnd = calendar.date(byAdding: .day, value: 1, to: day) else { return nil }
                let total = all.filter { $0.loggedAt >= day && $0.loggedAt < dayEnd }
                               .reduce(0) { $0 + macro.extract(from: $1) }
                return DataPoint(date: day, value: total)
            }

        case .weeks:
            // Anchor to start of current week (Monday)
            let weekdayOffset = (calendar.component(.weekday, from: today) + 5) % 7
            guard let thisWeek = calendar.date(byAdding: .day, value: -weekdayOffset, to: today),
                  let start    = calendar.date(byAdding: .weekOfYear, value: -7, to: thisWeek),
                  let end      = calendar.date(byAdding: .day, value: 7, to: thisWeek) else { return }
            let all = fetchEntries(from: start, to: end)
            dataPoints = (0..<8).compactMap { offset in
                guard let wStart = calendar.date(byAdding: .weekOfYear, value: -(7 - offset), to: thisWeek),
                      let wEnd   = calendar.date(byAdding: .day, value: 7, to: wStart) else { return nil }
                let entries    = all.filter { $0.loggedAt >= wStart && $0.loggedAt < wEnd }
                let total      = entries.reduce(0.0) { $0 + macro.extract(from: $1) }
                let loggedDays = Set(entries.map { calendar.startOfDay(for: $0.loggedAt) }).count
                let avg        = loggedDays > 0 ? total / Double(loggedDays) : 0
                return DataPoint(date: wStart, value: avg)
            }

        case .months:
            let monthComps = calendar.dateComponents([.year, .month], from: today)
            guard let thisMonth = calendar.date(from: monthComps),
                  let start     = calendar.date(byAdding: .month, value: -5, to: thisMonth),
                  let end       = calendar.date(byAdding: .month, value:  1, to: thisMonth) else { return }
            let all = fetchEntries(from: start, to: end)
            dataPoints = (0..<6).compactMap { offset in
                guard let mStart = calendar.date(byAdding: .month, value: -(5 - offset), to: thisMonth),
                      let mEnd   = calendar.date(byAdding: .month, value: 1, to: mStart) else { return nil }
                let entries    = all.filter { $0.loggedAt >= mStart && $0.loggedAt < mEnd }
                let total      = entries.reduce(0.0) { $0 + macro.extract(from: $1) }
                let loggedDays = Set(entries.map { calendar.startOfDay(for: $0.loggedAt) }).count
                let avg        = loggedDays > 0 ? total / Double(loggedDays) : 0
                return DataPoint(date: mStart, value: avg)
            }
        }
    }

    private func fetchEntries(from start: Date, to end: Date) -> [FoodEntry] {
        let pred = #Predicate<FoodEntry> { $0.loggedAt >= start && $0.loggedAt < end }
        return (try? modelContext.fetch(FetchDescriptor<FoodEntry>(predicate: pred))) ?? []
    }

    // MARK: - Labels & scale

    private var subtitle: String {
        switch period {
        case .days:   return "Daily total — last 7 days"
        case .weeks:  return "Daily avg per week — last 8 weeks"
        case .months: return "Daily avg per month — last 6 months"
        }
    }

    private func xLabel(for date: Date) -> String {
        let f = DateFormatter()
        switch period {
        case .days:
            if Calendar.current.isDateInToday(date) { return "Today" }
            f.dateFormat = "EEE"; return f.string(from: date)
        case .weeks:
            f.dateFormat = "M/d"; return f.string(from: date)
        case .months:
            f.dateFormat = "MMM"; return f.string(from: date)
        }
    }

    private func yLabel(_ v: Double) -> String {
        macro == .calories && v >= 1000
            ? String(format: "%.0fk", v / 1000)
            : String(format: "%.0f", v)
    }

    private var yDomain: ClosedRange<Double> {
        let maxVal = max(dataPoints.map { $0.value }.max() ?? 0, goalValue)
        return 0...(maxVal * 1.2)
    }
}

#Preview {
    MacroHistorySheet(macro: .calories, goalValue: 2000)
}
