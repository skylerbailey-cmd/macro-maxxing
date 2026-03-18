//
//  FollowEntry.swift
//  Wellness
//
//  Represents a single document in either the following or followers subcollection.
//
//  Following:  users/{userA}/following/{userB}
//  Followers:  users/{userB}/followers/{userA}
//

import Foundation
import FirebaseFirestore

struct FollowEntry: Codable, Identifiable {

    /// Document ID — the userID of the person being represented in this collection.
    @DocumentID var documentID: String?

    /// UserID of the person this entry represents.
    var userID:          String
    var username:        String
    var displayName:     String?
    var profilePhotoURL: String
    var followedAt:      Timestamp?

    var id: String { userID }

    var followedAtDate: Date { followedAt?.dateValue() ?? .distantPast }

    init(userID: String, username: String, displayName: String? = nil, profilePhotoURL: String, followedAt: Date = Date()) {
        self.userID          = userID
        self.username        = username
        self.displayName     = displayName
        self.profilePhotoURL = profilePhotoURL
        self.followedAt      = Timestamp(date: followedAt)
    }

    /// Tolerant init from a Firestore document — never returns nil even if fields are missing.
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let uid = data["userID"] as? String, !uid.isEmpty else { return nil }
        userID          = uid
        username        = data["username"] as? String ?? ""
        displayName     = data["displayName"] as? String
        profilePhotoURL = data["profilePhotoURL"] as? String ?? ""
        followedAt      = data["followedAt"] as? Timestamp
    }
}
