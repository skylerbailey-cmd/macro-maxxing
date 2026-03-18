//
//  AppNotification.swift
//  Wellness
//

import Foundation

struct AppNotification: Identifiable, Codable {
    var id:                   String = UUID().uuidString
    var type:                 NotifType
    var actorID:              String
    var actorUsername:        String
    var actorDisplayName:     String
    var actorProfilePhotoURL: String = ""
    var message:              String
    var postID:               String = ""
    var postHeadline:         String = ""
    var leaderboardRank:      Int    = 0
    var leaderboardScope:     String = ""
    var isRead:               Bool   = false
    var createdAt:            Date   = Date()

    enum NotifType: String, Codable {
        case follow, rep, comment, leaderboard, newPost
    }
}
