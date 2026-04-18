//
//  FeedView.swift
//  Wellness
//
//  Firebase-backed global social feed.
//

import SwiftUI

// MARK: - FeedView

struct FeedView: View {
    let userSettings: UserSettings

    @State private var viewModel        = FeedViewModel()
    @State private var followingIDs:    Set<String> = []
    @State private var blockedUserIDs:  Set<String> = []

    /// Single presentation state to avoid multiple .sheet/.fullScreenCover conflicts.
    private enum PostPresentation: Identifiable {
        case detail(FeedPost)
        case comment(FeedPost)
        case profile(FeedPost)

        var id: String {
            switch self {
            case .detail(let p):  return "detail-\(p.id)"
            case .comment(let p): return "comment-\(p.id)"
            case .profile(let p): return "profile-\(p.id)"
            }
        }
    }
    @State private var activePresentation: PostPresentation? = nil

    /// Tracked separately from `activePresentation` because share uses a
    /// standard .sheet (detents + easy dismiss) while detail/comment/profile
    /// use a fullScreenCover.
    @State private var postToShare: FeedPost? = nil

    var body: some View {
        ZStack {
            Color.pageBg.ignoresSafeArea()

            Group {
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    skeletonFeed
                } else if displayedPosts.isEmpty {
                    emptyState
                } else {
                    feedList
                }
            }

            // Error toast (bottom)
            if let err = viewModel.errorMessage {
                VStack {
                    Spacer()
                    errorToast(err)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationTitle("Aura Feed")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.posts.isEmpty { await viewModel.loadInitialFeed() }
            if let ids = try? await BlockService.shared.fetchBlockedUserIDs(userID: userSettings.userID) {
                blockedUserIDs = ids
            }
            if let entries = try? await FollowService.shared.fetchFollowing(userID: userSettings.userID) {
                followingIDs = Set(entries.map { $0.userID })
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage)
        .sheet(item: $postToShare) { post in
            PostShareView(post: post)
        }
        .fullScreenCover(item: $activePresentation) { presentation in
            NavigationStack {
                switch presentation {
                case .detail(let post):
                    FeedPostDetailView(post: post, currentUserSettings: userSettings,
                                       onCommentCountChanged: { delta in viewModel.updateCommentCount(postID: post.id, delta: delta) })
                case .comment(let post):
                    FeedPostDetailView(post: post, currentUserSettings: userSettings, focusComment: true,
                                       onCommentCountChanged: { delta in viewModel.updateCommentCount(postID: post.id, delta: delta) })
                case .profile(let post):
                    ProfileView(
                        profileUserID:       post.userID,
                        profileUsername:     post.username,
                        profileDisplayName:  post.whoName,
                        profileAuraLevel:    post.auraLevel,
                        profileAuraPoints:   post.auraPoints,
                        profileImageData:    nil,
                        currentUserSettings: userSettings,
                        isDismissable:       true,
                        profileIsPrivate:    !post.isPublic
                    )
                }
            }
        }
    }

    // MARK: - Feed list

    /// Extracted to a helper so the ForEach body stays simple enough for the Swift type-checker.
    private func postCard(for post: FeedPost) -> some View {
        let isOwnPost = post.userID == userSettings.userID
        let deleteAction: (() -> Void)? = isOwnPost
            ? { Task { await viewModel.deletePost(post) } }
            : nil
        let shareAction: (() -> Void)? = isOwnPost
            ? { postToShare = post }
            : nil
        return FeedPostCard(
            post:              post,
            currentUserID:     userSettings.userID,
            onRep:             { Task { await viewModel.toggleRep(postID: post.id, currentUserID: userSettings.userID) } },
            onCelebrate:       { Task { await viewModel.toggleCelebrate(postID: post.id, currentUserID: userSettings.userID) } },
            onZap:             { Task { await viewModel.addZap(postID: post.id, currentUserID: userSettings.userID) } },
            onDelete:          deleteAction,
            onShare:           shareAction,
            onTap:             { activePresentation = .detail(post) },
            onAvatarTap:       { activePresentation = .profile(post) },
            onCommentTap:      { activePresentation = .comment(post) },
            isFollowingAuthor: followingIDs.contains(post.userID),
            onFollowToggle:    { Task { await toggleFollowFromPost(post: post) } },
            onBlockUser:       { Task { await blockUserFromPost(post: post) } },
            onReportUser:      { Task { await reportUserFromPost(post: post) } },
            onReportPost:      { Task { await reportPostFromPost(post: post) } }
        )
    }

    private var displayedPosts: [FeedPost] {
        viewModel.posts.filter { !blockedUserIDs.contains($0.userID) }
    }

    private var feedList: some View {
        ScrollView {
            feedListStack
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    /// Extracted so the type-checker has a simpler expression per computed
    /// property. Was timing out when the scroll/transition modifiers + spring
    /// animation + conditional footers all lived inside the ScrollView body.
    private var feedListStack: some View {
        LazyVStack(spacing: 12) {
            ForEach(displayedPosts) { post in
                animatedPostCard(for: post)
            }

            if viewModel.isLoading && !viewModel.posts.isEmpty {
                ProgressView()
                    .tint(Color.purpleHi)
                    .padding(.vertical, 20)
                    .transition(.opacity)
            }

            if !viewModel.hasMore && !viewModel.posts.isEmpty {
                Text("You've seen it all 💪")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.25))
                    .padding(.vertical, 20)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 40)
        // Spring whenever the displayed list mutates — refresh, new post
        // via the live listener, a block removing someone's posts, or an
        // own delete. Keyed off IDs so identical reorderings don't replay.
        .animation(
            .spring(response: 0.45, dampingFraction: 0.78),
            value: displayedPosts.map(\.id)
        )
    }

    /// One post card wrapped in a 3D tilt-in animation. Each card starts
    /// tilted 25° away and faded out, then springs flat + fully opaque when
    /// it enters the viewport. In a LazyVStack the view is recreated each
    /// time it scrolls into the lazy-loading window, so the animation
    /// replays reliably — no `.scrollTransition` phase magic needed.
    private func animatedPostCard(for post: FeedPost) -> some View {
        postCard(for: post)
            .scrollTransition(axis: .vertical) { content, phase in
                let tiltDegrees: Double = {
                    switch phase {
                    case .topLeading:     return -45
                    case .identity:       return 0
                    case .bottomTrailing: return 45
                    }
                }()
                return content
                    .opacity(phase.isIdentity ? 1 : 0.15)
                    .scaleEffect(phase.isIdentity ? 1 : 0.88)
                    .offset(y: phase.isIdentity ? 0 : (phase == .bottomTrailing ? 40 : -40))
                    .rotation3DEffect(
                        .degrees(tiltDegrees),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: phase == .bottomTrailing ? .top : .bottom,
                        perspective: 0.8
                    )
            }
            .onAppear {
                Task { await viewModel.loadMoreIfNeeded(currentPost: post) }
            }
    }

    // MARK: - Post menu actions

    private func toggleFollowFromPost(post: FeedPost) async {
        if followingIDs.contains(post.userID) {
            try? await FollowService.shared.unfollowUser(
                currentUserID: userSettings.userID, targetUserID: post.userID)
            followingIDs.remove(post.userID)
        } else {
            try? await FollowService.shared.followUser(
                currentUserID:          userSettings.userID,
                currentUsername:        userSettings.username,
                currentDisplayName:     userSettings.name,
                currentProfilePhotoURL: userSettings.profilePhotoURL,
                targetUserID:           post.userID,
                targetUsername:         post.username,
                targetDisplayName:      post.whoName,
                targetProfilePhotoURL:  post.userProfilePhotoURL)
            followingIDs.insert(post.userID)
        }
    }

    private func blockUserFromPost(post: FeedPost) async {
        try? await BlockService.shared.blockUser(
            currentUserID:         userSettings.userID,
            targetUserID:          post.userID,
            targetUsername:         post.username,
            targetDisplayName:     post.whoName,
            targetProfilePhotoURL: post.userProfilePhotoURL)
        blockedUserIDs.insert(post.userID)
        followingIDs.remove(post.userID)
    }

    private func reportUserFromPost(post: FeedPost) async {
        try? await BlockService.shared.reportUser(
            reporterID: userSettings.userID, reportedUserID: post.userID)
    }

    private func reportPostFromPost(post: FeedPost) async {
        try? await BlockService.shared.reportPost(
            postID: post.id, reporterID: userSettings.userID)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 52))
                .foregroundStyle(.white.opacity(0.12))

            Text("No posts yet")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.35))

