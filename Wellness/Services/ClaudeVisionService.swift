//
//  ClaudeVisionService.swift
//  Wellness
//
//  DEPRECATED: This service has been replaced by the three-tier food recognition system.
//  See FoodRecognitionManager.swift for the new entry point.
//
//  - Tier 1: CoreMLClassifierService + USDAService
//  - Tier 2: ClaudeHaikuService + FatSecretService + OpenFoodFactsService
//  - Tier 3: ClaudeSonnetService
//

import Foundation

// Keep ClaudeServiceError available for backward compatibility with ClaudeAnalysisService
enum ClaudeServiceError: Error, LocalizedError {
    case overloaded
    case rateLimited
    case serverError
    case noConnection
    case badResponse(statusCode: Int)
    case noContent
    case malformedJSON(String)

    var errorDescription: String? {
        switch self {
        case .overloaded:              return "Our AI coach is a little busy right now. Tap to try again in a moment."
        case .rateLimited:             return "There's a lot of requests right now. Try again in a few minutes."
        case .serverError:             return "Something went wrong on our end. Please try again."
        case .noConnection:            return "No internet connection. Please check your network and try again."
        case .badResponse(let code):   return "Something went wrong (error \(code)). Please try again."
        case .noContent:               return "No content in API response"
        case .malformedJSON(let text): return "Could not parse response: \(text)"
        }
    }
}
