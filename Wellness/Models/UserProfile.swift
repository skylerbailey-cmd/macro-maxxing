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

    /// Stored as a plain field in Firestore so it survives encode/decode round-trips.
    var userID: String

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

    // MARK: - Settings (persisted so they survive sign-out / device switches)

    var bio:              String
    var instagramHandle:  String
    var tiktokHandle:     String
    var isPrivateAccount: Bool
    var currentWeight:    Double
    var goalWeight:       Double
    var heightInches:     Int
    var proteinPerLb:     Double
    var fastingEnabled:   Bool
    var auraPopupsEnabled: Bool

    // MARK: - Weekly aura (synced so it survives sign-out / device switches)

    var weeklyAuraPoints: Int
    /// Unix timestamp (seconds) of the Monday that opened the current weekly window.
    var weeklyAuraWeekStartTimestamp: Double

    // MARK: - Dates

    /// Unix timestamp (seconds) of when the profile was created.
    var joinDate: Int
    /// Date of birth stored as "yyyy-MM-dd". Empty string if not set.
    var dateOfBirth: String

    // MARK: - Identifiable

    var id: String { userID }

    // MARK: - Init

    init(
        userID:           String = "",
        username:         String,
        name:             String,
        location:         String,
        profilePhotoURL:  String,
        auraPoints:       Int,
        streakDays:       Int,
        friendCount:      Int,
        followingCount:   Int    = 0,
        followerCount:    Int    = 0,
        bio:              String = "",
        instagramHandle:  String = "",
        tiktokHandle:     String = "",
        isPrivateAccount: Bool   = false,
        currentWeight:    Double = 160,
        goalWeight:       Double = 160,
        heightInches:     Int    = 0,
        proteinPerLb:     Double = 0.9,
        fastingEnabled:   Bool   = false,
        auraPopupsEnabled: Bool  = true,
        weeklyAuraPoints: Int    = 0,
        weeklyAuraWeekStartTimestamp: Double = 0,
        joinDate:         Int,
        dateOfBirth:      String = ""
    ) {
        self.userID           = userID
        self.username         = username
        self.name             = name
        self.location         = location
        self.profilePhotoURL  = profilePhotoURL
        self.auraPoints       = auraPoints
        self.streakDays       = streakDays
        self.friendCount      = friendCount
        self.followingCount   = followingCount
        self.followerCount    = followerCount
        self.bio              = bio
        self.instagramHandle  = instagramHandle
        self.tiktokHandle     = tiktokHandle
        self.isPrivateAccount = isPrivateAccount
        self.currentWeight    = currentWeight
        self.goalWeight       = goalWeight
        self.heightInches     = heightInches
        self.proteinPerLb     = proteinPerLb
        self.fastingEnabled   = fastingEnabled
        self.auraPopupsEnabled = auraPopupsEnabled
        self.weeklyAuraPoints = weeklyAuraPoints
        self.weeklyAuraWeekStartTimestamp = weeklyAuraWeekStartTimestamp
        self.joinDate         = joinDate
        self.dateOfBirth      = dateOfBirth
    }
}

// MARK: - Firestore Helpers

extension UserProfile {

    /// Decodes a UserProfile from a Firestore DocumentSnapshot.
    /// Pre-fills any fields that may be absent from older documents so decoding
    /// never silently drops a user (e.g. friendCount added after initial launch).
    init?(document: DocumentSnapshot) {
        guard document.exists else { return nil }
        var data = document.data() ?? [:]
        // Inject the document ID as the userID field so the plain String property
        // is always populated regardless of whether it was stored as a field.
        data["userID"] = document.documentID
        // Default values for fields added after initial schema — prevents decode failure
        // on documents written before these fields existed.
        let intDefaults: [String: Any] = [
            "friendCount":    0,
            "followerCount":  0,
            "followingCount": 0,
            "streakDays":     0,
            "auraPoints":     0,
            "joinDate":       0,
            "weeklyAuraPoints": 0,
            "heightInches":   0,
        ]
        for (key, value) in intDefaults where data[key] == nil {
            data[key] = value
        }
        let doubleDefaults: [String: Any] = [
            "currentWeight": 160.0,
            "goalWeight":    160.0,
            "proteinPerLb":  0.9,
            "weeklyAuraWeekStartTimestamp": 0.0,
        ]
        for (key, value) in doubleDefaults where data[key] == nil {
            data[key] = value
        }
        let boolDefaults: [String: Any] = [
            "isPrivateAccount":  false,
            "fastingEnabled":    false,
            "auraPopupsEnabled": true,
        ]
        for (key, value) in boolDefaults where data[key] == nil {
            data[key] = value
        }
        let stringDefaults: [String: Any] = [
            "profilePhotoURL": "",
            "location":        "",
            "name":            "",
            "username":        "",   // guard against missing field causing decode failure
            "bio":             "",
            "instagramHandle": "",
            "tiktokHandle":    "",
            "dateOfBirth":     "",
        ]
        for (key, value) in stringDefaults where data[key] == nil {
            data[key] = value
        }
        do {
            self = try Firestore.Decoder().decode(UserProfile.self, from: data)
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
