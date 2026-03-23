//
//  AgeVerificationService.swift
//  Wellness
//
//  Placeholder for Apple's Declared Age Range API (iOS 26+).
//  Currently returns .unavailable on all OS versions.
//  The onboarding flow falls back to the DOB date picker.
//

import SwiftUI

// MARK: - Age Verification Result

enum AgeVerificationResult {
    case verified
    case underage
    case declined
    case unavailable
}

// MARK: - AgeVerificationService

@MainActor
struct AgeVerificationService {

    static func verifyAge() async -> AgeVerificationResult {
        // DeclaredAgeRange API is not available until iOS 26.
        // Fall back to the DOB picker in onboarding.
        return .unavailable
    }

    static var isAvailable: Bool { false }
}
