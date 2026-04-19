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

    /// Whether the post has label-specific detail (fuel log / workout / goal)
    /// that should be shown alongside or instead of the photo.
    private var hasLabelDetail: Bool {
        !post.fuelLogItems.isEmpty || !post.workoutItems.isEmpty || post.goalCalories > 0
    }

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
                .padding(.top, 28)
                .padding(.horizontal, 22)

                Spacer(minLength: 10)

                // Title + caption
                contentBlock
                    .padding(.horizontal, 22)

                Spacer(minLength: 10)

                // Photo (shown smaller when detail table follows)
                if let img = foodImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: hasLabelDetail ? 160 : 260)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.horizontal, 22)
                }

                Spacer(minLength: 8)

                // Label-specific detail: fuel log / workout / goal
                if !post.fuelLogItems.isEmpty {
                    fuelLogVisual
                        .padding(.horizontal, 22)
                } else if !post.workoutItems.isEmpty {
                    workoutVisual
                        .padding(.horizontal, 22)
                } else if post.goalCalories > 0 {
                    goalVisual
                        .padding(.horizontal, 22)
                } else if foodImage == nil {
                    // Text-only fallback when there's no photo and no detail
                    titleVisual
                        .padding(.horizontal, 22)
                }

                Spacer(minLength: 10)

                footer
                    .padding(.bottom, 24)
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

    // (Center content is now rendered inline in body to combine photo + detail)

    // MARK: Workout visual

    private var workoutVisual: some View {
        let sorted = post.workoutItems.sorted { $0.sortOrder < $1.sortOrder }
        let totalMin = sorted.reduce(0) { $0 + $1.durationMinutes }
        let totalCal = sorted.reduce(0) { $0 + $1.caloriesBurned }
        let timeLabel = totalMin >= 60 ? "\(totalMin / 60)h \(totalMin % 60)m" : "\(totalMin)m"

        return VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(sorted.prefix(4).enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: WorkoutType(rawValue: item.workoutType)?.icon ?? "figure.run")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(accent)
                            .frame(width: 16)
                        Text(item.workoutName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer()
                        if item.durationMinutes > 0 {
                            Text(item.formattedDuration)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.40))
                        }
                        if item.caloriesBurned > 0 {
                            Text("\(item.caloriesBurned) cal")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(calClr)
                        }
                    }
                    // Exercise detail rows
                    if !item.exercises.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(item.exercises.prefix(4).enumerated()), id: \.offset) { _, ex in
                                HStack(spacing: 4) {
                                    Text("·")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.25))
                                    Text(ex.name)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.55))
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(ex.sets.count) sets")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.30))
                                }
                            }
                            if item.exercises.count > 4 {
                                Text("+ \(item.exercises.count - 4) more exercises")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.25))
                            }
                        }
                        .padding(.leading, 22)
                    }
                }
            }
            if sorted.count > 4 {
                Text("+ \(sorted.count - 4) more workouts")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.30))
            }

            // Total summary
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
            HStack(spacing: 10) {
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill").font(.system(size: 9, weight: .bold))
                    Text(timeLabel)
                }.font(.system(size: 10, weight: .bold)).foregroundStyle(accent)
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").font(.system(size: 9, weight: .bold))
                    Text("\(totalCal) cal")
                }.font(.system(size: 10, weight: .bold)).foregroundStyle(calClr)
            }
        }
        .padding(14)
        .background(card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.20), lineWidth: 1))
    }

    // MARK: Fuel log visual

    private var fuelLogVisual: some View {
        let sorted = post.fuelLogItems.sorted { $0.sortOrder < $1.sortOrder }
        let totalCal = sorted.reduce(0.0) { $0 + $1.calories }
        let totalPro = sorted.reduce(0.0) { $0 + $1.protein }
        let totalCarb = sorted.reduce(0.0) { $0 + $1.carbs }
        let totalFat = sorted.reduce(0.0) { $0 + $1.fat }

        return VStack(alignment: .leading, spacing: 5) {
            // Header
            HStack {
                Text("Meal").font(.system(size: 9, weight: .semibold)).foregroundStyle(.white.opacity(0.35))
                Spacer()
                Text("Cal").font(.system(size: 9, weight: .semibold)).foregroundStyle(calClr.opacity(0.55)).frame(width: 38, alignment: .trailing)
                Text("P").font(.system(size: 9, weight: .semibold)).foregroundStyle(proClr.opacity(0.55)).frame(width: 28, alignment: .trailing)
                Text("C").font(.system(size: 9, weight: .semibold)).foregroundStyle(carbClr.opacity(0.55)).frame(width: 28, alignment: .trailing)
                Text("F").font(.system(size: 9, weight: .semibold)).foregroundStyle(fatClr.opacity(0.55)).frame(width: 28, alignment: .trailing)
            }
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            ForEach(Array(sorted.prefix(6).enumerated()), id: \.offset) { _, item in
                HStack {
                    Text(item.foodName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    Text("\(Int(item.calories))").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(calClr).frame(width: 38, alignment: .trailing)
                    Text("\(Int(item.protein))g").font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(proClr).frame(width: 28, alignment: .trailing)
                    Text("\(Int(item.carbs))g").font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(carbClr).frame(width: 28, alignment: .trailing)
                    Text("\(Int(item.fat))g").font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(fatClr).frame(width: 28, alignment: .trailing)
                }
            }
            if sorted.count > 6 {
                Text("+ \(sorted.count - 6) more meals")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.30))
            }

            // Totals
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
            HStack {
                Text("Total")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                Text("\(Int(totalCal))").font(.system(size: 10, weight: .black, design: .rounded)).foregroundStyle(calClr).frame(width: 38, alignment: .trailing)
                Text("\(Int(totalPro))g").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(proClr).frame(width: 28, alignment: .trailing)
                Text("\(Int(totalCarb))g").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(carbClr).frame(width: 28, alignment: .trailing)
                Text("\(Int(totalFat))g").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(fatClr).frame(width: 28, alignment: .trailing)
            }
        }
        .padding(14)
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
