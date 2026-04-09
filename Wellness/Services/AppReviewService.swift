//
//  AppReviewService.swift
//  Wellness
//
//  Requests an App Store review using Apple's native SKStoreReviewController.
//  Apple limits the popup to 3 times per 365 days — this service adds its own
//  guard to avoid wasting those limited slots.
//

import StoreKit
import UIKit

enum AppReviewService {

    private static let lastRequestedKey = "appReview_lastRequestedDate"
    private static let requestCountKey  = "appReview_requestCount"

    /// Requests a review if the user hasn't been prompted recently.
    /// - Only prompts once per 90 days (our own limit on top of Apple's 3/year)
    /// - Delays 2 seconds so the streak celebration popup can show first
    static func requestReviewIfAppropriate() {
        let ud = UserDefaults.standard
        let count = ud.integer(forKey: requestCountKey)

        // Don't request more than 2 times from our side (Apple caps at 3/year anyway)
        guard count < 2 else { return }

        // Don't request again within 90 days
        let lastRequested = ud.double(forKey: lastRequestedKey)
        if lastRequested > 0 {
            let daysSince = Date().timeIntervalSince1970 - lastRequested
            guard daysSince > 90 * 24 * 3600 else { return }
        }

        // Delay so the streak aura popup shows first
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first {
                SKStoreReviewController.requestReview(in: scene)
                ud.set(Date().timeIntervalSince1970, forKey: lastRequestedKey)
                ud.set(count + 1, forKey: requestCountKey)
            }
        }
    }
}
