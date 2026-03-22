//
//  BannerAdView.swift
//  Wellness
//
//  SwiftUI wrapper for AdMob banner ad.
//

import SwiftUI
import GoogleMobileAds

/// A self-sizing adaptive banner ad.
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView()
        banner.adUnitID = adUnitID
        banner.translatesAutoresizingMaskIntoConstraints = false

        let width = UIScreen.main.bounds.width
        banner.adSize = currentOrientationAnchoredAdaptiveBanner(width: width)

        if let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController {
            banner.rootViewController = root
        }

        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}

/// Convenience: only shows the banner when the flag is true.
struct ConditionalBannerAd: View {
    let isEnabled: Bool

    var body: some View {
        if isEnabled {
            BannerAdView(adUnitID: AdManager.shared.bannerUnitID)
                .frame(height: 50)
                .padding(.vertical, 4)
        }
    }
}
