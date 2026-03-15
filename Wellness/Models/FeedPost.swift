//
//  FeedPost.swift
//  Wellness
//
//  Firestore-backed post model for the social feed.
//  Collection: "posts"
//

import Foundation
import FirebaseFirestore

struct FeedPost: Codable, Identifiable {

    // MARK: - Identity

    /// Populated by Firestore on read; matches the document ID.
    @DocumentID var postID: String?

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
    var auraLevel:  Int
    var auraPoints: Int

    /// Macro streak at time of posting.
    var streak: Int

    /// Meme badge key (e.g. "sigma", "gigachad", "roman"). Matches asset names.
    var memeType: String

    /// Fasting window at time of posting, e.g. "9:00 AM – 5:00 PM · 8h window". Empty if not applicable.
    var fastingWindowDisplay: String

    // MARK: - Location

    /// Human-readable city/region string shown on the post card.
    var locationName: String

    /// Geo-coordinates stored for radius-based feed queries.
    var latitude:  Double
    var longitude: Double

    // MARK: - Visibility

    /// False if the author had a private account when posting.
    var isPublic: Bool

    // MARK: - Dates

    /// The calendar date the macros represent (may differ from createdAt if posted next-day).
    /// Stored as a Firestore Timestamp; nil until first read-back.
    var macroDate: Timestamp?

    /// Server-set creation timestamp. Nil locally until Firestore writes the value back.
    @ServerTimestamp var createdAt: Timestamp?

    // MARK: - Identifiable

    var id: String { postID ?? UUID().uuidString }

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
        streak:              Int    = 0,
        memeType:            String = "",
        locationName:        String = "",
        latitude:            Double = 0,
        longitude:           Double = 0,
        isPublic:            Bool   = true,
        macroDate:           Date?  = nil,
        fastingWindowDisplay: String = ""
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
        self.streak              = streak
        self.memeType            = memeType
        self.locationName         = locationName
        self.latitude             = latitude
        self.longitude            = longitude
        self.isPublic             = isPublic
        self.macroDate            = macroDate.map { Timestamp(date: $0) }
        self.fastingWindowDisplay = fastingWindowDisplay
    }
}

// MARK: - Firestore Helpers

extension FeedPost {

    /// Decodes a FeedPost from a Firestore DocumentSnapshot.
    init?(document: DocumentSnapshot) {
        guard document.exists else { return nil }
        do {
            self = try Firestore.Decoder().decode(FeedPost.self, from: document.data() ?? [:])
        } catch {
            print("[FeedPost] Decode error – \(document.documentID): \(error)")
            return nil
        }
    }

    /// Encodes this FeedPost to a Firestore-compatible dictionary.
    /// Use the result with `collection.addDocument(data:)` or `document.setData(:)`.
    func firestoreData() throws -> [String: Any] {
        try Firestore.Encoder().encode(self)
    }
}
