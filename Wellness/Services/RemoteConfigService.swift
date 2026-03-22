//
//  RemoteConfigService.swift
//  Wellness
//
//  Wraps Firebase Remote Config for feature flags.
//  All ad-related flags default to false/0 so ads are dormant until
//  enabled in the Firebase Console — no App Store update required.
//

import Foundation
import FirebaseRemoteConfig

final class RemoteConfigService {
    static let shared = RemoteConfigService()

    private let config = RemoteConfig.remoteConfig()

    private init() {
        let settings = RemoteConfigSettings()
        // In debug, fetch frequently. In production, cache for 1 hour.
        #if DEBUG
        settings.minimumFetchInterval = 30
        #else
        settings.minimumFetchInterval = 3600
        #endif
        config.configSettings = settings

        // Default values — everything disabled
        config.setDefaults([
            // Master switch
            "ads_enabled":                   false as NSObject,
            // Feed banners
            "feed_banner_ads_enabled":       false as NSObject,
            "feed_ad_frequency":             5 as NSObject,
            // Log tab banner
            "log_tab_banner_enabled":        false as NSObject,
            // Rewarded ads
            "mog_board_ad_required":         false as NSObject,
            "brainstorm_ad_required":        false as NSObject,
            "nutrition_coach_ad_required":   false as NSObject,
            "aura_reward_ad_required":       false as NSObject,
            // Interstitial
            "interstitial_on_post":          false as NSObject,
        ])
    }

    /// Fetch and activate remote config values. Call on app launch.
    func fetchAndActivate() async {
        do {
            let status = try await config.fetchAndActivate()
            print("[RemoteConfig] Fetch status: \(status == .successFetchedFromRemote ? "remote" : "cached")")
        } catch {
            print("[RemoteConfig] Fetch error: \(error.localizedDescription)")
        }
    }

    // MARK: - Accessors

    var adsEnabled: Bool {
        config.configValue(forKey: "ads_enabled").boolValue
    }

    var feedBannerAdsEnabled: Bool {
        adsEnabled && config.configValue(forKey: "feed_banner_ads_enabled").boolValue
    }

    var feedAdFrequency: Int {
        let val = config.configValue(forKey: "feed_ad_frequency").numberValue.intValue
        return val > 0 ? val : 5
    }

    var logTabBannerEnabled: Bool {
        adsEnabled && config.configValue(forKey: "log_tab_banner_enabled").boolValue
    }

    var mogBoardAdRequired: Bool {
        adsEnabled && config.configValue(forKey: "mog_board_ad_required").boolValue
    }

    var brainstormAdRequired: Bool {
        adsEnabled && config.configValue(forKey: "brainstorm_ad_required").boolValue
    }

    var nutritionCoachAdRequired: Bool {
        adsEnabled && config.configValue(forKey: "nutrition_coach_ad_required").boolValue
    }

    var auraRewardAdRequired: Bool {
        adsEnabled && config.configValue(forKey: "aura_reward_ad_required").boolValue
    }

    var interstitialOnPost: Bool {
        adsEnabled && config.configValue(forKey: "interstitial_on_post").boolValue
    }
}
