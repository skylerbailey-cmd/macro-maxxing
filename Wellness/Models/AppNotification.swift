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
        case follow, rep, celebrate, zap, comment, mention, leaderboard, newPost, workoutTag
    }

    /// Which filter tab this notification belongs to.
    var filterCategory: NotifFilter {
        switch type {
        case .rep, .celebrate, .zap: return .reactions
        case .follow, .comment, .mention, .newPost: return .social
        case .leaderboard, .workoutTag: return .activity
        }
    }

    /// Whether this type can be collapsed with other reactions on the same post.
    var isReaction: Bool {
        type == .rep || type == .celebrate || type == .zap
    }

    enum NotifFilter: String, CaseIterable {
        case all       = "All"
        case reactions = "Reactions"
        case social    = "Social"
        case activity  = "Activity"
    }
}
