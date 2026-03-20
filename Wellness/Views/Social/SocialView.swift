//
//  SocialView.swift
//  Wellness
//

import SwiftUI
import SwiftData
import CoreLocation

// MARK: - Color palette

private extension Color {
    static let pageBg   = Color(red: 0.07, green: 0.05, blue: 0.12)
    static let cardBg   = Color(red: 0.13, green: 0.10, blue: 0.22)
    static let purpleHi = Color(red: 0.65, green: 0.45, blue: 1.00)
}

// MARK: - SocialView

struct SocialView: View {
    let userSettings: UserSettings

    @Environment(LocationManager.self) private var locationManager
    @Environment(NotificationState.self) private var notificationState
    /// Firestore-loaded set of userIDs the current user follows.
    @State private var followingIDs: Set<String> = []
    /// Intersection of followingIDs and followerIDs — mutual friends.
    @State private var friendIDs: Set<String> = []

    @State private var showingTutorial   = false
    @State private var tutorialAnchors:  [String: Anchor<CGRect>] = [:]
    @State private var showingNewPost    = false
    @State private var selectedFeed:     Feed        = .arena
    @State private var showingOwnProfile = false
    @State private var showingSearch     = false
    @State private var showingNotifications = false
    @State private var labelFilter:      PostLabel?  = nil

    /// Firestore-backed Arena feed.
    @State private var arenaViewModel = FeedViewModel()

    /// Firestore-backed Team feed state.
    @State private var teamFirestorePosts: [FeedPost] = []
    @State private var teamLoading:        Bool        = false
    @State private var teamError:          String?     = nil

    /// Firestore-backed Following feed state.
    @State private var followingFirestorePosts: [FeedPost] = []
    @State private var followingLoading:        Bool        = false
    @State private var followingError:          String?     = nil

    /// Firestore-backed Local feed state.
    @State private var localFirestorePosts: [FeedPost] = []
    @State private var localLoading:        Bool        = false
    @State private var localError:          String?     = nil

    /// Selected Firestore post for detail sheet.
    @State private var selectedFeedPost:  FeedPost? = nil
    @State private var commentFeedPost:   FeedPost? = nil
    @State private var profileFeedPost:   FeedPost? = nil

    enum Feed: String, CaseIterable {
        case team      = "Team"
        case following = "Following"
        case local     = "Local"
        case arena     = "Arena"
    }

    /// Label-filtered view of the Firestore Team feed.
    private var teamDisplayed: [FeedPost] {
        guard let filter = labelFilter else { return teamFirestorePosts }
        return teamFirestorePosts.filter { $0.postLabel == filter.rawValue }
    }

    /// Label-filtered view of the Firestore Following feed.
    private var followingDisplayed: [FeedPost] {
        guard let filter = labelFilter else { return followingFirestorePosts }
        return followingFirestorePosts.filter { $0.postLabel == filter.rawValue }
    }

    /// Label-filtered view of the Firestore Arena feed.
    private var arenaDisplayed: [FeedPost] {
        guard let filter = labelFilter else { return arenaViewModel.posts }
        return arenaViewModel.posts.filter { $0.postLabel == filter.rawValue }
    }

    private static let localRadiusMeters: Double = 160_934 // 100 miles

    /// Distance-filtered + label-filtered view of the Firestore Local feed.
    private var localDisplayed: [FeedPost] {
        guard let coord = locationManager.coordinate else { return [] }
        let userLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)

        let nearby = localFirestorePosts.filter { post in
            if post.userID == userSettings.userID { return true }
            guard post.isPublic else { return false }
            guard post.latitude != 0 || post.longitude != 0 else { return false }
            return CLLocation(latitude: post.latitude, longitude: post.longitude)
                .distance(from: userLoc) <= Self.localRadiusMeters
        }

        var authorDist: [String: Double] = [:]
        for post in nearby {
            guard authorDist[post.userID] == nil else { continue }
            authorDist[post.userID] = post.userID == userSettings.userID ? 0 :
                CLLocation(latitude: post.latitude, longitude: post.longitude).distance(from: userLoc)
        }
        let top500 = Set(authorDist.sorted { $0.value < $1.value }.prefix(500).map(\.key))
        let filtered = nearby.filter { top500.contains($0.userID) }

