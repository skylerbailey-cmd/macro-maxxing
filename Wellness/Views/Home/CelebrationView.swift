//
//  CelebrationView.swift
//  Wellness
//

import SwiftUI

// MARK: - GymMeme (internal so ShareCardView can also use it)

struct GymMeme {
    let emoji:    String
    let headline: String
    let sub:      String

    static func random() -> GymMeme { all.randomElement()! }

    static let all: [GymMeme] = [
        GymMeme(emoji: "🗿",  headline: "LOOKSMAXX MODE\nACTIVATED",       sub: "your gains are immaculate fr"),
        GymMeme(emoji: "💪",  headline: "GIGACHAD ENERGY\nUNLOCKED",        sub: "NPC energy has officially left the chat"),
        GymMeme(emoji: "⚡",  headline: "SIGMA GRINDSET\nCOMPLETE",          sub: "the mewing is literally paying off rn"),
        GymMeme(emoji: "🏛️", headline: "ROMAN EMPEROR\nPHYSIQUE",          sub: "built different. always have been."),
        GymMeme(emoji: "🔱",  headline: "ALL MACROS?\nEZ CLAP.",             sub: "you are simply not the same as them"),
        GymMeme(emoji: "🐐",  headline: "GOAT STATUS\nCONFIRMED",           sub: "your jawline could cut through steel rn"),
        GymMeme(emoji: "💀",  headline: "BRO ATE\n(LITERALLY)",             sub: "no cap this is your villain arc and you're winning"),
        GymMeme(emoji: "🧬",  headline: "OPTIMAL SPECIMEN\nUNLOCKED",       sub: "peak performance protocol: complete"),
        GymMeme(emoji: "👑",  headline: "MACRO KING\nHAS LOGGED",           sub: "the iron never lies. neither do your macros."),
        GymMeme(emoji: "🦍",  headline: "SILVERBACK\nNUTRITION",            sub: "respect. every gram accounted for."),
    ]
}

// MARK: - CelebrationView

struct CelebrationView: View {
    let macroGoalsMet: [Bool]
    let userName:      String
    let onDismiss:     () -> Void

    @State private var cardScale:    CGFloat = 0.2
    @State private var cardOpacity:  Double  = 0
    @State private var bgOpacity:    Double  = 0
    @State private var showingShare  = false
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
            VStack(spacing: 16) {
                Text(meme.emoji)
                    .font(.system(size: 70))

                Text(meme.headline)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                Text(meme.sub)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.60))
                    .multilineTextAlignment(.center)

                // Macro met indicators
                macroRow
                    .padding(.top, 4)

                // Share button
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
                    .background(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.35))
                    .cornerRadius(14)
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
            if let img = renderedImage { ActivitySheet(items: [img]) }
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

                // Meme
                VStack(spacing: 12) {
                    Text(meme.emoji)
                        .font(.system(size: 80))

                    Text(meme.headline)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

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
