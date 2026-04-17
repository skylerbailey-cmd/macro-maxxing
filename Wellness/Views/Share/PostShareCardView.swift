//
//  PostShareCardView.swift
//  Wellness
//
//  Self-contained renderable preview of a FeedPost for sharing to Instagram
//  Stories / Photos / AirDrop. No environment dependencies, no async image
//  loading — all images must be passed in as UIImages so ImageRenderer can
//  produce a stable snapshot.
//

import SwiftUI

// MARK: - PostShareCardView (360 × 640 pt → 1080 × 1920 px @ 3×)

struct PostShareCardView: View {

    // Inputs
    let post:         FeedPost
    /// Pre-fetched primary food photo (nil → falls back to a gradient panel).
    let foodImage:    UIImage?
    /// Pre-fetched author avatar (nil → falls back to an initial circle).
    let authorAvatar: UIImage?

    // Palette — matches app chrome
    private let bg1  = Color(red: 0.08, green: 0.04, blue: 0.15)
    private let bg2  = Color(red: 0.03, green: 0.01, blue: 0.08)
    private let card = Color(red: 0.13, green: 0.09, blue: 0.22)
    /// Uses the post's label color when one was set in the composer, otherwise
    /// the app accent. This is what colors the glow, author badge, workout
    /// chips, and the Lv pill in the rendered share visual — so the shared
    /// image matches the label the user picked.
    private var accent: Color { post.themeColor }

    // Macro palette (mirrors Color+Extensions.swift)
    private let calClr  = Color(red: 1.00, green: 0.55, blue: 0.15)
    private let proClr  = Color(red: 0.35, green: 0.75, blue: 1.00)
    private let carbClr = Color(red: 0.40, green: 0.90, blue: 0.72)
    private let fatClr  = Color(red: 1.00, green: 0.50, blue: 0.72)

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                // Top row: label chip (left) + author (right)
                HStack(alignment: .top) {
                    labelChip
                    Spacer()
                    authorHeader
                }
                .padding(.top, 32)
                .padding(.horizontal, 22)

                Spacer(minLength: 14)

                // Centerpiece: label-driven visual or food photo
                centerContent
                    .padding(.horizontal, 22)

                Spacer(minLength: 14)

                contentBlock
                    .padding(.horizontal, 22)

                Spacer(minLength: 14)