        guard let filter = labelFilter else { return filtered }
        return filtered.filter { $0.postLabel == filter.rawValue }
    }

    var body: some View {
        ZStack {
            Color.pageBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header (nav bar is hidden)
                HStack {
                    Text("Aura Stream")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    HStack(spacing: 14) {
                        Button { showingTutorial = true } label: {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 20))
                                .foregroundStyle(.white.opacity(0.65))
                        }
                        .buttonStyle(.plain)
                        BellButton(showingNotifications: $showingNotifications, notificationState: notificationState)
                        Button { showingOwnProfile = true } label: {
                            socialProfileAvatarIcon
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .tutorialAnchor("feed.header")

                HStack(spacing: 0) {
                    ForEach(Feed.allCases, id: \.self) { feed in
                        Button { selectedFeed = feed } label: {
                            Text(feed.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(selectedFeed == feed ? .black : .white.opacity(0.55))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule().fill(selectedFeed == feed
                                        ? Color(red: 1.00, green: 0.80, blue: 0.20)
                                        : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(duration: 0.2), value: selectedFeed)
                    }
                }
                .padding(4)
                .background(Capsule().fill(Color.cardBg))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .tutorialAnchor("feed.scopePicker")
                .onAppear {
                    if selectedFeed == .local { locationManager.requestLocationIfNeeded() }
                }
                .onChange(of: selectedFeed) { _, feed in
                    switch feed {
                    case .local:
                        locationManager.requestLocationIfNeeded()
                        if localFirestorePosts.isEmpty { Task { await loadLocalFeed() } }
                    case .team:
                        if teamFirestorePosts.isEmpty { Task { await loadTeamFeed() } }
                    case .following:
                        if followingFirestorePosts.isEmpty { Task { await loadFollowingFeed() } }
                    case .arena:
                        break
                    }
                }

                // Label filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        filterChip(label: nil)
                        ForEach(PostLabel.allCases, id: \.self) { label in
                            filterChip(label: label)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
                .tutorialAnchor("feed.labelChips")

                if selectedFeed == .arena {
                    // ── Firestore-backed Arena feed ──────────────────────────
                    if userSettings.isPrivateAccount {
                        privateAccountBanner
                    }
                    if arenaViewModel.isLoading && arenaViewModel.posts.isEmpty {
                        arenaSkeletonFeed
                    } else if let err = arenaViewModel.errorMessage {
                        arenaErrorView(err)
                    } else if arenaDisplayed.isEmpty {
                        emptyFeed
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(arenaDisplayed) { post in
                                    FeedPostCard(
                                        post:          post,
                                        currentUserID: userSettings.userID,
                                        onRep:        { Task { await arenaViewModel.toggleRep(postID: post.id, currentUserID: userSettings.userID) } },
                                        onDelete:     post.userID == userSettings.userID ? { Task { await arenaViewModel.deletePost(post) } } : nil,
                                        onTap:        { selectedFeedPost = post },
                                        onAvatarTap:  { profileFeedPost  = post },
                                        onCommentTap: { commentFeedPost  = post }
                                    )
                                    .onAppear { Task { await arenaViewModel.loadMoreIfNeeded(currentPost: post) } }
                                }
                                if arenaViewModel.isLoading && !arenaViewModel.posts.isEmpty {
                                    ProgressView().tint(Color.purpleHi).padding(.vertical, 20)
                                }
                                if !arenaViewModel.hasMore && !arenaViewModel.posts.isEmpty {
                                    Text("You've seen it all 💪")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.25))
                                        .padding(.vertical, 20)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 40)
                        }
                        .refreshable {
                            await arenaViewModel.refresh()
                            await notificationState.refresh(userID: userSettings.userID)
                        }
                    }
                } else if selectedFeed == .local {
                    // ── Firestore-backed Local feed ──────────────────────────
                    if userSettings.isPrivateAccount {
                        privateAccountBanner
                    }
                    if localLoading && localFirestorePosts.isEmpty {
                        arenaSkeletonFeed
                    } else if let err = localError {
                        arenaErrorView(err)
                    } else if localDisplayed.isEmpty {
                        emptyFeed
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(localDisplayed) { post in
                                    FeedPostCard(
                                        post:          post,
                                        currentUserID: userSettings.userID,
                                        onRep:        { Task { await arenaViewModel.toggleRep(postID: post.id, currentUserID: userSettings.userID) } },
                                        onDelete:     post.userID == userSettings.userID ? { Task { await arenaViewModel.deletePost(post) } } : nil,
                                        onTap:        { selectedFeedPost = post },
                                        onAvatarTap:  { profileFeedPost  = post },
                                        onCommentTap: { commentFeedPost  = post }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 40)
                        }
                        .refreshable {
                            await loadLocalFeed()
                            await notificationState.refresh(userID: userSettings.userID)
                        }
                    }
                } else if selectedFeed == .team {
                    // ── Firestore-backed Team feed ────────────────────────────
                    if teamLoading && teamFirestorePosts.isEmpty {
                        arenaSkeletonFeed
                    } else if let err = teamError {
                        arenaErrorView(err)
                    } else if teamDisplayed.isEmpty {
                        emptyFeed
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(teamDisplayed) { post in
                                    FeedPostCard(
                                        post:          post,
                                        currentUserID: userSettings.userID,
                                        onRep:        { Task { await arenaViewModel.toggleRep(postID: post.id, currentUserID: userSettings.userID) } },
                                        onDelete:     post.userID == userSettings.userID ? { Task { await arenaViewModel.deletePost(post) } } : nil,
                                        onTap:        { selectedFeedPost = post },
                                        onAvatarTap:  { profileFeedPost  = post },
                                        onCommentTap: { commentFeedPost  = post }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 40)
                        }
                        .refreshable {
                            await loadFollowingIDs()
                            await loadTeamFeed()
                            await notificationState.refresh(userID: userSettings.userID)
                        }
                    }
                } else {
                    // ── Firestore-backed Following feed ───────────────────────
                    if followingLoading && followingFirestorePosts.isEmpty {
                        arenaSkeletonFeed
                    } else if let err = followingError {
                        arenaErrorView(err)
                    } else if followingDisplayed.isEmpty {
                        emptyFeed
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(followingDisplayed) { post in
                                    FeedPostCard(
                                        post:          post,
                                        currentUserID: userSettings.userID,
                                        onRep:        { Task { await arenaViewModel.toggleRep(postID: post.id, currentUserID: userSettings.userID) } },
                                        onDelete:     post.userID == userSettings.userID ? { Task { await arenaViewModel.deletePost(post) } } : nil,
                                        onTap:        { selectedFeedPost = post },
                                        onAvatarTap:  { profileFeedPost  = post },
                                        onCommentTap: { commentFeedPost  = post }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 40)
                        }
                        .refreshable {
                            await loadFollowingIDs()
                            await loadFollowingFeed()
                            await notificationState.refresh(userID: userSettings.userID)
                        }
                    }
                }
            }
            if showingTutorial {
                TutorialOverlayView(steps: TutorialSteps.feed, anchors: tutorialAnchors, onDismiss: {
                    withAnimation(.easeOut(duration: 0.25)) { showingTutorial = false }
                })
                .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                .zIndex(100)
            }
        }
        .onPreferenceChange(TutorialAnchorKey.self) { tutorialAnchors = $0 }
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
        .task {
            // Run both in parallel — they're independent
            async let followingLoad: Void = loadFollowingIDs()
            async let arenaLoad: Void = arenaViewModel.loadInitialFeed()
            _ = await (followingLoad, arenaLoad)
        }
        .sheet(isPresented: $showingNewPost) {
            NewPostView(userSettings: userSettings, onPostCompleted: {
                // Secondary refresh after Firebase write completes — guarantees
                // fuelLogItems are in Firestore before we fetch.
                Task { await arenaViewModel.refresh() }
                if !localFirestorePosts.isEmpty     { Task { await loadLocalFeed() } }
                if !teamFirestorePosts.isEmpty      { Task { await loadTeamFeed() } }
                if !followingFirestorePosts.isEmpty { Task { await loadFollowingFeed() } }
            })
            .environment(locationManager)
        }
        .onChange(of: showingNewPost) { _, isShowing in
            // Refresh Firestore feeds when the post sheet closes so new posts appear immediately
            if !isShowing {
                Task { await arenaViewModel.refresh() }
                if !localFirestorePosts.isEmpty     { Task { await loadLocalFeed() } }
                if !teamFirestorePosts.isEmpty      { Task { await loadTeamFeed() } }
                if !followingFirestorePosts.isEmpty { Task { await loadFollowingFeed() } }
            }
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView(userSettings: userSettings, notificationState: notificationState)
        }
        .sheet(isPresented: $showingOwnProfile) {
            NavigationStack {
                ProfileView(
                    profileUserID:      userSettings.userID,
                    profileUsername:    userSettings.username,
                    profileDisplayName: userSettings.name,
                    profileAuraLevel:   userSettings.auraLevel,
                    profileAuraPoints:  userSettings.auraPoints,
                    profileImageData:   userSettings.profileImageData,
                    profileLocation:    userSettings.location,
                    ownUserSettings:    userSettings,
                    isDismissable:      true
                )
            }
        }
        .sheet(item: $selectedFeedPost) { post in
            NavigationStack {
                FeedPostDetailView(post: post, currentUserSettings: userSettings)
            }
            .presentationDetents([.large])
        }
        .sheet(item: $commentFeedPost) { post in
            NavigationStack {
                FeedPostDetailView(post: post, currentUserSettings: userSettings, focusComment: true)
            }
            .presentationDetents([.large])
        }
        .sheet(item: $profileFeedPost, onDismiss: { Task { await loadFollowingIDs() } }) { post in
            NavigationStack {
                ProfileView(
                    profileUserID:       post.userID,
                    profileUsername:     post.username,
                    profileDisplayName:  post.whoName,
                    profileAuraLevel:    post.auraLevel,
                    profileAuraPoints:   post.auraPoints,
                    profileImageData:    nil,
                    ownUserSettings:     post.userID == userSettings.userID ? userSettings : nil,
                    currentUserSettings: post.userID == userSettings.userID ? nil : userSettings,
                    isDismissable:       true,
                    profileIsPrivate:    !post.isPublic
                )
            }
            .presentationDetents([.large])
            
        }
        .sheet(isPresented: $showingSearch) {
            NavigationStack {
                UserSearchView(currentUserSettings: userSettings)
            }
        }
    }

    private var socialProfileAvatarIcon: some View {
        Group {
            if let data = userSettings.profileImageData, let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg)
                    .resizable().scaledToFill()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.purpleHi, lineWidth: 1.5))
            } else {
                ZStack {
                    Circle().fill(Color.cardBg).frame(width: 30, height: 30)
                        .overlay(Circle().stroke(Color.purpleHi, lineWidth: 1.5))
                    Image(systemName: "person.fill").font(.system(size: 14)).foregroundStyle(Color.purpleHi)
                }
            }
        }
    }

    // MARK: - Filter chip

    @ViewBuilder
    private func filterChip(label: PostLabel?) -> some View {
        let isActive = labelFilter == label
        let color: Color = label.map { postLabelColor($0) } ?? Color.white
        Button {
            withAnimation(.spring(duration: 0.2)) { labelFilter = label }
        } label: {
            HStack(spacing: 4) {
                if let l = label {
                    Image(systemName: l.icon)
                        .font(.system(size: 10, weight: .semibold))
                }
                Text(label?.rawValue ?? "All")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(isActive ? .black : (label == nil ? .white.opacity(0.60) : color))
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(Capsule().fill(isActive
                ? (label == nil ? Color.white : color)
                : color.opacity(label == nil ? 0.08 : 0.10)))
            .overlay(Capsule().stroke(color.opacity(isActive ? 0 : (label == nil ? 0.20 : 0.30)), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Arena error / skeleton

    private func arenaErrorView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.orange.opacity(0.75))
            Text("Couldn't load Arena")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.70))
            Text(message)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.40))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                arenaViewModel.errorMessage = nil
                Task { await arenaViewModel.refresh() }
            } label: {
                Text("Retry")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.purpleHi)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var arenaSkeletonFeed: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cardBg)
                        .frame(height: 260)
                        .opacity(0.55)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Local feed

    private func loadLocalFeed() async {
        localLoading = true
        localError   = nil
        defer { localLoading = false }
        guard let (posts, _) = try? await PostService.shared.fetchFeedPosts(limit: 200) else {
            localError = "Couldn't load nearby posts. Pull down to retry."
            return
        }
        localFirestorePosts = posts
    }

    // MARK: - Team feed

    private func loadTeamFeed() async {
        teamLoading = true
        teamError   = nil
        defer { teamLoading = false }
        await loadFollowingIDs()
        // Team = mutual follows (friends) + the current user's own posts
        var ids = Array(friendIDs)
        if !userSettings.userID.isEmpty { ids.append(userSettings.userID) }
        guard !ids.isEmpty else { return }
        guard let posts = try? await PostService.shared.fetchPostsByAuthors(authorIDs: ids, limit: 200) else {
            teamError = "Couldn't load team posts. Pull down to retry."
            return
        }
        teamFirestorePosts = posts
    }

    // MARK: - Following feed

    private func loadFollowingFeed() async {
        followingLoading = true
        followingError   = nil
        defer { followingLoading = false }
        await loadFollowingIDs()
        // Following = everyone the current user follows, excluding self
        let ids = Array(followingIDs).filter { $0 != userSettings.userID }
        guard !ids.isEmpty else { return }
        guard let posts = try? await PostService.shared.fetchPostsByAuthors(authorIDs: ids, limit: 200) else {
            followingError = "Couldn't load following posts. Pull down to retry."
            return
        }
        followingFirestorePosts = posts
    }

    // MARK: - Following IDs

    private func loadFollowingIDs() async {
        guard !userSettings.userID.isEmpty else { return }
        async let followingTask = FollowService.shared.fetchFollowing(userID: userSettings.userID)
        async let followersTask = FollowService.shared.fetchFollowers(userID: userSettings.userID)
        let following = (try? await followingTask) ?? []
        let followers = (try? await followersTask) ?? []
        followingIDs = Set(following.map { $0.userID })
        let followerIDs = Set(followers.map { $0.userID })
        friendIDs = followingIDs.intersection(followerIDs)
    }

    @ViewBuilder
    private var privateAccountBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color.purpleHi)
            VStack(alignment: .leading, spacing: 4) {
                Text("You're hidden from this feed")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Private accounts don't appear in Local or Arena. Switch to a public profile in Settings to join the conversation.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.50))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.purpleHi.opacity(0.30), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var emptyFeed: some View {
        let noLocation = selectedFeed == .local && locationManager.coordinate == nil
        let icon = (selectedFeed == .team || selectedFeed == .following) ? "person.2.fill"
            : selectedFeed == .local ? "location.circle.fill"
            : "bolt.circle.fill"
        let headline = selectedFeed == .team ? "No friends have posted"
            : selectedFeed == .following ? "Nobody you follow has posted"
            : noLocation ? "Location needed"
            : selectedFeed == .local ? "No local posts yet"
            : "Arena is empty"
        let body = selectedFeed == .team
            ? "Friends are people who follow you back. Follow more people to grow your team."
            : selectedFeed == .following
            ? "Follow people using the search button above — their posts will appear here."
            : noLocation
            ? "Enable location in Settings so we can show posts from people near you."
            : selectedFeed == .local ? "No one in your area has posted yet. Be the first."
            : "Hit your macro goals and post from the celebration screen, or tap ✏️ to drop a post."

        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.purpleHi.opacity(0.10))
                    .frame(width: 88, height: 88)
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Color.purpleHi.opacity(0.45))
            }
            VStack(spacing: 6) {
                Text(headline)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.32))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 32)
            }
            if noLocation {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.purpleHi)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Post label color helper

