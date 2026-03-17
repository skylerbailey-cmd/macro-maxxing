//
//  NotificationsView.swift
//  Wellness
//

import SwiftUI

// MARK: - Shared state

@Observable final class NotificationState {
    var unreadCount: Int = 0

    func refresh(userID: String) async {
        guard !userID.isEmpty else { return }
        unreadCount = (try? await InAppNotificationService.shared.unreadCount(userID: userID)) ?? 0
    }
}

// MARK: - NotificationsView

struct NotificationsView: View {
    let userSettings: UserSettings
    let notificationState: NotificationState

    @Environment(\.dismiss) private var dismiss
    @State private var notifications: [AppNotification] = []
    @State private var loading = true
    @State private var followingIDs:  Set<String> = []
    @State private var followLoading: Set<String> = []

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()

                if loading {
                    ProgressView()
                        .tint(purpl)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if notifications.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(notifications) { notif in
                                notifRow(notif)
                                Divider()
                                    .background(Color.white.opacity(0.06))
                                    .padding(.leading, 70)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(purpl)
                }
                if notifications.contains(where: { !$0.isRead }) {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Mark all read") {
                            Task { await markAllRead() }
                        }
                        .font(.subheadline)
                        .foregroundStyle(gold)
                    }
                }
            }
        }
        .task { await loadNotifications() }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(purpl.opacity(0.10))
                    .frame(width: 80, height: 80)
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(purpl.opacity(0.40))
            }
            Text("No notifications yet")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
            Text("You'll see follows, reps, comments,\nand leaderboard placements here.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.28))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Row

    @ViewBuilder
    private func notifRow(_ notif: AppNotification) -> some View {
        HStack(alignment: .top, spacing: 14) {
            notifAvatar(notif)

            VStack(alignment: .leading, spacing: 4) {
                Text(notif.message)
                    .font(.system(size: 14, weight: notif.isRead ? .regular : .semibold))
                    .foregroundStyle(notif.isRead ? .white.opacity(0.70) : .white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(timeAgo(from: notif.createdAt))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))
            }

            Spacer()

            // Follow-back button for follow notifications
            if notif.type == .follow,
               !notif.actorID.isEmpty,
               notif.actorID != userSettings.userID,
               !followingIDs.contains(notif.actorID) {
                followBackButton(actorID: notif.actorID)
            }

            if !notif.isRead {
                Circle()
                    .fill(purpl)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(notif.isRead ? Color.clear : purpl.opacity(0.04))
    }

    @ViewBuilder
    private func followBackButton(actorID: String) -> some View {
        Button {
            Task { await followBack(actorID: actorID) }
        } label: {
            ZStack {
                Circle()
                    .fill(gold.opacity(0.15))
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(gold.opacity(0.45), lineWidth: 1))
                if followLoading.contains(actorID) {
                    ProgressView().scaleEffect(0.55).tint(gold)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(gold)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(followLoading.contains(actorID))
        .padding(.top, 4)
    }

    // MARK: - Avatar

    @ViewBuilder
    private func notifAvatar(_ notif: AppNotification) -> some View {
        ZStack {
            if notif.type == .leaderboard {
                Circle()
                    .fill(gold.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(gold.opacity(0.35), lineWidth: 1))
                Image(systemName: "crown.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(gold)
            } else if !notif.actorProfilePhotoURL.isEmpty,
                      let url = URL(string: notif.actorProfilePhotoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    default:
                        initialsCircle(notif)
                    }
                }
                .frame(width: 44, height: 44)
            } else {
                initialsCircle(notif)
            }

            // Type badge
            Circle()
                .fill(pageBg)
                .frame(width: 18, height: 18)
                .overlay {
                    Image(systemName: typeBadgeIcon(notif.type))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(typeBadgeColor(notif.type))
                }
                .offset(x: 14, y: 14)
        }
        .frame(width: 44, height: 44)
    }

    private func initialsCircle(_ notif: AppNotification) -> some View {
        Circle()
            .fill(purpl.opacity(0.25))
            .frame(width: 44, height: 44)
            .overlay {
                Text(String((notif.actorDisplayName.isEmpty ? notif.actorUsername : notif.actorDisplayName).prefix(1)).uppercased())
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(purpl)
            }
    }

    private func typeBadgeIcon(_ type: AppNotification.NotifType) -> String {
        switch type {
        case .follow:      return "person.badge.plus"
        case .rep:         return "hand.raised.fill"
        case .comment:     return "bubble.left.fill"
        case .leaderboard: return "crown.fill"
        }
    }

    private func typeBadgeColor(_ type: AppNotification.NotifType) -> Color {
        switch type {
        case .follow:      return Color(red: 0.35, green: 1.00, blue: 0.60)
        case .rep:         return Color(red: 1.00, green: 0.80, blue: 0.20)
        case .comment:     return Color(red: 0.65, green: 0.45, blue: 1.00)
        case .leaderboard: return Color(red: 1.00, green: 0.80, blue: 0.20)
        }
    }

    // MARK: - Actions

    private func loadNotifications() async {
        loading = true
        async let notifFetch   = InAppNotificationService.shared.fetch(userID: userSettings.userID)
        async let followFetch  = FollowService.shared.fetchFollowing(userID: userSettings.userID)
        notifications = (try? await notifFetch) ?? []
        if let entries = try? await followFetch {
            followingIDs = Set(entries.map { $0.userID })
        }
        loading = false
        // Mark all read after 1 second
        try? await Task.sleep(for: .seconds(1))
        await markAllRead()
    }

    private func markAllRead() async {
        try? await InAppNotificationService.shared.markAllRead(userID: userSettings.userID)
        for i in notifications.indices { notifications[i].isRead = true }
        notificationState.unreadCount = 0
    }

    private func followBack(actorID: String) async {
        guard !actorID.isEmpty, !userSettings.userID.isEmpty else { return }
        followLoading.insert(actorID)
        defer { followLoading.remove(actorID) }

        let actorProfile = try? await UserProfileService.shared.fetchProfile(userID: actorID)
        try? await FollowService.shared.followUser(
            currentUserID:          userSettings.userID,
            currentUsername:        userSettings.username,
            currentProfilePhotoURL: userSettings.profilePhotoURL,
            targetUserID:           actorID,
            targetUsername:         actorProfile?.username ?? "",
            targetProfilePhotoURL:  actorProfile?.profilePhotoURL ?? ""
        )
        followingIDs.insert(actorID)

        await InAppNotificationService.shared.sendFollow(
            to:               actorID,
            actorID:          userSettings.userID,
            actorUsername:    userSettings.username,
            actorDisplayName: userSettings.name,
            actorPhotoURL:    userSettings.profilePhotoURL
        )
    }

    // MARK: - Time formatter

    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60    { return "just now" }
        if seconds < 3600  { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}
