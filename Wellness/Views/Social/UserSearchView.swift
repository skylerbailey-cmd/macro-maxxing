//
//  UserSearchView.swift
//  Wellness
//
//  Searchable user directory backed by Firestore.
//  • Empty state  → location-based suggestions (up to 10)
//  • Typing       → live prefix search across username + name (0.3 s debounce)
//  • Each row     → photo, username, name, location, follower count, follow/unfollow
//

import SwiftUI

// MARK: - UserSearchView

struct UserSearchView: View {

    let currentUserSettings: UserSettings

    // MARK: State

    @State private var searchText    = ""
    @State private var results:      [UserProfile] = []
    @State private var suggestions:  [UserProfile] = []
    @State private var followingIDs: Set<String>   = []
    @State private var loadingIDs:   Set<String>   = []
    @State private var isSearching   = false
    @State private var searchTask:   Task<Void, Never>?

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

            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                if isSearching {
                    loadingRow
                } else if searchText.isEmpty {
                    suggestionsSection
                } else {
                    resultsSection
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Find People")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadInitialData() }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(purpl.opacity(0.70))
                .font(.system(size: 15, weight: .semibold))

            TextField("Search username or name", text: $searchText)
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: searchText) { _, newValue in
                    scheduleSearch(query: newValue)
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    results    = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.35))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(purpl.opacity(0.20), lineWidth: 1)
        )
    }

    // MARK: - Loading Indicator

    private var loadingRow: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(purpl)
            Text("Searching…")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.40))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 40)
    }

    // MARK: - Suggestions Section

    private var suggestionsSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader(
                    title: "PEOPLE NEAR YOU",
                    subtitle: currentUserSettings.location.isEmpty ? nil : currentUserSettings.location
                )

                if suggestions.isEmpty {
                    emptyState(message: "No suggestions yet.\nUpdate your location in Settings to find nearby users.")
                } else {
                    ForEach(suggestions) { profile in
                        userRow(profile: profile)
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader(title: "RESULTS", subtitle: nil)

                if results.isEmpty {
                    emptyState(message: "No users found for "\(searchText)"")
                } else {
                    ForEach(results) { profile in
                        userRow(profile: profile)
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - User Row

    @ViewBuilder
    private func userRow(profile: UserProfile) -> some View {
        NavigationLink {
            ProfileView(
                profileUserID:      profile.id,
                profileUsername:    profile.username,
                profileDisplayName: profile.name,
                profileAuraLevel:   auraLevel(for: profile.auraPoints),
                profileAuraPoints:  profile.auraPoints,
                profileImageData:   nil,
                profileLocation:    profile.location,
                profileStreak:      profile.streakDays,
                currentUserSettings: currentUserSettings
            )
        } label: {
            HStack(spacing: 12) {
                // Avatar
                userAvatar(url: profile.profilePhotoURL, name: profile.name, size: 48)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(profile.username)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    if !profile.name.isEmpty {
                        Text(profile.name)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.50))
                    }
                    HStack(spacing: 10) {
                        if !profile.location.isEmpty {
                            Label(profile.location, systemImage: "mappin.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(purpl.opacity(0.60))
                        }
                        Label("\(profile.followerCount)", systemImage: "person.2.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.30))
                    }
                }

                Spacer()

                // Follow / Unfollow button
                followButton(for: profile)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)

        Divider()
            .background(purpl.opacity(0.10))
            .padding(.leading, 76)
    }

    // MARK: - Follow Button

    @ViewBuilder
    private func followButton(for profile: UserProfile) -> some View {
        let isFollowing = followingIDs.contains(profile.id)
        let isLoading   = loadingIDs.contains(profile.id)

        Button {
            Task { await toggleFollow(profile: profile) }
        } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.75)
                        .frame(width: 72, height: 30)
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

    // MARK: - Section Header

    private func sectionHeader(title: String, subtitle: String?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.30))
            if let sub = subtitle, !sub.isEmpty {
                Text("· \(sub)")
                    .font(.system(size: 10))
                    .foregroundStyle(purpl.opacity(0.50))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Empty State

    private func emptyState(message: String) -> some View {
        Text(message)
            .font(.system(size: 13))
            .foregroundStyle(.white.opacity(0.25))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.top, 40)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Data Loading

    private func loadInitialData() async {
        // Load current user's following list
        if let ids = try? await FollowService.shared.fetchFollowing(userID: currentUserSettings.userID) {
            followingIDs = Set(ids.map { $0.userID })
        }

        // Load location-based suggestions
        if let suggested = try? await UserSearchService.shared.fetchSuggestedUsers(
            currentUserID: currentUserSettings.userID,
            location:      currentUserSettings.location,
            followingIDs:  followingIDs
        ) {
            suggestions = suggested
        }
    }

    // MARK: - Debounced Search

    private func scheduleSearch(query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else {
            results    = []
            isSearching = false
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            await MainActor.run { isSearching = true }

            let found = (try? await UserSearchService.shared.search(
                query:           trimmed,
                excludingUserID: currentUserSettings.userID
            )) ?? []

            guard !Task.isCancelled else { return }
            await MainActor.run {
                results     = found
                isSearching = false
            }
        }
    }

    // MARK: - Follow / Unfollow

    private func toggleFollow(profile: UserProfile) async {
        let targetID = profile.id
        guard !loadingIDs.contains(targetID) else { return }

        loadingIDs.insert(targetID)
        defer { loadingIDs.remove(targetID) }

        do {
            if followingIDs.contains(targetID) {
                try await FollowService.shared.unfollowUser(
                    currentUserID: currentUserSettings.userID,
                    targetUserID:  targetID
                )
                followingIDs.remove(targetID)
                // Decrement local follower count so the row updates instantly
                if let idx = results.firstIndex(where: { $0.id == targetID }) {
                    results[idx].followerCount = max(0, results[idx].followerCount - 1)
                }
                if let idx = suggestions.firstIndex(where: { $0.id == targetID }) {
                    suggestions[idx].followerCount = max(0, suggestions[idx].followerCount - 1)
                }
            } else {
                let viewerPhotoURL = (try? await UserProfileService.shared.fetchProfile(
                    userID: currentUserSettings.userID
                ))?.profilePhotoURL ?? ""

                try await FollowService.shared.followUser(
                    currentUserID:          currentUserSettings.userID,
                    currentUsername:        currentUserSettings.username,
                    currentProfilePhotoURL: viewerPhotoURL,
                    targetUserID:           targetID,
                    targetUsername:         profile.username,
                    targetProfilePhotoURL:  profile.profilePhotoURL
                )
                followingIDs.insert(targetID)
                // Increment local follower count
                if let idx = results.firstIndex(where: { $0.id == targetID }) {
                    results[idx].followerCount += 1
                }
                if let idx = suggestions.firstIndex(where: { $0.id == targetID }) {
                    suggestions[idx].followerCount += 1
                }
            }
        } catch {
            print("[UserSearchView] toggleFollow error: \(error)")
        }
    }

    // MARK: - Helpers

    private func auraLevel(for points: Int) -> Int {
        switch points {
        case 0:         return 0
        case 1..<100:   return 1
        case 100..<500: return 10
        case 500..<1000: return 25
        case 1000..<2500: return 40
        case 2500..<5000: return 60
        case 5000..<10000: return 80
        default:        return 95
        }
    }
}
