//
//  BellButton.swift
//  Wellness
//

import SwiftUI

struct BellButton: View {
    @Binding var showingNotifications: Bool
    let notificationState: NotificationState

    @State private var ringTrigger = 0

    private let purpl = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold  = Color(red: 1.00, green: 0.80, blue: 0.20)

    private var hasUnread: Bool { notificationState.unreadCount > 0 }

    var body: some View {
        Button { showingNotifications = true } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(hasUnread ? gold : purpl)
                    .padding(.trailing, hasUnread ? 6 : 0)
                    .padding(.top,      hasUnread ? 6 : 0)
                    .keyframeAnimator(initialValue: 0.0, trigger: ringTrigger) { content, angle in
                        content.rotationEffect(.degrees(angle))
                    } keyframes: { _ in
                        CubicKeyframe(-18, duration: 0.08)
                        CubicKeyframe( 16, duration: 0.08)
                        CubicKeyframe(-12, duration: 0.08)
                        CubicKeyframe( 10, duration: 0.08)
                        CubicKeyframe( -6, duration: 0.07)
                        CubicKeyframe(  5, duration: 0.07)
                        CubicKeyframe(  0, duration: 0.07)
                    }

                if hasUnread {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 14, height: 14)
                        Text(notificationState.unreadCount > 9 ? "9+" : "\(notificationState.unreadCount)")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .onAppear {
            if hasUnread { ringTrigger += 1 }
        }
        .onChange(of: notificationState.unreadCount) { _, count in
            if count > 0 { ringTrigger += 1 }
        }
        .accessibilityLabel("Notifications")
        .accessibilityValue(hasUnread ? "\(notificationState.unreadCount) unread" : "No unread notifications")
        .accessibilityHint("Opens your notifications")
    }
}
