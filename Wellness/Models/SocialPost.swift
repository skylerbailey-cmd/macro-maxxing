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
    var isCustomPost:  Bool   = false
    @Attribute(.externalStorage) var imageData: Data?

    // Author aura at time of posting
    var authorAuraLevel:  Int = 0
    var authorAuraPoints: Int = 0

    // 💪 Reps (likes)
    var repsCount:    Int    = 0
    var reppedByRaw:  String = ""   // comma-separated userIDs

    @Relationship(deleteRule: .cascade)
    var comments: [SocialComment] = []

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
