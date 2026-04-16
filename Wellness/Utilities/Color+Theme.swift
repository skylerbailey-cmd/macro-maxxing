//
//  Color+Theme.swift
//  Wellness
//
//  Shared color palette used across all views. The "accent" color that reacts
//  to the user's settings choice lives on `ThemeStore.shared.accent` — views
//  that want it should keep a `@State private var theme = ThemeStore.shared`
//  and read `theme.accent`.
//

import SwiftUI

extension Color {
    // MARK: - Chrome (neutral-dark; no purple cast)

    static let pageBg    = Color(red: 0.05, green: 0.05, blue: 0.07)
    static let cardBg    = Color(red: 0.11, green: 0.11, blue: 0.14)

    /// Deeper dark for screens that want extra contrast (e.g. Profile, Splash).
    static let pageBgDeep = Color(red: 0.03, green: 0.03, blue: 0.04)
    static let cardBgDeep = Color(red: 0.08, green: 0.08, blue: 0.10)

    // MARK: - Legacy alias for the pickable accent

    /// Returns the user's currently-selected accent color. Kept for
    /// compatibility with the many existing `Color.purpleHi` call sites —
    /// prefer `ThemeStore.shared.accent` directly in new code. Because this
    /// is a computed `static var`, reads from inside an `@Observable`-tracked
    /// body will re-render when the user picks a different accent.
    static var purpleHi: Color { ThemeStore.shared.accent }

    // MARK: - Semantic (unchanged by theme selection)

    static let macroBlue = Color(red: 0.35, green: 0.75, blue: 1.00)
    static let macroMint = Color(red: 0.40, green: 0.90, blue: 0.72)
    static let macroRose = Color(red: 1.00, green: 0.50, blue: 0.72)
    static let calClr    = Color(red: 1.00, green: 0.55, blue: 0.15)
    static let proClr    = Color(red: 0.35, green: 0.75, blue: 1.00)
    static let carbClr   = Color(red: 0.40, green: 0.90, blue: 0.72)
    static let fatClr    = Color(red: 1.00, green: 0.50, blue: 0.72)
}
