//
//  ProfileView.swift
//  Wellness
//

import SwiftUI
import SwiftData

// MARK: - ProfileView

struct ProfileView: View {
    // Profile being viewed
    let profileUserID:       String
    let profileUsername:     String
    let profileDisplayName:  String
    let profileAuraLevel:    Int
    let profileAuraPoints:   Int
    let profileImageData:    Data?
    var profileLocation:     String = ""
    var profileStreak:       Int    = 0

    /// Non-nil only when viewing your own profile (enables photo editing)
    var ownUserSettings: UserSettings? = nil

    /// Non-nil when viewing someone else's profile — provides the viewer's identity for follow actions
    var currentUserSettings: UserSettings? = nil

    /// Set true when ProfileView is presented as a sheet so an X dismiss button is shown.
    var isDismissable: Bool = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @Query(sort: \SocialPost.repsCount, order: .reverse) private var allPosts: [SocialPost]

    @State private var showingCamera       = false
    @State private var showingLibrary      = false
    @State private var showingPhotoSource  = false
    @State private var rawPickedImage:     UIImage? = nil
    @State private var showingCrop         = false
    @State private var newProfileImage:    UIImage?
    @State private var selectedPost:       SocialPost?
    @State private var showingProfileShare = false
    @State private var showingSettings     = false

    // Firestore posts (primary source for profile grid)
    @State private var firestorePosts: [FeedPost] = []
    @State private var postsLoading   = false

    // Follow state
    @State private var isFollowing:           Bool   = false
    @State private var followerCount:         Int    = 0
    @State private var followingCount:        Int    = 0
    @State private var friendCount:           Int    = 0
    @State private var followLoading:         Bool   = false
    @State private var viewerProfilePhotoURL: String = ""
    @State private var targetProfilePhotoURL: String = ""
    @State private var showingFollowersList:  Bool   = false
    @State private var showingFollowingList:  Bool   = false
    @State private var showingFriendsList:    Bool   = false

    // Subscription state
    @State private var isSubscribed:     Bool = false
    @State private var subscribeLoading: Bool = false

    private var isOwnProfile: Bool { ownUserSettings != nil }

    private var resolvedStreak: Int {
        if let own = ownUserSettings { return own.macroStreak }
        // For other users derive from the highest streak seen on their Firestore posts
        return firestorePosts.map { $0.streak }.max() ?? profileStreak
    }

    private var displayName: String {
        profileDisplayName.isEmpty ? profileUsername : profileDisplayName
    }

    private var resolvedAvatarImage: UIImage? {
        if isOwnProfile {
            if let img = newProfileImage { return img }
            if let data = ownUserSettings?.profileImageData { return UIImage(data: data) }
            return nil
        }
        if let data = profileImageData { return UIImage(data: data) }
        return nil
    }

