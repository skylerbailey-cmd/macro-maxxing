//
//  FriendTagPickerView.swift
//  Wellness
//
//  Multi-select sheet for tagging friends on a workout. Source list is
//  the user's MUTUAL follows (friends), fetched via FollowService —
//  one-way followers don't appear here by design.
//
//  Returns the final `[TaggedFriend]` via an `onDone` closure so the
//  caller can attach them to whatever it's building (a WorkoutEntry
//  being saved, etc).
//

import SwiftUI

struct FriendTagPickerView: View {
    /// Current user ID — used to fetch the right friend list.
    let currentUserID: String
    /// Friends already selected on the calling screen. Pre-checks
    /// their rows so the user sees their existing selection.
    let initialSelection: [TaggedFriend]
    /// Called with the final selection when the user taps Done.
    let onDone: ([TaggedFriend]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var query:     String = ""
    @State private var friends:   [UserProfile] = []
    @State private var selection: Set<String> = []
    @State private var isLoading: Bool = true
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pageBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchField
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    if isLoading && friends.isEmpty {
                        Spacer()
                        ProgressView().tint(.white.opacity(0.5))
                        Spacer()
                    } else if friends.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(filtered, id: \.userID) { profile in
                                    friendRow(profile)
                                    divider
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("Tag Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDone(buildResult())
                        dismiss()
                    }
                    .bold()
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                selection = Set(initialSelection.map { $0.userID })
                Task { await loadFriends() }
            }
        }
    }

    // MARK: - Derived

    private var filtered: [UserProfile] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return friends }
        return friends.filter {
            $0.username.lowercased().contains(trimmed)
                || $0.name.lowercased().contains(trimmed)
        }
    }

    private func buildResult() -> [TaggedFriend] {
        friends
            .filter { selection.contains($0.userID) }
            .map {
                TaggedFriend(
                    userID:      $0.userID,
                    username:    $0.username,
                    displayName: $0.name
                )
            }
    }

    // MARK: - Rows

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.50))
            TextField("", text: $query, prompt:
                Text("Search friends").foregroundStyle(.white.opacity(0.40))
            )
            .textFieldStyle(.plain)
            .autocorrectionDisabled()
            .foregroundStyle(.white)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.cardBg, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    private func friendRow(_ profile: UserProfile) -> some View {
        let isSelected = selection.contains(profile.userID)
        return Button {
            if isSelected { selection.remove(profile.userID) }
            else          { selection.insert(profile.userID) }
        } label: {
            HStack(spacing: 12) {
                avatarCircle(size: 36, data: nil,
                             urlString: profile.profilePhotoURL,
                             initial: String(profile.name.prefix(1).uppercased()))
                VStack(alignment: .leading, spacing: 1) {
                    Text(profile.name.isEmpty ? profile.username : profile.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("@\(profile.username)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSelected
                                     ? ThemeStore.shared.accent
                                     : Color.white.opacity(0.30))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .frame(height: 1)
            .padding(.leading, 64)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "person.2.slash")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.20))
            Text(loadError ?? "No mutual friends yet")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))
            Text("Friends tag you back — once you follow each other, they'll appear here.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Loading

    @MainActor
    private func loadFriends() async {
        do {
            let profiles = try await FollowService.shared.fetchFriends(userID: currentUserID)
            friends = profiles
        } catch {
            loadError = "Couldn't load friends. Pull to retry."
            AppLogger.log("[FriendTagPickerView] fetchFriends failed: \(error.localizedDescription)")
        }
        isLoading = false
    }
}
