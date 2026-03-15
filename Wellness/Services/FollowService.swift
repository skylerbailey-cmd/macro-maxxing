//
//  FollowService.swift
//  Wellness
//
//  Manages follow/unfollow relationships in Firestore using batch writes
//  so both sides of the relationship always succeed or fail together.
//
//  Following:  users/{userA}/following/{userB}
//  Followers:  users/{userB}/followers/{userA}
//  Counts:     users/{userA}.followingCount  |  users/{userB}.followerCount
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

    /// Writes a following document for userA and a followers document for userB
    /// in a single batch, then increments followingCount on userA and
    /// followerCount on userB — all atomically.
    func followUser(
        currentUserID:          String,
        currentUsername:        String,
        currentProfilePhotoURL: String,
        targetUserID:           String,
        targetUsername:         String,
        targetProfilePhotoURL:  String
    ) async throws {
        guard currentUserID != targetUserID else { return }

        let now   = Date()
        let batch = db.batch()

        // 1a. users/{currentUser}/following/{targetUser}
        let followingEntry = FollowEntry(
            userID:          targetUserID,
            username:        targetUsername,
            profilePhotoURL: targetProfilePhotoURL,
            followedAt:      now
        )
        let followingRef = db.collection("users").document(currentUserID)
            .collection("following").document(targetUserID)
        batch.setData(try Firestore.Encoder().encode(followingEntry), forDocument: followingRef)

        // 1b. users/{targetUser}/followers/{currentUser}
        let followerEntry = FollowEntry(
            userID:          currentUserID,
            username:        currentUsername,
            profilePhotoURL: currentProfilePhotoURL,
            followedAt:      now
        )
        let followersRef = db.collection("users").document(targetUserID)
            .collection("followers").document(currentUserID)
        batch.setData(try Firestore.Encoder().encode(followerEntry), forDocument: followersRef)

        // 2a. Increment followingCount on currentUser's profile
        let currentUserRef = db.collection("users").document(currentUserID)
        batch.updateData(
            ["followingCount": FieldValue.increment(Int64(1))],
            forDocument: currentUserRef
        )

        // 2b. Increment followerCount on targetUser's profile
        let targetUserRef = db.collection("users").document(targetUserID)
        batch.updateData(
            ["followerCount": FieldValue.increment(Int64(1))],
            forDocument: targetUserRef
        )

        try await batch.commit()
        print("[FollowService] \(currentUserID) followed \(targetUserID)")
    }

    // MARK: - 2. Unfollow User

    /// Deletes both relationship documents and decrements the counts atomically.
    func unfollowUser(currentUserID: String, targetUserID: String) async throws {
        let batch = db.batch()

        // Delete following doc
        let followingRef = db.collection("users").document(currentUserID)
            .collection("following").document(targetUserID)
        batch.deleteDocument(followingRef)

        // Delete followers doc
        let followersRef = db.collection("users").document(targetUserID)
            .collection("followers").document(currentUserID)
        batch.deleteDocument(followersRef)

        // Decrement counts (floor at 0 via max in Cloud Functions if needed;
        // FieldValue.increment with a negative value is safe in practice)
        let currentUserRef = db.collection("users").document(currentUserID)
        batch.updateData(
            ["followingCount": FieldValue.increment(Int64(-1))],
            forDocument: currentUserRef
        )

        let targetUserRef = db.collection("users").document(targetUserID)
        batch.updateData(
            ["followerCount": FieldValue.increment(Int64(-1))],
            forDocument: targetUserRef
        )

        try await batch.commit()
        print("[FollowService] \(currentUserID) unfollowed \(targetUserID)")
    }

    // MARK: - 3. Is Following

    /// Returns true if `currentUserID` is currently following `targetUserID`.
    /// Checks by document existence — no full read required.
    func isFollowing(currentUserID: String, targetUserID: String) async throws -> Bool {
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
            .order(by: "followedAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            try? Firestore.Decoder().decode(FollowEntry.self, from: doc.data())
        }
    }

    // MARK: - 5. Fetch Followers

    /// Returns all users that are currently following `userID`, ordered newest first.
    func fetchFollowers(userID: String) async throws -> [FollowEntry] {
        guard !userID.isEmpty else { return [] }
        let snapshot = try await db.collection("users").document(userID)
            .collection("followers")
            .order(by: "followedAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            try? Firestore.Decoder().decode(FollowEntry.self, from: doc.data())
        }
    }
}