            Text("Be the first to share a meal.\nPost from the Fuel Log after scanning your food.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.22))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                Task { await viewModel.loadInitialFeed() }
            } label: {
                Text("Retry")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.purpleHi)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Skeleton

    private var skeletonFeed: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in SkeletonCard() }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Error toast

    private func errorToast(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(2)
            Spacer()
            Button { viewModel.errorMessage = nil } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.50))
            }
        }
        .padding(14)
        .background(Color(red: 0.18, green: 0.06, blue: 0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.red.opacity(0.30), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.40), radius: 10)
    }
}

// MARK: - Feed Post Card

struct FeedPostCard: View {
    let post:          FeedPost
    let currentUserID: String
    let onRep:         () -> Void
    var onCelebrate:   (() -> Void)? = nil
    var onZap:         (() -> Void)? = nil
    var onDelete:      (() -> Void)? = nil
    var onShare:       (() -> Void)? = nil
    var onTap:         (() -> Void)? = nil
    var onAvatarTap:   (() -> Void)? = nil
    var onCommentTap:  (() -> Void)? = nil
    var showStreak:         Bool          = true
    var isFollowingAuthor: Bool          = false
    var onFollowToggle:    (() -> Void)? = nil
    var onBlockUser:       (() -> Void)? = nil
    var onReportUser:      (() -> Void)? = nil
    var onReportPost:      (() -> Void)? = nil

    @State private var showBlockConfirm      = false
    @State private var showReportUserConfirm = false
    @State private var showReportPostConfirm = false
    @State private var showDeleteConfirm     = false
    @State private var repBurstTrigger       = 0
    @State private var celebrateBurst        = false
    @State private var zapBurst              = false
    @State private var expandedWorkoutID: String? = nil
    @State private var showPhotoViewer       = false
    @State private var photoViewerIndex      = 0

