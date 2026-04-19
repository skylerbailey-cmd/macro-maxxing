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
        w.frame = scene.screen.bounds

        let vc = UIHostingController(rootView:
            FireAnimationView()
                .frame(
                    width:  scene.screen.bounds.width,
                    height: scene.screen.bounds.height
                )
                .ignoresSafeArea()
        )
        vc.view.backgroundColor = .clear
        vc.view.isUserInteractionEnabled = false
        vc.view.frame = scene.screen.bounds

        w.rootViewController = vc
        w.isHidden = false
        w.alpha = 1

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
