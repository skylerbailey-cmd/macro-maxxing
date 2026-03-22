//
//  FeedPost.swift
//  Wellness
//
//  Firestore-backed post model for the social feed.
//  Collection: "posts"
//

import Foundation
import FirebaseFirestore

struct FeedPost: Codable, Identifiable, Hashable {

    static func == (lhs: FeedPost, rhs: FeedPost) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Identity

    /// Populated manually from the Firestore document ID.
    var postID: String?

    var userID:              String
    var username:            String
    var whoName:             String   // Display name shown on the post
    var userProfilePhotoURL: String   // Firebase Storage download URL

    // MARK: - Content

    var title:       String
    var caption:     String

    /// Primary food photo (Firebase Storage download URL).
    var foodPhotoURL: String

    /// Up to 3 additional food photos. The UI shows foodPhotoURL + these together.
    var additionalPhotoURLs: [String]

    // MARK: - Macros

    var calories: Int
    var protein:  Double
    var carbs:    Double
    var fat:      Double

    /// Goal values at time of posting — lets the feed show a progress ring.
    var goalCalories: Int
    var goalProtein:  Double
    var goalCarbs:    Double
    var goalFat:      Double

    // MARK: - Engagement

    /// Like count (a.k.a. Reps).
    var reps: Int

    /// UserIDs of everyone who repped this post. Used to toggle the like button state.
    /// Suitable for posts with up to ~25 k likers; use a subcollection beyond that.
    var reppedBy: [String]

    var commentsCount: Int

    // MARK: - Author snapshot

    /// Aura level at time of posting — displayed as a badge without a live lookup.
    var auraLevel:  Int    = 0
    var auraPoints: Int    = 0
    var auraTitle:  String = ""

    /// Macro streak at time of posting.
    var streak: Int = 0

    /// Meme badge key (e.g. "sigma", "gigachad", "roman"). Matches asset names.
    var memeType: String = ""

    /// Fasting window at time of posting, e.g. "9:00 AM – 5:00 PM · 8h window". Empty if not applicable.
    var fastingWindowDisplay: String = ""

    /// Post label (PostLabel.rawValue). Empty string means no label.
    var postLabel: String = ""

    /// Mog Board sub-selections (only relevant when postLabel == "Mog Board").
    var mogBoardScope:    String = ""
    var mogBoardType:     String = ""
    var mogBoardSnapshot: String = ""

    // MARK: - Location

    /// Human-readable city/region string shown on the post card.
    var locationName: String = ""

    /// Geo-coordinates stored for radius-based feed queries.
    var latitude:  Double = 0
    var longitude: Double = 0

    // MARK: - Visibility

    /// "arena" (default) | "local" | "team" — controls which feed scopes show this post.
    var postScope: String = "arena"

    /// False if the author had a private account when posting.
    var isPublic: Bool = true

    // MARK: - Fuel log items (written when posting a fuel log so all users see the table)

    var fuelLogItems:   [FeedFuelLogItem]   = []
    var workoutItems:   [FeedWorkoutItem]   = []

    // MARK: - Dates

    /// The calendar date the macros represent (may differ from createdAt if posted next-day).
    var macroDate: Timestamp?

    /// Server-set creation timestamp. Populated from Firestore on read.
    var createdAt: Timestamp?

    // MARK: - Identifiable

    /// Stable identity for SwiftUI. Falls back to a deterministic string
    /// so the ID never changes between accesses (no random UUIDs).
    var id: String {
        if let postID, !postID.isEmpty { return postID }
        return "\(userID)-\(title)-\(createdAt?.seconds ?? 0)"
    }

    // MARK: - Computed helpers

    var createdAtDate: Date? { createdAt?.dateValue() }
    var macroDateDate: Date? { macroDate?.dateValue() }

    /// All photo URLs in display order (primary first).
    var allPhotoURLs: [String] {
        [foodPhotoURL].filter { !$0.isEmpty } + additionalPhotoURLs.filter { !$0.isEmpty }
    }

    /// Whether the given user has repped (liked) this post.
    func hasRepped(userID: String) -> Bool { reppedBy.contains(userID) }

    /// Calorie completion percentage clamped to 0–1.
    var calorieProgress: Double {
        guard goalCalories > 0 else { return 0 }
        return min(Double(calories) / Double(goalCalories), 1)
    }

    // MARK: - Init

