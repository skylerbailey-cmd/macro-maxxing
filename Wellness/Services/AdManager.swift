//
//  AdManager.swift
//  Wellness
//
//  Manages Google AdMob ad loading and display.
//  All ad types are loaded eagerly but only shown when Remote Config flags are enabled.
//  Ships dormant — zero ads until you flip the switch in Firebase Console.
//

import UIKit
import Combine
import GoogleMobileAds

@MainActor
final class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()

    // MARK: - Ad Unit IDs

    #if DEBUG
    // Use Google's official test ad unit IDs during development
    private let bannerAdUnitID       = "ca-app-pub-3940256099942544/2934735716"
    private let rewardedAdUnitID     = "ca-app-pub-3940256099942544/1712485313"
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    #else
    private let bannerAdUnitID       = "ca-app-pub-6655726785172845/6540251637"
    private let rewardedAdUnitID     = "ca-app-pub-6655726785172845/2311731581"
    private let interstitialAdUnitID = "ca-app-pub-6655726785172845/9695397581"
    #endif

    // MARK: - Loaded Ads

    private var rewardedAd:     RewardedAd?
    private var interstitialAd: InterstitialAd?

    /// True once the SDK is initialized.
    @Published var isReady = false

    private override init() {
        super.init()
    }

    // MARK: - Initialize SDK

    /// Call once on app launch (e.g. in WellnessApp .task).
    func initialize() {
        MobileAds.shared.start { [weak self] _ in
            print("[AdManager] Google Mobile Ads SDK initialized")
            self?.isReady = true
            self?.preloadRewarded()
            self?.preloadInterstitial()
        }
    }

    // MARK: - Banner Ad Unit ID (for BannerAdView)

    var bannerUnitID: String { bannerAdUnitID }

    // MARK: - Rewarded Ad

    func preloadRewarded() {
        RewardedAd.load(with: rewardedAdUnitID, request: Request()) { [weak self] ad, error in
            if let error {
                print("[AdManager] Rewarded ad load failed: \(error.localizedDescription)")
                return
            }
            self?.rewardedAd = ad
            print("[AdManager] Rewarded ad loaded")
        }
    }

    /// Shows a rewarded ad. Calls `onReward` when the user earns the reward.
    /// Calls `onDismiss` when the ad is dismissed (whether rewarded or not).
    /// If no ad is loaded, calls `onReward` immediately (fail-open so users aren't blocked).
    func showRewarded(onReward: @escaping () -> Void, onDismiss: (() -> Void)? = nil) {
        guard let ad = rewardedAd,
              let root = rootViewController() else {
            print("[AdManager] No rewarded ad available — granting reward anyway")
            onReward()
            onDismiss?()
            return
        }

        ad.fullScreenContentDelegate = RewardedAdDelegate(onDismiss: { [weak self] in
            self?.preloadRewarded()
            onDismiss?()
        })

        ad.present(from: root) {
            let reward = ad.adReward
            print("[AdManager] User earned reward: \(reward.amount) \(reward.type)")
            onReward()
        }
        rewardedAd = nil
    }

    /// Whether a rewarded ad is loaded and ready to show.
    var rewardedAdReady: Bool { rewardedAd != nil }

    // MARK: - Interstitial Ad

    func preloadInterstitial() {
        InterstitialAd.load(with: interstitialAdUnitID, request: Request()) { [weak self] ad, error in
            if let error {
                print("[AdManager] Interstitial ad load failed: \(error.localizedDescription)")
                return
            }
            self?.interstitialAd = ad
            print("[AdManager] Interstitial ad loaded")
        }
    }

    /// Shows an interstitial ad. Calls `onDismiss` when complete.
    /// If no ad is loaded, calls `onDismiss` immediately.
    func showInterstitial(onDismiss: (() -> Void)? = nil) {
        guard let ad = interstitialAd,
              let root = rootViewController() else {
            onDismiss?()
            return
        }

        ad.fullScreenContentDelegate = InterstitialAdDelegate(onDismiss: { [weak self] in
            self?.preloadInterstitial()
            onDismiss?()
        })

        ad.present(from: root)
        interstitialAd = nil
    }

    // MARK: - Helpers

    private func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController
    }
}

// MARK: - Delegates

private class RewardedAdDelegate: NSObject, FullScreenContentDelegate {
    let onDismiss: () -> Void
    init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        onDismiss()
    }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("[AdManager] Ad failed to present: \(error.localizedDescription)")
        onDismiss()
    }
}

private class InterstitialAdDelegate: NSObject, FullScreenContentDelegate {
    let onDismiss: () -> Void
    init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        onDismiss()
    }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("[AdManager] Ad failed to present: \(error.localizedDescription)")
        onDismiss()
    }
}
