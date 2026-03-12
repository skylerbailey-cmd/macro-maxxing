//
//  FastingTimelineView.swift
//  Wellness
//

import SwiftUI
import Charts

struct FastingTimelineView: View {
    let windowStart: Double   // fractional hour, e.g. 9.0
    let windowEnd: Double     // fractional hour, e.g. 17.0

    private var currentFractionalHour: Double {
        let now = Date()
        let hour = Double(Calendar.current.component(.hour, from: now))
        let minute = Double(Calendar.current.component(.minute, from: now))
        return hour + minute / 60.0
    }

    // Data model for the three segments
    private struct Segment: Identifiable {
        let id = UUID()
        let label: String
        let start: Double
        let end: Double
        let isEatingWindow: Bool
    }

    private var segments: [Segment] {
        var result: [Segment] = []
        if windowStart > 0 {
            result.append(Segment(label: "fast1", start: 0, end: windowStart, isEatingWindow: false))
        }
        result.append(Segment(label: "eating", start: windowStart, end: min(windowEnd, 24), isEatingWindow: true))
        if windowEnd < 24 {
            result.append(Segment(label: "fast2", start: min(windowEnd, 24), end: 24, isEatingWindow: false))
        }
        return result
    }

    var body: some View {
        Chart {
            ForEach(segments) { segment in
                RectangleMark(
                    xStart: .value("Hour", segment.start),
                    xEnd: .value("Hour", segment.end),
                    y: .value("", "")
                )
                .foregroundStyle(segment.isEatingWindow
                    ? Color.green.opacity(0.75)
                    : Color(.systemGray4))
                .cornerRadius(4)
            }

            // Current time indicator
            let now = currentFractionalHour
            if now >= 0 && now <= 24 {
                RuleMark(x: .value("Now", now))
                    .foregroundStyle(.red.opacity(0.85))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    .annotation(position: .top, alignment: .center, spacing: 2) {
                        Text("Now")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
            }
        }
        .chartXScale(domain: 0...24)
        .chartXAxis {
            AxisMarks(values: [0, 3, 6, 9, 12, 15, 18, 21, 24]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color(.systemGray5))
                AxisValueLabel {
                    if let hour = value.as(Int.self) {
                        Text(hourLabel(hour))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .frame(height: 72)
    }

    private func hourLabel(_ hour: Int) -> String {
        switch hour {
        case 0: return "12a"
        case 12: return "12p"
        case 24: return ""
        default:
            let h = hour > 12 ? hour - 12 : hour
            return hour < 12 ? "\(h)a" : "\(h)p"
        }
    }
}

#Preview {
    FastingTimelineView(windowStart: 9.0, windowEnd: 17.0)
        .padding()
}
