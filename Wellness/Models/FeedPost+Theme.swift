//
//  FeedPost+Theme.swift
//  Wellness
//
//  View-layer extension (imports SwiftUI) that gives a FeedPost its display
//  accent color. When the post has a PostLabel, the label's color wins over
//  the user's app-wide accent — so chrome around the post (fuel-log dividers,
//  workout table, mog board card, generated share visual) matches the label
//  the author chose in the composer.
//

import SwiftUI

extension FeedPost {

    /// The color chrome on this post should use: the label's color if one was
    /// selected when the post was created, otherwise the app accent. Keeps
    /// FeedPostCard, FeedPostDetailView, and PostShareCardView in sync.
    var themeColor: Color {
        if let label = PostLabel(rawValue: postLabel) {
            return label.color
        }
        return ThemeStore.shared.accent
    }
}
