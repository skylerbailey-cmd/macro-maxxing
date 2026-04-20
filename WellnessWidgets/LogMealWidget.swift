//
//  LogMealWidget.swift
//  WellnessWidgets
//
//  Lock screen circular widget. Tapping it deep-links into the app's
//  Log tab so the user can quickly log a meal.
//

import SwiftUI
import WidgetKit

// MARK: - Timeline

struct LogMealProvider: TimelineProvider {
    func placeholder(in context: Context) -> LogMealEntry {
        LogMealEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (LogMealEntry) -> Void) {
        completion(LogMealEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LogMealEntry>) -> Void) {
        let entry = LogMealEntry(date: .now)
        // Static widget — refresh once a day
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct LogMealEntry: TimelineEntry {
    let date: Date
}

// MARK: - Widget

struct LogMealWidget: Widget {
    let kind = "LogMealWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LogMealProvider()) { entry in
            LogMealWidgetView(entry: entry)
        }
        .configurationDisplayName("Log a Meal")
        .description("Quick access to log your meals.")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - View

struct LogMealWidgetView: View {
    let entry: LogMealEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            // App icon: circle ring + three vertical bars
            AppIconShape()
                .frame(width: 24, height: 24)
        }
        .widgetURL(URL(string: "wellness://log"))
        .containerBackground(for: .widget) { }
    }
}

// MARK: - App Icon (vector recreation for lock screen)

/// Simplified monochrome version of the app icon: a circle ring with
/// three rounded vertical bars in the center.
private struct AppIconShape: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let cx = w / 2
            let cy = h / 2
            let radius = min(w, h) / 2

            // Outer ring
            let ringWidth: CGFloat = radius * 0.12
            let ringRect = CGRect(
                x: cx - radius + ringWidth / 2,
                y: cy - radius + ringWidth / 2,
                width: (radius - ringWidth / 2) * 2,
                height: (radius - ringWidth / 2) * 2
            )
            ctx.stroke(
                Path(ellipseIn: ringRect),
                with: .color(.white),
                lineWidth: ringWidth
            )

            // Three vertical bars
            let barWidth: CGFloat = radius * 0.13
            let barCorner = barWidth / 2
            let centerBarH = radius * 0.9
            let sideBarH   = radius * 0.65
            let barGap: CGFloat = radius * 0.24

            // Center bar
            let centerBar = CGRect(
                x: cx - barWidth / 2,
                y: cy - centerBarH / 2,
                width: barWidth,
                height: centerBarH
            )
            ctx.fill(
                Path(roundedRect: centerBar, cornerRadius: barCorner),
                with: .color(.white)
            )

            // Left bar
            let leftBar = CGRect(
                x: cx - barWidth / 2 - barGap,
                y: cy - sideBarH / 2,
                width: barWidth,
                height: sideBarH
            )
            ctx.fill(
                Path(roundedRect: leftBar, cornerRadius: barCorner),
                with: .color(.white)
            )

            // Right bar
            let rightBar = CGRect(
                x: cx - barWidth / 2 + barGap,
                y: cy - sideBarH / 2,
                width: barWidth,
                height: sideBarH
            )
            ctx.fill(
                Path(roundedRect: rightBar, cornerRadius: barCorner),
                with: .color(.white)
            )
        }
    }
}