    private let cardBg   = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var purpleHi: Color { post.themeColor }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            authorHeader
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 12)

            foodPhoto

            VStack(alignment: .leading, spacing: 10) {
                titleRow
                if !post.caption.isEmpty {
                    captionView(post.caption)
                }
                if !post.fuelLogItems.isEmpty {
                    fuelLogTable
                } else if !post.workoutItems.isEmpty {
                    workoutTable
                } else if !post.mogBoardSnapshot.isEmpty {
                    mogBoardSnapshotCard
                } else if post.postLabel == "Goal" {
                    MacroDisciplineCard(
                        totalCalories: Double(post.calories),  goalCalories: Double(post.goalCalories > 0 ? post.goalCalories : 2000),
                        totalProtein:  post.protein,           goalProtein:  post.goalProtein > 0  ? post.goalProtein  : 150,
                        totalCarbs:    post.carbs,             goalCarbs:    post.goalCarbs   > 0  ? post.goalCarbs    : 200,
                        totalFat:      post.fat,               goalFat:      post.goalFat     > 0  ? post.goalFat      : 65
                    )
                }
                if post.currentWeight > 0, post.goalWeight > 0 {
                    GoalWeightBadge(currentWeight: post.currentWeight, goalWeight: post.goalWeight)
                }
                actionRow
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 14)
        }
        .background(cardBg)
        .cornerRadius(16)
        .overlay(alignment: .topTrailing) {
            postMenu
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .alert("Block @\(post.username)?", isPresented: $showBlockConfirm) {
            Button("Block", role: .destructive) { onBlockUser?() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("They won't be able to see your posts and you won't see theirs.")
        }
        .alert("Report @\(post.username)?", isPresented: $showReportUserConfirm) {
            Button("Report", role: .destructive) { onReportUser?() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This user will be flagged for review.")
        }
        .alert("Delete this post?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { onDelete?() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This can't be undone. The post will be removed from everyone's feed.")
        }
        .alert("Report this post?", isPresented: $showReportPostConfirm) {
            Button("Report", role: .destructive) { onReportPost?() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This post will be flagged for review.")
        }
    }

    // MARK: Author header

    private var authorHeader: some View {
        HStack(spacing: 10) {
            // Avatar (tappable → profile)
            Button { onAvatarTap?() } label: {
                CachedAsyncImage(
                    url: URL(string: post.userProfilePhotoURL),
                    content: { image in
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 38, height: 38)
                            .clipShape(Circle())
                    },
                    placeholder: { initialCircle(size: 38, name: post.whoName) }
                )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(post.whoName.isEmpty ? post.username : post.whoName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    if post.isProSubscriber {
                        Text("PRO")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 1.00, green: 0.80, blue: 0.20),
                                             Color(red: 1.00, green: 0.65, blue: 0.10)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                    }

                    if post.auraPoints > 0 {
                        Text("⭐ Lv \(post.auraLevel)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(ThemeStore.shared.accent)
                    }

                    if showStreak && post.streak > 0 {
                        FlickerStreakBadge(streak: post.streak)
                    }

                    if let label = PostLabel(rawValue: post.postLabel) {
                        let labelColor = label.color
                        HStack(spacing: 3) {
                            Image(systemName: label.icon)
                                .font(.system(size: 8, weight: .bold))
                            if label == .mogBoard, !post.mogBoardScope.isEmpty {
                                Text("\(post.mogBoardScope) Mog")
                                    .font(.system(size: 9, weight: .bold))
                            } else {
                                Text(label.rawValue)
                                    .font(.system(size: 9, weight: .bold))
                            }
                        }
                        .foregroundStyle(labelColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(labelColor.opacity(0.15), in: Capsule())
                        .overlay(Capsule().stroke(labelColor.opacity(0.35), lineWidth: 0.75))
                    }
                }

                HStack(spacing: 4) {
                    Text("@\(post.username)")
                    Text("·")
                    Text(timeAgo(from: post.createdAtDate ?? Date()))
                    if !post.locationName.isEmpty {
                        Text("·")
                        Image(systemName: "location.fill")
                            .font(.system(size: 8))
                        Text(post.locationName)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.35))
            }

            Spacer()
        }
    }

    // MARK: Food photo

    @ViewBuilder
    private var foodPhoto: some View {
        let urls = post.allPhotoURLs
        if !urls.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(Array(urls.enumerated()), id: \.offset) { idx, urlString in
                        CachedAsyncImage(
                            url: URL(string: urlString),
                            content: { image in
                                image.resizable()
                                    .scaledToFill()
                                    .frame(
                                        width:  urls.count == 1 ? UIScreen.main.bounds.width : 260,
                                        height: urls.count == 1 ? nil : 260
                                    )
                                    .clipped()
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        photoViewerIndex = idx
                                        showPhotoViewer = true
                                    }
                            },
                            placeholder: { photoPlaceholder(loading: true) }
                        )
                    }
                }
            }
            .scrollDisabled(urls.count == 1)
            .fullScreenCover(isPresented: $showPhotoViewer) {
                PhotoViewerSheet(urls: urls, initialIndex: photoViewerIndex)
            }
        }
    }

    private func photoPlaceholder(loading: Bool) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .overlay {
                if loading {
                    ProgressView().tint(.white.opacity(0.30))
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.15))
                }
            }
    }

    // MARK: Title + meal type badge

    private var titleRow: some View {
        HStack(spacing: 8) {
            // Extract food name from "MealType: FoodName" title
            let parts  = post.title.split(separator: ":", maxSplits: 1).map(String.init)
            let meal   = parts.count > 1 ? parts[0].trimmingCharacters(in: .whitespaces) : ""
            let name   = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : post.title

            Text(name)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            if !meal.isEmpty {
                Text(meal)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(purpleHi)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(purpleHi.opacity(0.12))
                    .cornerRadius(6)
            }
        }
    }

    // MARK: Caption

    private func captionView(_ caption: String) -> some View {
        Text(caption)
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.70))
            .lineLimit(3)
    }

    // MARK: Mog Board snapshot card

    private var mogBoardSnapshotEntries: [MogBoardSnapshotEntry] {
        guard !post.mogBoardSnapshot.isEmpty,
              let data = post.mogBoardSnapshot.data(using: .utf8),
              let entries = try? JSONDecoder().decode([MogBoardSnapshotEntry].self, from: data)
        else { return [] }
        return entries
    }

    @ViewBuilder
    private var mogBoardSnapshotCard: some View {
        let gold    = post.themeColor
        let entries = mogBoardSnapshotEntries
        let scoreLabel: String = {
            switch post.mogBoardType {
            case "Streak":     return "days"
            case "Engagement": return "score"
            default:           return "pts"
            }
        }()

        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "list.number")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(gold)
                Text(post.mogBoardType.isEmpty ? "Board" : post.mogBoardType)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(gold)
                Spacer()
                Text(scoreLabel.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.30))
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 6)

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            VStack(spacing: 0) {
                ForEach(Array(entries.prefix(5).enumerated()), id: \.element.id) { rank, entry in
                    HStack(spacing: 8) {
                        Text("#\(rank + 1)")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(rank == 0 ? gold : .white.opacity(0.30))
                            .frame(width: 26, alignment: .trailing)
                        Text(entry.displayName.isEmpty ? "@\(entry.username)" : entry.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                        Spacer()
                        Text("\(entry.score)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(rank == 0 ? gold : .white.opacity(0.55))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(rank == 0 ? gold.opacity(0.07) : Color.clear)
                }
            }
            .padding(.vertical, 4)
        }
        .background(Color.cardBg)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(gold.opacity(0.20), lineWidth: 1))
    }

    // MARK: Workout table

    // Follows the post's label color when one is set (so a "Workout" labeled
    // post uses the workout-label green), otherwise the app accent.
    private var workoutGreen: Color { post.themeColor }

    @ViewBuilder
    private var workoutTable: some View {
        let sorted   = post.workoutItems.sorted { $0.sortOrder < $1.sortOrder }
        let totalCal = sorted.reduce(0) { $0 + $1.caloriesBurned }
        let totalMin = sorted.reduce(0) { $0 + $1.durationMinutes }
        let totalTime = totalMin >= 60 ? "\(totalMin / 60)h \(totalMin % 60)m" : "\(totalMin)m"
        VStack(alignment: .leading, spacing: 0) {
            ForEach(sorted) { item in
                workoutRow(item: item, isLast: item.id == sorted.last?.id)
            }
            if sorted.count > 1 {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                HStack {
                    Spacer()
                    Text("Total: \(totalTime) · \(totalCal) cal burned")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(workoutGreen.opacity(0.80))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
        }
        .background(Color.cardBg)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(workoutGreen.opacity(0.20), lineWidth: 1))
    }

    private func workoutRow(item: FeedWorkoutItem, isLast: Bool) -> some View {
        let icon      = WorkoutType(rawValue: item.workoutType)?.icon ?? "figure.mixed.cardio"
        let typeLabel = WorkoutType(rawValue: item.workoutType)?.shortLabel ?? item.workoutType
        let isExpanded = expandedWorkoutID == item.id
        let hasExercises = !item.exercises.isEmpty
        return VStack(spacing: 0) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(workoutGreen.opacity(0.12))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundStyle(workoutGreen)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.workoutName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.90))
                        .lineLimit(1)
                    Text("\(item.formattedDuration) · \(typeLabel)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.40))
                    if !item.gymName.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 9, weight: .semibold))
                            Text(item.gymName)
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(workoutGreen.opacity(0.80))
                    }
                    if !item.taggedFriends.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 9, weight: .semibold))
                            Text(item.taggedFriends.map { "@\($0.username)" }.joined(separator: ", "))
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(workoutGreen.opacity(0.80))
                    }
                }
                Spacer()
                HStack(spacing: 6) {
                    Text("\(item.caloriesBurned) cal")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(workoutGreen)
                    if hasExercises {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(workoutGreen.opacity(0.70))
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .animation(.spring(duration: 0.3), value: isExpanded)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                guard hasExercises else { return }
                withAnimation(.spring(duration: 0.35)) {
                    expandedWorkoutID = isExpanded ? nil : item.id
                }
            }

            if isExpanded && hasExercises {
                workoutExerciseList(item.exercises)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if !isLast {
                Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1).padding(.horizontal, 10)
            }
        }
    }

    private func workoutExerciseList(_ exercises: [Exercise]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(workoutGreen.opacity(0.12)).frame(height: 1)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(exercises) { exercise in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(workoutGreen.opacity(0.25))
                            .frame(width: 6, height: 6)
                            .padding(.top, 5)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                            Text(exerciseSetsLabel(exercise))
                                .font(.system(size: 11))
                                .foregroundStyle(workoutGreen.opacity(0.70))
                        }
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }

    private func exerciseSetsLabel(_ exercise: Exercise) -> String {
        let setCount = exercise.sets.count
        guard setCount > 0 else { return "" }
        if exercise.hasUniformSets, let first = exercise.sets.first {
            let weightStr = first.weight.map { w in
                w.truncatingRemainder(dividingBy: 1) == 0
                    ? "\(Int(w)) lb"
                    : "\(w) lb"
            } ?? "bodyweight"
            return "\(setCount) × \(first.reps) reps · \(weightStr)"
        } else {
            return exercise.sets.enumerated().map { i, s in
                let weightStr = s.weight.map { w in
                    w.truncatingRemainder(dividingBy: 1) == 0
                        ? "\(Int(w)) lb"
                        : "\(w) lb"
                } ?? "BW"
                return "Set \(i + 1): \(s.reps) × \(weightStr)"
            }.joined(separator: "  ·  ")
        }
    }

    // MARK: Fuel log table

    private var fuelLogTable: some View {
        let sorted    = post.fuelLogItems.sorted { $0.sortOrder < $1.sortOrder }
        let purpl     = post.themeColor
        let totalCal  = sorted.reduce(0.0) { $0 + $1.calories }
        let totalPro  = sorted.reduce(0.0) { $0 + $1.protein  }
        let totalCarb = sorted.reduce(0.0) { $0 + $1.carbs    }
        let totalFat  = sorted.reduce(0.0) { $0 + $1.fat      }
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(sorted) { item in
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        if !item.photoURL.isEmpty, let url = URL(string: item.photoURL) {
                            CachedAsyncImage(
                                url: url,
                                content: { img in
                                    img.resizable().scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipped().cornerRadius(8)
                                },
                                placeholder: {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.07))
                                        .frame(width: 40, height: 40)
                                        .overlay {
                                            Image(systemName: "fork.knife")
                                                .font(.system(size: 14))
                                                .foregroundStyle(.white.opacity(0.30))
                                        }
                                }
                            )
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.07))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white.opacity(0.30))
                                }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.foodName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("\(Int(item.calories)) kcal · \(Int(item.protein))g P · \(Int(item.carbs))g C · \(Int(item.fat))g F")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    if item.id != sorted.last?.id {
                        Divider().background(Color.white.opacity(0.08))
                    }
                }
            }
            Divider().background(purpl.opacity(0.40)).padding(.top, 4)
            HStack(spacing: 6) {
                Text("Total")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                macroTotalLine(cal: Int(totalCal), pro: Int(totalPro),
                               carb: Int(totalCarb), fat: Int(totalFat))
            }
            .padding(.top, 8)
        }
    }

    /// Fuel-log "Total" line rendered as per-macro colored segments
    /// (orange / blue / mint / rose) separated by dim dots. Keeps each
    /// macro visually tied to the KPI color used throughout the app
    /// rather than a single accent tint.
    private func macroTotalLine(cal: Int, pro: Int, carb: Int, fat: Int) -> some View {
        HStack(spacing: 4) {
            Text("\(cal) kcal")
                .foregroundStyle(Color.calClr)
            Text("·").foregroundStyle(.white.opacity(0.30))
            Text("\(pro)g P")
                .foregroundStyle(Color.proClr)
            Text("·").foregroundStyle(.white.opacity(0.30))
            Text("\(carb)g C")
                .foregroundStyle(Color.carbClr)
            Text("·").foregroundStyle(.white.opacity(0.30))
            Text("\(fat)g F")
                .foregroundStyle(Color.fatClr)
        }
        .font(.caption.weight(.semibold))
    }

    // MARK: Macro row

    private var macroRow: some View {
        HStack(spacing: 6) {
            macroBadge(value: "\(post.calories)",     unit: "kcal", color: Color.calClr)
            macroBadge(value: "\(Int(post.protein))", unit: "P",    color: Color.proClr)
            macroBadge(value: "\(Int(post.carbs))",   unit: "C",    color: Color.carbClr)
            macroBadge(value: "\(Int(post.fat))",     unit: "F",    color: Color.fatClr)

            Spacer()

            // Goal progress ring (when goal is set)
            if post.goalCalories > 0 {
                goalRing
            }
        }
    }

    private func macroBadge(value: String, unit: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(unit)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color.opacity(0.65))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color.opacity(0.10))
        .cornerRadius(8)
    }

    private var goalRing: some View {
        let pct = min(Double(post.calories) / Double(max(post.goalCalories, 1)), 1.0)
        let met = pct >= 0.85 && pct <= 1.15
        return ZStack {
            Circle()
                .stroke(.white.opacity(0.08), lineWidth: 3)
                .frame(width: 26, height: 26)
            Circle()
                .trim(from: 0, to: pct)
                .stroke(met ? Color.calClr : Color.calClr.opacity(0.50), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 26, height: 26)
                .rotationEffect(.degrees(-90))
            if met {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.calClr)
            }
        }
    }

    // MARK: Action row (reps + celebrate + comments)

    private var actionRow: some View {
        HStack(spacing: 16) {
            Spacer()

            // 💪 Rep button
            Button {
                if !post.hasRepped(userID: currentUserID) {
                    repBurstTrigger += 1
                }
                onRep()
            } label: {
                HStack(spacing: 5) {
                    Text("💪")
                        .font(.system(size: 15))
                    Text("\(post.reps)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(
                            post.hasRepped(userID: currentUserID)
                                ? Color(red: 1.0, green: 0.75, blue: 0.2)
                                : .white.opacity(0.35)
                        )
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(post.hasRepped(userID: currentUserID) ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: post.hasRepped(userID: currentUserID))
            .overlay {
                Text("💪")
                    .font(.system(size: 28))
                    .keyframeAnimator(
                        initialValue: RepBurstKeyframe(),
                        trigger: repBurstTrigger
                    ) { content, value in
                        content
                            .scaleEffect(value.scale)
                            .opacity(value.opacity)
                            .offset(y: value.offset)
                    } keyframes: { _ in
                        KeyframeTrack(\.scale) {
                            SpringKeyframe(1.8, duration: 0.15, spring: .bouncy)
                            SpringKeyframe(2.4, duration: 0.65)
                        }
                        KeyframeTrack(\.opacity) {
                            LinearKeyframe(1.0, duration: 0.1)
                            LinearKeyframe(1.0, duration: 0.35)
                            LinearKeyframe(0.0, duration: 0.4)
                        }
                        KeyframeTrack(\.offset) {
                            SpringKeyframe(-10, duration: 0.15)
                            SpringKeyframe(-80, duration: 0.7)
                        }
                    }
                    .allowsHitTesting(false)
            }

            // 🎉 Celebrate button
            let isCelebrated = post.hasCelebrated(userID: currentUserID)
            Button {
                if !isCelebrated { celebrateBurst = true }
                onCelebrate?()
            } label: {
                HStack(spacing: 5) {
                    Text("🎉")
                        .font(.system(size: 15))
                    Text("\(post.celebrates)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(
                            isCelebrated
                                ? Color(red: 1.0, green: 0.55, blue: 0.85)
                                : .white.opacity(0.35)
                        )
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(isCelebrated ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCelebrated)
            .overlay {
                if celebrateBurst {
                    CelebrateBurstView {
                        celebrateBurst = false
                    }
                    .allowsHitTesting(false)
                }
            }

            // ⚡ Zap button
            let isZapped = post.hasZapped(userID: currentUserID)
            let zapYellow = Color(red: 1.0, green: 0.85, blue: 0.05)
            Button {
                zapBurst = true
                onZap?()
            } label: {
                HStack(spacing: 4) {
                    Text("⚡")
                        .font(.system(size: 13))
                    Text("\(post.zaps)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isZapped ? zapYellow : .white.opacity(0.45))
                }
            }
            .buttonStyle(.plain)
            .overlay(alignment: .top) {
                if zapBurst {
                    LightningUpView { zapBurst = false }
                        .allowsHitTesting(false)
                        .offset(y: -110) // shift up so canvas bottom sits at button top
                }
            }

            // 💬 Comment count (tappable → open detail with comment focused)
            Button { onCommentTap?() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 13))
                    Text("\(post.commentsCount)")
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.30))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Post menu (three-dot)

    @ViewBuilder
    private var postMenu: some View {
        Menu {
            if post.userID == currentUserID {
                if onDelete != nil {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete Post", systemImage: "trash")
                    }
                }
                if onShare != nil {
                    Button {
                        onShare?()
                    } label: {
                        Label("Share Post", systemImage: "square.and.arrow.up")
                    }
                }
            } else {
                Button {
                    onFollowToggle?()
                } label: {
                    Label(
                        isFollowingAuthor ? "Unfollow @\(post.username)" : "Follow @\(post.username)",
                        systemImage: isFollowingAuthor ? "person.badge.minus" : "person.badge.plus"
                    )
                }
                Divider()
                Button(role: .destructive) {
                    showReportPostConfirm = true
                } label: {
                    Label("Report Post", systemImage: "flag")
                }
                Button(role: .destructive) {
                    showReportUserConfirm = true
                } label: {
                    Label("Report @\(post.username)", systemImage: "exclamationmark.bubble")
                }
                Button(role: .destructive) {
                    showBlockConfirm = true
                } label: {
                    Label("Block @\(post.username)", systemImage: "hand.raised")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.07), in: Circle())
        }
        .padding(8)
    }

    // MARK: Helpers

    private func initialCircle(size: CGFloat, name: String) -> some View {
        Circle()
            .fill(ThemeStore.shared.accent.opacity(0.22))
            .frame(width: size, height: size)
            .overlay {
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                    .foregroundStyle(ThemeStore.shared.accent)
            }
    }

    private func timeAgo(from date: Date) -> String {
        let s = Int(Date().timeIntervalSince(date))
        switch s {
        case ..<60:       return "just now"
        case 60..<3600:   return "\(s / 60)m"
        case 3600..<86400: return "\(s / 3600)h"
        case 86400..<604800: return "\(s / 86400)d"
        default:          return "\(s / 604800)w"
        }
    }
}

// MARK: - Macro Discipline Card (shared by feed + post detail)

struct MacroDisciplineCard: View {
    let totalCalories: Double; let goalCalories:  Double
    let totalProtein:  Double; let goalProtein:   Double
    let totalCarbs:    Double; let goalCarbs:     Double
    let totalFat:      Double; let goalFat:       Double

    private var purpl: Color { ThemeStore.shared.accent }
    private let neon   = Color(red: 0.35, green: 1.00, blue: 0.60)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)

    // Slot-machine animation triggers — start at false, flip to true
    // staggered on appear so bars grow and digits roll one-by-one.
    @State private var showDiscipline = false
    @State private var showRow: [Bool] = [false, false, false, false]

    private var disciplineProgress: Double {
        let pairs = [(totalCalories, goalCalories), (totalProtein, goalProtein),
                     (totalCarbs, goalCarbs), (totalFat, goalFat)]
        let active = pairs.filter { $0.1 > 0 }
        guard !active.isEmpty else { return 0 }
        return active.reduce(0.0) { $0 + max(0, 1.0 - abs($1.0 / $1.1 - 1.0)) } / Double(active.count)
    }

    var body: some View {
        let animDiscipline = showDiscipline ? disciplineProgress : 0
        let pct = Int((animDiscipline * 100 / 5).rounded()) * 5
        let macros: [(String, Double, Double, String, Color)] = [
            ("Calories", totalCalories, goalCalories, "kcal", Color.calClr),
            ("Protein",  totalProtein,  goalProtein,  "g",    Color.proClr),
            ("Carbs",    totalCarbs,    goalCarbs,    "g",    Color.carbClr),
            ("Fat",      totalFat,      goalFat,      "g",    Color.fatClr),
        ]
        VStack(spacing: 10) {
            // Overall discipline bar
            HStack(spacing: 0) {
                Text("DISCIPLINE")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.40))
                Spacer()
                HStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08)).frame(height: 5)
                            Capsule()
                                .fill(LinearGradient(
                                    colors: animDiscipline >= 1.0
                                        ? [neon, Color(red: 0.20, green: 0.85, blue: 0.50)]
                                        : [purpl, Color(red: 0.35, green: 0.75, blue: 1.00)],
                                    startPoint: .leading, endPoint: .trailing))
                                .frame(width: showDiscipline ? max(4, geo.size.width * animDiscipline) : 0, height: 5)
                        }
                    }
                    .frame(width: 80, height: 5)
                    Text("\(pct)%")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(animDiscipline >= 1.0 ? neon : purpl)
                        .fixedSize()
                        .frame(minWidth: 38, alignment: .trailing)
                        .contentTransition(.numericText())
                }
            }
            Divider().background(purpl.opacity(0.15))
            // Per-macro target-zone bars — each animates with a staggered delay
            ForEach(Array(macros.enumerated()), id: \.offset) { idx, macro in
                let (label, total, goal, unit, color) = macro
                let shown = idx < showRow.count && showRow[idx]
                TargetZoneRow(
                    label: label, total: total, goal: goal,
                    unit: unit, color: color, shown: shown
                )
            }
        }
        .padding(14)
        .background(cardBg)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(purpl.opacity(0.20), lineWidth: 1))
        .onAppear {
            guard !showDiscipline else { return }
            // Discipline bar leads, then each macro row staggers in
            withAnimation(.easeOut(duration: 0.7).delay(0.15)) {
                showDiscipline = true
            }
            for i in 0..<min(4, showRow.count) {
                withAnimation(.easeOut(duration: 0.7).delay(0.3 + Double(i) * 0.12)) {
                    showRow[i] = true
                }
            }
        }
    }
}

