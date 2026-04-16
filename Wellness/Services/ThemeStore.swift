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
///
/// Persists to two places:
///  - **UserDefaults** — fast, synchronous, read on app launch so the UI
///    renders with the right accent immediately.
///  - **Firestore** (`users/{uid}.accentColor`) — durable across devices
///    so signing in on a new phone picks up the user's previous choice.
///    Written fire-and-forget; errors are logged but not surfaced.
@Observable
final class ThemeStore {
    static let shared = ThemeStore()

    private let storageKey = "selectedAccentColor"

    /// Suppresses the Firestore write path when we're applying a value
    /// that already came from Firestore — otherwise every login would
    /// echo the accent straight back to the server.
    @ObservationIgnored private var isApplyingRemote = false

    var selectedAccent: AccentChoice {
        didSet {
            UserDefaults.standard.set(selectedAccent.rawValue, forKey: storageKey)
            if !isApplyingRemote { syncToFirestore() }
        }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: "selectedAccentColor") ?? ""
        self.selectedAccent = AccentChoice(rawValue: raw) ?? .purple
    }

    /// Convenience accessor used in views: `theme.accent`
    var accent: Color { selectedAccent.color }

    // MARK: - Firestore sync

    /// Applies an accent pulled from Firestore (via `UserSettings.populate(from:)`).
    /// No-op for unknown values or when the current choice already matches.
    /// Still routes through the setter so `@Observable` re-renders fire and
    /// UserDefaults stays in sync — only the Firestore write is skipped.
    @MainActor
    func applyRemoteAccent(_ raw: String) {
        guard let choice = AccentChoice(rawValue: raw),
              choice != selectedAccent else { return }
        isApplyingRemote = true
        selectedAccent   = choice
        isApplyingRemote = false
    }

    /// Fire-and-forget push of the current choice to the user's Firestore
    /// profile doc. No-ops when there's no cached user ID (signed out).
    private func syncToFirestore() {
        guard let userID = KeychainService.get(key: "cachedUserID"),
              !userID.isEmpty else { return }
        let choice = selectedAccent.rawValue
        Task {
            do {
                try await UserProfileService.shared.updateProfile(
                    userID: userID,
                    fields: ["accentColor": choice]
                )
            } catch {
                AppLogger.log("[ThemeStore] Failed to sync accent to Firestore: \(error.localizedDescription)")
            }
        }
    }
}
