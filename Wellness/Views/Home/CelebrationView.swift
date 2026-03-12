//
//  CelebrationView.swift
//  Wellness
//

import SwiftUI
import SwiftData

// MARK: - GymMeme (internal so ShareCardView can also use it)

struct GymMeme {
    let imageName: String   // asset catalog image
    let emoji:     String   // shown in social posts
    let headline:  String
    let sub:       String

    static func random() -> GymMeme { all.randomElement()! }

    static let all: [GymMeme] = [
        GymMeme(imageName: "meme_looksmaxx",  emoji: "🗿",  headline: "LOOKSMAXX MODE\nACTIVATED",    sub: "your gains are immaculate fr"),
        GymMeme(imageName: "meme_gigachad",   emoji: "💪",  headline: "GIGACHAD ENERGY\nUNLOCKED",    sub: "NPC energy has officially left the chat"),
        GymMeme(imageName: "meme_sigma",      emoji: "⚡",  headline: "SIGMA GRINDSET\nCOMPLETE",      sub: "the mewing is literally paying off rn"),
        GymMeme(imageName: "meme_roman",      emoji: "🏛️", headline: "ROMAN EMPEROR\nPHYSIQUE",      sub: "built different. always have been."),
        GymMeme(imageName: "meme_finalform",  emoji: "🔱",  headline: "ALL MACROS?\nEZ CLAP.",         sub: "you are simply not the same as them"),
        GymMeme(imageName: "meme_goat",       emoji: "🐐",  headline: "GOAT STATUS\nCONFIRMED",       sub: "your jawline could cut through steel rn"),
        GymMeme(imageName: "meme_bro",        emoji: "💀",  headline: "BRO ATE\n(LITERALLY)",         sub: "no cap this is your villain arc and you're winning"),
        GymMeme(imageName: "meme_optimal",    emoji: "🧬",  headline: "OPTIMAL SPECIMEN\nUNLOCKED",   sub: "peak performance protocol: complete"),
        GymMeme(imageName: "meme_king",       emoji: "👑",  headline: "MACRO KING\nHAS LOGGED",       sub: "the iron never lies. neither do your macros."),
        GymMeme(imageName: "meme_silverback", emoji: "🦍",  headline: "SILVERBACK\nNUTRITION",        sub: "respect. every gram accounted for."),
    ]
}

// MARK: - CelebrationView

/// All macro data needed to create a social post from the celebration screen.
struct CelebrationPostData {
    let totalCalories: Double; let goalCalories: Double
    let totalProtein:  Double; let goalProtein:  Double
    let totalCarbs:    Double; let goalCarbs:    Double
    let totalFat:      Double; let goalFat:      Double
    let date: Date
}

struct CelebrationView: View {
    let macroGoalsMet: [Bool]
    let userName:      String
    let userSettings:  UserSettings
    let postData:      CelebrationPostData
    let onDismiss:     () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var cardScale:     CGFloat = 0.2
    @State private var cardOpacity:   Double  = 0
    @State private var bgOpacity:     Double  = 0
    @State private var showingShare   = false
    @State private var postedToFeed   = false
    @State private var renderedImage: UIImage?

    private let meme = GymMeme.random()

    var body: some View {
        ZStack {
            // Dimmed backdrop (tap outside card does nothing — use X button)
            Color.black.opacity(bgOpacity * 0.72)
                .ignoresSafeArea()

            // Confetti
            ConfettiView()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Card
            VStack(spacing: 12) {
                // Meme image
                Image(meme.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(14)
                    .shadow(color: Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.4), radius: 12)

                Text(meme.sub)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.60))
                    .multilineTextAlignment(.center)

                // Macro met indicators
                macroRow
                    .padding(.top, 4)

                // Buttons row
                VStack(spacing: 10) {
                    // Post to Feed
                    Button {
                        postToFeed()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: postedToFeed ? "checkmark.circle.fill" : "person.2.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text(postedToFeed ? "Posted!" : "Post to Feed")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(postedToFeed
                            ? Color.green.opacity(0.30)
                            : Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.35))
                        .cornerRadius(14)
                    }
                    .disabled(postedToFeed)

