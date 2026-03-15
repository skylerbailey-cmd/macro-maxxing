//
//  AppSchema.swift
//  Wellness
//
//  Versioned SwiftData schema + lightweight migration plan.
//
//  V1 → V2 changes:
//    • Removed Friend model (replaced by Firestore FollowService)
//    • SocialComment.imageData marked @Attribute(.externalStorage)
//

import SwiftData

// MARK: - Schema V1 (original)

enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [FoodEntry.self, SocialPost.self, SocialCommentV1.self, FriendV1.self, FuelLogEntry.self]
    }

    // Minimal stub of Friend so the migration source compiles.
    @Model final class FriendV1 {
        var id:          UUID   = UUID()
        var userID:      String = ""
        var username:    String = ""
        var displayName: String = ""
        var addedAt:     Date   = Date()
        init() {}
    }

    // Minimal stub of SocialComment V1 (imageData NOT externalStorage).
    @Model final class SocialCommentV1 {
        var id:                UUID   = UUID()
        var authorID:          String = ""
        var authorUsername:    String = ""
        var authorDisplayName: String = ""
        var text:              String = ""
        var imageData:         Data?  = nil   // was inline
        var postedAt:          Date   = Date()
        var repsCount:         Int    = 0
        var reppedByRaw:       String = ""
        var post:              SocialPost?
        init() {}
    }
}

// MARK: - Schema V2 (current)

enum SchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        // Friend removed; SocialComment now uses external image storage.
        [FoodEntry.self, SocialPost.self, SocialComment.self, FuelLogEntry.self]
    }
}

// MARK: - Migration plan

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self] }

    static var stages: [MigrationStage] {
        [
            // Lightweight migration: Friend records are simply dropped;
            // SocialComment.imageData storage mode is updated automatically.
            .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
        ]
    }
}
