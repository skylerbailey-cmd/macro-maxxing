//
//  BellButton.swift
//  Wellness
//

import SwiftUI

struct BellButton: View {
    @Binding var showingNotifications: Bool
    let notificationState: NotificationState

    private let purpl = Color(red: 0.65, green: 0.45, blue: 1.00)

    var body: some View {
        Button { showingNotifications = true } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(purpl)
                    .padding(.trailing, notificationState.unreadCount > 0 ? 6 : 0)
                    .padding(.top, notificationState.unreadCount > 0 ? 6 : 0)

                if notificationState.unreadCount > 0 {
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
    }
}
