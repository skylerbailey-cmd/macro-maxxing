//
//  WorkoutTimerBanner.swift
//  Wellness
//
//  Persistent top-of-screen banner shown while a workout is in progress.
//

import SwiftUI

struct WorkoutTimerBanner: View {

    let startTime:           Date
    let pausedAt:            Date?
    let totalPausedSeconds:  Double
    let onPause:             () -> Void
    let onResume:            () -> Void
    let onLog:               () -> Void

    @State private var now = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let accent = Color(red: 0.30, green: 0.90, blue: 0.55)
    private let bg     = Color(red: 0.07, green: 0.05, blue: 0.14)

    var isPaused: Bool { pausedAt != nil }

    var elapsedSeconds: Double {
        let end = isPaused ? pausedAt! : now
        return max(0, end.timeIntervalSince(startTime) - totalPausedSeconds)
    }

    var body: some View {
        HStack(spacing: 12) {

            // Icon
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accent)
            }

            // Time info
            VStack(alignment: .leading, spacing: 1) {
                Text(formatElapsed(elapsedSeconds))
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("Started \(startTime.formatted(date: .omitted, time: .shortened))"
                     + (isPaused ? "  ·  Paused" : ""))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isPaused ? .orange.opacity(0.85) : .white.opacity(0.42))
            }

            Spacer()

            // Pause / Resume
            Button(action: isPaused ? onResume : onPause) {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.10), in: Circle())
            }
            .buttonStyle(.plain)

            // Log workout
            Button(action: onLog) {
                Text("Log")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(accent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(bg)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(accent.opacity(0.25)),
            alignment: .bottom
        )
        .onReceive(ticker) { t in
            if !isPaused { now = t }
        }
    }

    // MARK: - Helpers

    private func formatElapsed(_ seconds: Double) -> String {
        let s   = Int(seconds)
        let h   = s / 3600
        let m   = (s % 3600) / 60
        let sec = s % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, sec)
            : String(format: "%02d:%02d", m, sec)
    }
}
