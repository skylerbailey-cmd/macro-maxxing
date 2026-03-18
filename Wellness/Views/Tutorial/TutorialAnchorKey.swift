//
//  TutorialAnchorKey.swift
//  Wellness
//

import SwiftUI

/// PreferenceKey that collects named CGRect anchors from tagged views.
struct TutorialAnchorKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    /// Tags this view so the tutorial overlay can locate and spotlight it.
    func tutorialAnchor(_ id: String) -> some View {
        anchorPreference(key: TutorialAnchorKey.self, value: .bounds) { [id: $0] }
    }
}