// MARK: - Goal Weight Badge

struct GoalWeightBadge: View {
    let currentWeight: Double
    let goalWeight: Double

    private var phase: String {
        let diff = goalWeight - currentWeight
        if diff > 2      { return "Bulking" }
        else if diff < -2 { return "Cutting" }
        else              { return "Maintaining" }
    }

    private var phaseIcon: String {
        switch phase {
        case "Bulking":     return "arrow.up.circle.fill"
        case "Cutting":     return "arrow.down.circle.fill"
        default:            return "equal.circle.fill"
        }
    }

    private var phaseColor: Color {
        switch phase {
        case "Bulking":     return Color(red: 0.30, green: 0.90, blue: 0.55)
        case "Cutting":     return Color(red: 1.00, green: 0.40, blue: 0.40)
        default:            return Color(red: 0.65, green: 0.45, blue: 1.00)
        }
    }

    private func fmt(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(w))"
            : String(format: "%.1f", w)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: phaseIcon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(phaseColor)

            Text(phase.uppercased())
                .font(.system(size: 11, weight: .black))
                .tracking(1.2)
                .foregroundStyle(phaseColor)

            Spacer()

            HStack(spacing: 4) {
                Text("\(fmt(currentWeight)) lbs")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Image(systemName: "arrow.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.35))
                Text("\(fmt(goalWeight)) lbs")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(phaseColor)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(red: 0.11, green: 0.11, blue: 0.14))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(phaseColor.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Target Zone Row
//
// Horizontal bar with a highlighted "zone" (85%–115% of goal) and three tick
// marks: min, target, max. A colored indicator dot shows current intake.
// The bar spans 0 → 130% of goal so overshoot is visible but capped.

private struct TargetZoneRow: View {
    let label: String
    let total: Double
    let goal:  Double
    let unit:  String
    let color: Color
    let shown: Bool

    // Zone boundaries as fractions of goal
    private let minFrac:   Double = 0.85
    private let maxFrac:   Double = 1.15
    private let floorFrac: Double = 0.60
    private let capFrac:   Double = 1.30
    private var rangeFrac: Double { capFrac - floorFrac }

    /// Maps a goal-fraction to a 0…1 bar position.
    private func barX(_ frac: Double) -> Double {
        max(0, min(1, (frac - floorFrac) / rangeFrac))
    }

    private var intakeFrac: Double {
        guard goal > 0 else { return 0 }
        return shown ? min(total / goal, capFrac) : floorFrac
    }

    private var inZone: Bool {
        guard goal > 0 else { return false }
        let pct = total / goal
        return pct >= minFrac && pct <= maxFrac
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label + value
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
                Text("\(Int(total)) / \(Int(goal)) \(unit)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(inZone && shown ? color : .white.opacity(0.45))
            }

            // Bar
            GeometryReader { geo in
                let w = geo.size.width
                let zoneStartX = barX(minFrac) * w
                let zoneEndX   = barX(maxFrac) * w
                let indicatorX = barX(intakeFrac) * w

                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 8)

                    // Target zone highlight (85%–115%)
                    Capsule()
                        .fill(color.opacity(shown ? 0.18 : 0))
                        .frame(width: zoneEndX - zoneStartX, height: 8)
                        .offset(x: zoneStartX)

                    // Tick marks: min, target, max
                    tickMark(at: minFrac, width: w)
                    tickMark(at: 1.0,     width: w)
                    tickMark(at: maxFrac,  width: w)

                    // Current intake indicator — upward triangle below the bar
                    TriangleIndicator()
                        .fill(color)
                        .frame(width: 10, height: 8)
                        .shadow(color: inZone && shown ? color.opacity(0.60) : .clear, radius: 4)
                        .offset(x: shown ? indicatorX - 5 : -5, y: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.72), value: intakeFrac)
                }
            }
            .frame(height: 20)

            // Min / Target / Max labels below the bar
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Text("min")
                        .offset(x: max(0, barX(minFrac) * w - 8))
                    Text("target")
                        .offset(x: max(0, barX(1.0) * w - 14))
                    Text("max")
                        .offset(x: min(w - 16, barX(maxFrac) * w - 8))
                }
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.white.opacity(0.25))
            }
            .frame(height: 10)
        }
    }

    private func tickMark(at frac: Double, width: CGFloat) -> some View {
        let x = barX(frac) * width
        return Rectangle()
            .fill(Color.white.opacity(shown ? 0.30 : 0))
            .frame(width: 1, height: 14)
            .offset(x: x - 0.5, y: -3)
    }
}

