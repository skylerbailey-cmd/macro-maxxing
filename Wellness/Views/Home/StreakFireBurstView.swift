//
//  StreakFireBurstView.swift
//  Wellness
//
//  Full-screen celebration overlay when the user extends their streak.
//  A ring of fire bursts outward from center, particles fly, and the
//  streak number scales up with a punchy spring. Auto-dismisses after
//  a few seconds or on tap.
//

import SwiftUI

struct StreakFireBurstView: View {
    let streak: Int
    let onDismiss: () -> Void

    // MARK: - Animation state

    @State private var phase: Phase = .idle

    // Ring burst
    @State private var ringScale: CGFloat = 0.15
    @State private var ringOpacity: Double = 0

    // Streak number
    @State private var numberScale: CGFloat = 0.0
    @State private var numberOpacity: Double = 0

    // Subtitle
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = 12

    // Background
    @State private var bgOpacity: Double = 0

    // Glow pulse
    @State private var glowScale: CGFloat = 0.8
    @State private var glowOpacity: Double = 0

    // Particles
    @State private var particles: [FireParticle] = []
    @State private var particleTick: Int = 0

    // Shockwave
    @State private var shockwaveScale: CGFloat = 0.0
    @State private var shockwaveOpacity: Double = 0

    private enum Phase { case idle, burst, hold, exit }

    // MARK: - Colors

    private let fireOrange  = Color(red: 1.00, green: 0.55, blue: 0.08)
    private let fireYellow  = Color(red: 1.00, green: 0.85, blue: 0.15)
    private let fireRed     = Color(red: 1.00, green: 0.25, blue: 0.05)
    private let fireWhite   = Color(red: 1.00, green: 0.97, blue: 0.85)

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(bgOpacity * 0.75)
                .ignoresSafeArea()

            // Radial heat haze
            RadialGradient(
                colors: [fireOrange.opacity(glowOpacity * 0.35), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 280
            )
            .scaleEffect(glowScale)
            .ignoresSafeArea()

            // Shockwave ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [fireYellow.opacity(0.7), fireOrange.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 3
                )
                .frame(width: 300, height: 300)
                .scaleEffect(shockwaveScale)
                .opacity(shockwaveOpacity)

