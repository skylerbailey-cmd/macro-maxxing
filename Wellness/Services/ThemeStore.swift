//
//  ThemeStore.swift
//  Wellness
//
//  Holds the user's chosen accent color and persists it in UserDefaults.
//  Views observe `ThemeStore.shared` (the @Observable tracks reads) so
//  any @State or @Environment reference re-renders when the accent changes.
//

import SwiftUI

/// The pickable accent colors exposed in Settings.
///
/// Each case owns:
///  - its brand RGB
///  - a display name for the settings row
///  - a tinted variant used for chip fills, outlines, and subtle highlights
enum AccentChoice: String, CaseIterable, Identifiable, Codable {
    case purple
    case orange
    case red
    case blue
    case green

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .purple: return "Purple"
        case .orange: return "Orange"
        case .red:    return "Red"
        case .blue:   return "Blue"
        case .green:  return "Green"
        }
    }

    /// The primary accent swatch used for buttons, selections, and chrome.
    var color: Color {
        switch self {
        case .purple: return Color(red: 0.65, green: 0.45, blue: 1.00) // preserves current brand
        case .orange: return Color(red: 1.00, green: 0.55, blue: 0.15)
        case .red:    return Color(red: 1.00, green: 0.40, blue: 0.45)
        case .blue:   return Color(red: 0.35, green: 0.75, blue: 1.00)
        case .green:  return Color(red: 0.30, green: 0.90, blue: 0.55)
        }
    }
}

/// Single source of truth for the user's theme preference.
@Observable
final class ThemeStore {
    static let shared = ThemeStore()

    private let storageKey = "selectedAccentColor"

    var selectedAccent: AccentChoice {
        didSet {
            UserDefaults.standard.set(selectedAccent.rawValue, forKey: storageKey)
        }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: "selectedAccentColor") ?? ""
        self.selectedAccent = AccentChoice(rawValue: raw) ?? .purple
    }

    /// Convenience accessor used in views: `theme.accent`
    var accent: Color { selectedAccent.color }
}