// MARK: - Triangle Indicator Shape

/// Upward-pointing triangle whose tip touches the bar above.
private struct TriangleIndicator: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to:    CGPoint(x: rect.midX, y: rect.minY))  // tip (top center)
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))  // bottom-left
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))  // bottom-right
            p.closeSubpath()
        }
    }
}

// MARK: - Rep burst keyframe state

/// Drives the floating 💪 keyframe animation on FeedPostCard.
/// Initial values are all zero (invisible). When `repBurstTrigger`
/// increments, the keyframes run: pop in → grow → float up → fade out,
/// then the animator returns to these initial values (invisible again).
private struct RepBurstKeyframe {
    var scale:   CGFloat = 0
    var opacity: Double  = 0
    var offset:  CGFloat = 0
}

// MARK: - Skeleton card

private struct SkeletonCard: View {
    @State private var opacity: Double = 0.4

    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Author row
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 5) {
                    Capsule().fill(Color.white.opacity(0.12)).frame(width: 120, height: 10)
                    Capsule().fill(Color.white.opacity(0.08)).frame(width: 80,  height: 8)
                }
                Spacer()
            }
            .padding(14)

            // Photo placeholder
            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(maxWidth: .infinity)
                .frame(height: 220)

            // Text rows
            VStack(alignment: .leading, spacing: 8) {
                Capsule().fill(Color.white.opacity(0.10)).frame(width: 160, height: 11)
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 60, height: 26)
                    }
                }
                HStack {
                    Spacer()
                    Capsule().fill(Color.white.opacity(0.08)).frame(width: 80, height: 9)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(cardBg)
        .cornerRadius(16)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                opacity = 0.85
            }
        }
    }
}

