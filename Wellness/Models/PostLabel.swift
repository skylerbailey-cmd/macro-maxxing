//
//  PostLabel.swift
//  Wellness
//

import Foundation
import SwiftUI

enum PostLabel: String, CaseIterable, Codable {
    case fuelLog        = "Fuel Log"
    case goalPost       = "Goal"
    case workout        = "Workout"
    case mogBoard       = "Mog Board"
    case transformation = "Transformation"
    case mealInspo      = "Meal Inspo"
    case advice         = "Advice"

    var icon: String {
        switch self {
        case .transformation: return "figure.walk"
        case .fuelLog:        return "flame.fill"
        case .mealInspo:      return "fork.knife"
        case .mogBoard:       return "crown.fill"
        case .advice:         return "lightbulb.fill"
        case .workout:        return "figure.strengthtraining.traditional"
        case .goalPost:       return "target"
        }
    }

    /// Palette used everywhere this label is rendered — the chip in the
    /// composer, the badge on the post card, and the chrome of the
    /// generated share visual. Kept in one place so the three surfaces
    /// never drift.
    var color: Color {
        switch self {
        case .transformation: return Color(red: 0.35, green: 0.75, blue: 1.00)
        case .fuelLog:        return Color(red: 1.00, green: 0.55, blue: 0.15)
        case .mealInspo:      return Color(red: 1.00, green: 0.30, blue: 0.55)
        case .mogBoard:       return Color.premiumGold
        case .advice:         return Color(red: 1.00, green: 0.90, blue: 0.20)
        case .workout:        return Color(red: 0.30, green: 0.90, blue: 0.55)
        case .goalPost:       return Color(red: 0.65, green: 0.45, blue: 1.00)
        }
    }
}
