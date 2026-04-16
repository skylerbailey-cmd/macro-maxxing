//
//  Shimmer.swift
//  Wellness
//
//  Shared styling for premium / AI surfaces: a fixed "premium gold"
//  color and a reusable `.shimmering()` view modifier that sweeps a
//  highlight band across the view.
//
//  The gold is intentionally NOT theme-driven — we want it to always
//  read as a "special" accent (AI features, premium upsells) distinct
//  from the user's selected accent color.
//

import SwiftUI

extension Color {
    /// Warm gold reserved for premium / AI CTAs (AI Meal Planner,
    /// AI Nutrition Coach, voice-to-workout mic, etc).
    static let premiumGold = Color(red: 1.00, green: 0.80, blue: 0.20)

    /// Amber paired with `premiumGold` for warm gold→amber gradients.
    static let premiumAmber = Color(red: 1.00, green: 0.60, blue: 0.10)
}

// MARK: - Shimmer modifier

/// Sweeping diagonal highlight used to draw attention to premium CTAs.
/// The shimmer band travels left→right on a slow loop; it's masked to
/// a rounded rectangle so it never bleeds past a button's edge.
struct ShimmerModifier: ViewModifier {
    let cornerRadius: CGFloat
    let duration:     Double
    let bandWidth:    CGFloat  // fraction of the view width, 0–1

    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.45), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * bandWidth)
                    // Start just off the leading edge and travel past the
                    // trailing edge, then the repeatForever jumps back and
                    // replays (not auto-reversing so it always moves the
                    // same direction).
                    .offset(x: isAnimating
                            ? proxy.size.width
                            : -proxy.size.width * bandWidth)
                    .animation(
                        .linear(duration: duration).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                }
                .mask {
                    RoundedRectangle(cornerRadius: cornerRadius)
                }
                .allowsHitTesting(false)
            }
            .onAppear { isAnimating = true }
    }
}

extension View {
    /// Adds a slow, looping shimmer highlight across the view.
    /// Pass the target's corner radius so the sweep is clipped cleanly.
    func shimmering(cornerRadius: CGFloat = 12,
                    duration:     Double  = 2.4,
                    bandWidth:    CGFloat = 0.5) -> some View {
        modifier(ShimmerModifier(
            cornerRadius: cornerRadius,
            duration:     duration,
            bandWidth:    bandWidth
        ))
    }
}
