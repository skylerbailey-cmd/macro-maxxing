//
//  FireWindowController.swift
//  Wellness
//
//  Shows fire animation in a dedicated UIWindow above everything.
//

import SwiftUI
import UIKit

@MainActor
final class FireWindowController {
    static let shared = FireWindowController()
    private init() {}

    private var window: UIWindow?
    private var dismissTask: Task<Void, Never>?

    func show(duration: TimeInterval = 5.0) {
        dismissTask?.cancel()

        if window != nil {
            scheduleDismiss(after: duration)
            return
        }

        guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first else { return }

        let w = UIWindow(windowScene: scene)
        w.windowLevel = .statusBar + 100
        w.backgroundColor = .clear
        w.isUserInteractionEnabled = false

        let vc = UIHostingController(rootView:
            FireAnimationView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
        vc.view.backgroundColor = .clear
        vc.view.isUserInteractionEnabled = false
        // This is the critical line — .ignoresSafeArea() in SwiftUI does NOT
        // work inside a UIHostingController. You must disable safe area at the
        // view controller level using this iOS 16.4+ API.
        vc.safeAreaRegions = []
        vc.view.frame = w.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        w.rootViewController = vc
        w.isHidden = false

        self.window = w
        scheduleDismiss(after: duration)
    }

    func dismiss() {
        guard let w = window else { return }
        UIView.animate(withDuration: 0.4, animations: {
            w.alpha = 0
        }, completion: { _ in
            w.isHidden = true
            w.rootViewController = nil
            self.window = nil
        })
    }

    private func scheduleDismiss(after duration: TimeInterval) {
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }
}
