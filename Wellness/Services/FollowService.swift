//
//  FollowService.swift
//  Wellness
//
//  Manages follow/unfollow relationships in Firestore.
//
//  The client writes only one document — `users/{currentUser}/following/{target}`.
//  A Cloud Function trigger (`onFollowCreate` / `onFollowDelete`) mirrors the
//  relationship into `users/{target}/followers/{currentUser}` and updates the
//  cached counters (followingCount, followerCount, friendCount) on both user
//  docs. This keeps rules tight: each user can only write to their own
//  document and their own subcollections.
//
//  Following:  users/{userA}/following/{userB}   (written by client)
//  Followers:  users/{userB}/followers/{userA}   (written by trigger, admin SDK)
//  Counts:     users/{userA}.followingCount  |  users/{userB}.followerCount
//              users/{X}.friendCount                 (mutual follows)
//

import Foundation
import FirebaseFirestore

final class FollowService {

    // MARK: - Singleton

    static let shared = FollowService()
    private init() {}

    // MARK: - Private refs

    private var db: Firestore { FirebaseManager.shared.db }

    // MARK: - Errors

    enum FollowError: LocalizedError {
        case alreadyFollowing
        case notFollowing

        var errorDescription: String? {
            switch self {
            case .alreadyFollowing: return "You are already following this user."
            case .notFollowing:     return "You are not following this user."
            }
        }
    }

    // MARK: - 1. Follow User

    /// Writes `users/{currentUser}/following/{targetUser}`. The onFollowCreate
    /// Cloud Function mirrors this into the target's followers subcollection
    /// and updates the cached follower / friend counters.
    ///
    /// The current / target username / photo parameters are kept on the
    /// signature for backwards-compatibility and are stored on the following
    /// doc so the caller's "Following" list renders without a join.
    func followUser(
        currentUserID:          String,
        currentUsername:        String,
        currentDisplayName:     String? = nil,
        currentProfilePhotoURL: String,
        targetUserID:           String,
        targetUsername:         String,
        targetDisplayName:      String? = nil,
        targetProfilePhotoURL:  String
    ) async throws {
        guard !currentUserID.isEmpty, !targetUserID.isEmpty, currentUserID != targetUserID else { return }

        let followingEntry = FollowEntry(
            userID:          targetUserID,
            username:        targetUsername,
            displayName:     targetDisplayName,
            profilePhotoURL: targetProfilePhotoURL,
            followedAt:      Date()
        )
        let followingRef = db.collection("users").document(currentUserID)
            .collection("following").document(targetUserID)
        try await followingRef.setData(try Firestore.Encoder().encode(followingEntry))

        AppLogger.log("[FollowService] \(currentUserID) followed \(targetUserID)")
    }

    // MARK: - 2. Unfollow User

    /// Deletes `users/{currentUser}/following/{targetUser}`. The onFollowDelete
    /// Cloud Function removes the mirrored followers doc and decrements the
    /// cached counters.
    func unfollowUser(currentUserID: String, targetUserID: String) async throws {
        guard !currentUserID.isEmpty, !targetUserID.isEmpty else { return }
        try await db.collection("users").document(currentUserID)
            .collection("following").document(targetUserID)
            .delete()
        AppLogger.log("[FollowService] \(currentUserID) unfollowed \(targetUserID)")
    }

    // MARK: - 3. Is Following

    /// Returns true if `currentUserID` is currently following `targetUserID`.
    /// Checks by document existence — no full read required.
    func isFollowing(currentUserID: String, targetUserID: String) async throws -> Bool {
        guard !currentUserID.isEmpty, !targetUserID.isEmpty else { return false }
        let doc = try await db.collection("users").document(currentUserID)
            .collection("following").document(targetUserID)
            .getDocument()
        return doc.exists
    }

    // MARK: - 4. Fetch Following

    /// Returns all users that `userID` is currently following, ordered newest first.
    func fetchFollowing(userID: String) async throws -> [FollowEntry] {
        guard !userID.isEmpty else { return [] }
        let snapshot = try await db.collection("users").document(userID)
            .collection("following")
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            FollowEntry(document: doc)
        }
        .sorted { ($0.followedAt?.dateValue() ?? .distantPast) > ($1.followedAt?.dateValue() ?? .distantPast) }
    }

    // MARK: - 5. Fetch Followers

    /// Returns all users that are currently following `userID`, ordered newest first.
    func fetchFollowers(userID: String) async throws -> [FollowEntry] {
        guard !userID.isEmpty else { return [] }
        let snapshot = try await db.collection("users").document(userID)
            .collection("followers")
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            FollowEntry(document: doc)
        }
        .sorted { ($0.followedAt?.dateValue() ?? .distantPast) > ($1.followedAt?.dateValue() ?? .distantPast) }
    }

    // MARK: - 6. Fetch Friends (mutual follows)

    /// Returns UserProfiles for all users that mutually follow `userID` (i.e. friends).
    func fetchFriends(userID: String) async throws -> [UserProfile] {
        guard !userID.isEmpty else { return [] }

        async let followingFetch = fetchFollowing(userID: userID)
        async let followersFetch = fetchFollowers(userID: userID)
        let (following, followers) = try await (followingFetch, followersFetch)

        let followingIDs = Set(following.map { $0.userID })
        let followerIDs  = Set(followers.map { $0.userID })
        let friendIDs    = followingIDs.intersection(followerIDs)

        var profiles: [UserProfile] = []
        for id in friendIDs {
            if let profile = try? await UserProfileService.shared.fetchProfile(userID: id, includePrivateFields: false) {
                profiles.append(profile)
            }
        }
        return profiles.sorted { $0.username < $1.username }
    }
}