func postLabelColor(_ label: PostLabel) -> Color {
    switch label {
    case .transformation: return Color(red: 0.35, green: 0.75, blue: 1.00)
    case .fuelLog:        return Color(red: 1.00, green: 0.55, blue: 0.15)
    case .mealInspo:      return Color(red: 1.00, green: 0.30, blue: 0.55)
    case .mogBoard:       return Color(red: 1.00, green: 0.80, blue: 0.20)
    case .advice:         return Color(red: 1.00, green: 0.90, blue: 0.20)
    case .workout:        return Color(red: 0.30, green: 0.90, blue: 0.55)
    case .goalPost:       return Color(red: 0.65, green: 0.45, blue: 1.00)
    }
}

// MARK: - Post card

// Reusable avatar circle used by PostCard and PostDetailView
func avatarCircle(size: CGFloat, data: Data?, initial: String) -> some View {
    avatarCircle(size: size, data: data, urlString: "", initial: initial)
}

/// Avatar circle that supports local image data, a remote URL fallback, or an initial letter.
func avatarCircle(size: CGFloat, data: Data?, urlString: String, initial: String) -> some View {
    Group {
        if let d = data, let img = UIImage(data: d) {
            Image(uiImage: img)
                .resizable().scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else if let url = URL(string: urlString), !urlString.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable().scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                default:
                    avatarPlaceholder(size: size, initial: initial)
                }
            }
        } else {
            avatarPlaceholder(size: size, initial: initial)
        }
    }
}