                    // Share image
                    Button {
                        showingShare = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Share")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.10))
                        .cornerRadius(14)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.18, green: 0.08, blue: 0.36),
                                     Color(red: 0.08, green: 0.04, blue: 0.16)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.50), radius: 40)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.55), lineWidth: 1.5)
            )
            // X dismiss button
            .overlay(alignment: .topTrailing) {
                Button(action: animatedDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(14)
                }
            }
            .padding(.horizontal, 24)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.18)) { bgOpacity = 1 }
            withAnimation(.spring(duration: 0.55, bounce: 0.45).delay(0.06)) {
                cardScale   = 1.0
                cardOpacity = 1.0
            }
            Task { await renderShareCard() }
        }
        .sheet(isPresented: $showingShare) {
            if let img = renderedImage {
                CelebrationShareOptionsSheet(image: img)
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Macro row

    private var macroRow: some View {
        let items: [(String, Color)] = [
            ("Cal",  Color(red: 1.00, green: 0.55, blue: 0.15)),
            ("Pro",  Color(red: 0.35, green: 0.75, blue: 1.00)),
            ("Carb", Color(red: 0.40, green: 0.90, blue: 0.72)),
            ("Fat",  Color(red: 1.00, green: 0.50, blue: 0.72)),
        ]
        return HStack(spacing: 14) {
            ForEach(items.indices, id: \.self) { i in
                let met = i < macroGoalsMet.count ? macroGoalsMet[i] : false
                VStack(spacing: 4) {
                    Circle()
                        .fill(met ? items[i].1 : items[i].1.opacity(0.18))
                        .frame(width: 32, height: 32)
                        .overlay {
                            if met {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .shadow(color: met ? items[i].1.opacity(0.6) : .clear, radius: 6)
                    Text(items[i].0)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
        }
    }

    // MARK: - Render & dismiss

    @MainActor
    private func renderShareCard() async {
        let card = CelebrationShareCard(
            meme: meme,
            macroGoalsMet: macroGoalsMet,
            userName: userName
        )
        let renderer   = ImageRenderer(content: card)
        renderer.scale = 3.0
        renderedImage  = renderer.uiImage
    }

    private func postToFeed() {
        guard !postedToFeed else { return }
        let post = SocialPost(
            authorID:          userSettings.userID,
            authorUsername:    userSettings.username.isEmpty ? "me" : userSettings.username,
            authorDisplayName: userSettings.name,
            memeEmoji:         meme.emoji,
            memeHeadline:      meme.headline,
            memeSub:           meme.sub,
            macroDate:         postData.date,
            totalCalories:     postData.totalCalories, goalCalories: postData.goalCalories,
            totalProtein:      postData.totalProtein,  goalProtein:  postData.goalProtein,
            totalCarbs:        postData.totalCarbs,    goalCarbs:    postData.goalCarbs,
            totalFat:          postData.totalFat,      goalFat:      postData.goalFat
        )
        post.authorAuraLevel = userSettings.auraLevel
        post.authorAuraPoints = userSettings.auraPoints
        modelContext.insert(post)
        withAnimation { postedToFeed = true }
        userSettings.awardAura(
            points: 75,
            reason: "📸 Macro Goal Post",
            message: "posting your W to the feed — aura farming is real, no cap."
        )
    }

    private func animatedDismiss() {
        withAnimation(.easeIn(duration: 0.18)) {
            cardScale   = 0.85
            cardOpacity = 0
            bgOpacity   = 0
        }
        Task {
            try? await Task.sleep(for: .seconds(0.2))
            onDismiss()
        }
    }
}

// MARK: - Share options sheet

private struct CelebrationShareOptionsSheet: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var showingActivitySheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.05, blue: 0.12).ignoresSafeArea()

                VStack(spacing: 12) {
                    shareButton(
                        title: "Instagram Stories",
                        subtitle: "Share directly to your story",
                        icon: "camera.fill",
                        colors: [Color(red: 0.88, green: 0.19, blue: 0.42),
                                 Color(red: 0.98, green: 0.35, blue: 0.00)]
                    ) { shareToInstagram() }

                    shareButton(
                        title: "Share / Save / More",
                        subtitle: "Messages, AirDrop, save to Photos…",
                        icon: "square.and.arrow.up",
                        colors: [Color(red: 0.65, green: 0.45, blue: 1.00),
                                 Color(red: 0.40, green: 0.20, blue: 0.85)]
                    ) { showingActivitySheet = true }
                }
                .padding(.horizontal, 20)
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingActivitySheet) {
            ActivitySheet(items: [image])
        }
    }

    private func shareButton(title: String, subtitle: String,
                             icon: String, colors: [Color],
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: colors,
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.45))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.30))
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color(red: 0.13, green: 0.10, blue: 0.22))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    private func shareToInstagram() {
        guard let data = image.pngData(),
              let url  = URL(string: "instagram-stories://share?source_application=com.sbailey.Wellness")
        else { showingActivitySheet = true; return }

        let items: [String: Any] = [
            "com.instagram.sharedSticker.backgroundImage": data,
            "com.instagram.sharedSticker.backgroundTopColor":    "#080215",
            "com.instagram.sharedSticker.backgroundBottomColor": "#030108"
        ]
        UIPasteboard.general.setItems(
            [items],
            options: [.expirationDate: Date(timeIntervalSinceNow: 300)]
        )
        UIApplication.shared.open(url) { success in
            if !success { showingActivitySheet = true }
        }
    }
}

// MARK: - Celebration share card (1080 × 1920 @ 3×)

private struct CelebrationShareCard: View {
    let meme:          GymMeme
    let macroGoalsMet: [Bool]
    let userName:      String