                footer
                    .padding(.bottom, 28)
            }
        }
        .frame(width: 360, height: 640)
        .preferredColorScheme(.dark)
    }

    // MARK: Background

    private var background: some View {
        ZStack {
            LinearGradient(colors: [bg1, bg2],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            // Soft accent glow
            Circle()
                .fill(accent.opacity(0.25))
                .frame(width: 360)
                .blur(radius: 90)
                .offset(x: -120, y: -220)
            Circle()
                .fill(accent.opacity(0.18))
                .frame(width: 300)
                .blur(radius: 90)
                .offset(x: 140, y: 240)
        }
    }

    // MARK: Author header

    private var authorHeader: some View {
        HStack(spacing: 8) {
            VStack(alignment: .trailing, spacing: 1) {
                Text(post.whoName.isEmpty ? post.username : post.whoName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("@\(post.username)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
            }
            Group {
                if let img = authorAvatar {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Circle().fill(accent.opacity(0.25))
                        Text(String((post.whoName.isEmpty ? post.username : post.whoName).prefix(1)).uppercased())
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.20), lineWidth: 1))
        }
    }

    // MARK: Label chip (upper left)

    @ViewBuilder
    private var labelChip: some View {
        if let label = PostLabel(rawValue: post.postLabel) {
            HStack(spacing: 5) {
                Image(systemName: label.icon)
                    .font(.system(size: 10, weight: .bold))
                Text(label.rawValue)
                    .font(.system(size: 11, weight: .black, design: .rounded))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(label.color, in: Capsule())
        } else {
            EmptyView()
        }
    }

    // MARK: Center content (label-driven)

    @ViewBuilder
    private var centerContent: some View {
        if let img = foodImage {
            // Food photo always wins when present
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(height: 260)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        } else if !post.workoutItems.isEmpty {
            workoutVisual
        } else if !post.fuelLogItems.isEmpty {
            fuelLogVisual
        } else if post.goalCalories > 0 {
            goalVisual
        } else {
            // Text-only fallback — no giant icon
            titleVisual
        }
    }

    // MARK: Workout visual

    private var workoutVisual: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(post.workoutItems.prefix(6).enumerated()), id: \.offset) { _, item in
                HStack(spacing: 8) {
                    Image(systemName: WorkoutType(rawValue: item.workoutType)?.icon ?? "figure.run")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(accent)
                        .frame(width: 20)
                    Text(item.workoutName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    if item.durationMinutes > 0 {
                        Text("\(item.durationMinutes)m")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    if item.caloriesBurned > 0 {
                        Text("\(item.caloriesBurned) cal")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(calClr)
                    }
                }
            }
            if post.workoutItems.count > 6 {
                Text("+ \(post.workoutItems.count - 6) more")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .padding(16)
        .background(card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.20), lineWidth: 1))
    }

    // MARK: Fuel log visual

    private var fuelLogVisual: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(post.fuelLogItems.prefix(5).enumerated()), id: \.offset) { _, item in
                HStack(spacing: 8) {
                    Text(item.foodName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    Text("\(Int(item.calories)) cal")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(calClr)
                    Text("\(Int(item.protein))g P")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(proClr)
                }
            }
            if post.fuelLogItems.count > 5 {
                Text("+ \(post.fuelLogItems.count - 5) more")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .padding(16)
        .background(card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.20), lineWidth: 1))
    }

    // MARK: Goal visual

    private var goalVisual: some View {
        let macros: [(String, Int, Int, Color)] = [
            ("Calories", post.calories, post.goalCalories, calClr),
            ("Protein",  Int(post.protein), Int(post.goalProtein), proClr),
            ("Carbs",    Int(post.carbs), Int(post.goalCarbs), carbClr),
            ("Fat",      Int(post.fat), Int(post.goalFat), fatClr),
        ]
        return VStack(spacing: 10) {
            ForEach(Array(macros.enumerated()), id: \.offset) { _, macro in
                let (label, actual, goal, color) = macro
                let pct = goal > 0 ? min(Double(actual) / Double(goal), 1.0) : 0
                HStack(spacing: 8) {
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.70))
                        .frame(width: 60, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.07)).frame(height: 8)
                            Capsule().fill(color.opacity(0.85))
                                .frame(width: max(4, geo.size.width * pct), height: 8)
                        }
                    }
                    .frame(height: 8)
                    Text("\(Int(pct * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                        .frame(width: 34, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.20), lineWidth: 1))
    }

    // MARK: Text-only fallback

    private var titleVisual: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !post.title.isEmpty {
                Text(displayTitle)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(4)
            }
            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.70))
                    .lineLimit(6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.20), lineWidth: 1))
    }

    // MARK: Content block (title + caption + macro/workout summary)

    private var contentBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !post.title.isEmpty {
                Text(displayTitle)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }

            if !post.workoutItems.isEmpty {
                workoutSummary
            } else if post.calories > 0 {
                macroSummary
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Strips the "Breakfast: " style prefix — redundant inside a card that already
    /// visually implies a meal.
    private var displayTitle: String {
        let parts = post.title.split(separator: ":", maxSplits: 1).map(String.init)
        return parts.count > 1
            ? parts[1].trimmingCharacters(in: CharacterSet.whitespaces)
            : post.title
    }

    private var macroSummary: some View {
        HStack(spacing: 6) {
            macroBadge(value: "\(post.calories)",      unit: "kcal", color: calClr)
            macroBadge(value: "\(Int(post.protein))",  unit: "P",    color: proClr)
            macroBadge(value: "\(Int(post.carbs))",    unit: "C",    color: carbClr)
            macroBadge(value: "\(Int(post.fat))",      unit: "F",    color: fatClr)
        }
    }

    private func macroBadge(value: String, unit: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(value).font(.system(size: 14, weight: .black, design: .rounded)).foregroundStyle(color)
            Text(unit).font(.system(size: 10, weight: .semibold)).foregroundStyle(color.opacity(0.65))
        }
        .padding(.horizontal, 9).padding(.vertical, 6)
        .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 9))
    }

    private var workoutSummary: some View {
        let totalMin = post.workoutItems.reduce(0) { $0 + $1.durationMinutes }
        let totalCal = post.workoutItems.reduce(0) { $0 + $1.caloriesBurned }
        let timeLabel = totalMin >= 60 ? "\(totalMin / 60)h \(totalMin % 60)m" : "\(totalMin)m"
        return HStack(spacing: 10) {
            workoutBadge(icon: "clock.fill",    text: timeLabel,         color: accent)
            workoutBadge(icon: "flame.fill",    text: "\(totalCal) kcal", color: calClr)
            workoutBadge(icon: "dumbbell.fill", text: "\(post.workoutItems.count) lifts",
                         color: proClr)
        }
    }

    private func workoutBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundStyle(color)
            Text(text).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(.white)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 9))
    }

    // MARK: Footer branding

    private var footer: some View {
        VStack(spacing: 4) {
            Text("MACRO MAXXING")
                .font(.system(size: 12, weight: .black))
                .tracking(3.0)
                .foregroundStyle(.white.opacity(0.90))
            Text("macromaxxing.app")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.40))
        }
    }
}
