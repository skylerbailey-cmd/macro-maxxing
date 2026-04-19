//
//  NotificationsView.swift
//  Wellness
//

import SwiftUI
import SwiftData

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

    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = NotificationsViewModel()

    // Navigation
    @State private var selectedPost:  SocialPost? = nil
    @State private var loadingPostID: String?      = nil
    @State private var viewingActor:  ActorData?   = nil

    private struct ActorData: Identifiable {
        let id: String
        let username: String
        let displayName: String
        let photoURL: String
    }

    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var purpl: Color { ThemeStore.shared.accent }

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()

                if viewModel.loading {
                    ProgressView()
                        .tint(purpl)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.notifications.isEmpty && viewModel.recentFollowers.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        filterBar
                        ScrollView {
                            VStack(spacing: 0) {
                                // New followers section
                                if !viewModel.recentFollowers.isEmpty,
                                   viewModel.selectedFilter == .all || viewModel.selectedFilter == .social {
                                    newFollowersSection
                                }
                                // Notification list inline
                                notificationListContent
                            }
                            .padding(.bottom, 40)
                        }
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
                if viewModel.hasUnread {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Mark all read") {
                            Task { await viewModel.markAllRead(userID: userSettings.userID, notificationState: notificationState) }
                        }
                        .font(.subheadline)
                        .foregroundStyle(purpl)
                    }
                }
            }
        }
        .task {
            await viewModel.load(userID: userSettings.userID)
            // Auto mark-read after a short delay
            try? await Task.sleep(for: .seconds(1))
            await viewModel.markAllRead(userID: userSettings.userID, notificationState: notificationState)
        }
        .sheet(item: $selectedPost) { post in
            NavigationStack {
                PostDetailView(post: post, userSettings: userSettings)
            }
        }
        .sheet(item: $viewingActor) { actor in
            NavigationStack {
                ProfileView(
                    profileUserID:       actor.id,
                    profileUsername:     actor.username,
                    profileDisplayName:  actor.displayName,
                    profileAuraLevel:    0,
                    profileAuraPoints:   0,
                    profileImageData:    nil,
                    currentUserSettings: userSettings,
                    isDismissable:       true
                )
            }
        }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(AppNotification.NotifFilter.allCases, id: \.self) { filter in
                let selected = viewModel.selectedFilter == filter
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        viewModel.selectedFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selected ? .white : .white.opacity(0.50))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(selected ? purpl : cardBg)
                        )
                        .overlay(
                            Capsule()
                                .stroke(selected ? Color.clear : Color.white.opacity(0.08), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Notification list

    @ViewBuilder
    private var notificationListContent: some View {
        if viewModel.isEmpty {
            filterEmptyState
        } else {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(viewModel.sections) { section in
                    Section {
                        ForEach(section.items) { item in
                            notifRow(item)
                            if item.id != section.items.last?.id {
                                Divider()
                                    .background(Color.white.opacity(0.06))
                                    .padding(.leading, 70)
                            }
                        }
                    } header: {
                        sectionHeader(section.title)
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.40))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(pageBg)
    }

    private var filterEmptyState: some View {
        VStack(spacing: 12) {
            let label: String = switch viewModel.selectedFilter {
            case .all:       "No notifications yet"
            case .reactions: "No reactions yet"
            case .social:    "No social activity yet"
            case .activity:  "No activity yet"
            }
            Text(label)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    // MARK: - New Followers Section

    @State private var showAllFollowers = false

    private var newFollowersSection: some View {
        let followGreen = Color(red: 0.35, green: 1.00, blue: 0.60)
        let followers = viewModel.recentFollowers.filter { $0.userID != userSettings.userID }
        let displayed = showAllFollowers ? followers : Array(followers.prefix(5))

        return VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(followGreen)
                Text("New Followers")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(followers.count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.40))
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Follower rows
            ForEach(displayed) { follower in
                followerRow(follower)
                if follower.id != displayed.last?.id {
                    Divider()
                        .background(Color.white.opacity(0.06))
                        .padding(.leading, 70)
                }
            }

            // Show more / less
            if followers.count > 5 {
                Button {
                    withAnimation(.spring(duration: 0.25)) { showAllFollowers.toggle() }
                } label: {
                    Text(showAllFollowers ? "Show less" : "Show all \(followers.count) followers")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(purpl)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .background(cardBg)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(followGreen.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func followerRow(_ follower: FollowEntry) -> some View {
        let followGreen = Color(red: 0.35, green: 1.00, blue: 0.60)
        let name = follower.displayName?.isEmpty == false ? follower.displayName! : follower.username
        let alreadyFollowing = viewModel.followingIDs.contains(follower.userID)

        HStack(spacing: 12) {
            // Avatar (tappable → profile)
            Button {
                viewingActor = ActorData(
                    id: follower.userID,
                    username: follower.username,
                    displayName: follower.displayName ?? follower.username,
                    photoURL: follower.profilePhotoURL
                )
            } label: {
                if !follower.profilePhotoURL.isEmpty,
                   let url = URL(string: follower.profilePhotoURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        default:
                            initialsCircle(name: name)
                                .frame(width: 40, height: 40)
                        }
                    }
                    .frame(width: 40, height: 40)
                } else {
                    initialsCircle(name: name)
                        .frame(width: 40, height: 40)
                }
            }
            .buttonStyle(.plain)

            // Name + username + time
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text("@\(follower.username)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.40))
                    if follower.followedAtDate != .distantPast {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.25))
                        Text(timeAgo(from: follower.followedAtDate))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
            }

            Spacer()

            // Follow-back / already following
            if viewModel.checkmarkedIDs.contains(follower.userID) {
                // Just followed — show checkmark
                ZStack {
                    Circle()
                        .fill(followGreen.opacity(0.15))
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(followGreen.opacity(0.45), lineWidth: 1))
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(followGreen)
                }
                .transition(.scale.combined(with: .opacity))
            } else if alreadyFollowing {
                Text("Following")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
            } else {
                Button {
                    Task { await followBack(actorID: follower.userID) }
                } label: {
                    HStack(spacing: 4) {
                        if viewModel.followLoading.contains(follower.userID) {
                            ProgressView().scaleEffect(0.55).tint(.white)
                        } else {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 10, weight: .bold))
                        }
                        Text("Follow")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(followGreen, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.followLoading.contains(follower.userID))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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
            Text("You'll see follows, reps, comments, workout tags,\nleaderboard placements, and new posts here.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.28))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Row

    @ViewBuilder
    private func notifRow(_ group: GroupedNotification) -> some View {
        let isPostNotif = !group.postID.isEmpty
        let canViewProfile: Bool = {
            if case .single(let n) = group.kind {
                return n.type != .leaderboard && !n.actorID.isEmpty
            }
            return !group.actors.isEmpty
        }()

        HStack(alignment: .top, spacing: 0) {
            // Unread accent bar
            RoundedRectangle(cornerRadius: 1.5)
                .fill(group.isRead ? Color.clear : purpl)
                .frame(width: 3)
                .padding(.vertical, 4)
                .padding(.trailing, 11)

            // Avatar(s)
            Button {
                guard canViewProfile, let actor = group.actors.first else { return }
                viewingActor = ActorData(id: actor.id, username: actor.username,
                                          displayName: actor.displayName, photoURL: actor.photoURL)
            } label: {
                avatarView(for: group)
            }
            .buttonStyle(.plain)
            .disabled(!canViewProfile)
            .padding(.trailing, 14)

            VStack(alignment: .leading, spacing: 4) {
                messageText(for: group)

                // Reaction type pills for collapsed groups
                if case .collapsed = group.kind, group.reactionTypes.count > 0 {
                    reactionPills(group.reactionTypes)
                }

                Text(timeAgo(from: group.newestDate))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))
            }

            Spacer()

            // Follow-back button
            if case .single(let n) = group.kind,
               n.type == .follow,
               !n.actorID.isEmpty,
               n.actorID != userSettings.userID,
               !viewModel.followingIDs.contains(n.actorID) {
                if viewModel.checkmarkedIDs.contains(n.actorID) {
                    followCheckmark
                } else {
                    followBackButton(actorID: n.actorID)
                }
            }

            if loadingPostID == group.postID {
                ProgressView().scaleEffect(0.65).tint(purpl).padding(.top, 4)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 16)
        .padding(.vertical, 14)
        .background(group.isRead ? Color.clear : purpl.opacity(0.04))
        .contentShape(Rectangle())
        .onTapGesture {
            guard isPostNotif else { return }
            Task { await openPost(group.postID) }
        }
    }

    // MARK: - Message text

    @ViewBuilder
    private func messageText(for group: GroupedNotification) -> some View {
        switch group.kind {
        case .single(let n):
            Text(n.message)
                .font(.system(size: 14, weight: group.isRead ? .regular : .semibold))
                .foregroundStyle(group.isRead ? .white.opacity(0.70) : .white)
                .fixedSize(horizontal: false, vertical: true)

        case .collapsed(let count):
            let headline = group.postHeadline.isEmpty ? "your post" : "\"\(group.postHeadline)\""
            if count == 2, group.actors.count >= 2 {
                (Text(group.actors[0].shortName).bold() +
                 Text(" and ") +
                 Text(group.actors[1].shortName).bold() +
                 Text(" reacted to \(headline)"))
                    .font(.system(size: 14, weight: group.isRead ? .regular : .medium))
                    .foregroundStyle(group.isRead ? .white.opacity(0.70) : .white)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                let othersCount = count - 1
                (Text(group.actors.first?.shortName ?? "Someone").bold() +
                 Text(" and \(othersCount) \(othersCount == 1 ? "other" : "others") reacted to \(headline)"))
                    .font(.system(size: 14, weight: group.isRead ? .regular : .medium))
                    .foregroundStyle(group.isRead ? .white.opacity(0.70) : .white)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Reaction type pills

    private func reactionPills(_ types: Set<AppNotification.NotifType>) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(types).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { type in
                Text(reactionEmoji(type))
                    .font(.system(size: 11))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(reactionColor(type).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }

    private func reactionEmoji(_ type: AppNotification.NotifType) -> String {
        switch type {
        case .rep:       return "💪"
        case .celebrate: return "🎉"
        case .zap:       return "⚡"
        default:         return ""
        }
    }

    private func reactionColor(_ type: AppNotification.NotifType) -> Color {
        switch type {
        case .rep:       return Color(red: 1.0, green: 0.75, blue: 0.2)
        case .celebrate: return Color(red: 1.0, green: 0.55, blue: 0.85)
        case .zap:       return Color(red: 1.0, green: 0.85, blue: 0.05)
        default:         return .white
        }
    }

    // MARK: - Avatar

    @ViewBuilder
    private func avatarView(for group: GroupedNotification) -> some View {
        if case .single(let n) = group.kind {
            singleAvatar(n)
        } else if group.actors.count >= 2 {
            stackedAvatars(group.actors, badgeTypes: group.reactionTypes)
        } else if let actor = group.actors.first {
            let fallbackNotif = AppNotification(
                type: group.reactionTypes.first ?? .rep,
                actorID: actor.id, actorUsername: actor.username,
                actorDisplayName: actor.displayName,
                actorProfilePhotoURL: actor.photoURL, message: "")
            singleAvatar(fallbackNotif)
        }
    }

    private func singleAvatar(_ notif: AppNotification) -> some View {
        ZStack {
            if notif.type == .leaderboard {
                Circle()
                    .fill(purpl.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(purpl.opacity(0.35), lineWidth: 1))
                Image(systemName: "crown.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(purpl)
            } else if !notif.actorProfilePhotoURL.isEmpty,
                      let url = URL(string: notif.actorProfilePhotoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    default:
                        initialsCircle(name: notif.actorDisplayName.isEmpty ? notif.actorUsername : notif.actorDisplayName)
                    }
                }
                .frame(width: 44, height: 44)
            } else {
                initialsCircle(name: notif.actorDisplayName.isEmpty ? notif.actorUsername : notif.actorDisplayName)
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

    private func stackedAvatars(_ actors: [ActorSummary], badgeTypes: Set<AppNotification.NotifType>) -> some View {
        ZStack {
            // Show up to 3 overlapping circles
            let capped = Array(actors.prefix(3))
            ForEach(Array(capped.enumerated()), id: \.element.id) { idx, actor in
                smallAvatar(actor)
                    .offset(x: CGFloat(idx) * 14 - 7)
                    .zIndex(Double(capped.count - idx))
            }
            if actors.count > 3 {
                ZStack {
                    Circle()
                        .fill(cardBg)
                        .frame(width: 24, height: 24)
                    Text("+\(actors.count - 3)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.60))
                }
                .offset(x: CGFloat(3) * 14 - 7)
                .zIndex(0)
            }
        }
        .frame(width: 44, height: 44)
    }

    private func smallAvatar(_ actor: ActorSummary) -> some View {
        Group {
            if !actor.photoURL.isEmpty, let url = URL(string: actor.photoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(pageBg, lineWidth: 2))
                    default:
                        smallInitialsCircle(actor.shortName)
                    }
                }
                .frame(width: 28, height: 28)
            } else {
                smallInitialsCircle(actor.shortName)
            }
        }
    }

    private func smallInitialsCircle(_ name: String) -> some View {
        Circle()
            .fill(purpl.opacity(0.25))
            .frame(width: 28, height: 28)
            .overlay(Circle().stroke(pageBg, lineWidth: 2))
            .overlay {
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(purpl)
            }
    }

    private func initialsCircle(name: String) -> some View {
        Circle()
            .fill(purpl.opacity(0.25))
            .frame(width: 44, height: 44)
            .overlay {
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(purpl)
            }
    }

    // MARK: - Follow-back

    private var followCheckmark: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.35, green: 1.00, blue: 0.60).opacity(0.15))
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(Color(red: 0.35, green: 1.00, blue: 0.60).opacity(0.45), lineWidth: 1))
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(Color(red: 0.35, green: 1.00, blue: 0.60))
        }
        .transition(.scale.combined(with: .opacity))
        .padding(.top, 4)
    }

    @ViewBuilder
    private func followBackButton(actorID: String) -> some View {
        Button {
            Task { await followBack(actorID: actorID) }
        } label: {
            ZStack {
                Circle()
                    .fill(purpl.opacity(0.15))
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(purpl.opacity(0.45), lineWidth: 1))
                if viewModel.followLoading.contains(actorID) {
                    ProgressView().scaleEffect(0.55).tint(purpl)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(purpl)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.followLoading.contains(actorID))
        .padding(.top, 4)
    }

    // MARK: - Badge helpers

    private func typeBadgeIcon(_ type: AppNotification.NotifType) -> String {
        switch type {
        case .follow:      return "person.badge.plus"
        case .rep:         return "hand.raised.fill"
        case .celebrate:   return "party.popper.fill"
        case .zap:         return "bolt.fill"
        case .comment:     return "bubble.left.fill"
        case .mention:     return "at"
        case .leaderboard: return "crown.fill"
        case .newPost:     return "bell.fill"
        case .workoutTag:  return "figure.strengthtraining.traditional"
        }
    }

    private func typeBadgeColor(_ type: AppNotification.NotifType) -> Color {
        switch type {
        case .follow:      return Color(red: 0.35, green: 1.00, blue: 0.60)
        case .rep:         return ThemeStore.shared.accent
        case .celebrate:   return Color(red: 1.00, green: 0.55, blue: 0.85)
        case .zap:         return Color(red: 1.00, green: 0.85, blue: 0.05)
        case .comment:     return ThemeStore.shared.accent
        case .mention:     return Color(red: 1.00, green: 0.80, blue: 0.20)
        case .leaderboard: return ThemeStore.shared.accent
        case .newPost:     return Color(red: 1.00, green: 0.60, blue: 0.20)
        case .workoutTag:  return Color(red: 0.30, green: 0.90, blue: 0.55)
        }
    }

    // MARK: - Post navigation

    private func openPost(_ postID: String) async {
        guard !postID.isEmpty else { return }
        loadingPostID = postID
        defer { loadingPostID = nil }

        let descriptor = FetchDescriptor<SocialPost>(
            predicate: #Predicate { $0.firebasePostID == postID }
        )
        if let local = (try? modelContext.fetch(descriptor))?.first {
            selectedPost = local
            return
        }

        guard let feed = try? await PostService.shared.fetchPost(postID: postID) else { return }
        let post = makeSocialPost(from: feed)
        modelContext.insert(post)
        selectedPost = post
    }

    private func makeSocialPost(from feed: FeedPost) -> SocialPost {
        let post = SocialPost(
            authorID:          feed.userID,
            authorUsername:    feed.username,
            authorDisplayName: feed.whoName,
            memeEmoji:         "",
            memeHeadline:      feed.title,
            memeSub:           feed.caption,
            macroDate:         feed.macroDateDate ?? Date(),
            totalCalories:     Double(feed.calories),
            goalCalories:      Double(feed.goalCalories),
            totalProtein:      feed.protein,   goalProtein:  feed.goalProtein,
            totalCarbs:        feed.carbs,     goalCarbs:    feed.goalCarbs,
            totalFat:          feed.fat,       goalFat:      feed.goalFat
        )
        post.firebasePostID       = feed.postID ?? ""
        post.postedAt             = feed.createdAtDate ?? Date()
        post.repsCount            = feed.reps
        post.reppedByRaw          = feed.reppedBy.joined(separator: ",")
        post.postLabel            = feed.postLabel
        post.fastingWindowDisplay = feed.fastingWindowDisplay
        post.mogBoardScope        = feed.mogBoardScope
        post.mogBoardType         = feed.mogBoardType
        post.authorAuraLevel      = feed.auraLevel
        post.authorAuraPoints     = feed.auraPoints
        post.authorAuraTitle      = feed.auraTitle
        post.authorStreak         = feed.streak
        post.authorLocation       = feed.locationName
        post.authorLatitude       = feed.latitude
        post.authorLongitude      = feed.longitude
        post.isAuthorPrivate      = !feed.isPublic
        return post
    }

    // MARK: - Actions

    private func followBack(actorID: String) async {
        guard !actorID.isEmpty, !userSettings.userID.isEmpty else { return }
        viewModel.followLoading.insert(actorID)
        defer { viewModel.followLoading.remove(actorID) }

        let actorProfile = try? await UserProfileService.shared.fetchProfile(userID: actorID, includePrivateFields: false)
        try? await FollowService.shared.followUser(
            currentUserID:          userSettings.userID,
            currentUsername:        userSettings.username,
            currentDisplayName:     userSettings.name.isEmpty ? nil : userSettings.name,
            currentProfilePhotoURL: userSettings.profilePhotoURL,
            targetUserID:           actorID,
            targetUsername:         actorProfile?.username ?? "",
            targetDisplayName:      actorProfile?.name.isEmpty == false ? actorProfile?.name : nil,
            targetProfilePhotoURL:  actorProfile?.profilePhotoURL ?? ""
        )
        withAnimation(.easeInOut(duration: 0.2)) { viewModel.checkmarkedIDs.insert(actorID) }

        await InAppNotificationService.shared.sendFollow(
            to:               actorID,
            actorID:          userSettings.userID,
            actorUsername:    userSettings.username,
            actorDisplayName: userSettings.name,
            actorPhotoURL:    userSettings.profilePhotoURL
        )

        try? await Task.sleep(for: .seconds(2.5))
        withAnimation(.easeOut(duration: 0.2)) {
            viewModel.checkmarkedIDs.remove(actorID)
            viewModel.followingIDs.insert(actorID)
        }
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
