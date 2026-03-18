//
//  PostLabel.swift
//  Wellness
//

import Foundation

enum PostLabel: String, CaseIterable, Codable {
    case transformation = "Transformation"
    case fuelLog        = "Fuel Log"
    case mealInspo      = "Meal Inspo"
    case mogBoard       = "Mog Board"
    case advice         = "Advice"

    var icon: String {
        switch self {
        case .transformation: return "figure.walk"
        case .fuelLog:        return "flame.fill"
        case .mealInspo:      return "fork.knife"
        case .mogBoard:       return "crown.fill"
        case .advice:         return "lightbulb.fill"
        }
    }
}
