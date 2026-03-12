//
//  ShareCardView.swift
//  Wellness
//
//  Self-contained card for ImageRenderer — no environment dependencies.
//

import SwiftUI

// MARK: - Data model for the card

struct ShareCardData {
    let totalCalories: Double
    let goalCalories:  Double
    let totalProtein:  Double
    let goalProtein:   Double
    let totalCarbs:    Double
    let goalCarbs:     Double
    let totalFat:      Double
    let goalFat:       Double
    let calMet:  Bool
    let proMet:  Bool
    let carbMet: Bool
    let fatMet:  Bool
    let streak:  Int
    let date:    Date
    let name:    String

    var allMet: Bool { calMet && proMet && carbMet && fatMet }
}

// MARK: - Share Card (360 × 640 pt  →  1080 × 1920 px @ 3×)

struct ShareCardView: View {
    let data: ShareCardData

    // Palette
    private let bg1   = Color(red: 0.08, green: 0.04, blue: 0.15)
    private let bg2   = Color(red: 0.03, green: 0.01, blue: 0.08)
    private let card  = Color(red: 0.13, green: 0.09, blue: 0.22)
    private let purpl = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold  = Color(red: 1.00, green: 0.80, blue: 0.20)

    // Macro colours
    private let colCal  = Color(red: 1.00, green: 0.55, blue: 0.15)
    private let colPro  = Color(red: 0.35, green: 0.75, blue: 1.00)
    private let colCarb = Color(red: 0.40, green: 0.90, blue: 0.72)
    private let colFat  = Color(red: 1.00, green: 0.50, blue: 0.72)

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                header.padding(.top, 38)

                Spacer()

                if data.allMet { celebration.padding(.bottom, 4) }

                macroGrid
                    .padding(.horizontal, 22)
                    .padding(.top, data.allMet ? 16 : 0)

                Spacer()

                streakBadge

                Spacer()

                footer.padding(.bottom, 30)
            }
        }
        .frame(width: 360, height: 640)
        .preferredColorScheme(.dark)
    }

    // MARK: Background

    @ViewBuilder
    private var background: some View {
        Rectangle()
            .fill(
                RadialGradient(
                    colors: data.allMet
                        ? [Color(red: 0.18, green: 0.10, blue: 0.04), bg2]
                        : [Color(red: 0.11, green: 0.06, blue: 0.20), bg2],
                    center: .init(x: 0.5, y: 0.3),
                    startRadius: 0, endRadius: 380
                )
            )

        // Subtle sparkle dots for celebration
        if data.allMet {
            ForEach(0..<8, id: \.self) { i in
                let positions: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                    (0.08, 0.09, 0.55, 4), (0.88, 0.12, 0.40, 3),
                    (0.18, 0.88, 0.50, 5), (0.92, 0.78, 0.35, 4),
                    (0.50, 0.04, 0.65, 3), (0.12, 0.52, 0.40, 2),
                    (0.78, 0.42, 0.50, 4), (0.40, 0.94, 0.40, 3),
                ]
                let p = positions[i]
                Circle()
                    .fill(gold.opacity(p.2))
                    .frame(width: p.3, height: p.3)
                    .position(x: p.0 * 360, y: p.1 * 640)
                    .blur(radius: 1)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 5) {
            // App name + logo mark
            HStack(spacing: 8) {
                // Mini logo circle
                ZStack {
                    Circle()
                        .stroke(purpl, lineWidth: 2)
                        .frame(width: 26, height: 26)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(purpl)
                }
                Text("Macro Maxxing")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(formattedDate)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.40))
        }
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: data.date)
    }

    // MARK: Celebration

    private var celebration: some View {
        VStack(spacing: 6) {
            Text("🏆")
                .font(.system(size: 50))

            Text(data.name.isEmpty ? "All Goals Crushed!" : "\(data.name.components(separatedBy: " ").first ?? data.name) Crushed It!")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [gold, Color(red: 1.0, green: 0.6, blue: 0.15)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text("Every macro goal met today 🔥")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
        }
    }

    // MARK: Macro grid (2 × 2)

    private var macroGrid: some View {
        let items: [(String, Double, Double, Color, Bool)] = [
            ("Calories", data.totalCalories, data.goalCalories, colCal,  data.calMet),
            ("Protein",  data.totalProtein,  data.goalProtein,  colPro,  data.proMet),
            ("Carbs",    data.totalCarbs,    data.goalCarbs,    colCarb, data.carbMet),
            ("Fat",      data.totalFat,      data.goalFat,      colFat,  data.fatMet),
        ]
        return LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 10
        ) {
            ForEach(items.indices, id: \.self) { i in
                macroCell(items[i])
            }
        }
    }

    private func macroCell(_ item: (String, Double, Double, Color, Bool)) -> some View {
        let (label, value, goal, color, met) = item
        let progress  = goal > 0 ? min(value / goal, 1.0) : 0
        let unit      = label == "Calories" ? "kcal" : "g"
        let valueText = label == "Calories" ? "\(Int(value))" : "\(Int(value))g"
        let goalText  = "/ \(Int(goal))\(unit)"

        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(color.opacity(0.14),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(135))

                Circle()
                    .trim(from: 0, to: progress * 0.75)
                    .stroke(color,
                            style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(135))

                VStack(spacing: 1) {
                    Text(valueText)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    if met {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(color)
                    }
                }
            }
            .frame(width: 66, height: 66)

            VStack(spacing: 1) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.90))
                Text(goalText)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(card)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(met ? color.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
    }

    // MARK: Streak badge

    private var streakBadge: some View {
        HStack(spacing: 8) {
            Text("🔥")
                .font(.system(size: 26))
            VStack(alignment: .leading, spacing: 1) {
                Text("\(data.streak) Day Streak")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("consecutive days logged")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.40))
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            Text("macro maxxing")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(purpl.opacity(0.70))
            Spacer()
            Text("Track your journey")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.22))
        }
        .padding(.horizontal, 28)
    }
}
