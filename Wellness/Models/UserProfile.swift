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
    /// All-time best streak.
    var longestStreak:  Int
    /// "yyyy-MM-dd" date on which the daily streak check last ran. Prevents double-running.
    var lastStreakCheckDate: String
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
    var gender:           String
    var fastingEnabled:       Bool
    var windowStartHour:      Int
    var windowStartMinute:    Int
    var windowDurationHours:  Int
    var auraPopupsEnabled:    Bool
    var excludeDairy:         Bool
    var excludeGluten:        Bool
    /// Comma-separated streak milestone days already awarded, e.g. "3,7,14".
    /// Synced to Firestore so milestones survive reinstalls and device switches.
    var achievedMilestones:   String
    /// Canonical list of "yyyy-MM-dd" date strings on which all macro goals were met.
    /// Used as the primary source of truth for streak calculation across devices.
    var goalsMetDates:        [String]
    /// Most recent "yyyy-MM-dd" on which all macro goals were confirmed met.
    /// Updated in real-time; used as the anchor for streak counting.
    var lastGoalsMetDate:     String

    // MARK: - Weekly aura (synced so it survives sign-out / device switches)

    var weeklyAuraPoints: Int
    /// Unix timestamp (seconds) of the Monday that opened the current weekly window.
    var weeklyAuraWeekStartTimestamp: Double

    // MARK: - Weekly winner notification (set by Cloud Function, cleared after display)
    /// Arena finishing rank (1–10) from the most recent weekly reset. 0 = not a winner.
    var weeklyWinnerRank: Int
    /// Arena XP awarded for the weekly finish. 0 = not a winner.
    var weeklyWinnerXP:   Int
    /// "YYYY-MM-DD" of the Sunday this arena award was for. Used to avoid double-showing.
    var weeklyWinnerWeek: String
    /// Local-board finishing rank (1–10) from the most recent weekly reset. 0 = not a winner.
    var localWinnerRank:  Int
    /// Local XP awarded for the weekly finish. 0 = not a winner.
    var localWinnerXP:    Int
    /// "YYYY-MM-DD" of the Sunday this local award was for. Used to avoid double-showing.
    var localWinnerWeek:  String

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
        auraPoints:          Int,
        streakDays:          Int,
        longestStreak:       Int    = 0,
        lastStreakCheckDate: String = "",
        friendCount:         Int,
        followingCount:   Int    = 0,
        followerCount:    Int    = 0,
        bio:              String = "",
        instagramHandle:  String = "",
        tiktokHandle:     String = "",
        isPrivateAccount: Bool   = true,
        currentWeight:    Double = 160,
        goalWeight:       Double = 160,
        heightInches:     Int    = 0,
        proteinPerLb:     Double = 0.9,
        gender:           String = "",
        fastingEnabled:       Bool     = false,
        windowStartHour:      Int      = 9,
        windowStartMinute:    Int      = 0,
        windowDurationHours:  Int      = 8,
        auraPopupsEnabled:    Bool     = true,
        excludeDairy:         Bool     = false,
        excludeGluten:        Bool     = false,
        achievedMilestones:   String   = "",
        goalsMetDates:        [String] = [],
        lastGoalsMetDate:     String   = "",
        weeklyAuraPoints: Int    = 0,
        weeklyAuraWeekStartTimestamp: Double = 0,
        weeklyWinnerRank: Int    = 0,
        weeklyWinnerXP:   Int    = 0,
        weeklyWinnerWeek: String = "",
        localWinnerRank:  Int    = 0,
        localWinnerXP:    Int    = 0,
        localWinnerWeek:  String = "",
        joinDate:         Int,
        dateOfBirth:      String = ""
    ) {
        self.userID           = userID
        self.username         = username
        self.name             = name
        self.location         = location
        self.profilePhotoURL  = profilePhotoURL
        self.auraPoints          = auraPoints
        self.streakDays          = streakDays
        self.longestStreak       = longestStreak
        self.lastStreakCheckDate = lastStreakCheckDate
        self.friendCount         = friendCount
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
        self.gender           = gender
        self.fastingEnabled      = fastingEnabled
        self.windowStartHour     = windowStartHour
        self.windowStartMinute   = windowStartMinute
        self.windowDurationHours = windowDurationHours
        self.auraPopupsEnabled   = auraPopupsEnabled
        self.excludeDairy        = excludeDairy
        self.excludeGluten       = excludeGluten
        self.achievedMilestones  = achievedMilestones
        self.goalsMetDates       = goalsMetDates
        self.lastGoalsMetDate    = lastGoalsMetDate
        self.weeklyAuraPoints = weeklyAuraPoints
        self.weeklyAuraWeekStartTimestamp = weeklyAuraWeekStartTimestamp
        self.weeklyWinnerRank = weeklyWinnerRank
        self.weeklyWinnerXP   = weeklyWinnerXP
        self.weeklyWinnerWeek = weeklyWinnerWeek
        self.localWinnerRank  = localWinnerRank
        self.localWinnerXP    = localWinnerXP
        self.localWinnerWeek  = localWinnerWeek
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
            "friendCount":         0,
            "followerCount":       0,
            "followingCount":      0,
            "streakDays":          0,
            "longestStreak":       0,
            "auraPoints":          0,
            "joinDate":            0,
            "weeklyAuraPoints":    0,
            "heightInches":        0,
            "windowStartHour":     9,
            "windowStartMinute":   0,
            "windowDurationHours": 8,
            "weeklyWinnerRank":    0,
            "weeklyWinnerXP":      0,
            "localWinnerRank":     0,
            "localWinnerXP":       0,
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
            "excludeDairy":      false,
            "excludeGluten":     false,
        ]
        for (key, value) in boolDefaults where data[key] == nil {
            data[key] = value
        }
        if data["achievedMilestones"]  == nil { data["achievedMilestones"]  = "" }
        if data["goalsMetDates"]       == nil { data["goalsMetDates"]       = [String]() }
        if data["lastGoalsMetDate"]    == nil { data["lastGoalsMetDate"]    = "" }
        if data["lastStreakCheckDate"] == nil { data["lastStreakCheckDate"] = "" }
        if data["weeklyWinnerWeek"]    == nil { data["weeklyWinnerWeek"]    = "" }
        if data["localWinnerWeek"]     == nil { data["localWinnerWeek"]     = "" }
        let stringDefaults: [String: Any] = [
            "profilePhotoURL": "",
            "location":        "",
            "name":            "",
            "username":        "",   // guard against missing field causing decode failure
            "bio":             "",
            "instagramHandle": "",
            "tiktokHandle":    "",
            "dateOfBirth":     "",
            "gender":          "",
        ]
        for (key, value) in stringDefaults where data[key] == nil {
            data[key] = value
        }
        do {
            self = try Firestore.Decoder().decode(UserProfile.self, from: data)
        } catch {
            AppLogger.log("[UserProfile] Decode error – \(document.documentID): \(error)")
            return nil
        }
    }

    /// Encodes this UserProfile to a Firestore-compatible dictionary.
    func firestoreData() throws -> [String: Any] {
        try Firestore.Encoder().encode(self)
    }

    // MARK: - Private / Public Field Splitting

    /// Keys that belong in `users/{uid}/private/profile` rather than the
    /// public `users/{uid}` document.  These contain health/PII data that
    /// other authenticated users should NOT be able to read.
    static let privateFieldKeys: Set<String> = [
        "dateOfBirth", "currentWeight", "goalWeight", "heightInches",
        "proteinPerLb", "gender", "excludeDairy", "excludeGluten",
    ]

    /// Returns only the sensitive fields, suitable for writing to
    /// `users/{uid}/private/profile`.
    func privateFieldsData() -> [String: Any] {
        [
            "dateOfBirth":   dateOfBirth,
            "currentWeight": currentWeight,
            "goalWeight":    goalWeight,
            "heightInches":  heightInches,
            "proteinPerLb":  proteinPerLb,
            "gender":        gender,
            "excludeDairy":  excludeDairy,
            "excludeGluten": excludeGluten,
        ]
    }

    /// Returns the full encoded data with private keys removed, suitable for
    /// writing to the public `users/{uid}` document.
    func publicFieldsData() throws -> [String: Any] {
        var data = try firestoreData()
        for key in Self.privateFieldKeys { data.removeValue(forKey: key) }
        return data
    }
}
