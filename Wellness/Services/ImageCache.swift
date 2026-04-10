//
//  ImageCache.swift
//  Wellness
//
//  In-memory NSCache for decoded UIImages.
//  URLCache (configured at launch) handles the disk layer automatically.
//

import UIKit
import SwiftUI

// MARK: - In-memory image cache

final class ImageCache {
    static let shared = ImageCache()
    private init() {
        cache.countLimit   = 200          // max 200 images in memory
        cache.totalCostLimit = 50 * 1024 * 1024  // 50 MB ceiling
    }

    private let cache = NSCache<NSString, UIImage>()

    func removeAll() {
        cache.removeAllObjects()
    }

    subscript(url: String) -> UIImage? {
        get { cache.object(forKey: url as NSString) }
        set {
            if let img = newValue {
                let cost = Int(img.size.width * img.size.height * img.scale * 4)
                cache.setObject(img, forKey: url as NSString, cost: cost)
            } else {
                cache.removeObject(forKey: url as NSString)
            }
        }
    }
}

// MARK: - CachedAsyncImage

/// Drop-in replacement for AsyncImage that checks in-memory cache first,
/// then falls through to URLSession (which uses the URLCache disk layer).
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content:     (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var uiImage: UIImage? = nil
    @State private var failed  = false

    var body: some View {
        Group {
            if let img = uiImage {
                content(Image(uiImage: img))
            } else if failed {
                placeholder()
            } else {
                placeholder()
                    .task(id: url?.absoluteString) { await load() }
            }
        }
    }

    private func load() async {
        guard let url else { failed = true; return }
        let key = url.absoluteString

        // 1. Memory cache hit → instant
        if let cached = ImageCache.shared[key] {
            uiImage = cached
            return
        }

        // 2. Network / disk cache (URLSession + URLCache)
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad   // serve from disk if available

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let img = UIImage(data: data) else { failed = true; return }
            ImageCache.shared[key] = img   // store in memory cache
            uiImage = img
        } catch {
            failed = true
        }
    }
}
