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

    /// Celebrate count (🎉 reactions).
    var celebrates: Int = 0

    /// UserIDs of everyone who celebrated this post.
    var celebratedBy: [String] = []

    /// Zap count (⚡ reactions).
    var zaps: Int = 0

    /// UserIDs of everyone who zapped this post.
    var zappedBy: [String] = []

    /// Number of times this post has been reported.
    var reportCount: Int = 0

    /// UserIDs of everyone who reported this post (prevents duplicate reports).
    var reportedBy: [String] = []

    // MARK: - Author snapshot

    /// Aura level at time of posting — displayed as a badge without a live lookup.
    var auraLevel:  Int    = 0
    var auraPoints: Int    = 0
    var auraTitle:  String = ""

    /// Macro streak at time of posting.
    var streak: Int = 0

    /// True if the author had an active AI subscription when the post was created.
    var isProSubscriber: Bool = false

    /// Meme badge key (e.g. "sigma", "gigachad", "roman"). Matches asset names.
    var memeType: String = ""

    /// Fasting window at time of posting, e.g. "9:00 AM – 5:00 PM · 8h window". Empty if not applicable.
    var fastingWindowDisplay: String = ""

    /// Weight snapshot at time of a Goal post. 0 means not set / not a goal post.
    var currentWeight: Double = 0
    var goalWeight:    Double = 0

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

    // MARK: - Dates (stored as plain Date to avoid Timestamp reference-type crashes)

    /// The calendar date the macros represent (may differ from createdAt if posted next-day).
    var macroDate: Date?

    /// Server-set creation timestamp. Populated from Firestore on read.
    var createdAt: Date?

    // MARK: - Identifiable

    /// Stable identity for SwiftUI. Falls back to a deterministic string
    /// so the ID never changes between accesses (no random UUIDs).
    var id: String {
        if let postID, !postID.isEmpty { return postID }
        return "\(userID)-\(title)-\(Int(createdAt?.timeIntervalSince1970 ?? 0))"
    }

    // MARK: - Computed helpers

    var createdAtDate: Date? { createdAt }
    var macroDateDate: Date? { macroDate }

    /// All photo URLs in display order (primary first).
    var allPhotoURLs: [String] {
        [foodPhotoURL].filter { !$0.isEmpty } + additionalPhotoURLs.filter { !$0.isEmpty }
    }

    /// Whether the given user has repped (liked) this post.
    func hasRepped(userID: String) -> Bool { reppedBy.contains(userID) }
    func hasCelebrated(userID: String) -> Bool { celebratedBy.contains(userID) }
    func hasZapped(userID: String) -> Bool { zappedBy.contains(userID) }

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
        currentWeight:       Double = 0,
        goalWeight:          Double = 0,
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
        self.macroDate            = macroDate
        self.fastingWindowDisplay = fastingWindowDisplay
        self.currentWeight        = currentWeight
        self.goalWeight           = goalWeight
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

    // Gym/location tag — mirrored as flat fields so older Firestore
    // documents (which have none of these keys) decode cleanly via the
    // defaults below.
    var gymName:      String = ""
    var gymAddress:   String = ""
    var gymLatitude:  Double = 0.0
    var gymLongitude: Double = 0.0

    // Friends tagged on this workout — stored as an array of objects.
    // Defaults to [] so older Firestore docs decode cleanly.
    var taggedFriends: [TaggedFriend] = []

    // Per-exercise detail. Empty on posts created before this field was added.
    var exercises: [Exercise] = []

    var formattedDuration: String {
        durationMinutes >= 60
            ? "\(durationMinutes / 60)h \(durationMinutes % 60)m"
            : "\(durationMinutes)m"
    }

    /// Convenience — nil when no gym was tagged.
    var location: WorkoutLocation? {
        guard !gymName.isEmpty else { return nil }
        return WorkoutLocation(name: gymName, address: gymAddress,
                               latitude: gymLatitude, longitude: gymLongitude)
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
            "currentWeight": 0.0, "goalWeight": 0.0,
        ]
        for (key, value) in doubleDefaults where data[key] == nil {
            data[key] = value
        }
        if data["celebrates"]          == nil { data["celebrates"]          = 0 }
        if data["celebratedBy"]        == nil { data["celebratedBy"]        = [String]() }
        if data["reppedBy"]            == nil { data["reppedBy"]            = [String]() }
        if data["zaps"]                == nil { data["zaps"]                = 0 }
        if data["zappedBy"]            == nil { data["zappedBy"]            = [String]() }
        if data["reportCount"]         == nil { data["reportCount"]         = 0 }
        if data["reportedBy"]          == nil { data["reportedBy"]          = [String]() }
        if data["additionalPhotoURLs"] == nil { data["additionalPhotoURLs"] = [String]() }
        if data["fuelLogItems"]        == nil { data["fuelLogItems"]        = [[String: Any]]() }
        if data["workoutItems"]        == nil { data["workoutItems"]        = [[String: Any]]() }
        if data["isPublic"]            == nil { data["isPublic"]            = true }
        if data["isProSubscriber"]     == nil { data["isProSubscriber"]     = false }

        // Backfill missing keys inside nested `workoutItems` so posts
        // created before the gym-tag / friend-tag features decode cleanly.
        // Swift's synthesized Codable init ignores property-level defaults
        // on missing keys, so we have to seed them here.
        if var items = data["workoutItems"] as? [[String: Any]] {
            let workoutItemDefaults: [String: Any] = [
                "id":              "",
                "workoutName":     "",
                "workoutType":     "",
                "durationMinutes": 0,
                "caloriesBurned":  0,
                "sortOrder":       0,
                "gymName":         "",
                "gymAddress":      "",
                "gymLatitude":     0.0,
                "gymLongitude":    0.0,
                "taggedFriends":   [[String: Any]](),
                "exercises":       [[String: Any]]()
            ]
            for idx in items.indices {
                for (key, value) in workoutItemDefaults where items[idx][key] == nil {
                    items[idx][key] = value
                }
                // Give each item a stable id if the older doc didn't have one
                if (items[idx]["id"] as? String)?.isEmpty ?? true {
                    items[idx]["id"] = UUID().uuidString
                }
            }
            data["workoutItems"] = items
        }

        // Same treatment for fuel-log items in case older posts are missing
        // any fields that were added later.
        if var items = data["fuelLogItems"] as? [[String: Any]] {
            let fuelLogDefaults: [String: Any] = [
                "id":        "",
                "foodName":  "",
                "calories":  0.0,
                "protein":   0.0,
                "carbs":     0.0,
                "fat":       0.0,
                "photoURL":  "",
                "sortOrder": 0
            ]
            for idx in items.indices {
                for (key, value) in fuelLogDefaults where items[idx][key] == nil {
                    items[idx][key] = value
                }
                if (items[idx]["id"] as? String)?.isEmpty ?? true {
                    items[idx]["id"] = UUID().uuidString
                }
            }
            data["fuelLogItems"] = items
        }

        // Pull Timestamps out before decoding (Firestore.Decoder can't map Timestamp→Date)
        let createdAtTs = data.removeValue(forKey: "createdAt") as? Timestamp
        let macroDateTs = data.removeValue(forKey: "macroDate") as? Timestamp

        do {
            let decoder = Firestore.Decoder()
            self = try decoder.decode(FeedPost.self, from: data, in: document.reference)
            self.postID    = document.documentID
            self.createdAt = createdAtTs?.dateValue()
            self.macroDate = macroDateTs?.dateValue()
        } catch {
            AppLogger.log("[FeedPost] Decode error – \(document.documentID): \(error)")
            return nil
        }
    }

    /// Encodes this FeedPost to a Firestore-compatible dictionary.
    /// Use the result with `collection.addDocument(data:)` or `document.setData(:)`.
    func firestoreData() throws -> [String: Any] {
        var data = try Firestore.Encoder().encode(self)
        // Convert Date back to Timestamp for Firestore storage
        if let date = createdAt {
            data["createdAt"] = Timestamp(date: date)
        } else {
            data["createdAt"] = FieldValue.serverTimestamp()
        }
        if let date = macroDate {
            data["macroDate"] = Timestamp(date: date)
        }
        return data
    }
}