private func avatarPlaceholder(size: CGFloat, initial: String) -> some View {
    Circle()
        .fill(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.25))
        .frame(width: size, height: size)
        .overlay {
            Text(String(initial.prefix(1)).uppercased())
                .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.0))
        }
}

struct PostCard: View {
    @Bindable var post: SocialPost
    let userID: String
    let userSettings: UserSettings
    @Binding var followingIDs: Set<String>
    var onAvatarTap: (() -> Void)? = nil

    @State private var showingImageViewer = false
    @State private var followLoading      = false
    @State private var showCheckmark      = false

    private var isFollowing: Bool { followingIDs.contains(post.authorID) }
    private var isOwnPost:   Bool { post.authorID == userID }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            authorHeader

            if !post.fuelLogEntries.isEmpty {
                fuelLogBody
            } else if post.isCustomPost {
                customBody
            } else {
                achievementBody
            }

            // Reps + comments (right-aligned)
            HStack(spacing: 8) {
                Spacer()
                // 💪 Rep button
                Button {
                    let isNewRep = !post.hasRepped(userID: userID)
                    post.toggleRep(userID: userID)
                    if isNewRep {
                        userSettings.awardAura(points: 1, silent: true)
                    }
                    if isNewRep && post.authorID != userID {
                        Task {
                            await InAppNotificationService.shared.sendRep(
                                to:               post.authorID,
                                postID:           post.firebasePostID,
                                postHeadline:     post.memeHeadline,
                                actorID:          userSettings.userID,
                                actorUsername:    userSettings.username,
                                actorDisplayName: userSettings.name
                            )
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text("💪")
                            .font(.system(size: 12))
                        Text(post.repsCount > 0 ? "\(post.repsCount)" : "Rep")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(
                                post.hasRepped(userID: userID)
                                    ? Color(red: 1.0, green: 0.75, blue: 0.2)
                                    : .white.opacity(0.70)
                            )
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        post.hasRepped(userID: userID)
                            ? Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.14)
                            : Color.white.opacity(0.06)
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(
                            post.hasRepped(userID: userID)
                                ? Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.35)
                                : Color.clear,
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)

                HStack(spacing: 5) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 11))
                    Text("\(post.comments.count)")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(.white.opacity(0.35))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.05))
                .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(Color.cardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .sheet(isPresented: $showingImageViewer) {
            PostImageViewerSheet(imageDatas: post.allImageDatas)
        }
    }

    private var authorHeader: some View {
        HStack(spacing: 10) {
            // Tappable avatar
            Button(action: { onAvatarTap?() }) {
                avatarCircle(size: 38, data: post.authorProfileImageData,
                             initial: post.authorDisplayName)
            }
            .buttonStyle(.plain)
            .disabled(onAvatarTap == nil)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(post.authorDisplayName.isEmpty ? post.authorUsername : post.authorDisplayName)
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    if post.authorAuraPoints > 0 {
                        HStack(spacing: 3) {
                            Text("⭐")
                                .font(.system(size: 9))
                            Text("Lv \(post.authorAuraLevel)")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                            if !post.authorAuraTitle.isEmpty {
                                Text("· \(post.authorAuraTitle)")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                            }
                        }
                        .foregroundStyle(Color(red: 1.0, green: 0.80, blue: 0.20))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color(red: 1.0, green: 0.80, blue: 0.20).opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
                Text("@\(post.authorUsername)  ·  \(timeAgo(from: post.postedAt))")
                    .font(.caption2).foregroundStyle(.white.opacity(0.35))
            }
            Spacer()
            if let label = PostLabel(rawValue: post.postLabel) {
                let color = postLabelColor(label)
                HStack(spacing: 4) {
                    Image(systemName: label.icon)
                        .font(.system(size: 9, weight: .bold))
                    if label == .mogBoard, !post.mogBoardScope.isEmpty {
                        Text("\(post.mogBoardScope) Mog")
                            .font(.system(size: 9, weight: .bold))
                    } else {
                        Text(label.rawValue)
                            .font(.system(size: 9, weight: .bold))
                    }
                }
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.15), in: Capsule())
                .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 0.75))
            }
            if !isOwnPost && (!isFollowing || showCheckmark) {
                followButton
            }
        }
    }

    private let neon = Color(red: 0.35, green: 1.00, blue: 0.60)
    private let gold = Color(red: 1.00, green: 0.80, blue: 0.20)

    private var followButton: some View {
        ZStack {
            Circle()
                .fill(showCheckmark ? neon.opacity(0.15) : gold.opacity(0.15))
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(
                    showCheckmark ? neon.opacity(0.45) : gold.opacity(0.45),
                    lineWidth: 1
                ))
            if followLoading {
                ProgressView().scaleEffect(0.55)
            } else if showCheckmark {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(neon)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(gold)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showCheckmark)
        .onTapGesture {
            guard !followLoading && !showCheckmark else { return }
            Task { await toggleFollow() }
        }
    }

    private func toggleFollow() async {
        followLoading = true
        defer { followLoading = false }
        do {
            if isFollowing {
                try await FollowService.shared.unfollowUser(
                    currentUserID: userSettings.userID,
                    targetUserID:  post.authorID
                )
                followingIDs.remove(post.authorID)
            } else {
                try await FollowService.shared.followUser(
                    currentUserID:          userSettings.userID,
                    currentUsername:        userSettings.username,
                    currentProfilePhotoURL: "",
                    targetUserID:           post.authorID,
                    targetUsername:         post.authorUsername,
                    targetProfilePhotoURL:  ""
                )
                followingIDs.insert(post.authorID)
                withAnimation { showCheckmark = true }
                await InAppNotificationService.shared.sendFollow(
                    to:               post.authorID,
                    actorID:          userSettings.userID,
                    actorUsername:    userSettings.username,
                    actorDisplayName: userSettings.name
                )
                try? await Task.sleep(for: .seconds(2))
                withAnimation { showCheckmark = false }
            }
        } catch {
            print("[PostCard] toggleFollow error: \(error)")
        }
    }

    // Custom post: image + title + body
    @ViewBuilder
    private var customBody: some View {
        if !post.allImageDatas.isEmpty {
            imageThumbnailStrip
        }
        Text(post.memeHeadline)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
        if !post.memeSub.isEmpty {
            Text(post.memeSub)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .lineLimit(3)
        }
        if post.postLabel == PostLabel.goalPost.rawValue && post.goalCalories > 0 {
            MacroDisciplineCard(
                totalCalories: post.totalCalories, goalCalories: post.goalCalories,
                totalProtein:  post.totalProtein,  goalProtein:  post.goalProtein,
                totalCarbs:    post.totalCarbs,    goalCarbs:    post.goalCarbs,
                totalFat:      post.totalFat,      goalFat:      post.goalFat
            )
        }
        if post.postLabel == PostLabel.workout.rawValue && !post.workoutEntries.isEmpty {
            workoutCard
        }
        if post.postLabel == PostLabel.mogBoard.rawValue && !mogBoardSnapshotEntries.isEmpty {
            mogBoardSnapshotCard
        }
    }

    private let socialWorkoutGreen = Color(red: 0.30, green: 0.90, blue: 0.55)

    @ViewBuilder
    private var workoutCard: some View {
        let sorted    = post.workoutEntries.sorted { $0.sortOrder < $1.sortOrder }
        let totalCal  = sorted.reduce(0) { $0 + $1.caloriesBurned }
        let totalMin  = sorted.reduce(0) { $0 + $1.durationMinutes }
        let totalTime = totalMin >= 60 ? "\(totalMin / 60)h \(totalMin % 60)m" : "\(totalMin)m"
        VStack(alignment: .leading, spacing: 0) {
            ForEach(sorted) { item in
                socialWorkoutRow(item: item, isLast: item.id == sorted.last?.id)
            }
            if sorted.count > 1 {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                HStack {
                    Spacer()
                    Text("Total: \(totalTime) · \(totalCal) cal burned")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(socialWorkoutGreen.opacity(0.80))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
        }
        .background(Color(red: 0.10, green: 0.07, blue: 0.18))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(socialWorkoutGreen.opacity(0.20), lineWidth: 1))
        .padding(.top, 4)
    }

    private func socialWorkoutRow(item: WorkoutLogEntry, isLast: Bool) -> some View {
        let icon      = WorkoutType(rawValue: item.workoutType)?.icon ?? "figure.mixed.cardio"
        let typeLabel = WorkoutType(rawValue: item.workoutType)?.shortLabel ?? item.workoutType
        return VStack(spacing: 0) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(socialWorkoutGreen.opacity(0.12))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundStyle(socialWorkoutGreen)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.workoutName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.90))
                        .lineLimit(1)
                    Text("\(item.formattedDuration) · \(typeLabel)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.40))
                }
                Spacer()
                Text("\(item.caloriesBurned) cal")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(socialWorkoutGreen)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            if !isLast {
                Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1).padding(.horizontal, 10)
            }
        }
    }

    private var mogBoardSnapshotEntries: [MogBoardSnapshotEntry] {
        guard !post.mogBoardSnapshot.isEmpty,
              let data = post.mogBoardSnapshot.data(using: .utf8),
              let entries = try? JSONDecoder().decode([MogBoardSnapshotEntry].self, from: data)
        else { return [] }
        return entries
    }

    @ViewBuilder
    private var mogBoardSnapshotCard: some View {
        let snapshotGold = Color(red: 1.0, green: 0.80, blue: 0.20)
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
                    .foregroundStyle(snapshotGold)
                Text(post.mogBoardType.isEmpty ? "Board" : post.mogBoardType)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(snapshotGold)
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
                            .foregroundStyle(rank == 0 ? snapshotGold : .white.opacity(0.30))
                            .frame(width: 26, alignment: .trailing)
                        Text(entry.displayName.isEmpty ? "@\(entry.username)" : entry.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                        Spacer()
                        Text("\(entry.score)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(rank == 0 ? snapshotGold : .white.opacity(0.55))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(rank == 0 ? snapshotGold.opacity(0.07) : Color.clear)
                }
            }
            .padding(.vertical, 4)
        }
        .background(Color(red: 0.10, green: 0.07, blue: 0.18))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(snapshotGold.opacity(0.20), lineWidth: 1))
        .padding(.top, 4)
    }

    // Achievement post: optional photo + meme + macro summary
    @ViewBuilder
    private var achievementBody: some View {
        if !post.allImageDatas.isEmpty {
            imageThumbnailStrip
        }
        Text(post.memeHeadline.replacingOccurrences(of: "\n", with: " "))
            .font(.system(size: 15, weight: .black, design: .rounded))
            .foregroundStyle(.white)
        Text(post.memeSub)
            .font(.caption).foregroundStyle(.white.opacity(0.50))

        if post.goalCalories > 0 {
            MacroDisciplineCard(
                totalCalories: post.totalCalories, goalCalories:  post.goalCalories,
                totalProtein:  post.totalProtein,  goalProtein:   post.goalProtein,
                totalCarbs:    post.totalCarbs,    goalCarbs:     post.goalCarbs,
                totalFat:      post.totalFat,      goalFat:       post.goalFat
            )
            .padding(.top, 4)
        }

        if !post.fastingWindowDisplay.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.00))
                Text(post.fastingWindowDisplay)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.60))
            }
            .padding(.top, 2)
        }
    }

    /// Fixed-height thumbnail strip shown in the feed card. Tap opens full-screen viewer.
    @ViewBuilder
    private var imageThumbnailStrip: some View {
        let datas = post.allImageDatas
        let images = datas.compactMap { UIImage(data: $0) }
        if !images.isEmpty {
            Button(action: { showingImageViewer = true }) {
                ZStack(alignment: .bottomTrailing) {
                    if images.count == 1 {
                        Image(uiImage: images[0])
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .clipped()
                            .cornerRadius(10)
                    } else {
                        PostImagesView(imageDatas: datas)
                    }

                    // Expand hint badge
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                        .padding(6)
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var macroSummaryRow: some View {
        let items: [(String, Double, Double, Color)] = [
            ("Cal",  post.totalCalories, post.goalCalories, Color(red: 1.00, green: 0.55, blue: 0.15)),
            ("Pro",  post.totalProtein,  post.goalProtein,  Color(red: 0.35, green: 0.75, blue: 1.00)),
            ("Carb", post.totalCarbs,    post.goalCarbs,    Color(red: 0.40, green: 0.90, blue: 0.72)),
            ("Fat",  post.totalFat,      post.goalFat,      Color(red: 1.00, green: 0.50, blue: 0.72)),
        ]
        HStack(spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                let (label, actual, goal, color) = item
                let met: Bool = label == "Cal"
                    ? actual >= goal * 0.85 && actual <= goal * 1.15
                    : actual >= goal * 0.85
                HStack(spacing: 3) {
                    if met {
                        Image(systemName: "checkmark")
                            .font(.system(size: 7, weight: .black))
                    }
                    Text(label)
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(met ? color : .white.opacity(0.32))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(met ? color.opacity(0.14) : Color.white.opacity(0.05))
                .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    private func fuelBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    /// 0–100 meal quality score based on how closely macros match the viewer's goal ratios.
    private func fuelEntryScore(calories: Double, protein: Double, carbs: Double, fat: Double) -> Int {
        guard calories >= 300 else { return 0 }
        let ud = UserDefaults.standard
        func g(_ key: String, fallback: Double) -> Double {
            ud.object(forKey: key) != nil ? ud.double(forKey: key) : fallback
        }
        let pCal  = g("goalProtein", fallback: 150) * 4
        let cCal  = g("goalCarbs",   fallback: 200) * 4
        let fCal  = g("goalFat",     fallback:  65) * 9
        let total = pCal + cCal + fCal
        let goalP = total > 0 ? pCal / total : 0.26
        let goalC = total > 0 ? cCal / total : 0.49
        let goalF = total > 0 ? fCal / total : 0.25
        let actualP = (protein * 4) / calories
        let actualC = (carbs   * 4) / calories
        let actualF = (fat     * 9) / calories
        let dev = abs(actualP - goalP) + abs(actualC - goalC) + abs(actualF - goalF)
        return max(0, min(100, Int(((1.0 - dev / 2.0) * 100).rounded())))
    }

    @ViewBuilder
    private func fuelScoreCircle(calories: Double, protein: Double, carbs: Double, fat: Double) -> some View {
        let score = fuelEntryScore(calories: calories, protein: protein, carbs: carbs, fat: fat)
        if score > 0 {
            let color: Color = score >= 75 ? Color(red: 0.25, green: 0.85, blue: 0.50)
                             : score >= 50 ? Color(red: 1.00, green: 0.75, blue: 0.20)
                             :               Color(red: 1.00, green: 0.35, blue: 0.35)
            ZStack {
                Circle()
                    .stroke(color.opacity(0.30), lineWidth: 1.5)
                    .frame(width: 32, height: 32)
                Text("\(score)")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(color)
            }
        }
    }

    private func timeAgo(from date: Date) -> String {
        let s = Int(Date().timeIntervalSince(date))
        switch s {
        case ..<60:          return "just now"
        case 60..<3600:      return "\(s / 60)m"
        case 3600..<86400:   return "\(s / 3600)h"
        case 86400..<604800: return "\(s / 86400)d"
        default:             return "\(s / 604800)w"
        }
    }

    // Fuel log post: visual meal table matching the preview
    @ViewBuilder
    private var fuelLogBody: some View {
        let sorted = post.fuelLogEntries.sorted { $0.sortOrder < $1.sortOrder }
        let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
        let totalCal = sorted.reduce(0.0) { $0 + $1.calories }
        let totalPro = sorted.reduce(0.0) { $0 + $1.protein  }
        let totalCarb = sorted.reduce(0.0) { $0 + $1.carbs   }
        let totalFat = sorted.reduce(0.0) { $0 + $1.fat      }

        VStack(alignment: .leading, spacing: 0) {
            // Header — user's typed status (falls back to date label)
            Text(post.memeHeadline)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, post.memeSub.isEmpty ? 10 : 4)

            // Optional user message
            if !post.memeSub.isEmpty {
                Text(post.memeSub)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.bottom, 10)
            }

            // Entries
            ForEach(sorted) { entry in
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        if let data = entry.imageData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipped()
                                .cornerRadius(8)
                        } else if !entry.photoURL.isEmpty, let url = URL(string: entry.photoURL) {
                            AsyncImage(url: url) { phase in
                                if let img = phase.image {
                                    img.resizable().scaledToFill()
                                } else {
                                    Color.white.opacity(0.07)
                                }
                            }
                            .frame(width: 40, height: 40)
                            .clipped()
                            .cornerRadius(8)
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
                            Text(entry.foodName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            HStack(spacing: 4) {
                                fuelBadge("\(Int(entry.calories)) kcal", color: Color(red: 1.00, green: 0.55, blue: 0.15))
                                fuelBadge("\(Int(entry.protein))g P",    color: Color(red: 0.35, green: 0.75, blue: 1.00))
                                fuelBadge("\(Int(entry.carbs))g C",      color: Color(red: 0.40, green: 0.90, blue: 0.72))
                                fuelBadge("\(Int(entry.fat))g F",        color: Color(red: 1.00, green: 0.50, blue: 0.72))
                            }
                        }
                        Spacer()
                        fuelScoreCircle(calories: entry.calories, protein: entry.protein,
                                        carbs: entry.carbs, fat: entry.fat)
                        Text(entry.loggedAt, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.25))
                    }
                    .padding(.vertical, 8)

                    if entry.id != sorted.last?.id {
                        Divider().background(Color.white.opacity(0.08))
                    }
                }
            }

            // Totals row
            Divider()
                .background(purpl.opacity(0.40))
                .padding(.top, 4)

            HStack {
                Text("Total")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 4) {
                    fuelBadge("\(Int(totalCal)) kcal", color: Color(red: 1.00, green: 0.55, blue: 0.15))
                    fuelBadge("\(Int(totalPro))g P",   color: Color(red: 0.35, green: 0.75, blue: 1.00))
                    fuelBadge("\(Int(totalCarb))g C",  color: Color(red: 0.40, green: 0.90, blue: 0.72))
                    fuelBadge("\(Int(totalFat))g F",   color: Color(red: 1.00, green: 0.50, blue: 0.72))
                }
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Full-screen image viewer

struct PostImageViewerSheet: View {
    let imageDatas: [Data]

    @Environment(\.dismiss) private var dismiss

    private var images: [UIImage] { imageDatas.compactMap { UIImage(data: $0) } }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if images.isEmpty {
                Text("No images").foregroundStyle(.white.opacity(0.40))
            } else if images.count == 1 {
                Image(uiImage: images[0])
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView {
                    ForEach(Array(images.enumerated()), id: \.offset) { _, img in
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.80))
                            .shadow(radius: 4)
                    }
                    .padding(20)
                }
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

