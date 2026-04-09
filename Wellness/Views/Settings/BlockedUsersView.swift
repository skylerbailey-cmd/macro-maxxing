//
//  BlockedUsersView.swift
//  Wellness
//
//  Shows all users the current user has blocked, with the option to unblock.
//

import SwiftUI

struct BlockedUsersView: View {

    let currentUserID: String

    @State private var blockedUsers:  [BlockedUserEntry] = []
    @State private var isLoading      = true
    @State private var unblockingIDs: Set<String> = []

    private let pageBg = Color(red: 0.04, green: 0.03, blue: 0.08)
    private let cardBg = Color(red: 0.10, green: 0.08, blue: 0.18)
    private let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(purpl)
            } else if blockedUsers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.15))
                    Text("No blocked users")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.35))
                }
            } else {
                List {
                    ForEach(blockedUsers) { user in
                        HStack(spacing: 12) {
                            userAvatar(user)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayName.isEmpty ? user.username : user.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text("@\(user.username)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.40))
                            }
                            Spacer()
                            unblockButton(user)
                        }
                        .listRowBackground(cardBg)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .task { await loadBlockedUsers() }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func userAvatar(_ user: BlockedUserEntry) -> some View {
        if let url = URL(string: user.profilePhotoURL), !user.profilePhotoURL.isEmpty {
            AsyncImage(url: url) { phase in
                if case .success(let img) = phase {
                    img.resizable().scaledToFill()
                        .frame(width: 40, height: 40).clipShape(Circle())
                } else {
                    avatarPlaceholder(name: user.displayName.isEmpty ? user.username : user.displayName)
                }
            }
        } else {
            avatarPlaceholder(name: user.displayName.isEmpty ? user.username : user.displayName)
        }
    }

    private func avatarPlaceholder(name: String) -> some View {
        Circle()
            .fill(purpl.opacity(0.25))
            .frame(width: 40, height: 40)
            .overlay {
                Text(String((name.isEmpty ? "?" : name).prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(purpl)
            }
    }

    @ViewBuilder
    private func unblockButton(_ user: BlockedUserEntry) -> some View {
        Button {
            Task { await unblock(user) }
        } label: {
            if unblockingIDs.contains(user.userID) {
                ProgressView().scaleEffect(0.7)
            } else {
                Text("Unblock")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.12))
                    .cornerRadius(8)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data

    private func loadBlockedUsers() async {
        do {
            blockedUsers = try await BlockService.shared.fetchBlockedUsers(userID: currentUserID)
        } catch {
            print("[BlockedUsersView] Failed to load: \(error)")
        }
        isLoading = false
    }

    private func unblock(_ user: BlockedUserEntry) async {
        unblockingIDs.insert(user.userID)
        do {
            try await BlockService.shared.unblockUser(currentUserID: currentUserID, targetUserID: user.userID)
            blockedUsers.removeAll { $0.userID == user.userID }
        } catch {
            print("[BlockedUsersView] Unblock failed: \(error)")
        }
        unblockingIDs.remove(user.userID)
    }
}
