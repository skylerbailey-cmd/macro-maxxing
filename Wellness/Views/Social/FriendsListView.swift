//
//  FriendsListView.swift
//  Wellness
//
//  Shows all mutual follows (friends) for a given user.
//  Each row displays: avatar, display name, @username, aura level, streak.
//

import SwiftUI

struct FriendsListView: View {

    // MARK: Parameters

    let userID:              String
    var currentUserSettings: UserSettings? = nil

    // MARK: State

    @State private var friends:   [UserProfile] = []
    @State private var isLoading: Bool          = true

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
            } else if friends.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(friends) { profile in
                            friendRow(profile: profile)
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
        .task { await loadFriends() }
    }

    // MARK: - Nav Title

    private var navTitle: String {
        friends.count == 1 ? "1 Friend" : "\(friends.count) Friends"
    }

    // MARK: - Friend Row

    @ViewBuilder
    private func friendRow(profile: UserProfile) -> some View {
        NavigationLink {
            ProfileView(
                profileUserID:       profile.id,
                profileUsername:     profile.username,
                profileDisplayName:  profile.name,
                profileAuraLevel:    auraLevel(for: profile.auraPoints),
                profileAuraPoints:   profile.auraPoints,
                profileImageData:    nil,
                currentUserSettings: currentUserSettings,
                isDismissable:       false
            )
        } label: {
            HStack(spacing: 12) {
                // Avatar
                userAvatar(url: profile.profilePhotoURL, name: profile.name.isEmpty ? profile.username : profile.name, size: 48)

                // Name + username
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name.isEmpty ? profile.username : profile.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text("@\(profile.username)")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.40))
                }

                Spacer()

                // Level + streak
                HStack(spacing: 10) {
                    // Aura level badge
                    let level = auraLevel(for: profile.auraPoints)
                    if level > 0 {
                        Text("Lv \(level)")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(gold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(gold.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(gold.opacity(0.25), lineWidth: 1))
                    }

                    // Streak
                    if profile.streakDays > 0 {
                        HStack(spacing: 3) {
                            Text("🔥")
                                .font(.system(size: 11))
                            Text("\(profile.streakDays)")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(Color(red: 1.00, green: 0.60, blue: 0.15))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
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
            Text("🤝")
                .font(.system(size: 40))
            Text("No friends yet.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.30))
            Text("Follow someone back to become friends.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.18))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data Loading

    private func loadFriends() async {
        friends   = (try? await FollowService.shared.fetchFriends(userID: userID)) ?? []
        isLoading = false
    }

    // MARK: - Helpers

    private func auraLevel(for points: Int) -> Int {
        min(points / 1000, 100)
    }
}
