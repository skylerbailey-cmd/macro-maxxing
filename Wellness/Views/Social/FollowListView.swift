//
//  FollowListView.swift
//  Wellness
//
//  Displays a user's followers or following list loaded from Firestore.
//  Open in .followers mode to show who follows `userID`.
//  Open in .following mode to show who `userID` follows.
//  Pass `currentUserSettings` to enable follow/unfollow actions on each row.
//

import SwiftUI

// MARK: - FollowListView

struct FollowListView: View {

    // MARK: Parameters

    enum Mode {
        case followers, following
    }

    let userID:              String
    let mode:                Mode
    /// Settings for the currently logged-in viewer — enables follow/unfollow buttons.
    var currentUserSettings: UserSettings? = nil

    // MARK: State

    @State private var entries:      [FollowEntry] = []
    @State private var isLoading:    Bool          = true
    @State private var followingIDs: Set<String>   = []
    @State private var loadingIDs:   Set<String>   = []
    @State private var followErrorMessage: String? = nil

    // MARK: Palette

    private let pageBg = Color(red: 0.04, green: 0.03, blue: 0.08)
    private let cardBg = Color(red: 0.10, green: 0.08, blue: 0.18)
    private let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)
    private let neon   = Color(red: 0.35, green: 1.00, blue: 0.60)

    // MARK: Body

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(purpl)
            } else if entries.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(entries) { entry in
                            entryRow(entry: entry)
                            Divider()
                                .background(purpl.opacity(0.10))
                                .padding(.leading, 72)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadData() }
        .alert(
            "Follow failed",
            isPresented: Binding(
                get: { followErrorMessage != nil },
                set: { if !$0 { followErrorMessage = nil } }
            ),
            presenting: followErrorMessage
        ) { _ in
            Button("OK", role: .cancel) { followErrorMessage = nil }
        } message: { msg in
            Text(msg)
        }
    }

    // MARK: - Nav Title

    private var navTitle: String {
        let count = entries.count
        switch mode {
        case .followers: return count == 1 ? "1 Follower" : "\(count) Followers"
        case .following: return "\(count) Following"
        }
    }

    // MARK: - Entry Row

    @ViewBuilder
    private func entryRow(entry: FollowEntry) -> some View {
        NavigationLink {
            ProfileView(
                profileUserID:       entry.userID,
                profileUsername:     entry.username,
                profileDisplayName:  entry.displayName ?? entry.username,
                profileAuraLevel:    0,
                profileAuraPoints:   0,
                profileImageData:    nil,
                currentUserSettings: currentUserSettings
            )
        } label: {
            HStack(spacing: 12) {
                userAvatar(url: entry.profilePhotoURL, name: entry.displayName ?? entry.username, size: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text((entry.displayName?.isEmpty == false ? entry.displayName : nil) ?? entry.username)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text("@\(entry.username)")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.40))
                }

                Spacer()

                if let viewer = currentUserSettings, viewer.userID != entry.userID {
                    if mode == .following {
                        unfollowMinusButton(for: entry)
                    } else {
                        followButton(for: entry)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Unfollow (red minus) — shown in .following mode

    @ViewBuilder
    private func unfollowMinusButton(for entry: FollowEntry) -> some View {
        let isLoading = loadingIDs.contains(entry.userID)
        Button {
            Task { await toggleFollow(entry: entry) }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.red.opacity(0.40), lineWidth: 1))
                if isLoading {
                    ProgressView().scaleEffect(0.55).tint(.red)
                } else {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.red)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    // MARK: - Follow Button — shown in .followers mode

    @ViewBuilder
    private func followButton(for entry: FollowEntry) -> some View {
        let isFollowing = followingIDs.contains(entry.userID)
        let isLoading   = loadingIDs.contains(entry.userID)

        Button {
            Task { await toggleFollow(entry: entry) }
        } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.75)
                        .frame(width: 80, height: 30)
                } else if isFollowing {
                    Text("Following")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(neon)
                        .frame(width: 80, height: 30)
                        .background(neon.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(neon.opacity(0.35), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Text("Follow")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.black)
                        .frame(width: 80, height: 30)
                        .background(
                            LinearGradient(
                                colors: [gold, Color(red: 1.0, green: 0.60, blue: 0.10)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    // MARK: - Avatar

    @ViewBuilder
    private func userAvatar(url: String, name: String, size: CGFloat) -> some View {
        if let imageURL = URL(string: url), !url.isEmpty {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                default:
                    avatarPlaceholder(name: name, size: size)
                }
            }
        } else {
            avatarPlaceholder(name: name, size: size)
        }
    }

    private func avatarPlaceholder(name: String, size: CGFloat) -> some View {
        Circle()
            .fill(LinearGradient(
                colors: [purpl.opacity(0.40), Color(red: 0.30, green: 0.10, blue: 0.60)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .frame(width: size, height: size)
            .overlay {
                Text(String((name.isEmpty ? "?" : name).prefix(1)).uppercased())
                    .font(.system(size: size * 0.38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text(mode == .followers ? "👥" : "🔍")
                .font(.system(size: 40))
            Text(mode == .followers ? "No followers yet." : "Not following anyone yet.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.30))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data Loading

    private func loadData() async {
        async let entriesFetch: [FollowEntry] = {
            switch mode {
            case .followers: return (try? await FollowService.shared.fetchFollowers(userID: userID)) ?? []
            case .following: return (try? await FollowService.shared.fetchFollowing(userID: userID)) ?? []
            }
        }()

        async let viewerFollowingFetch: [FollowEntry] = {
            guard let viewer = currentUserSettings, !viewer.userID.isEmpty else { return [] }
            return (try? await FollowService.shared.fetchFollowing(userID: viewer.userID)) ?? []
        }()

        let (loaded, viewerFollowing) = await (entriesFetch, viewerFollowingFetch)

        entries      = loaded
        followingIDs = Set(viewerFollowing.map { $0.userID })
        isLoading    = false
    }

    // MARK: - Toggle Follow

    private func toggleFollow(entry: FollowEntry) async {
        guard let viewer = currentUserSettings, !viewer.userID.isEmpty else { return }
        let targetID = entry.userID
        guard !loadingIDs.contains(targetID) else { return }

        loadingIDs.insert(targetID)
        defer { loadingIDs.remove(targetID) }

        let wasFollowing = followingIDs.contains(targetID)
        do {
            if wasFollowing {
                try await FollowService.shared.unfollowUser(
                    currentUserID: viewer.userID,
                    targetUserID:  targetID
                )
                followingIDs.remove(targetID)
            } else {
                let viewerPhotoURL = (try? await UserProfileService.shared.fetchProfile(
                    userID: viewer.userID
                ))?.profilePhotoURL ?? ""

                try await FollowService.shared.followUser(
                    currentUserID:          viewer.userID,
                    currentUsername:        viewer.username,
                    currentProfilePhotoURL: viewerPhotoURL,
                    targetUserID:           targetID,
                    targetUsername:         entry.username,
                    targetProfilePhotoURL:  entry.profilePhotoURL
                )
                followingIDs.insert(targetID)
            }
        } catch {
            AppLogger.log("[FollowListView] toggleFollow error: \(error)")
            followErrorMessage = wasFollowing
                ? "Couldn't unfollow @\(entry.username). \(error.localizedDescription)"
                : "Couldn't follow @\(entry.username). \(error.localizedDescription)"
        }
    }
}
