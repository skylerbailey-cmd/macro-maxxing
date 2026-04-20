//
//  PostShareView.swift
//  Wellness
//
//  Sheet that shows a preview of a user's own FeedPost and provides share
//  destinations — Instagram Stories (via the instagram-stories:// URL scheme)
//  and a generic UIActivityViewController for Messages / Photos / AirDrop.
//
//  Mirrors `ShareView` / `ProfileShareView` to keep UX consistent across the
//  app's share surfaces.
//

import SwiftUI
import UIKit

struct PostShareView: View {
    let post: FeedPost

    @Environment(\.dismiss) private var dismiss
    @State private var foodImages:   [UIImage] = []
    @State private var authorAvatar: UIImage?
    @State private var renderedImage: UIImage?
    @State private var showingActivitySheet = false
    @State private var didFinishLoadingAssets = false
    @State private var darkMode = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()

                VStack(spacing: 16) {
                    cardPreview

                    // Dark / Light toggle
                    HStack(spacing: 12) {
                        Spacer()
                        Button {
                            darkMode = true
                            renderCard()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Dark")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(darkMode ? .black : .white.opacity(0.50))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(darkMode ? ThemeStore.shared.accent : Color.white.opacity(0.08), in: Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            darkMode = false
                            renderCard()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Light")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(!darkMode ? .black : .white.opacity(0.50))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(!darkMode ? ThemeStore.shared.accent : Color.white.opacity(0.08), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }

                    VStack(spacing: 10) {
                        shareButton(
                            title: "Instagram Stories",
                            subtitle: "Share directly to your story",
                            icon: "camera.fill",
                            colors: [Color(red: 0.88, green: 0.19, blue: 0.42),
                                     Color(red: 0.98, green: 0.35, blue: 0.00)]
                        ) { shareToInstagram() }

                        shareButton(
                            title: "Share / Save / More",
                            subtitle: "Messages, AirDrop, save to Photos…",
                            icon: "square.and.arrow.up",
                            colors: [ThemeStore.shared.accent,
                                     Color(red: 0.40, green: 0.20, blue: 0.85)]
                        ) { showingActivitySheet = true }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 8)
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Share Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task { await prepareAssetsAndRender() }
        .sheet(isPresented: $showingActivitySheet) {
            if let img = renderedImage { ActivitySheet(items: [img]) }
        }
    }

    // MARK: - Card preview

    private var cardPreview: some View {
        Group {
            if let image = renderedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .purple.opacity(0.35), radius: 24, y: 8)
                    .frame(maxHeight: 440)
                    .padding(.horizontal, 40)
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.14))
                    .frame(height: 360)
                    .padding(.horizontal, 40)
                    .overlay {
                        VStack(spacing: 10) {
                            ProgressView().tint(ThemeStore.shared.accent)
                            Text("Rendering…")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.40))
                        }
                    }
            }
        }
    }

    // MARK: - Share button

    private func shareButton(title: String, subtitle: String,
                             icon: String, colors: [Color],
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(colors: colors,
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.30))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(red: 0.11, green: 0.11, blue: 0.14))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .disabled(renderedImage == nil)
    }

    // MARK: - Asset preparation

    /// Downloads the post photo and the author avatar in parallel, then renders
    /// the card. Running the download first means the rendered snapshot
    /// includes the actual imagery instead of a placeholder.
    @MainActor
    private func prepareAssetsAndRender() async {
        // Collect up to 2 photo URLs
        let allURLs = post.allPhotoURLs.prefix(2)
        let photoResults = await withTaskGroup(of: (Int, UIImage?).self) { group in
            for (idx, urlStr) in allURLs.enumerated() {
                group.addTask { (idx, await Self.download(URL(string: urlStr))) }
            }
            var results: [(Int, UIImage?)] = []
            for await result in group { results.append(result) }
            return results.sorted { $0.0 < $1.0 }.compactMap { $0.1 }
        }
        foodImages   = photoResults
        authorAvatar = await Self.download(URL(string: post.userProfilePhotoURL))
        didFinishLoadingAssets = true
        renderCard()
    }

    @MainActor
    private func renderCard() {
        let card = PostShareCardView(
            post:         post,
            foodImages:   foodImages,
            authorAvatar: authorAvatar,
            lightMode:    !darkMode
        )
        let renderer   = ImageRenderer(content: card)
        renderer.scale = 3.0                   // 360 × 640 pt  →  1080 × 1920 px
        renderedImage  = renderer.uiImage
    }

    private static func download(_ url: URL?) async -> UIImage? {
        guard let url, !url.absoluteString.isEmpty else { return nil }
        return await withCheckedContinuation { continuation in
            URLSession.shared.dataTask(with: url) { data, _, _ in
                let img = data.flatMap { UIImage(data: $0) }
                continuation.resume(returning: img)
            }.resume()
        }
    }

    // MARK: - Platform share actions

    private func shareToInstagram() {
        guard let image = renderedImage,
              let data  = image.pngData(),
              let url   = URL(string: "instagram-stories://share?source_application=com.sbailey.Wellness")
        else { showingActivitySheet = true; return }

        let items: [String: Any] = [
            "com.instagram.sharedSticker.backgroundImage":       data,
            "com.instagram.sharedSticker.backgroundTopColor":    "#080215",
            "com.instagram.sharedSticker.backgroundBottomColor": "#030108"
        ]
        UIPasteboard.general.setItems(
            [items],
            options: [.expirationDate: Date(timeIntervalSinceNow: 300)]
        )
        UIApplication.shared.open(url) { success in
            if !success { showingActivitySheet = true }
        }
    }
}
