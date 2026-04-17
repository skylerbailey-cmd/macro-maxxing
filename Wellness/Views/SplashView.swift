//
//  SplashView.swift
//  Wellness
//
//  Lightning-strike loading screen. A single bolt cracks down the screen
//  with realistic forked geometry, flickering intensity, and a bright
//  flash at 100% before the app loads.
//

import SwiftUI

// MARK: - SplashView

struct SplashView: View {
    let onComplete: () -> Void

    @State private var progress: Double = 0
    @State private var flash:    Double = 0
    @State private var done:     Bool   = false

    private var accent: Color { ThemeStore.shared.accent }

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.03, green: 0.03, blue: 0.05)
                .ignoresSafeArea()

            // Full-screen white flash at 100%
            Color.white.opacity(flash)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if !done {
                // Lightning canvas — redraws every frame for flicker
                TimelineView(.animation) { timeline in
                    Canvas { ctx, size in
                        var c = ctx
                        let t = timeline.date.timeIntervalSince1970
                        drawLightning(ctx: &c, size: size, progress: progress, time: t)
                    }
                }
                .ignoresSafeArea()

                // Percentage at very bottom
                VStack {
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.80))
                        .padding(.bottom, 50)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { await runLoading() }
    }

    // MARK: - Loading sequence

    private func runLoading() async {
        try? await Task.sleep(for: .seconds(0.1))

        // Animate progress 0 → 1 over ~2s
        let steps = 100
        let dur   = 2.0
        for i in 1...steps {
            try? await Task.sleep(nanoseconds: UInt64(dur / Double(steps) * 1_000_000_000))
            let t = Double(i) / Double(steps)
            progress = 1 - pow(1 - t, 3)
        }
        progress = 1.0
        try? await Task.sleep(for: .seconds(0.15))

        // Flash → fade
        withAnimation(.easeIn(duration: 0.08)) { flash = 0.85 }
        try? await Task.sleep(for: .seconds(0.12))
        withAnimation(.easeOut(duration: 0.5))  { flash = 0 }
        try? await Task.sleep(for: .seconds(0.3))

        done = true
        onComplete()
    }

    // MARK: - Draw lightning

    private func drawLightning(ctx: inout GraphicsContext, size: CGSize, progress: Double, time: Double) {
        // Seed changes ~10x/sec so the bolt flickers
        let seed = UInt64(time * 10)
        var rng  = LightningRNG(seed: seed)

        let startY:  CGFloat = 0
        let fullEndY: CGFloat = size.height * 0.88
        let currentEndY = startY + (fullEndY - startY) * CGFloat(progress)

        // Generate the main bolt
        let mainBolt = generateBolt(
            from: CGPoint(x: size.width * 0.48 + CGFloat(rng.next(-8, 8)), y: startY),
            to:   CGPoint(x: size.width * 0.50, y: currentEndY),
            segments: 28,
            jitter: size.width * 0.12,
            rng: &rng
        )

        // Generate 3–5 branches off the main bolt
        var branches: [Path] = []
        let branchCount = Int(rng.next(3, 6))
        for _ in 0..<branchCount {
            let ptIdx = Int(rng.next(4, Double(max(5, mainBolt.count - 3))))
            guard ptIdx < mainBolt.count else { continue }
            let origin = mainBolt[ptIdx]
            let side: CGFloat = rng.nextBool() ? 1 : -1
            let endX = origin.x + side * CGFloat(rng.next(40, 120))
            let endY = origin.y + CGFloat(rng.next(30, 80))
            let bPts = generateBolt(
                from: origin,
                to: CGPoint(x: endX, y: min(endY, currentEndY)),
                segments: Int(rng.next(5, 10)),
                jitter: size.width * 0.04,
                rng: &rng
            )
            branches.append(pathFrom(bPts))
        }

        let mainPath = pathFrom(mainBolt)

        // Flicker intensity — pulses between 0.7 and 1.0
        let flicker = 0.85 + 0.15 * sin(time * 30)

        // --- Draw layers ---
        // Reduced blur radii for a sharper, more defined bolt.

        // 1. Outermost glow (subtle ambient)
        ctx.addFilter(.blur(radius: 10))
        ctx.stroke(mainPath, with: .color(accent.opacity(0.45 * flicker)),
                   style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
        ctx.addFilter(.blur(radius: 0))

        // 2. Mid glow (tight halo)
        ctx.addFilter(.blur(radius: 4))
        ctx.stroke(mainPath, with: .color(accent.opacity(0.75 * flicker)),
                   style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
        ctx.addFilter(.blur(radius: 0))

        // 3. Solid accent body (no blur)
        ctx.stroke(mainPath, with: .color(accent.opacity(flicker)),
                   style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))

        // 4. White-hot core (no blur)
        ctx.stroke(mainPath, with: .color(.white.opacity(0.95 * flicker)),
                   style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

        // --- Branches ---
        for bPath in branches {
            ctx.addFilter(.blur(radius: 3))
            ctx.stroke(bPath, with: .color(accent.opacity(0.40 * flicker)),
                       style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            ctx.addFilter(.blur(radius: 0))

            ctx.stroke(bPath, with: .color(accent.opacity(0.75 * flicker)),
                       style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

            ctx.stroke(bPath, with: .color(.white.opacity(0.80 * flicker)),
                       style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
        }
    }

    // MARK: - Bolt geometry

    /// Generates a jagged bolt path between two points. Each segment has
    /// random horizontal displacement that creates the forked look of
    /// real lightning. Displacement is strongest in the middle and tapers
    /// at the endpoints so the bolt starts and ends cleanly.
    private func generateBolt(
        from start: CGPoint, to end: CGPoint,
        segments: Int, jitter: CGFloat,
        rng: inout LightningRNG
    ) -> [CGPoint] {
        var points: [CGPoint] = [start]
        for i in 1..<segments {
            let frac = CGFloat(i) / CGFloat(segments)
            // Base position along the line
            let baseX = start.x + (end.x - start.x) * frac
            let baseY = start.y + (end.y - start.y) * frac
            // Displacement envelope — strongest in the middle, tapers at ends
            let envelope = sin(frac * .pi)
            let offsetX = CGFloat(rng.next(-1, 1)) * jitter * envelope
            let offsetY = CGFloat(rng.next(-0.2, 0.2)) * jitter * 0.3
            points.append(CGPoint(x: baseX + offsetX, y: baseY + offsetY))
        }
        points.append(end)
        return points
    }

    private func pathFrom(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for pt in points.dropFirst() {
            path.addLine(to: pt)
        }
        return path
    }
}

// MARK: - Fast RNG for lightning generation

private struct LightningRNG {
    var state: UInt64

    init(seed: UInt64) { state = seed == 0 ? 1 : seed }

    mutating func nextRaw() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }

    /// Random Double in [lo, hi)
    mutating func next(_ lo: Double, _ hi: Double) -> Double {
        let d = Double(nextRaw() >> 11) / Double(1 << 53)
        return lo + d * (hi - lo)
    }

    mutating func nextBool() -> Bool { nextRaw() & 1 == 0 }
}

// MARK: - Logo (kept for other screens)

struct WellnessLogoView: View {
    let size: CGFloat
    var progress: Double = 1.0

    private var ringR: CGFloat { size * 0.36 }
    private var lw:    CGFloat { size * 0.058 }
    private var dotR:  CGFloat { size * 0.048 }

    private let macroDots: [(angle: Double, color: Color)] = [
        ( .pi / 2,  Color(red: 1.0, green: 0.55, blue: 0.15)),
        ( 0,        Color(red: 0.35, green: 0.75, blue: 1.00)),
        (-.pi / 2,  Color(red: 0.40, green: 0.90, blue: 0.72)),
        ( .pi,      Color(red: 1.00, green: 0.50, blue: 0.72)),
    ]

    var body: some View {
        ZStack {
            Circle()
                .stroke(ThemeStore.shared.accent.opacity(0.15), lineWidth: lw)
                .frame(width: ringR * 2, height: ringR * 2)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(ThemeStore.shared.accent,
                        style: StrokeStyle(lineWidth: lw, lineCap: .round))
                .frame(width: ringR * 2, height: ringR * 2)
                .rotationEffect(.degrees(-90))
                .shadow(color: ThemeStore.shared.accent.opacity(0.25), radius: size * 0.02)
            Circle()
                .stroke(ThemeStore.shared.accent.opacity(0.07), lineWidth: lw * 0.35)
                .frame(width: ringR * 1.24, height: ringR * 1.24)
            ForEach(macroDots.indices, id: \.self) { i in
                let d = macroDots[i]
                Circle()
                    .fill(d.color)
                    .frame(width: dotR * 2, height: dotR * 2)
                    .shadow(color: d.color.opacity(0.35), radius: size * 0.015)
                    .offset(
                        x:  ringR * CGFloat(cos(d.angle)),
                        y: -ringR * CGFloat(sin(d.angle))
                    )
            }
            ForkShape()
                .fill(Color.white.opacity(0.90))
                .frame(width: size * 0.22, height: size * 0.28)
                .shadow(color: ThemeStore.shared.accent.opacity(0.20), radius: size * 0.01)
        }
        .frame(width: size, height: size)
    }
}

private struct ForkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX, cy = rect.midY
        let w = rect.width, h = rect.height
        let pw = w * 0.145, gap = w * 0.115
        let prongH = h * 0.54, handleH = h * 0.46
        let cr = pw * 0.5, top = cy - h * 0.5, mid = top + prongH
        var path = Path()
        for xOff: CGFloat in [-(pw + gap), 0, (pw + gap)] {
            path.addRoundedRect(in: CGRect(x: cx + xOff - pw * 0.5, y: top, width: pw, height: prongH),
                                cornerSize: CGSize(width: cr, height: cr))
        }
        path.addRoundedRect(in: CGRect(x: cx - pw * 0.5, y: mid, width: pw, height: handleH),
                            cornerSize: CGSize(width: cr, height: cr))
        return path
    }
}

#Preview {
    SplashView(onComplete: {})
}