// MARK: - Flicker Streak Badge

/// Animated 🔥 streak badge — the flame emoji gently pulses in opacity and
/// scale to look like it's flickering. Lightweight: just two looping
/// animations on the emoji, no timers or state machines.
private struct FlickerStreakBadge: View {
    let streak: Int

    @State private var flicker = false

    private let flame = Color(red: 1.0, green: 0.60, blue: 0.20)

    var body: some View {
        HStack(spacing: 2) {
            Text("🔥")
                .font(.system(size: 10))
                .scaleEffect(flicker ? 1.18 : 0.92)
                .opacity(flicker ? 1.0 : 0.7)
                .animation(
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true),
                    value: flicker
                )
            Text("\(streak)d streak")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(flame)
        }
        .onAppear { flicker = true }
    }
}

// MARK: - Lightning Up View
//
// Real jagged lightning bolts drawn with Canvas path strokes shoot upward
// from the ⚡ button on tap. Two layers — a wide blurred glow and a sharp
// white core — create an electric discharge effect. A small fork branches
// off the main bolt for realism.

private struct LightningUpView: View {
    var onComplete: () -> Void

    @State private var opacity: Double = 1.0

    // All bolt segments. Origin (0,0) = bottom-center of the 90×110 canvas.
    // Negative y = upward. Coordinates are relative offsets from bottom-center.
    private let segments: [[(CGFloat, CGFloat)]] = [
        // Main center bolt — tall, strong zigzag
        [(0,0), (-14,-22), (10,-44), (-9,-66), (12,-90)],
        // Left branch — fans upper-left
        [(0,0), (-20,-22), (-34,-44), (-26,-66)],
        // Right branch — fans upper-right
        [(0,0), (18,-24), (32,-46), (24,-68)],
        // Small fork off main bolt at the (-9,-66) junction
        [(-9,-66), (-22,-80), (-16,-96)],
    ]