            // Fire ring burst — concentric rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(
                        ringGradient(index: i),
                        lineWidth: CGFloat(18 - i * 5)
                    )
                    .frame(width: CGFloat(160 + i * 50), height: CGFloat(160 + i * 50))
                    .scaleEffect(ringScale * CGFloat(1.0 - Double(i) * 0.08))
                    .opacity(ringOpacity * (1.0 - Double(i) * 0.25))
                    .blur(radius: CGFloat(i) * 3)
            }

            // Particle layer
            TimelineView(.animation) { timeline in
                Canvas { ctx, size in
                    let t = timeline.date.timeIntervalSince1970
                    drawParticles(ctx: ctx, size: size, time: t)
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()

            // Center content
            VStack(spacing: 8) {
                // Fire emoji with glow
                Text("🔥")
                    .font(.system(size: 52))
                    .shadow(color: fireOrange.opacity(0.8), radius: 20)
                    .scaleEffect(numberScale)
                    .opacity(numberOpacity)

                // Streak number — big, bold, gradient
                Text("\(streak)")
                    .font(.system(size: 96, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [fireYellow, fireOrange, fireRed],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: fireOrange.opacity(0.6), radius: 30)
                    .shadow(color: fireRed.opacity(0.3), radius: 60)
                    .scaleEffect(numberScale)
                    .opacity(numberOpacity)

                Text("DAY STREAK")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.80))
                    .scaleEffect(numberScale)
                    .opacity(numberOpacity)

                Text(subtitleText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.50))
                    .opacity(subtitleOpacity)
                    .offset(y: subtitleOffset)
                    .padding(.top, 4)
            }
        }
        .onTapGesture { animateOut() }
        .onAppear { animateIn() }
        .preferredColorScheme(.dark)
    }

    // MARK: - Subtitle

    private var subtitleText: String {
        switch streak {
        case 1:       return "first day locked in"
        case 2:       return "back to back"
        case 3...6:   return "the consistency is showing"
        case 7...13:  return "a full week of discipline"
        case 14...29: return "two weeks of not missing"
        case 30...59: return "a whole month. built different."
        case 60...99: return "60+ days. they can't stop you."
        default:      return "triple digits. legendary."
        }
    }

    // MARK: - Ring gradient

    private func ringGradient(index: Int) -> LinearGradient {
        let colors: [Color] = switch index {
        case 0: [fireYellow, fireOrange]
        case 1: [fireOrange, fireRed]
        default: [fireRed, fireRed.opacity(0.3)]
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    // MARK: - Particles

    private struct FireParticle: Identifiable {
        let id = UUID()
        var x: CGFloat       // 0-1 normalized
        var y: CGFloat       // 0-1 normalized
        let angle: Double    // radians, direction of travel
        let speed: Double
        let size: CGFloat
        let birth: TimeInterval
        let lifetime: Double
        let hue: Int         // 0=yellow, 1=orange, 2=red, 3=white
        let swayAmp: Double
        let swayFreq: Double
    }

    private func drawParticles(ctx: GraphicsContext, size: CGSize, time: TimeInterval) {
        for p in particles {
            let age = time - p.birth
            guard age >= 0, age < p.lifetime else { continue }

            let progress = age / p.lifetime
            let fadeIn  = min(1.0, age / 0.1)
            let fadeOut = max(0.0, 1.0 - pow(progress, 0.6))
            let alpha   = fadeIn * fadeOut

            let dist = age * p.speed * Double(min(size.width, size.height)) * 0.5
            let sway = sin(age * p.swayFreq * .pi * 2) * p.swayAmp

            let cx = size.width / 2
            let cy = size.height / 2
            let px = cx + CGFloat(cos(p.angle) * dist + cos(p.angle + .pi / 2) * sway)
            let py = cy + CGFloat(sin(p.angle) * dist + sin(p.angle + .pi / 2) * sway)

            let s = p.size * CGFloat(max(0.2, 1.0 - progress * 0.7))

            let color: Color = switch p.hue {
            case 0: fireYellow
            case 1: fireOrange
            case 2: fireRed
            default: fireWhite
            }

            // Glow
            let glowS = s * 3
            ctx.fill(
                Path(ellipseIn: CGRect(x: px - glowS/2, y: py - glowS/2, width: glowS, height: glowS)),
                with: .color(color.opacity(alpha * 0.2))
            )
            // Core
            ctx.fill(
                Path(ellipseIn: CGRect(x: px - s/2, y: py - s/2, width: s, height: s)),
                with: .color(color.opacity(alpha * 0.85))
            )
        }
    }

    private func spawnParticles() {
        let now = Date().timeIntervalSince1970
        var newParticles: [FireParticle] = []

        // Burst ring — 60 particles radiating outward
        for _ in 0..<60 {
            let angle = Double.random(in: 0...(2 * .pi))
            newParticles.append(FireParticle(
                x: 0.5, y: 0.5,
                angle: angle,
                speed: Double.random(in: 0.4...1.2),
                size: CGFloat.random(in: 3...10),
                birth: now + Double.random(in: 0...0.15),
                lifetime: Double.random(in: 0.8...2.0),
                hue: Int.random(in: 0...3),
                swayAmp: Double.random(in: 5...20),
                swayFreq: Double.random(in: 1...4)
            ))
        }

        // Upward sparks — 30 more biased upward
        for _ in 0..<30 {
            let angle = Double.random(in: -Double.pi * 0.85 ... -Double.pi * 0.15)
            newParticles.append(FireParticle(
                x: 0.5, y: 0.5,
                angle: angle,
                speed: Double.random(in: 0.3...0.8),
                size: CGFloat.random(in: 2...6),
                birth: now + Double.random(in: 0.05...0.4),
                lifetime: Double.random(in: 1.0...2.5),
                hue: Int.random(in: 0...2),
                swayAmp: Double.random(in: 8...25),
                swayFreq: Double.random(in: 0.8...3)
            ))
        }

        // Delayed secondary burst — 20 more at slight delay
        for _ in 0..<20 {
            let angle = Double.random(in: 0...(2 * .pi))
            newParticles.append(FireParticle(
                x: 0.5, y: 0.5,
                angle: angle,
                speed: Double.random(in: 0.2...0.6),
                size: CGFloat.random(in: 4...12),
                birth: now + Double.random(in: 0.3...0.6),
                lifetime: Double.random(in: 1.2...2.8),
                hue: Int.random(in: 0...1),
                swayAmp: Double.random(in: 10...30),
                swayFreq: Double.random(in: 0.5...2)
            ))
        }

        particles = newParticles
    }

    // MARK: - Animation sequence

    private func animateIn() {
        phase = .burst
        spawnParticles()

        // Background fade
        withAnimation(.easeOut(duration: 0.2)) {
            bgOpacity = 1
        }

        // Shockwave — fast expanding ring
        withAnimation(.easeOut(duration: 0.6)) {
            shockwaveScale = 3.5
            shockwaveOpacity = 0.8
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            shockwaveOpacity = 0
        }

        // Fire rings burst outward
        withAnimation(.spring(duration: 0.7, bounce: 0.3)) {
            ringScale = 1.6
            ringOpacity = 1.0
        }
        // Rings fade
        withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
            ringOpacity = 0
        }

        // Glow pulse
        withAnimation(.easeOut(duration: 0.4).delay(0.05)) {
            glowScale = 2.0
            glowOpacity = 1.0
        }
        withAnimation(.easeInOut(duration: 1.5).delay(0.5)) {
            glowScale = 1.2
            glowOpacity = 0.4
        }

        // Number punches in
        withAnimation(.spring(duration: 0.6, bounce: 0.5).delay(0.1)) {
            numberScale = 1.0
            numberOpacity = 1.0
        }

        // Subtitle slides up
        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            subtitleOpacity = 1.0
            subtitleOffset = 0
        }

        // Auto-dismiss
        phase = .hold
        Task {
            try? await Task.sleep(for: .seconds(3.5))
            if phase == .hold { animateOut() }
        }
    }

    private func animateOut() {
        guard phase != .exit else { return }
        phase = .exit

        withAnimation(.easeIn(duration: 0.25)) {
            numberScale = 0.85
            numberOpacity = 0
            subtitleOpacity = 0
            bgOpacity = 0
            glowOpacity = 0
        }

        Task {
            try? await Task.sleep(for: .seconds(0.3))
            onDismiss()
        }
    }
}
