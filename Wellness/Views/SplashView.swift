//
//  SplashView.swift
//  Wellness
//

import SwiftUI

// MARK: - SplashView

struct SplashView: View {
    @State private var ringScale: CGFloat  = 0.6
    @State private var ringOpacity: Double = 0
    @State private var forkScale: CGFloat  = 0.5
    @State private var forkOpacity: Double = 0
    @State private var titleOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background — matches app theme
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

            VStack(spacing: 28) {
                // Logo
                WellnessLogoView(size: 220)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)

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
            withAnimation(.spring(duration: 0.7, bounce: 0.3)) {
                ringScale   = 1.0
                ringOpacity = 1.0
            }
            withAnimation(.spring(duration: 0.6, bounce: 0.25).delay(0.15)) {
                forkScale   = 1.0
                forkOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.35)) {
                titleOpacity = 1.0
            }
        }
    }
}

// MARK: - Logo (shared design matching the app icon)

struct WellnessLogoView: View {
    let size: CGFloat

    private var ringR: CGFloat { size * 0.36 }
    private var lw:    CGFloat { size * 0.058 }
    private var dotR:  CGFloat { size * 0.048 }

    private let macroDots: [(angle: Double, color: Color)] = [
        (.pi / 2,  Color(red: 1.0, green: 0.55, blue: 0.15)),  // top    – orange
        (0,         Color(red: 0.35, green: 0.75, blue: 1.0)),  // right  – blue
        (-.pi / 2,  Color(red: 0.40, green: 0.90, blue: 0.72)), // bottom – mint
        (.pi,       Color(red: 1.0, green: 0.50, blue: 0.72)),  // left   – rose
    ]

    var body: some View {
        ZStack {
            // Dim track
            Circle()
                .stroke(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.15), lineWidth: lw)
                .frame(width: ringR * 2, height: ringR * 2)

            // Glowing ring
            Circle()
                .stroke(Color(red: 0.65, green: 0.45, blue: 1.0), lineWidth: lw)
                .frame(width: ringR * 2, height: ringR * 2)
                .shadow(color: Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.65), radius: size * 0.04)

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
                        x: ringR * CGFloat(cos(d.angle)),
                        y: -ringR * CGFloat(sin(d.angle))
                    )
            }

            // Fork
            ForkShape()
                .fill(Color.white.opacity(0.90))
                .frame(width: size * 0.22, height: size * 0.28)
                .shadow(color: Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.5), radius: size * 0.02)
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

        let pw     = w * 0.145   // prong width
        let gap    = w * 0.115   // gap between prongs
        let prongH = h * 0.54
        let handleH = h * 0.46
        let cr     = pw * 0.5
        let top    = cy - h * 0.5
        let mid    = top + prongH

        var path = Path()
        // 3 prongs
        for xOff: CGFloat in [-(pw + gap), 0, (pw + gap)] {
            let r = CGRect(x: cx + xOff - pw * 0.5, y: top, width: pw, height: prongH)
            path.addRoundedRect(in: r, cornerSize: CGSize(width: cr, height: cr))
        }
        // Handle
        let hr = CGRect(x: cx - pw * 0.5, y: mid, width: pw, height: handleH)
        path.addRoundedRect(in: hr, cornerSize: CGSize(width: cr, height: cr))
        return path
    }
}

#Preview {
    SplashView()
}
