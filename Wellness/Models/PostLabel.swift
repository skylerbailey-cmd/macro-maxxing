//
//  PostLabel.swift
//  Wellness
//

import Foundation

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
}
