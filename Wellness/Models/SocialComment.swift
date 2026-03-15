//
//  SocialComment.swift
//  Wellness
//

import Foundation
import SwiftData

@Model final class SocialComment {
    var id:                UUID   = UUID()
    var authorID:          String = ""
    var authorUsername:    String = ""
    var authorDisplayName: String = ""
    var text:              String = ""
    @Attribute(.externalStorage) var imageData: Data? = nil
    var postedAt:          Date   = Date()

    // 💪 Reps (likes)
    var repsCount:   Int    = 0
    var reppedByRaw: String = ""   // comma-separated userIDs

    var post: SocialPost?

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
         text: String, imageData: Data? = nil, post: SocialPost) {
        self.authorID = authorID; self.authorUsername = authorUsername
        self.authorDisplayName = authorDisplayName
        self.text = text; self.imageData = imageData; self.postedAt = Date(); self.post = post
    }
}