    // MARK: - Palette
    private let pageBg  = Color(red: 0.04, green: 0.03, blue: 0.08)
    private let cardBg  = Color(red: 0.10, green: 0.08, blue: 0.18)
    private let purpl   = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold    = Color(red: 1.00, green: 0.80, blue: 0.20)
    private let neon    = Color(red: 0.35, green: 1.00, blue: 0.60)

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerBanner
                    statsBar
                    rankBadge
                    auraLevelCard
                    socialLinks
                    if !isOwnProfile { addToTeamButton }
                    if !isOwnProfile && isFollowing { subscribeButton }
                    postsGrid
                }
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isDismissable {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.70))
                    }
                }
            }
            if isOwnProfile {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
                        Button { showingProfileShare = true } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(gold)
                        }
                        Button { showingSettings = true } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(purpl)
                        }
                    }
                }
            }
        }
        .task { await loadFollowState() }
        .task { await loadPosts() }
        .sheet(isPresented: $showingFollowersList) {
            NavigationStack {
                FollowListView(
                    userID:              profileUserID,
                    mode:                .followers,
                    currentUserSettings: currentUserSettings ?? ownUserSettings
                )
            }
        }
        .sheet(isPresented: $showingFollowingList) {
            NavigationStack {
                FollowListView(
                    userID:              profileUserID,
                    mode:                .following,
                    currentUserSettings: currentUserSettings ?? ownUserSettings
                )
            }
        }
        .sheet(isPresented: $showingFriendsList) {
            NavigationStack {
                FriendsListView(
                    userID:              profileUserID,
                    currentUserSettings: currentUserSettings ?? ownUserSettings
                )
            }
        }
        .sheet(isPresented: $showingSettings) {
            if let settings = ownUserSettings {
                NavigationStack { SettingsView(userSettings: settings) }
            }
        }
        .confirmationDialog("Change Profile Photo", isPresented: $showingPhotoSource, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") { showingCamera = true }
            }
            Button("Choose from Library") { showingLibrary = true }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showingCamera, onDismiss: { if rawPickedImage != nil { showingCrop = true } }) {
            ImagePickerView(sourceType: .camera, selectedImage: $rawPickedImage)
        }
        .sheet(isPresented: $showingLibrary, onDismiss: { if rawPickedImage != nil { showingCrop = true } }) {
            ImagePickerView(sourceType: .photoLibrary, selectedImage: $rawPickedImage)
        }
        .fullScreenCover(isPresented: $showingCrop) {
            if let img = rawPickedImage {
                CropCircleView(sourceImage: img) { cropped in
                    newProfileImage = cropped
                    rawPickedImage  = nil
                    showingCrop     = false
                    saveNewPhoto()
                } onCancel: {
                    rawPickedImage = nil
                    showingCrop    = false
                }
            }
        }
        .sheet(isPresented: $showingProfileShare) {
            ProfileShareView(
                displayName:     profileDisplayName.isEmpty ? profileUsername : profileDisplayName,
                username:        profileUsername,
                auraLevel:       profileAuraLevel,
                auraPoints:      profileAuraPoints,
                auraTitleString: auraTitleString,
                profileImage:    resolvedAvatarImage
            )
        }
        .sheet(item: $selectedPost) { post in
            if let settings = ownUserSettings {
                PostDetailView(post: post, userSettings: settings)
            }
        }
    }

    // MARK: - Header Banner

    private var headerBanner: some View {
        ZStack(alignment: .bottom) {
            // Gradient banner background
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.08, blue: 0.40),
                    Color(red: 0.08, green: 0.04, blue: 0.20),
                    pageBg
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)

            // Decorative glow orb
            Ellipse()
                .fill(purpl.opacity(0.18))
                .frame(width: 260, height: 120)
                .blur(radius: 40)
                .offset(y: -30)

            VStack(spacing: 12) {
                // Avatar
                Button {
                    if isOwnProfile { showingPhotoSource = true }
                } label: {
                    ZStack {
                        // Outer glow ring (gradient)
                        Circle()
                            .fill(
                                AngularGradient(
                                    colors: [gold, purpl, neon, gold],
                                    center: .center
                                )
                            )
                            .frame(width: 114, height: 114)
                            .blur(radius: 3)

                        avatarView(size: 104)

                        if isOwnProfile {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.black)
                                        .padding(6)
                                        .background(gold)
                                        .clipShape(Circle())
                                        .offset(x: 4, y: 4)
                                }
                            }
                            .frame(width: 104, height: 104)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(!isOwnProfile)
                .padding(.top, 24)

                // Name + handle
                VStack(spacing: 3) {
                    Text(displayName)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 6) {
                        if !profileUsername.isEmpty {
                            Text("@\(profileUsername)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        if !profileLocation.isEmpty {
                            Text("·")
                                .foregroundStyle(.white.opacity(0.25))
                            Image(systemName: "mappin.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(purpl.opacity(0.70))
                            Text(profileLocation)
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.40))
                        }
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            statCell(value: "\(firestorePosts.count)", label: "POSTS")
            statDivider
            Button { showingFollowersList = true } label: {
                statCell(value: "\(followerCount)", label: "FOLLOWERS")
            }
            .buttonStyle(.plain)
            statDivider
            Button { showingFollowingList = true } label: {
                statCell(value: "\(followingCount)", label: "FOLLOWING")
            }
            .buttonStyle(.plain)
            statDivider
            Button { showingFriendsList = true } label: {
                statCell(value: "\(friendCount)", label: "FRIENDS")
            }
            .buttonStyle(.plain)
            statDivider
            statCell(value: auraPointsFormatted, label: "AURA")
            statDivider
            streakCell
        }
        .padding(.vertical, 14)
        .background(cardBg)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(purpl.opacity(0.15), lineWidth: 1)
        )
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.35))
                .tracking(1.5)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(purpl.opacity(0.20))
            .frame(width: 1, height: 32)
    }

    private var streakCell: some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Text("🔥")
                    .font(.system(size: 14))
                Text(resolvedStreak > 0 ? "\(resolvedStreak)" : "—")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(resolvedStreak > 0
                        ? Color(red: 1.00, green: 0.60, blue: 0.15)
                        : .white.opacity(0.30))
            }
            Text("STREAK")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.35))
                .tracking(1.5)
        }
        .frame(maxWidth: .infinity)
    }

    private var auraPointsFormatted: String {
        if profileAuraPoints >= 1000 {
            return String(format: "%.1fk", Double(profileAuraPoints) / 1000)
        }
        return "\(profileAuraPoints)"
    }

    // MARK: - Rank Badge

    @ViewBuilder
    private var rankBadge: some View {
        if !auraTitleString.isEmpty {
            HStack(spacing: 8) {
                Text(rankEmoji)
                    .font(.system(size: 16))
                Text(auraTitleString.uppercased())
                    .font(.system(size: 11, weight: .black))
                    .tracking(2)
                    .foregroundStyle(gold)
                Text(rankEmoji)
                    .font(.system(size: 16))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [gold.opacity(0.12), purpl.opacity(0.12)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(colors: [gold.opacity(0.50), purpl.opacity(0.50)],
                                       startPoint: .leading, endPoint: .trailing),
                        lineWidth: 1
                    )
            )
            .clipShape(Capsule())
            .padding(.top, 14)
        }
    }

    // MARK: - Aura Level Card

    @ViewBuilder
    private var auraLevelCard: some View {
        if profileAuraPoints > 0 || profileAuraLevel > 0 {
            let pts        = profileAuraPoints
            let level      = UserSettings.auraLevel(for: pts)
            let levelStart = UserSettings.auraThreshold(level)
            let levelEnd   = UserSettings.auraThreshold(level + 1)
            let inLevel    = pts - levelStart
            let forLevel   = max(1, levelEnd - levelStart)
            let progress   = level >= 100 ? 1.0 : Double(inLevel) / Double(forLevel)
            let pctText    = level >= 100 ? "MAX" : "\(Int(progress * 100))%"

            VStack(spacing: 10) {
                HStack(spacing: 0) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(gold)
                        Text("Level \(max(1, level))")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        if !auraTitleString.isEmpty {
                            Text("·")
                                .foregroundStyle(.white.opacity(0.20))
                            Text(auraTitleString)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(gold.opacity(0.80))
                        }
                    }
                    Spacer()
                    Text(pctText)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(gold)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 8)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [gold, purpl],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, geo.size.width * progress), height: 8)
                            .animation(.easeOut(duration: 0.6), value: progress)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(inLevel) / \(forLevel) pts")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.30))
                    Spacer()
                    if level < 100 {
                        Text("\(forLevel - inLevel) pts to Level \(level + 1)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.30))
                    } else {
                        Text("Maximum level reached")
                            .font(.caption2)
                            .foregroundStyle(gold.opacity(0.60))
                    }
                }
            }
            .padding(14)
            .background(cardBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(gold.opacity(0.15), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.top, 14)
        }
    }

    // MARK: - Social Links

    @ViewBuilder
    private var socialLinks: some View {
        if isOwnProfile {
            let ig = ownUserSettings?.instagramHandle.trimmingCharacters(in: .whitespaces) ?? ""
            let tt = ownUserSettings?.tiktokHandle.trimmingCharacters(in: .whitespaces) ?? ""
            if !ig.isEmpty || !tt.isEmpty {
                HStack(spacing: 10) {
                    if !ig.isEmpty {
                        Button {
                            let appURL = URL(string: "instagram://user?username=\(ig)")!
                            let webURL = URL(string: "https://instagram.com/\(ig)")!
                            if UIApplication.shared.canOpenURL(appURL) {
                                UIApplication.shared.open(appURL)
                            } else {
                                UIApplication.shared.open(webURL)
                            }
                        } label: {
                            socialBadge(
                                icon: "camera.fill", label: "@\(ig)",
                                gradient: [Color(red: 1.0, green: 0.55, blue: 0.0),
                                           Color(red: 0.95, green: 0.2, blue: 0.55),
                                           Color(red: 0.55, green: 0.15, blue: 0.9)]
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    if !tt.isEmpty {
                        Button {
                            let appURL = URL(string: "tiktok://user?username=\(tt)")!
                            let webURL = URL(string: "https://www.tiktok.com/@\(tt)")!
                            if UIApplication.shared.canOpenURL(appURL) {
                                UIApplication.shared.open(appURL)
                            } else {
                                UIApplication.shared.open(webURL)
                            }
                        } label: {
                            socialBadge(
                                icon: "music.note", label: "@\(tt)",
                                gradient: [Color(red: 0.1, green: 0.1, blue: 0.1),
                                           Color(red: 0.28, green: 0.28, blue: 0.28)]
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 12)
            }
        }
    }

    // MARK: - Follow / Unfollow Button

    private var addToTeamButton: some View {
        Button {
            Task { await toggleFollow() }
        } label: {
            HStack(spacing: 8) {
                if followLoading {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Image(systemName: isFollowing ? "checkmark.seal.fill" : "person.badge.plus")
                        .font(.system(size: 14, weight: .bold))
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.system(size: 15, weight: .black))
                }
            }
            .foregroundStyle(isFollowing ? neon : .black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Group {
                    if isFollowing {
                        AnyView(neon.opacity(0.15))
                    } else {
                        AnyView(
                            LinearGradient(
                                colors: [gold, Color(red: 1.0, green: 0.60, blue: 0.10)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isFollowing ? neon.opacity(0.40) : Color.clear, lineWidth: 1)
            )
            .cornerRadius(14)
        }
        .disabled(followLoading)
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    // MARK: - Posts Grid

    private var postsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("POSTS")
                    .font(.system(size: 11, weight: .black))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.35))
                Spacer()
                Text("\(firestorePosts.count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(purpl.opacity(0.60))
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)

            if postsLoading {
                ProgressView()
                    .tint(purpl)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if firestorePosts.isEmpty {
                VStack(spacing: 8) {
                    Text("💀")
                        .font(.system(size: 36))
                    Text("No posts yet.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.25))
                    Text("Post your first W to the feed.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.15))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                    spacing: 8
                ) {
                    ForEach(firestorePosts) { post in
                        ProfilePostCard(post: post)
                            .onTapGesture {
                                // Bridge to local SocialPost for detail view if cached locally
                                if let local = allPosts.first(where: { $0.firebasePostID == post.postID }) {
                                    selectedPost = local
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Helpers

    private var auraTitleString: String {
        switch profileAuraLevel {
        case 0:       return ""
        case 1...9:   return "Initiate"
        case 10...24: return "Disciple"
        case 25...39: return "Ascender"
        case 40...59: return "Mog Apprentice"
        case 60...79: return "Aura Farmer"
        case 80...94: return "Elite Aesthetic"
        default:      return "Final Form"
        }
    }

    private var rankEmoji: String {
        switch profileAuraLevel {
        case 0:       return ""
        case 1...9:   return "🔥"
        case 10...24: return "⚡️"
        case 25...39: return "💪"
        case 40...59: return "👑"
        case 60...79: return "🐐"
        default:      return "🗿"
        }
    }

    @ViewBuilder
    func avatarView(size: CGFloat) -> some View {
        if let uiImg = resolvedAvatarImage {
            Image(uiImage: uiImg)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            let urlString = isOwnProfile
                ? (ownUserSettings?.profilePhotoURL ?? "")
                : targetProfilePhotoURL
            if !urlString.isEmpty, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    default:
                        avatarPlaceholder(size: size)
                    }
                }
            } else {
                avatarPlaceholder(size: size)
            }
        }
    }

    private func avatarPlaceholder(size: CGFloat) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [purpl.opacity(0.40), Color(red: 0.30, green: 0.10, blue: 0.60)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Text(String(displayName.prefix(1)).uppercased())
                    .font(.system(size: size * 0.40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
    }

    @ViewBuilder
    private func socialBadge(icon: String, label: String, gradient: [Color]) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing))
        .cornerRadius(20)
    }

    // MARK: - Actions

    private func saveNewPhoto() {
        guard let img = newProfileImage, let data = img.jpegData(compressionQuality: 0.75) else { return }
        ownUserSettings?.profileImageData = data
        // Upload to Firebase Storage and update the Firestore profile URL
        if let settings = ownUserSettings {
            Task {
                if let url = try? await UserProfileService.shared.updateProfilePhoto(userID: settings.userID, image: img) {
                    settings.profilePhotoURL = url
                }
            }
        }
    }

    private func loadPosts() async {
        guard !profileUserID.isEmpty else {
            print("[ProfileView] loadPosts: profileUserID is empty, skipping")
            postsLoading = false
            return
        }
        postsLoading = true
        do {
            firestorePosts = try await PostService.shared.fetchUserPosts(userID: profileUserID)
            print("[ProfileView] loadPosts: fetched \(firestorePosts.count) posts for userID=\(profileUserID)")
        } catch {
            print("[ProfileView] loadPosts error for userID=\(profileUserID): \(error)")
            firestorePosts = []
        }
        postsLoading = false
    }

    private func loadFollowState() async {
        // Compute counts from actual follow collections rather than cached Firestore counters,
        // which can drift over time.
        async let followersOfProfile  = FollowService.shared.fetchFollowers(userID: profileUserID)
        async let followingByProfile  = FollowService.shared.fetchFollowing(userID: profileUserID)

        let followers  = (try? await followersOfProfile)  ?? []
        let following  = (try? await followingByProfile)  ?? []
        let followerIDs  = Set(followers.map { $0.userID })
        let followingIDs = Set(following.map { $0.userID })

        followerCount  = followerIDs.count
        followingCount = followingIDs.count
        friendCount    = followingIDs.intersection(followerIDs).count

        if isOwnProfile {
            // Still fetch profile for photo URL updates
            if let uid = ownUserSettings?.userID, !uid.isEmpty,
               let profile = try? await UserProfileService.shared.fetchProfile(userID: uid) {
                targetProfilePhotoURL = profile.profilePhotoURL
            }
            return
        }
        let viewer = currentUserSettings ?? ownUserSettings
        guard let viewerID = viewer?.userID, !viewerID.isEmpty else { return }

        async let followingCheck = FollowService.shared.isFollowing(currentUserID: viewerID, targetUserID: profileUserID)
        async let targetProfile  = UserProfileService.shared.fetchProfile(userID: profileUserID)
        async let viewerProfile  = UserProfileService.shared.fetchProfile(userID: viewerID)

        if let viewerIsFollowing = try? await followingCheck { isFollowing = viewerIsFollowing }
        if let profile = try? await targetProfile {
            targetProfilePhotoURL = profile.profilePhotoURL
        }
        if let vp = try? await viewerProfile { viewerProfilePhotoURL = vp.profilePhotoURL }
        if let subscribed = try? await SubscriptionService.shared.isSubscribed(
            subscriberID: viewerID, targetUserID: profileUserID) {
            isSubscribed = subscribed
        }
    }

    private func toggleFollow() async {
        let viewer = currentUserSettings ?? ownUserSettings
        guard let viewerSettings = viewer, !viewerSettings.userID.isEmpty else { return }

        followLoading = true
        defer { followLoading = false }

        do {
            if isFollowing {
                try await FollowService.shared.unfollowUser(
                    currentUserID: viewerSettings.userID,
                    targetUserID:  profileUserID
                )
                isFollowing   = false
                followerCount = max(0, followerCount - 1)
            } else {
                try await FollowService.shared.followUser(
                    currentUserID:          viewerSettings.userID,
                    currentUsername:        viewerSettings.username,
                    currentDisplayName:     viewerSettings.name.isEmpty ? nil : viewerSettings.name,
                    currentProfilePhotoURL: viewerProfilePhotoURL,
                    targetUserID:           profileUserID,
                    targetUsername:         profileUsername,
                    targetDisplayName:      profileDisplayName.isEmpty ? nil : profileDisplayName,
                    targetProfilePhotoURL:  targetProfilePhotoURL
                )
                isFollowing   = true
                followerCount += 1
                await InAppNotificationService.shared.sendFollow(
                    to:               profileUserID,
                    actorID:          viewerSettings.userID,
                    actorUsername:    viewerSettings.username,
                    actorDisplayName: viewerSettings.name
                )
            }
        } catch {
            print("[ProfileView] toggleFollow error: \(error)")
        }
    }

    private var subscribeButton: some View {
        Button {
            Task { await toggleSubscribe() }
        } label: {
            HStack(spacing: 8) {
                if subscribeLoading {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Image(systemName: isSubscribed ? "bell.fill" : "bell")
                        .font(.system(size: 14, weight: .bold))
                    Text(isSubscribed ? "Subscribed" : "Get Notified")
                        .font(.system(size: 15, weight: .black))
                }
            }
            .foregroundStyle(isSubscribed ? gold : .white.opacity(0.70))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSubscribed ? gold.opacity(0.15) : Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSubscribed ? gold.opacity(0.40) : Color.white.opacity(0.15), lineWidth: 1)
            )
            .cornerRadius(14)
        }
        .disabled(subscribeLoading)
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    private func toggleSubscribe() async {
        let viewer = currentUserSettings ?? ownUserSettings
        guard let viewerSettings = viewer, !viewerSettings.userID.isEmpty else { return }
        subscribeLoading = true
        defer { subscribeLoading = false }
        do {
            if isSubscribed {
                try await SubscriptionService.shared.unsubscribe(
                    subscriberID: viewerSettings.userID,
                    targetUserID: profileUserID
                )
                isSubscribed = false
            } else {
                try await SubscriptionService.shared.subscribe(
                    subscriberID:          viewerSettings.userID,
                    subscriberUsername:    viewerSettings.username,
                    subscriberDisplayName: viewerSettings.name,
                    targetUserID:          profileUserID
                )
                isSubscribed = true
            }
        } catch {
            print("[ProfileView] toggleSubscribe error: \(error)")
        }
    }
}

// MARK: - Post card for profile grid

private struct ProfilePostCard: View {
    let post: FeedPost

    private let cardBg = Color(red: 0.10, green: 0.08, blue: 0.18)
    private let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail — load from Firebase Storage URL
            if let urlString = post.allPhotoURLs.first, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 130)
                            .clipped()
                    default:
                        placeholderThumbnail
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 130)
                .clipped()
            } else {
                placeholderThumbnail
            }

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(post.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text("💪")
                        .font(.system(size: 10))
                    Text("\(post.reps)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.50))
                    Spacer()
                    if let date = post.createdAtDate {
                        Text(date, style: .date)
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(cardBg)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(purpl.opacity(0.12), lineWidth: 1)
        )
        .clipped()
    }

    private var placeholderThumbnail: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.18, green: 0.08, blue: 0.35),
                         Color(red: 0.08, green: 0.05, blue: 0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 90)
            Text("🔥")
                .font(.system(size: 30))
        }
    }
}
