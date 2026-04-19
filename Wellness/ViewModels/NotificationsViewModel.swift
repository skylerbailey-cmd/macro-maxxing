//
//  NotificationsViewModel.swift
//  Wellness
//

import Foundation
import SwiftData

// MARK: - Grouped notification types

struct ActorSummary: Identifiable {
    let id: String           // actorID
    let username: String
    let displayName: String
    let photoURL: String

    var shortName: String {
        displayName.isEmpty ? username : displayName
    }
}

struct GroupedNotification: Identifiable {
    let id: String
    let kind: Kind
    let actors: [ActorSummary]
    let reactionTypes: Set<AppNotification.NotifType>
    let postID: String
    let postHeadline: String
    let isRead: Bool
    let newestDate: Date

    enum Kind {
        case single(AppNotification)
        case collapsed(count: Int)
    }

    /// Human-readable message for display.
    var message: String {
        switch kind {
        case .single(let n):
            return n.message
        case .collapsed(let count):
            let first = actors.first?.shortName ?? "Someone"
            if count == 2, let second = actors.dropFirst().first {
                return "\(first) and \(second.shortName) reacted to \"\(postHeadline)\""
            }
            let othersCount = count - 1
            return "\(first) and \(othersCount) \(othersCount == 1 ? "other" : "others") reacted to \"\(postHeadline)\""
        }
    }

    /// The primary notification for navigation/metadata.
    var representative: AppNotification? {
        switch kind {
        case .single(let n): return n
        case .collapsed: return nil
        }
    }
}

struct NotifSection: Identifiable {
    let id: String
    let title: String
    let items: [GroupedNotification]
}

// MARK: - ViewModel

@Observable @MainActor final class NotificationsViewModel {

    var notifications: [AppNotification] = []
    var loading: Bool = true
    var selectedFilter: AppNotification.NotifFilter = .all
    var followingIDs:   Set<String> = []
    var checkmarkedIDs: Set<String> = []
    var followLoading:  Set<String> = []

    /// Recent followers fetched from `users/{uid}/followers`, newest first.
    var recentFollowers: [FollowEntry] = []

    // MARK: - Computed sections

    var sections: [NotifSection] {
        let filtered: [AppNotification]
        if selectedFilter == .all {
            filtered = notifications
        } else {
            filtered = notifications.filter { $0.filterCategory == selectedFilter }
        }

        let grouped = groupNotifications(filtered)
        return partitionIntoSections(grouped)
    }

    var isEmpty: Bool {
        sections.allSatisfy { $0.items.isEmpty }
    }

    var hasUnread: Bool {
        notifications.contains { !$0.isRead }
    }

    // MARK: - Grouping

    private func groupNotifications(_ notifs: [AppNotification]) -> [GroupedNotification] {
        // Separate reactions from non-reactions
        var reactionBuckets: [String: [AppNotification]] = [:]
        var singles: [GroupedNotification] = []

        for n in notifs {
            if n.isReaction && !n.postID.isEmpty {
                reactionBuckets[n.postID, default: []].append(n)
            } else {
                let actor = ActorSummary(id: n.actorID, username: n.actorUsername,
                                         displayName: n.actorDisplayName, photoURL: n.actorProfilePhotoURL)
                singles.append(GroupedNotification(
                    id: n.id,
                    kind: .single(n),
                    actors: [actor],
                    reactionTypes: [n.type],
                    postID: n.postID,
                    postHeadline: n.postHeadline,
                    isRead: n.isRead,
                    newestDate: n.createdAt
                ))
            }
        }

        // Collapse reaction buckets
        for (postID, bucket) in reactionBuckets {
            let sorted = bucket.sorted { $0.createdAt > $1.createdAt }
            // Deduplicate actors (same person may rep + celebrate)
            var seenActors = Set<String>()
            var actors: [ActorSummary] = []
            for n in sorted {
                if seenActors.insert(n.actorID).inserted {
                    actors.append(ActorSummary(id: n.actorID, username: n.actorUsername,
                                               displayName: n.actorDisplayName, photoURL: n.actorProfilePhotoURL))
                }
            }
            let types = Set(sorted.map(\.type))
            let allRead = sorted.allSatisfy(\.isRead)
            let newest = sorted.first!.createdAt

            if sorted.count == 1 {
                singles.append(GroupedNotification(
                    id: sorted[0].id,
                    kind: .single(sorted[0]),
                    actors: actors,
                    reactionTypes: types,
                    postID: postID,
                    postHeadline: sorted[0].postHeadline,
                    isRead: allRead,
                    newestDate: newest
                ))
            } else {
                singles.append(GroupedNotification(
                    id: "group-\(postID)",
                    kind: .collapsed(count: actors.count),
                    actors: actors,
                    reactionTypes: types,
                    postID: postID,
                    postHeadline: sorted[0].postHeadline,
                    isRead: allRead,
                    newestDate: newest
                ))
            }
        }

        return singles.sorted { $0.newestDate > $1.newestDate }
    }

    // MARK: - Time sections

    private func partitionIntoSections(_ items: [GroupedNotification]) -> [NotifSection] {
        let cal = Calendar.current
        let now = Date()
        let startOfToday     = cal.startOfDay(for: now)
        let startOfYesterday = cal.date(byAdding: .day, value: -1, to: startOfToday)!
        let startOfWeek      = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!

        var today:     [GroupedNotification] = []
        var yesterday: [GroupedNotification] = []
        var thisWeek:  [GroupedNotification] = []
        var earlier:   [GroupedNotification] = []

        for item in items {
            if item.newestDate >= startOfToday {
                today.append(item)
            } else if item.newestDate >= startOfYesterday {
                yesterday.append(item)
            } else if item.newestDate >= startOfWeek {
                thisWeek.append(item)
            } else {
                earlier.append(item)
            }
        }

        var result: [NotifSection] = []
        if !today.isEmpty     { result.append(NotifSection(id: "today",     title: "Today",     items: today)) }
        if !yesterday.isEmpty { result.append(NotifSection(id: "yesterday", title: "Yesterday", items: yesterday)) }
        if !thisWeek.isEmpty  { result.append(NotifSection(id: "thisWeek",  title: "This Week", items: thisWeek)) }
        if !earlier.isEmpty   { result.append(NotifSection(id: "earlier",   title: "Earlier",   items: earlier)) }
        return result
    }

    // MARK: - Data loading

    func load(userID: String) async {
        loading = true
        async let notifFetch    = InAppNotificationService.shared.fetch(userID: userID)
        async let followFetch   = FollowService.shared.fetchFollowing(userID: userID)
        async let followerFetch = FollowService.shared.fetchFollowers(userID: userID)
        notifications = (try? await notifFetch) ?? []
        if let entries = try? await followFetch {
            followingIDs = Set(entries.map { $0.userID })
        }
        recentFollowers = (try? await followerFetch) ?? []
        loading = false
    }

    func markAllRead(userID: String, notificationState: NotificationState) async {
        try? await InAppNotificationService.shared.markAllRead(userID: userID)
        for i in notifications.indices { notifications[i].isRead = true }
        notificationState.unreadCount = 0
    }
}
