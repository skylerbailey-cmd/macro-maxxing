//
//  TaggedFriend.swift
//  Wellness
//
//  Lightweight representation of a friend tagged on a workout. Stored
//  denormalized (userID + display snapshot) so the UI can render the
//  tag without a follow-up profile fetch. `userID` is still the
//  identity source of truth — use it for linking / navigation.
//

import Foundation

struct TaggedFriend: Codable, Hashable, Identifiable {
    let userID:      String
    /// Username WITHOUT leading "@" — the renderer adds it.
    let username:    String
    /// Display name at tag time. May drift from the friend's current
    /// display name if they rename after being tagged — intentional,
    /// the tag is a snapshot.
    let displayName: String

    var id: String { userID }
}
