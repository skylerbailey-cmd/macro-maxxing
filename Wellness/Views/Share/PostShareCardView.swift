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
    /// Pre-fetched food photos (up to 2).
    let foodImages:   [UIImage]
    /// Pre-fetched author avatar (nil → falls back to an initial circle).
    let authorAvatar: UIImage?
    /// When true, renders with a light background and dark text.
    var lightMode:    Bool = false

    // Legacy convenience — callers that pass a single optional image still work.
    init(post: FeedPost, foodImage: UIImage?, authorAvatar: UIImage?) {
        self.post         = post
        self.foodImages   = [foodImage].compactMap { $0 }
        self.authorAvatar = authorAvatar
    }

    init(post: FeedPost, foodImages: [UIImage], authorAvatar: UIImage?, lightMode: Bool = false) {
        self.post         = post
        self.foodImages   = foodImages
        self.authorAvatar = authorAvatar
        self.lightMode    = lightMode
    }

    // Palette — adapts to light/dark
    private var pageBg: Color { lightMode ? Color(red: 0.96, green: 0.96, blue: 0.97) : Color(red: 0.05, green: 0.05, blue: 0.07) }
    private var cardBg: Color { lightMode ? Color.white : Color(red: 0.11, green: 0.11, blue: 0.14) }
    private var textPrimary: Color { lightMode ? .black : .white }
    private var textSecondary: Color { lightMode ? .black.opacity(0.55) : .white.opacity(0.65) }
    private var textTertiary: Color { lightMode ? .black.opacity(0.35) : .white.opacity(0.40) }
    private var borderColor: Color { lightMode ? .black.opacity(0.08) : .white.opacity(0.08) }
    private var cardBorder: Color { lightMode ? .black.opacity(0.06) : accent.opacity(0.15) }
    private var dividerColor: Color { lightMode ? .black.opacity(0.08) : .white.opacity(0.06) }
    private var accent: Color { post.themeColor }

    // Macro palette
    private let calClr  = Color(red: 1.00, green: 0.55, blue: 0.15)
    private let proClr  = Color(red: 0.35, green: 0.75, blue: 1.00)
    private let carbClr = Color(red: 0.40, green: 0.90, blue: 0.72)
    private let fatClr  = Color(red: 1.00, green: 0.50, blue: 0.72)

    // MARK: - Body

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // ── Top bar: label chip (left) + author (right) ──
                HStack(alignment: .top) {
                    labelChip
                    Spacer()
                    authorHeader
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)

                // ── Title + message ──
                VStack(alignment: .leading, spacing: 4) {
                    if !post.title.isEmpty {
                        Text(post.title)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(textPrimary)
                            .lineLimit(2)
                    }
                    if !post.caption.isEmpty {
                        Text(post.caption)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(textSecondary)
                            .lineLimit(3)
                    }
                }
                .padding(.top, 10)
                .padding(.horizontal, 20)

                // ── Photos (up to 2) ──
                if !foodImages.isEmpty {
                    photoStrip
                        .padding(.top, 10)
                        .padding(.horizontal, 20)
                }

                // ── Label-specific visual ──
                Group {
                    if !post.fuelLogItems.isEmpty {
                        fuelLogVisual
                    } else if !post.workoutItems.isEmpty {
                        workoutVisual
                    } else if post.goalWeight > 0, post.currentWeight > 0 {
                        VStack(spacing: 6) {
                            WeighInProgressCard(
                                previousWeight: post.previousWeight > 0 ? post.previousWeight : post.currentWeight,
                                currentWeight:  post.currentWeight,
                                goalWeight:     post.goalWeight
                            )
                            if post.goalCalories > 0 {
                                goalVisual
                            }
                        }
                    } else if post.goalCalories > 0 {
                        goalVisual
                    }
                }
                .padding(.top, 10)
                .padding(.horizontal, 20)

                Spacer(minLength: 10)

                // ── Footer branding ──
                footer
                    .padding(.bottom, 20)
            }
        }
        .frame(width: 360, height: 640)
        .preferredColorScheme(.dark)
    }

    // MARK: - Photo strip

    private var photoStrip: some View {
        Group {
            if foodImages.count == 1 {
                Image(uiImage: foodImages[0])
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 180)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1))
            } else {
                HStack(spacing: 6) {
                    ForEach(Array(foodImages.prefix(2).enumerated()), id: \.offset) { _, img in
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 140)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1))
                    }
                }
            }
        }
    }

    // MARK: - Author header

    private var authorHeader: some View {
        HStack(spacing: 8) {
            VStack(alignment: .trailing, spacing: 1) {
                Text(post.whoName.isEmpty ? post.username : post.whoName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(textPrimary)
                    .lineLimit(1)
                Text("@\(post.username)")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(textTertiary)
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
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(textPrimary)
                    }
                }
            }
            .frame(width: 30, height: 30)
            .clipShape(Circle())
            .overlay(Circle().stroke(borderColor, lineWidth: 1))
        }
    }

    // MARK: - Label chip

    @ViewBuilder
    private var labelChip: some View {
        if let label = PostLabel(rawValue: post.postLabel) {
            HStack(spacing: 4) {
                Image(systemName: label.icon)
                    .font(.system(size: 9, weight: .bold))
                Text(label.rawValue)
                    .font(.system(size: 10, weight: .black, design: .rounded))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(label.color, in: Capsule())
        }
    }

    // MARK: - Fuel log visual

    private var fuelLogVisual: some View {
        let sorted = post.fuelLogItems.sorted { $0.sortOrder < $1.sortOrder }
        let totalCal  = sorted.reduce(0.0) { $0 + $1.calories }
        let totalPro  = sorted.reduce(0.0) { $0 + $1.protein }
        let totalCarb = sorted.reduce(0.0) { $0 + $1.carbs }
        let totalFat  = sorted.reduce(0.0) { $0 + $1.fat }

        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("Meal").font(.system(size: 9, weight: .semibold)).foregroundStyle(textTertiary)
                Spacer()
                Text("Cal").font(.system(size: 9, weight: .semibold)).foregroundStyle(calClr.opacity(0.55)).frame(width: 38, alignment: .trailing)
                Text("P").font(.system(size: 9, weight: .semibold)).foregroundStyle(proClr.opacity(0.55)).frame(width: 28, alignment: .trailing)
                Text("C").font(.system(size: 9, weight: .semibold)).foregroundStyle(carbClr.opacity(0.55)).frame(width: 28, alignment: .trailing)
                Text("F").font(.system(size: 9, weight: .semibold)).foregroundStyle(fatClr.opacity(0.55)).frame(width: 28, alignment: .trailing)
            }
            Rectangle().fill(dividerColor).frame(height: 1)

            ForEach(Array(sorted.prefix(6).enumerated()), id: \.offset) { _, item in
                HStack {
                    Text(item.foodName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(textPrimary)
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
                    .foregroundStyle(textTertiary.opacity(0.75))
            }

            Rectangle().fill(dividerColor).frame(height: 1)
            HStack {
                Text("Total")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(textSecondary)
                Spacer()
                Text("\(Int(totalCal))").font(.system(size: 10, weight: .black, design: .rounded)).foregroundStyle(calClr).frame(width: 38, alignment: .trailing)
                Text("\(Int(totalPro))g").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(proClr).frame(width: 28, alignment: .trailing)
                Text("\(Int(totalCarb))g").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(carbClr).frame(width: 28, alignment: .trailing)
                Text("\(Int(totalFat))g").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(fatClr).frame(width: 28, alignment: .trailing)
            }
        }
        .padding(12)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(cardBorder, lineWidth: 1))
    }

    // MARK: - Workout visual

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
                            .foregroundStyle(textPrimary)
                            .lineLimit(1)
                        Spacer()
                        if item.durationMinutes > 0 {
                            Text(item.formattedDuration)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(textTertiary)
                        }
                        if item.caloriesBurned > 0 {
                            Text("\(item.caloriesBurned) cal")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(calClr)
                        }
                    }
                    if !item.exercises.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(item.exercises.prefix(4).enumerated()), id: \.offset) { _, ex in
                                HStack(spacing: 4) {
                                    Text("·").font(.system(size: 10, weight: .bold)).foregroundStyle(textTertiary.opacity(0.65))
                                    Text(ex.name).font(.system(size: 10, weight: .medium)).foregroundStyle(textSecondary).lineLimit(1)
                                    Spacer()
                                    Text("\(ex.sets.count) sets").font(.system(size: 9, weight: .semibold)).foregroundStyle(textTertiary.opacity(0.75))
                                }
                            }
                            if item.exercises.count > 4 {
                                Text("+ \(item.exercises.count - 4) more")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(textTertiary.opacity(0.65))
                            }
                        }
                        .padding(.leading, 22)
                    }
                }
            }
            if sorted.count > 4 {
                Text("+ \(sorted.count - 4) more workouts")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(textTertiary.opacity(0.75))
            }

            Rectangle().fill(dividerColor).frame(height: 1)
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
        .padding(12)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(cardBorder, lineWidth: 1))
    }

    // MARK: - Goal visual

    /// Static version of MacroDisciplineCard for ImageRenderer (no animation).
    private var goalVisual: some View {
        let neon = Color(red: 0.35, green: 1.00, blue: 0.60)
        let pairs = [(Double(post.calories), Double(post.goalCalories > 0 ? post.goalCalories : 2000)),
                     (post.protein, post.goalProtein > 0 ? post.goalProtein : 150),
                     (post.carbs, post.goalCarbs > 0 ? post.goalCarbs : 200),
                     (post.fat, post.goalFat > 0 ? post.goalFat : 65)]
        let activePairs = pairs.filter { $0.1 > 0 }
        let disciplineProgress = activePairs.isEmpty ? 0.0 :
            activePairs.reduce(0.0) { $0 + max(0, 1.0 - abs($1.0 / $1.1 - 1.0)) } / Double(activePairs.count)
        let pct = Int((disciplineProgress * 100 / 5).rounded()) * 5

        let macros: [(String, Double, Double, String, Color)] = [
            ("Calories", Double(post.calories), Double(post.goalCalories > 0 ? post.goalCalories : 2000), "kcal", calClr),
            ("Protein",  post.protein,  post.goalProtein > 0  ? post.goalProtein  : 150, "g", proClr),
            ("Carbs",    post.carbs,    post.goalCarbs   > 0  ? post.goalCarbs    : 200, "g", carbClr),
            ("Fat",      post.fat,      post.goalFat     > 0  ? post.goalFat      : 65,  "g", fatClr),
        ]

        return VStack(spacing: 10) {
            // Discipline bar
            HStack(spacing: 0) {
                Text("DISCIPLINE")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1.5)
                    .foregroundStyle(textTertiary)
                Spacer()
                HStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(dividerColor).frame(height: 5)
                            Capsule()
                                .fill(LinearGradient(
                                    colors: disciplineProgress >= 1.0
                                        ? [neon, Color(red: 0.20, green: 0.85, blue: 0.50)]
                                        : [accent, proClr],
                                    startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(4, geo.size.width * disciplineProgress), height: 5)
                        }
                    }
                    .frame(width: 80, height: 5)
                    Text("\(pct)%")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(disciplineProgress >= 1.0 ? neon : accent)
                        .fixedSize()
                        .frame(minWidth: 38, alignment: .trailing)
                }
            }
            Rectangle().fill(dividerColor).frame(height: 1)
            // Per-macro target zone rows (static, shown = true)
            ForEach(Array(macros.enumerated()), id: \.offset) { _, macro in
                let (label, total, goal, unit, color) = macro
                TargetZoneRow(label: label, total: total, goal: goal, unit: unit, color: color, shown: true)
            }
        }
        .padding(12)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(cardBorder, lineWidth: 1))
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 3) {
            Text("MACRO MAXXING")
                .font(.system(size: 11, weight: .black))
                .tracking(3.0)
                .foregroundStyle(textPrimary.opacity(0.85))
            Text("macromaxxing.app")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
