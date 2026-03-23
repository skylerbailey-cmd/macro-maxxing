//
//  AgeVerificationService.swift
//  Wellness
//
//  Wraps Apple's Declared Age Range API (iOS 26+) with a fallback for older OS versions.
//

import SwiftUI

// MARK: - Age Verification Result

enum AgeVerificationResult {
    /// User confirmed 18+ via Apple's system-level age range.
    case verified
    /// User is under 18 per Apple's declared age range.
    case underage
    /// User declined to share their age range — fall back to DOB picker.
    case declined
    /// API not available (pre-iOS 26 or unsupported device) — fall back to DOB picker.
    case unavailable
}

// MARK: - AgeVerificationService

@MainActor
struct AgeVerificationService {

    /// Attempts to verify the user is 18+ using Apple's Declared Age Range API.
    /// Falls back to `.unavailable` on iOS versions below 26.
    static func verifyAge() async -> AgeVerificationResult {
        #if canImport(DeclaredAgeRange)
        if #available(iOS 26, *) {
            return await verifyWithDeclaredAgeRange()
        }
        #endif
        return .unavailable
    }

    /// Returns true if the Declared Age Range API is available on this device/OS.
    static var isAvailable: Bool {
        #if canImport(DeclaredAgeRange)
        if #available(iOS 26, *) {
            return true
        }
        #endif
        return false
    }
}

// MARK: - iOS 26+ Implementation

#if canImport(DeclaredAgeRange)
import DeclaredAgeRange

@available(iOS 26, *)
private extension AgeVerificationService {

    static func verifyWithDeclaredAgeRange() async -> AgeVerificationResult {
        do {
            let response = try await AgeRangeService.shared.requestAgeRange(ageGates: 18)
            switch response {
            case .sharing(let range):
                return range.lowerBound >= 18 ? .verified : .underage
            case .declinedSharing:
                return .declined
            @unknown default:
                return .declined
            }
        } catch {
            print("[AgeVerification] DeclaredAgeRange error: \(error.localizedDescription)")
            return .unavailable
        }
    }
}
#endif