    private let purpl = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold  = Color(red: 1.00, green: 0.80, blue: 0.20)

    private let macroItems: [(String, Color)] = [
        ("Calories", Color(red: 1.00, green: 0.55, blue: 0.15)),
        ("Protein",  Color(red: 0.35, green: 0.75, blue: 1.00)),
        ("Carbs",    Color(red: 0.40, green: 0.90, blue: 0.72)),
        ("Fat",      Color(red: 1.00, green: 0.50, blue: 0.72)),
    ]

    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(RadialGradient(
                    colors: [Color(red: 0.18, green: 0.08, blue: 0.32),
                             Color(red: 0.04, green: 0.02, blue: 0.10)],
                    center: .init(x: 0.5, y: 0.35),
                    startRadius: 0, endRadius: 380
                ))

            // Sparkle dots
            ForEach(0..<8, id: \.self) { i in
                let pos: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                    (0.08,0.08,0.55,4),(0.88,0.12,0.40,3),(0.18,0.88,0.50,5),
                    (0.92,0.78,0.35,4),(0.50,0.04,0.65,3),(0.12,0.52,0.40,2),
                    (0.78,0.42,0.50,4),(0.40,0.94,0.40,3)
                ]
                Circle().fill(gold.opacity(pos[i].2))
                    .frame(width: pos[i].3, height: pos[i].3)
                    .position(x: pos[i].0 * 360, y: pos[i].1 * 640)
                    .blur(radius: 1)
            }

            VStack(spacing: 0) {
                // App branding
                HStack(spacing: 7) {
                    ZStack {
                        Circle().stroke(purpl, lineWidth: 2).frame(width: 26, height: 26)
                        Image(systemName: "fork.knife")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(purpl)
                    }
                    Text("Macro Maxxing")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.top, 44)

                Spacer()

                // Meme image
                VStack(spacing: 12) {
                    Image(meme.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 280)
                        .cornerRadius(14)
                        .shadow(color: gold.opacity(0.4), radius: 12)
                    Text(meme.sub)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.60))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Macro circles
                HStack(spacing: 20) {
                    ForEach(macroItems.indices, id: \.self) { i in
                        let met = i < macroGoalsMet.count ? macroGoalsMet[i] : false
                        VStack(spacing: 6) {
                            Circle()
                                .fill(met ? macroItems[i].1 : macroItems[i].1.opacity(0.15))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    if met {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .shadow(color: met ? macroItems[i].1.opacity(0.6) : .clear, radius: 8)
                            Text(macroItems[i].0)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                }
                .padding(.bottom, 8)

                Text("all macros crushed 🔥")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(gold.opacity(0.80))

                Spacer()

                // Footer
                HStack {
                    Text("macro maxxing")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(purpl.opacity(0.65))
                    Spacer()
                    Text("log the mog.")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.22))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 32)
            }
        }
        .frame(width: 360, height: 640)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Confetti

private struct ConfettiView: View {
    private struct Piece {
        let xFraction: CGFloat
        let color:     Color
        let size:      CGFloat
        let speed:     Double
        let sway:      Double
        let swayFreq:  Double
        let delay:     Double
    }

    @State private var pieces:    [Piece] = []
    @State private var startTime: Date    = .now

    private static let palette: [Color] = [
        .orange,
        Color(red: 0.65, green: 0.45, blue: 1.00),
        Color(red: 0.35, green: 0.75, blue: 1.00),
        Color(red: 0.40, green: 0.90, blue: 0.72),
        Color(red: 1.00, green: 0.50, blue: 0.72),
        .yellow, .white,
        Color(red: 1.00, green: 0.75, blue: 0.20),
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let elapsed = timeline.date.timeIntervalSince(startTime)
                for p in pieces {
                    let t     = max(0, elapsed - p.delay)
                    let yFrac = t * p.speed
                    guard yFrac < 1.4 else { continue }
                    let x      = p.xFraction * size.width + sin(t * p.swayFreq * .pi) * p.sway
                    let y      = yFrac * size.height
                    let fadeIn = min(1.0, t / 0.2)
                    let fadeOut = yFrac > 0.75 ? max(0, 1 - (yFrac - 0.75) / 0.6) : 1.0
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x - p.size/2, y: y - p.size/2,
                                               width: p.size, height: p.size)),
                        with: .color(p.color.opacity(fadeIn * fadeOut * 0.88))
                    )
                }
            }
        }
        .onAppear {
            startTime = .now
            pieces = (0..<50).map { i in
                Piece(
                    xFraction: CGFloat.random(in: 0...1),
                    color:     Self.palette[i % Self.palette.count],
                    size:      CGFloat.random(in: 5...13),
                    speed:     Double.random(in: 0.22...0.50),
                    sway:      Double.random(in: 12...45),
                    swayFreq:  Double.random(in: 1.2...3.5),
                    delay:     Double.random(in: 0...1.8)
                )
            }
        }
    }
}
