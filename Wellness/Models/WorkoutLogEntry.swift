//
//  WorkoutLogEntry.swift
//  Wellness
//
//  SwiftData model for workout entries attached to a SocialPost.
//

import Foundation
import SwiftData

@Model final class WorkoutLogEntry {
    var workoutName:     String = ""
    var workoutType:     String = ""   // WorkoutType.rawValue
    var durationMinutes: Int    = 0
    var caloriesBurned:  Int    = 0
    var loggedAt:        Date   = Date()
    var sortOrder:       Int    = 0

    // Gym / location tag — mirrors WorkoutEntry.location. Defaults keep
    // old rows safe during SwiftData migration (all-zero / empty = untagged).
    var gymName:      String = ""
    var gymAddress:   String = ""
    var gymLatitude:  Double = 0.0
    var gymLongitude: Double = 0.0

    // Friends tagged on this workout — stored as JSON because SwiftData
    // doesn't hold arrays of Codable structs directly. Empty string =
    // no tags, which keeps migration of old rows trivial.
    var taggedFriendsJSON: String = ""

    var post: SocialPost?

    init(workoutName: String, workoutType: String, durationMinutes: Int,
         caloriesBurned: Int, loggedAt: Date, sortOrder: Int,
         gymName: String = "", gymAddress: String = "",
         gymLatitude: Double = 0.0, gymLongitude: Double = 0.0,
         taggedFriends: [TaggedFriend] = []) {
        self.workoutName     = workoutName
        self.workoutType     = workoutType
        self.durationMinutes = durationMinutes
        self.caloriesBurned  = caloriesBurned
        self.loggedAt        = loggedAt
        self.sortOrder       = sortOrder
        self.gymName         = gymName
        self.gymAddress      = gymAddress
        self.gymLatitude     = gymLatitude
        self.gymLongitude    = gymLongitude
        self.taggedFriends   = taggedFriends
    }

    /// Rehydrated array — nil-safe JSON decode, returns [] for empty or bad data.
    var taggedFriends: [TaggedFriend] {
        get {
            guard let data = taggedFriendsJSON.data(using: .utf8),
                  !taggedFriendsJSON.isEmpty else { return [] }
            return (try? JSONDecoder().decode([TaggedFriend].self, from: data)) ?? []
        }
        set {
            guard !newValue.isEmpty,
                  let data = try? JSONEncoder().encode(newValue),
                  let json = String(data: data, encoding: .utf8) else {
                taggedFriendsJSON = ""
                return
            }
            taggedFriendsJSON = json
        }
    }

    var formattedDuration: String {
        durationMinutes >= 60
            ? "\(durationMinutes / 60)h \(durationMinutes % 60)m"
            : "\(durationMinutes)m"
    }

    /// Convenience: the tagged gym rebuilt as a `WorkoutLocation`, or nil
    /// when the fields are at their "no gym" defaults.
    var location: WorkoutLocation? {
        guard !gymName.isEmpty else { return nil }
        return WorkoutLocation(name: gymName, address: gymAddress,
                               latitude: gymLatitude, longitude: gymLongitude)
    }
}
