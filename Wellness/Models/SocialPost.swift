//
//  SocialPost.swift
//  Wellness
//

import Foundation
import SwiftData

@Model final class SocialPost {
    var id:                UUID   = UUID()
    var authorID:          String = ""   // userID of poster
    var authorUsername:    String = ""   // @handle
    var authorDisplayName: String = ""   // first name / display name
    var memeEmoji:         String = ""
    var memeHeadline:      String = ""
    var memeSub:           String = ""
    var macroDate:         Date   = Date()  // the day macros were hit
    var postedAt:          Date   = Date()
    // Snapshot of macros at post time
    var totalCalories: Double = 0
    var goalCalories:  Double = 0
    var totalProtein:  Double = 0
    var goalProtein:   Double = 0
    var totalCarbs:    Double = 0
    var goalCarbs:     Double = 0
    var totalFat:      Double = 0
    var goalFat:       Double = 0

    // Custom post fields (nil / false for achievement posts)
    var isCustomPost: Bool = false
    @Attribute(.externalStorage) var imageData: Data?

    @Relationship(deleteRule: .cascade)
    var comments: [SocialComment] = []

    init(authorID: String, authorUsername: String, authorDisplayName: String,
         memeEmoji: String, memeHeadline: String, memeSub: String,
         macroDate: Date,
         totalCalories: Double, goalCalories: Double,
         totalProtein:  Double, goalProtein:  Double,
         totalCarbs:    Double, goalCarbs:    Double,
         totalFat:      Double, goalFat:      Double) {
        self.authorID          = authorID
        self.authorUsername    = authorUsername
        self.authorDisplayName = authorDisplayName
        self.memeEmoji         = memeEmoji
        self.memeHeadline      = memeHeadline
        self.memeSub           = memeSub
        self.macroDate         = macroDate
        self.postedAt          = Date()
        self.totalCalories     = totalCalories
        self.goalCalories      = goalCalories
        self.totalProtein      = totalProtein
        self.goalProtein       = goalProtein
        self.totalCarbs        = totalCarbs
        self.goalCarbs         = goalCarbs
        self.totalFat          = totalFat
        self.goalFat           = goalFat
    }
}
