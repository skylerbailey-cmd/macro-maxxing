//
//  UserProfile.swift
//  Wellness
//
//  Firestore-backed user profile model.
//  Collection: "users"  Document ID: userID
//

import Foundation
import FirebaseFirestore

struct UserProfile: Codable, Identifiable {

    // MARK: - Identity

    /// Populated by Firestore on read; matches the document ID.
    @DocumentID var userID: String?

    var username:        String
    var name:            String
    var location:        String
    var profilePhotoURL: String

    // MARK: - Stats

    var auraPoints:     Int
    var streakDays:     Int
    var friendCount:    Int
    /// Number of users this account is following. Kept in sync by FollowService.
    var followingCount: Int
    /// Number of users following this account. Kept in sync by FollowService.
    var followerCount:  Int

    // MARK: - Dates

    /// Unix timestamp (seconds) of when the profile was created.
    var joinDate: Int

    // MARK: - Identifiable

    var id: String { userID ?? UUID().uuidString }

    // MARK: - Init

    init(
        userID:          String? = nil,
        username:        String,
        name:            String,
        location:        String,
        profilePhotoURL: String,
        auraPoints:      Int,
        streakDays:      Int,
        friendCount:     Int,
        followingCount:  Int = 0,
        followerCount:   Int = 0,
        joinDate:        Int
    ) {
        self._userID         = DocumentID(wrappedValue: userID)
        self.username        = username
        self.name            = name
        self.location        = location
        self.profilePhotoURL = profilePhotoURL
        self.auraPoints      = auraPoints
        self.streakDays      = streakDays
        self.friendCount     = friendCount
        self.followingCount  = followingCount
        self.followerCount   = followerCount
        self.joinDate        = joinDate
    }
}

// MARK: - Firestore Helpers

extension UserProfile {

    /// Decodes a UserProfile from a Firestore DocumentSnapshot.
    init?(document: DocumentSnapshot) {
        guard document.exists else { return nil }
        do {
            self = try Firestore.Decoder().decode(UserProfile.self, from: document.data() ?? [:])
        } catch {
            print("[UserProfile] Decode error – \(document.documentID): \(error)")
            return nil
        }
    }

    /// Encodes this UserProfile to a Firestore-compatible dictionary.
    func firestoreData() throws -> [String: Any] {
        try Firestore.Encoder().encode(self)
    }
}
