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
                authorHeader
                    .padding(.top, 32)
                    .padding(.horizontal, 22)

                Spacer(minLength: 14)

                photoPanel
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
        HStack(spacing: 10) {
            Group {
                if let img = authorAvatar {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Circle().fill(accent.opacity(0.25))
                        Text(String((post.whoName.isEmpty ? post.username : post.whoName).prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.20), lineWidth: 1))

            VStack(alignment: .leading, spacing: 1) {
                Text(post.whoName.isEmpty ? post.username : post.whoName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("@\(post.username)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
            }
            Spacer()
            if post.auraPoints > 0 {
                Text("Lv \(post.auraLevel)")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(accent, in: Capsule())
            }
        }
    }

    // MARK: Photo panel

    @ViewBuilder
    private var photoPanel: some View {
        if let img = foodImage {
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
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(card)
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .overlay(
                    Image(systemName: postGlyph)
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(accent.opacity(0.70))
                )
        }
    }

    private var postGlyph: String {
        if !post.workoutItems.isEmpty { return "dumbbell.fill" }
        if !post.fuelLogItems.isEmpty { return "fork.knife" }
        return "flame.fill"
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
