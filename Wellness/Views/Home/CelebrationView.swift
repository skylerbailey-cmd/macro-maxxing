//
//  CelebrationView.swift
//  Wellness
//

import SwiftUI

// MARK: - CelebrationView

struct CelebrationView: View {
    let onDismiss: () -> Void

    @State private var cardScale:   CGFloat = 0.2
    @State private var cardOpacity: Double  = 0
    @State private var bgOpacity:   Double  = 0

    private let meme = Meme.random()

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(bgOpacity * 0.70)
                .ignoresSafeArea()
                .onTapGesture { animatedDismiss() }

            // Confetti
            ConfettiView()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Meme card
            VStack(spacing: 16) {
                Text(meme.emoji)
                    .font(.system(size: 72))

                Text(meme.headline)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                Text(meme.sub)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.60))
                    .multilineTextAlignment(.center)

                // Macro emoji row
                HStack(spacing: 12) {
                    ForEach(["🍗", "🥦", "🥑", "🔥"], id: \.self) { e in
                        Text(e).font(.title2)
                    }
                }
                .padding(.top, 4)

                Text("tap anywhere to dismiss")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.28))
                    .padding(.top, 8)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 36)
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
                    .shadow(color: Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.50),
                            radius: 40)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.55),
                            lineWidth: 1.5)
            )
            .padding(.horizontal, 28)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.18)) { bgOpacity = 1 }
            withAnimation(.spring(duration: 0.55, bounce: 0.45).delay(0.06)) {
                cardScale   = 1.0
                cardOpacity = 1.0
            }
            // Auto-dismiss after 4 s
            Task {
                try? await Task.sleep(for: .seconds(4.0))
                animatedDismiss()
            }
        }
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

// MARK: - Meme data

private struct Meme {
    let emoji:    String
    let headline: String
    let sub:      String

    static func random() -> Meme { all.randomElement()! }

    private static let all: [Meme] = [
        Meme(emoji: "🗿",
             headline: "LOOKSMAXX MODE\nACTIVATED",
             sub: "your gains are immaculate fr"),
        Meme(emoji: "💪",
             headline: "GIGACHAD ENERGY\nUNLOCKED",
             sub: "NPC energy has officially left the chat"),
        Meme(emoji: "⚡",
             headline: "SIGMA GRINDSET\nCOMPLETE",
             sub: "the mewing is literally paying off rn"),
        Meme(emoji: "🏛️",
             headline: "ROMAN EMPEROR\nPHYSIQUE",
             sub: "built different. always have been."),
        Meme(emoji: "🔱",
             headline: "ALL MACROS?\nEZ CLAP.",
             sub: "you are simply not the same as them"),
        Meme(emoji: "🐐",
             headline: "GOAT STATUS\nCONFIRMED",
             sub: "your jawline could cut through steel rn"),
        Meme(emoji: "💀",
             headline: "BRO ATE\n(LITERALLY)",
             sub: "no cap this is your villain arc and you're winning"),
        Meme(emoji: "🧬",
             headline: "OPTIMAL SPECIMEN\nUNLOCKED",
             sub: "peak performance protocol: complete"),
        Meme(emoji: "👑",
             headline: "MACRO KING\nHAS LOGGED",
             sub: "the iron never lies. neither do your macros."),
        Meme(emoji: "🦍",
             headline: "SILVERBACK\nNUTRITION",
             sub: "every gram accounted for. respect."),
    ]
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
                    let t = max(0, elapsed - p.delay)
                    let yFrac = t * p.speed
                    guard yFrac < 1.4 else { continue }
                    let x = p.xFraction * size.width
                               + sin(t * p.swayFreq * .pi) * p.sway
                    let y = yFrac * size.height
                    let fadeIn  = min(1.0, t / 0.2)
                    let fadeOut = yFrac > 0.75 ? max(0, 1 - (yFrac - 0.75) / 0.6) : 1.0
                    let alpha   = fadeIn * fadeOut * 0.88
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x - p.size / 2,
                                               y: y - p.size / 2,
                                               width: p.size, height: p.size)),
                        with: .color(p.color.opacity(alpha))
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
