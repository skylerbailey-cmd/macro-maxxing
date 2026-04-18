//
//  WorkoutItem.swift
//  Wellness
//
//  Workout-type-aware "thing the user did" — the data the Log Workout
//  sheet edits, the Live Activity controls, and the feed displays.
//  A single discriminated union is persisted instead of a bag of typed
//  arrays so save/load stays simple and ordering is preserved.
//

import Foundation

// MARK: - Per-type payloads

/// One segment of a cardio workout — e.g. "Warmup · 5 min", "Tempo · 20 min".
struct CardioSegment: Codable, Identifiable, Hashable {
    var id:              String  = UUID().uuidString
    var label:           String          // user-visible label
    var durationSeconds: Int             // segment length
    var distanceMiles:   Double?         // optional distance
}

/// One block of a HIIT workout — a work/rest timer repeated `rounds` times.
struct HIITRound: Codable, Identifiable, Hashable {
    var id:           String = UUID().uuidString
    var name:         String         // "Burpees", "Sprint + Walk", …
    var workSeconds:  Int            // on-phase length
    var restSeconds:  Int            // off-phase length
    var rounds:       Int            // times to repeat this block
}

/// One pose / flow in a yoga session — optional hold time.
struct YogaPose: Codable, Identifiable, Hashable {
    var id:          String = UUID().uuidString
    var name:        String          // "Warrior 2", "Sun Salutation A"
    var holdSeconds: Int             // 0 = flow / no hold
}

// MARK: - Union

/// Discriminated union of every kind of thing you can log inside a workout.
/// The case picked at the top-level matches the selected `WorkoutType`.
enum WorkoutItem: Codable, Identifiable, Hashable {
    case strength(Exercise)
    case cardioSegment(CardioSegment)
    case hiitRound(HIITRound)
    case yogaPose(YogaPose)

    var id: String {
        switch self {
        case .strength(let x):      return x.id
        case .cardioSegment(let x): return x.id
        case .hiitRound(let x):     return x.id
        case .yogaPose(let x):      return x.id
        }
    }

    /// Type tag persisted in the `type` field. Stable across renames.
    private var tag: String {
        switch self {
        case .strength:      return "strength"
        case .cardioSegment: return "cardio"
        case .hiitRound:     return "hiit"
        case .yogaPose:      return "yoga"
        }
    }

    // MARK: Codable

    private enum CodingKeys: String, CodingKey { case type, payload }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(tag, forKey: .type)
        switch self {
        case .strength(let x):      try c.encode(x, forKey: .payload)
        case .cardioSegment(let x): try c.encode(x, forKey: .payload)
        case .hiitRound(let x):     try c.encode(x, forKey: .payload)
        case .yogaPose(let x):      try c.encode(x, forKey: .payload)
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "strength":
            self = .strength(try c.decode(Exercise.self, forKey: .payload))
        case "cardio":
            self = .cardioSegment(try c.decode(CardioSegment.self, forKey: .payload))
        case "hiit":
            self = .hiitRound(try c.decode(HIITRound.self, forKey: .payload))
        case "yoga":
            self = .yogaPose(try c.decode(YogaPose.self, forKey: .payload))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in:     c,
                debugDescription: "Unknown WorkoutItem type: \(type)"
            )
        }
    }
}

// MARK: - Convenience extractors

extension Array where Element == WorkoutItem {
    /// Pull Strength exercises out. Used by legacy code paths (Feed,
    /// Routines, WorkoutEntry.exercises) that still operate on `[Exercise]`.
    var strengthExercises: [Exercise] {
        compactMap { if case .strength(let x) = $0 { return x } else { return nil } }
    }

    var cardioSegments: [CardioSegment] {
        compactMap { if case .cardioSegment(let x) = $0 { return x } else { return nil } }
    }

    var hiitRounds: [HIITRound] {
        compactMap { if case .hiitRound(let x) = $0 { return x } else { return nil } }
    }

    var yogaPoses: [YogaPose] {
        compactMap { if case .yogaPose(let x) = $0 { return x } else { return nil } }
    }
}
