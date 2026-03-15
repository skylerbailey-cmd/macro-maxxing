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
    var profilePhotoURL: String
    var followedAt:      Timestamp

    var id: String { userID }

    var followedAtDate: Date { followedAt.dateValue() }

    init(userID: String, username: String, profilePhotoURL: String, followedAt: Date = Date()) {
        self.userID          = userID
        self.username        = username
        self.profilePhotoURL = profilePhotoURL
        self.followedAt      = Timestamp(date: followedAt)
    }
}