    init(
        userID:              String,
        username:            String,
        whoName:             String,
        userProfilePhotoURL: String,
        foodPhotoURL:        String,
        additionalPhotoURLs: [String] = [],
        caption:             String,
        title:               String,
        calories:            Int,
        protein:             Double,
        carbs:               Double,
        fat:                 Double,
        goalCalories:        Int    = 0,
        goalProtein:         Double = 0,
        goalCarbs:           Double = 0,
        goalFat:             Double = 0,
        reps:                Int    = 0,
        reppedBy:            [String] = [],
        commentsCount:       Int    = 0,
        auraLevel:           Int    = 0,
        auraPoints:          Int    = 0,
        auraTitle:           String = "",
        streak:              Int    = 0,
        memeType:            String = "",
        locationName:        String = "",
        latitude:            Double = 0,
        longitude:           Double = 0,
        isPublic:            Bool   = true,
        macroDate:           Date?  = nil,
        fastingWindowDisplay: String = "",
        postLabel:           String = "",
        mogBoardScope:       String = "",
        mogBoardType:        String = "",
        mogBoardSnapshot:    String = "",
        fuelLogItems:        [FeedFuelLogItem] = [],
        workoutItems:        [FeedWorkoutItem] = []
    ) {
        self.userID              = userID
        self.username            = username
        self.whoName             = whoName
        self.userProfilePhotoURL = userProfilePhotoURL
        self.foodPhotoURL        = foodPhotoURL
        self.additionalPhotoURLs = additionalPhotoURLs
        self.caption             = caption
        self.title               = title
        self.calories            = calories
        self.protein             = protein
        self.carbs               = carbs
        self.fat                 = fat
        self.goalCalories        = goalCalories
        self.goalProtein         = goalProtein
        self.goalCarbs           = goalCarbs
        self.goalFat             = goalFat
        self.reps                = reps
        self.reppedBy            = reppedBy
        self.commentsCount       = commentsCount
        self.auraLevel           = auraLevel
        self.auraPoints          = auraPoints
        self.auraTitle           = auraTitle
        self.streak              = streak
        self.memeType            = memeType
        self.locationName         = locationName
        self.latitude             = latitude
        self.longitude            = longitude
        self.isPublic             = isPublic
        self.macroDate            = macroDate.map { Timestamp(date: $0) }
        self.fastingWindowDisplay = fastingWindowDisplay
        self.postLabel            = postLabel
        self.mogBoardScope        = mogBoardScope
        self.mogBoardType         = mogBoardType
        self.mogBoardSnapshot     = mogBoardSnapshot
        self.fuelLogItems         = fuelLogItems
        self.workoutItems         = workoutItems
    }
}

// MARK: - FeedFuelLogItem

struct FeedFuelLogItem: Codable, Identifiable {
    var id:        String = UUID().uuidString
    var foodName:  String
    var calories:  Double
    var protein:   Double
    var carbs:     Double
    var fat:       Double
    var photoURL:  String = ""
    var sortOrder: Int    = 0
}

struct FeedWorkoutItem: Codable, Identifiable {
    var id:              String = UUID().uuidString
    var workoutName:     String = ""
    var workoutType:     String = ""  // WorkoutType.rawValue
    var durationMinutes: Int    = 0
    var caloriesBurned:  Int    = 0
    var sortOrder:       Int    = 0

    var formattedDuration: String {
        durationMinutes >= 60
            ? "\(durationMinutes / 60)h \(durationMinutes % 60)m"
            : "\(durationMinutes)m"
    }
}

// MARK: - Firestore Helpers

extension FeedPost {

    /// Decodes a FeedPost from a Firestore DocumentSnapshot.
    /// Pre-fills any fields that may be absent from older documents so decoding
    /// never silently drops a post.
    init?(document: DocumentSnapshot) {
        guard document.exists else { return nil }
        var data = document.data() ?? [:]

        // Default values for fields added after the initial schema
        let stringDefaults: [String: Any] = [
            "userProfilePhotoURL": "",
            "title":               "",
            "caption":             "",
            "foodPhotoURL":        "",
            "memeType":            "",
            "auraTitle":           "",
            "locationName":        "",
            "fastingWindowDisplay": "",
            "postLabel":           "",
            "mogBoardScope":       "",
            "mogBoardType":        "",
            "mogBoardSnapshot":    "",
            "postScope":           "arena",
        ]
        for (key, value) in stringDefaults where data[key] == nil {
            data[key] = value
        }
        let intDefaults: [String: Any] = [
            "calories": 0, "goalCalories": 0,
            "reps": 0, "commentsCount": 0,
            "auraLevel": 0, "auraPoints": 0, "streak": 0,
        ]
        for (key, value) in intDefaults where data[key] == nil {
            data[key] = value
        }
        let doubleDefaults: [String: Any] = [
            "protein": 0.0, "carbs": 0.0, "fat": 0.0,
            "goalProtein": 0.0, "goalCarbs": 0.0, "goalFat": 0.0,
            "latitude": 0.0, "longitude": 0.0,
        ]
        for (key, value) in doubleDefaults where data[key] == nil {
            data[key] = value
        }
        if data["reppedBy"]            == nil { data["reppedBy"]            = [String]() }
        if data["additionalPhotoURLs"] == nil { data["additionalPhotoURLs"] = [String]() }
        if data["fuelLogItems"]        == nil { data["fuelLogItems"]        = [[String: Any]]() }
        if data["workoutItems"]        == nil { data["workoutItems"]        = [[String: Any]]() }
        if data["isPublic"]            == nil { data["isPublic"]            = true }

        do {
            let decoder = Firestore.Decoder()
            self = try decoder.decode(FeedPost.self, from: data, in: document.reference)
            self.postID = document.documentID
        } catch {
            print("[FeedPost] Decode error – \(document.documentID): \(error)")
            return nil
        }
    }

    /// Encodes this FeedPost to a Firestore-compatible dictionary.
    /// Use the result with `collection.addDocument(data:)` or `document.setData(:)`.
    func firestoreData() throws -> [String: Any] {
        var data = try Firestore.Encoder().encode(self)
        // Set createdAt to server timestamp if not already set (replaces @ServerTimestamp behavior)
        if data["createdAt"] == nil {
            data["createdAt"] = FieldValue.serverTimestamp()
        }
        return data
    }
}
