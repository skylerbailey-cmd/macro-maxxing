//
//  SplashView.swift
//  Wellness
//

import SwiftUI

// MARK: - SplashView

struct SplashView: View {
    let onComplete: () -> Void

    @State private var ringScale:    CGFloat = 0.6
    @State private var ringOpacity:  Double  = 0
    @State private var titleOpacity: Double  = 0
    @State private var loadProgress: Double  = 0

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color(red: 0.10, green: 0.07, blue: 0.18),
                    Color(red: 0.04, green: 0.02, blue: 0.09)
                ],
                center: UnitPoint(x: 0.5, y: 0.45),
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Logo — ring fills with progress
                WellnessLogoView(size: 220, progress: loadProgress)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)

                // Percentage — visible once loading begins
                Text("\(Int(loadProgress * 100))%")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.50))
                    .padding(.top, 14)
                    .opacity(ringOpacity)

                Spacer().frame(height: 28)

                // App name
                VStack(spacing: 6) {
                    Text("Wellness")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Track your journey")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.40))
                }
                .opacity(titleOpacity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                ringScale   = 1.0
                ringOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.25).delay(0.15)) {
                titleOpacity = 1.0
            }
        }
        .task {
            // Brief pause for entrance animation
            try? await Task.sleep(for: .seconds(0.15))

            // Fill the ring 0 → 100% using ease-out cubic
            let steps    = 40
            let duration = 0.4
            let interval = duration / Double(steps)

            for i in 1...steps {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                let t = Double(i) / Double(steps)
                loadProgress = 1 - pow(1 - t, 3)   // ease-out cubic
            }
            loadProgress = 1.0

            // Very brief pause at 100%
            try? await Task.sleep(for: .seconds(0.1))
            onComplete()
        }
    }
}

// MARK: - Logo (ring fills with progress)

struct WellnessLogoView: View {
    let size: CGFloat
    var progress: Double = 1.0   // 0→1; defaults to full ring

    private var ringR: CGFloat { size * 0.36 }
    private var lw:    CGFloat { size * 0.058 }
    private var dotR:  CGFloat { size * 0.048 }

    private let macroDots: [(angle: Double, color: Color)] = [
        ( .pi / 2,  Color(red: 1.0, green: 0.55, blue: 0.15)),  // top    – orange
        ( 0,        Color(red: 0.35, green: 0.75, blue: 1.00)),  // right  – blue
        (-.pi / 2,  Color(red: 0.40, green: 0.90, blue: 0.72)), // bottom – mint
        ( .pi,      Color(red: 1.00, green: 0.50, blue: 0.72)),  // left   – rose
    ]

    var body: some View {
        ZStack {
            // Dim track — always full circle
            Circle()
                .stroke(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.15), lineWidth: lw)
                .frame(width: ringR * 2, height: ringR * 2)

            // Progress arc — fills clockwise from 12 o'clock
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color(red: 0.65, green: 0.45, blue: 1.0),
                    style: StrokeStyle(lineWidth: lw, lineCap: .round)
                )
                .frame(width: ringR * 2, height: ringR * 2)
                .rotationEffect(.degrees(-90))          // start at top
                .shadow(color: Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.65),
                        radius: size * 0.04)

            // Inner accent ring
            Circle()
                .stroke(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.07), lineWidth: lw * 0.35)
                .frame(width: ringR * 1.24, height: ringR * 1.24)

            // 4 macro dots
            ForEach(macroDots.indices, id: \.self) { i in
                let d = macroDots[i]
                Circle()
                    .fill(d.color)
                    .frame(width: dotR * 2, height: dotR * 2)
                    .shadow(color: d.color.opacity(0.9), radius: size * 0.025)
                    .offset(
                        x:  ringR * CGFloat(cos(d.angle)),
                        y: -ringR * CGFloat(sin(d.angle))
                    )
            }

            // Fork
            ForkShape()
                .fill(Color.white.opacity(0.90))
                .frame(width: size * 0.22, height: size * 0.28)
                .shadow(color: Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.5),
                        radius: size * 0.02)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Fork Shape

private struct ForkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let w  = rect.width
        let h  = rect.height

        let pw      = w * 0.145
        let gap     = w * 0.115
        let prongH  = h * 0.54
        let handleH = h * 0.46
        let cr      = pw * 0.5
        let top     = cy - h * 0.5
        let mid     = top + prongH

        var path = Path()
        for xOff: CGFloat in [-(pw + gap), 0, (pw + gap)] {
            let r = CGRect(x: cx + xOff - pw * 0.5, y: top, width: pw, height: prongH)
            path.addRoundedRect(in: r, cornerSize: CGSize(width: cr, height: cr))
        }
        let hr = CGRect(x: cx - pw * 0.5, y: mid, width: pw, height: handleH)
        path.addRoundedRect(in: hr, cornerSize: CGSize(width: cr, height: cr))
        return path
    }
}

#Preview {
    SplashView(onComplete: {})
}
