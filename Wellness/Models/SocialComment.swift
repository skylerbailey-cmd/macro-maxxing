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
    var postedAt:          Date   = Date()

    var post: SocialPost?

    init(authorID: String, authorUsername: String, authorDisplayName: String,
         text: String, post: SocialPost) {
        self.authorID          = authorID
        self.authorUsername    = authorUsername
        self.authorDisplayName = authorDisplayName
        self.text              = text
        self.postedAt          = Date()
        self.post              = post
    }
}