    var body: some View {
        ZStack {
            // Glow layer — wide blurred yellow strokes
            lightningCanvas(lineWidth: 7, color: Color(red: 1.0, green: 0.92, blue: 0.15), alpha: 0.75)
                .blur(radius: 6)
            // Core layer — thin white-yellow strokes on top
            lightningCanvas(lineWidth: 2, color: Color(red: 1.0, green: 0.97, blue: 0.70), alpha: 1.0)
        }
        .frame(width: 90, height: 110)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.55).delay(0.04)) { opacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { onComplete() }
        }
    }

    private func lightningCanvas(lineWidth: CGFloat, color: Color, alpha: Double) -> some View {
        Canvas { ctx, size in
            let ox = size.width / 2   // origin x = horizontal center
            let oy = size.height      // origin y = bottom of canvas

            for seg in segments {
                guard seg.count >= 2 else { continue }
                var path = Path()
                path.move(to: CGPoint(x: ox + seg[0].0, y: oy + seg[0].1))
                for pt in seg.dropFirst() {
                    path.addLine(to: CGPoint(x: ox + pt.0, y: oy + pt.1))
                }
                ctx.stroke(
                    path,
                    with: .color(color.opacity(alpha)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }
}

// MARK: - Card Tilt-In Animation
//
// MARK: - Celebrate Burst
//
// Mini confetti explosion that fires outward from the 🎉 button when a user
// taps it. 12 tiny colored circles shoot out in random directions, fade, and
// shrink, then the view calls `onComplete` to remove itself.

private struct CelebrateBurstView: View {
    var onComplete: () -> Void

    private struct Particle: Identifiable {
        let id = UUID()
        let color: Color
        let angle: Double   // radians
        let distance: CGFloat
        let size: CGFloat
    }

    @State private var fired = false
    @State private var particles: [Particle] = []

    private static let colors: [Color] = [
        .yellow, .orange, .pink, .purple,
        Color(red: 0.35, green: 0.75, blue: 1.00),
        Color(red: 0.40, green: 0.90, blue: 0.72),
        Color(red: 1.00, green: 0.50, blue: 0.72),
    ]

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size)
                    .offset(
                        x: fired ? cos(p.angle) * p.distance : 0,
                        y: fired ? sin(p.angle) * p.distance : 0
                    )
                    .opacity(fired ? 0 : 1)
                    .scaleEffect(fired ? 0.3 : 1.2)
            }
        }
        .onAppear {
            particles = (0..<12).map { _ in
                Particle(
                    color:    Self.colors.randomElement()!,
                    angle:    Double.random(in: 0 ..< .pi * 2),
                    distance: CGFloat.random(in: 45...85),
                    size:     CGFloat.random(in: 6...12)
                )
            }
            withAnimation(.easeOut(duration: 0.55)) {
                fired = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                onComplete()
            }
        }
    }
}

