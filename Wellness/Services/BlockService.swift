//
//  BlockService.swift
//  Wellness
//
//  Manages user blocking, user reporting, and post reporting in Firestore.
//
//  Blocked users:   users/{userID}/blockedUsers/{blockedUserID}
//  Reports:         reports/{auto-ID}
//  Post reports:    posts/{postID} → reportCount, reportedBy
//

import Foundation
import FirebaseFirestore

// MARK: - BlockedUserEntry

struct BlockedUserEntry: Codable, Identifiable {
    var userID:          String
    var username:        String
    var displayName:     String
    var profilePhotoURL: String
    var blockedAt:       Date?

    var id: String { userID }

    init(userID: String, username: String, displayName: String = "",
         profilePhotoURL: String = "", blockedAt: Date? = Date()) {
        self.userID          = userID
        self.username        = username
        self.displayName     = displayName
        self.profilePhotoURL = profilePhotoURL
        self.blockedAt       = blockedAt
    }

    init?(document: DocumentSnapshot) {
        guard document.exists, let data = document.data() else { return nil }
        self.userID          = document.documentID
        self.username        = data["username"]        as? String ?? ""
        self.displayName     = data["displayName"]     as? String ?? ""
        self.profilePhotoURL = data["profilePhotoURL"] as? String ?? ""
        if let ts = data["blockedAt"] as? Timestamp {
            self.blockedAt = ts.dateValue()
        }
    }
}

// MARK: - BlockService

final class BlockService {

    static let shared = BlockService()
    private init() {}

    private var db: Firestore { FirebaseManager.shared.db }

    // MARK: - Block User

    /// Blocks `targetUserID` for `currentUserID` and removes follow relationships in both directions.
    func blockUser(
        currentUserID:         String,
        targetUserID:          String,
        targetUsername:         String,
        targetDisplayName:     String = "",
        targetProfilePhotoURL: String = ""
    ) async throws {
        guard !currentUserID.isEmpty, !targetUserID.isEmpty, currentUserID != targetUserID else { return }

        // 1. Write block entry
        let data: [String: Any] = [
            "userID":          targetUserID,
            "username":        targetUsername,
            "displayName":     targetDisplayName,
            "profilePhotoURL": targetProfilePhotoURL,
            "blockedAt":       FieldValue.serverTimestamp()
        ]
        try await db.collection("users").document(currentUserID)
            .collection("blockedUsers").document(targetUserID)
            .setData(data)

        // 2. Remove follow relationships in both directions (best-effort)
        let batch = db.batch()
        batch.deleteDocument(
            db.collection("users").document(currentUserID)
                .collection("following").document(targetUserID))
        batch.deleteDocument(
            db.collection("users").document(targetUserID)
                .collection("followers").document(currentUserID))
        batch.deleteDocument(
            db.collection("users").document(targetUserID)
                .collection("following").document(currentUserID))
        batch.deleteDocument(
            db.collection("users").document(currentUserID)
                .collection("followers").document(targetUserID))
        try? await batch.commit()

        AppLogger.log("[BlockService] \(currentUserID) blocked \(targetUserID)")
    }

    // MARK: - Unblock User

    func unblockUser(currentUserID: String, targetUserID: String) async throws {
        guard !currentUserID.isEmpty, !targetUserID.isEmpty else { return }
        try await db.collection("users").document(currentUserID)
            .collection("blockedUsers").document(targetUserID)
            .delete()
        AppLogger.log("[BlockService] \(currentUserID) unblocked \(targetUserID)")
    }

    // MARK: - Fetch Blocked Users

    func fetchBlockedUsers(userID: String) async throws -> [BlockedUserEntry] {
        guard !userID.isEmpty else { return [] }
        let snapshot = try await db.collection("users").document(userID)
            .collection("blockedUsers")
            .getDocuments()
        return snapshot.documents.compactMap { BlockedUserEntry(document: $0) }
    }

    // MARK: - Fetch Blocked User IDs

    func fetchBlockedUserIDs(userID: String) async throws -> Set<String> {
        let entries = try await fetchBlockedUsers(userID: userID)
        return Set(entries.map { $0.userID })
    }

    // MARK: - Report User

    func reportUser(reporterID: String, reportedUserID: String) async throws {
        guard !reporterID.isEmpty, !reportedUserID.isEmpty else { return }
        let data: [String: Any] = [
            "reporterID":     reporterID,
            "reportedUserID": reportedUserID,
            "type":           "user",
            "createdAt":      FieldValue.serverTimestamp()
        ]
        try await db.collection("reports").addDocument(data: data)
        AppLogger.log("[BlockService] User \(reporterID) reported user \(reportedUserID)")
    }

    // MARK: - Report Post

    /// Atomically increments reportCount and adds reporterID to reportedBy.
    /// Also writes a record to the reports collection for admin review.
    func reportPost(postID: String, reporterID: String) async throws {
        guard !postID.isEmpty, !reporterID.isEmpty else { return }
        let docRef = db.collection("posts").document(postID)

        _ = try await db.runTransaction { transaction, errorPointer in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(docRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            guard snapshot.exists, let data = snapshot.data() else {
                errorPointer?.pointee = NSError(
                    domain: "BlockService", code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Post not found"])
                return nil
            }

            let reportedBy = data["reportedBy"] as? [String] ?? []
            guard !reportedBy.contains(reporterID) else { return nil }

            let currentCount = data["reportCount"] as? Int ?? 0
            transaction.updateData([
                "reportCount": currentCount + 1,
                "reportedBy":  FieldValue.arrayUnion([reporterID])
            ], forDocument: docRef)

            return nil
        }

        // Also log to reports collection
        let reportData: [String: Any] = [
            "reporterID":     reporterID,
            "reportedPostID": postID,
            "type":           "post",
            "createdAt":      FieldValue.serverTimestamp()
        ]
        _ = try? await db.collection("reports").addDocument(data: reportData)
        AppLogger.log("[BlockService] User \(reporterID) reported post \(postID)")
    }

    // MARK: - Report Comment

    /// Logs a report for a specific comment. Admins review the `reports` collection.
    func reportComment(
        postID:           String,
        commentID:        String,
        commentAuthorID:  String,
        reporterID:       String
    ) async throws {
        guard !postID.isEmpty, !commentID.isEmpty, !reporterID.isEmpty else { return }
        let data: [String: Any] = [
            "reporterID":        reporterID,
            "reportedPostID":    postID,
            "reportedCommentID": commentID,
            "reportedUserID":    commentAuthorID,
            "type":              "comment",
            "createdAt":         FieldValue.serverTimestamp()
        ]
        try await db.collection("reports").addDocument(data: data)
        AppLogger.log("[BlockService] User \(reporterID) reported comment \(commentID) on post \(postID)")
    }
}
