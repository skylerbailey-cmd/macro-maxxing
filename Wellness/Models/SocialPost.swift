//
//  SocialPost.swift
//  Wellness
//

import Foundation
import SwiftData

@Model final class SocialPost {
    var id:                UUID   = UUID()
    var authorID:          String = ""
    var authorUsername:    String = ""
    var authorDisplayName: String = ""
    var memeEmoji:         String = ""
    var memeHeadline:      String = ""
    var memeSub:           String = ""
    var macroDate:         Date   = Date()
    var postedAt:          Date   = Date()
    var totalCalories: Double = 0; var goalCalories: Double = 0
    var totalProtein:  Double = 0; var goalProtein:  Double = 0
    var totalCarbs:    Double = 0; var goalCarbs:    Double = 0
    var totalFat:      Double = 0; var goalFat:      Double = 0
    var isCustomPost:    Bool   = false
    var firebasePostID:  String = ""   // Firestore document ID — empty until Firebase confirms
    @Attribute(.externalStorage) var imageData:  Data?
    @Attribute(.externalStorage) var imageData2: Data?
    @Attribute(.externalStorage) var imageData3: Data?
    @Attribute(.externalStorage) var imageData4: Data?

    /// All image datas in order, skipping nils.
    var allImageDatas: [Data] {
        [imageData, imageData2, imageData3, imageData4].compactMap { $0 }
    }

    /// Fasting window at time of posting, e.g. "9:00 AM – 5:00 PM · 8h window". Empty if not applicable.
    var fastingWindowDisplay: String = ""

    // Author aura + profile picture + location + streak + privacy at time of posting
    var authorAuraLevel:   Int    = 0
    var authorAuraPoints:  Int    = 0
    var authorLocation:    String = ""
    var authorLatitude:    Double = 0.0
    var authorLongitude:   Double = 0.0
    var authorStreak:      Int    = 0
    var isAuthorPrivate:   Bool   = false
    @Attribute(.externalStorage) var authorProfileImageData: Data?

    // 💪 Reps (likes)
    var repsCount:    Int    = 0
    var reppedByRaw:  String = ""   // comma-separated userIDs

    @Relationship(deleteRule: .cascade)
    var comments: [SocialComment] = []

    @Relationship(deleteRule: .cascade)
    var fuelLogEntries: [FuelLogEntry] = []

    func hasRepped(userID: String) -> Bool {
        guard !reppedByRaw.isEmpty else { return false }
        return reppedByRaw.split(separator: ",").map(String.init).contains(userID)
    }

    func toggleRep(userID: String) {
        let ids = reppedByRaw.isEmpty ? [] : reppedByRaw.split(separator: ",").map(String.init)
        if ids.contains(userID) {
            repsCount   = max(0, repsCount - 1)
            reppedByRaw = ids.filter { $0 != userID }.joined(separator: ",")
        } else {
            repsCount  += 1
            reppedByRaw = (ids + [userID]).joined(separator: ",")
        }
    }

    init(authorID: String, authorUsername: String, authorDisplayName: String,
         memeEmoji: String, memeHeadline: String, memeSub: String, macroDate: Date,
         totalCalories: Double, goalCalories: Double,
         totalProtein:  Double, goalProtein:  Double,
         totalCarbs:    Double, goalCarbs:    Double,
         totalFat:      Double, goalFat:      Double) {
        self.authorID = authorID; self.authorUsername = authorUsername
        self.authorDisplayName = authorDisplayName
        self.memeEmoji = memeEmoji; self.memeHeadline = memeHeadline; self.memeSub = memeSub
        self.macroDate = macroDate; self.postedAt = Date()
        self.totalCalories = totalCalories; self.goalCalories = goalCalories
        self.totalProtein  = totalProtein;  self.goalProtein  = goalProtein
        self.totalCarbs    = totalCarbs;    self.goalCarbs    = goalCarbs
        self.totalFat      = totalFat;      self.goalFat      = goalFat
    }
}