// MARK: - Photo Viewer (full-screen zoom)

struct PhotoViewerSheet: View {
    let urls:         [String]
    let initialIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var scale:        CGFloat = 1
    @State private var offset:       CGSize  = .zero
    @State private var lastOffset:   CGSize  = .zero
    @GestureState private var pinchScale: CGFloat = 1

    init(urls: [String], initialIndex: Int = 0) {
        self.urls         = urls
        self.initialIndex = initialIndex
        _currentIndex     = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(urls.enumerated()), id: \.offset) { idx, urlString in
                    zoomableImage(urlString: urlString)
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: urls.count > 1 ? .always : .never))
            .onChange(of: currentIndex) { _, _ in
                // Reset zoom when swiping to another photo
                scale      = 1
                offset     = .zero
                lastOffset = .zero
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
            }
            .padding(.top, 56)
            .padding(.trailing, 20)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func zoomableImage(urlString: String) -> some View {
        CachedAsyncImage(
            url: URL(string: urlString),
            content: { image in
                image.resizable()
                    .scaledToFit()
                    .scaleEffect(max(1, scale * pinchScale))
                    .offset(scale > 1 ? offset : .zero)
                    .gesture(
                        MagnificationGesture()
                            .updating($pinchScale) { value, state, _ in state = value }
                            .onEnded { value in
                                let newScale = scale * value
                                scale = max(1, min(newScale, 6))
                                if scale == 1 { offset = .zero; lastOffset = .zero }
                            }
                    )
                    .simultaneousGesture(
                        scale > 1 ? DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width:  lastOffset.width  + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in lastOffset = offset }
                        : nil
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(duration: 0.3)) {
                            if scale > 1 { scale = 1; offset = .zero; lastOffset = .zero }
                            else         { scale = 3 }
                        }
                    }
            },
            placeholder: {
                ProgressView().tint(.white.opacity(0.5))
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

