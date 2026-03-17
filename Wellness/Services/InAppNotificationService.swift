//
//  InAppNotificationService.swift
//  Wellness
//

import Foundation
import FirebaseFirestore

final class InAppNotificationService {
    static let shared = InAppNotificationService()
    private init() {}
    private var db: Firestore { FirebaseManager.shared.db }

    private func col(_ userID: String) -> CollectionReference {
        db.collection("users").document(userID).collection("notifications")
    }

    // MARK: - Read

    func fetch(userID: String, limit: Int = 60) async throws -> [AppNotification] {
        guard !userID.isEmpty else { return [] }
        let snapshot = try await col(userID)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap {
            var n = try? Firestore.Decoder().decode(AppNotification.self, from: $0.data())
            n?.id = $0.documentID
            return n
        }
    }

    func unreadCount(userID: String) async throws -> Int {
        guard !userID.isEmpty else { return 0 }
        let snapshot = try await col(userID)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
        return snapshot.documents.count
    }

    func markAllRead(userID: String) async throws {
        guard !userID.isEmpty else { return }
        let snapshot = try await col(userID)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: doc.reference)
        }
        try await batch.commit()
    }

    // MARK: - Write helpers (fire-and-forget at call sites)

    func sendFollow(to targetID: String, actorID: String, actorUsername: String,
                    actorDisplayName: String, actorPhotoURL: String = "") async {
        guard !targetID.isEmpty, targetID != actorID else { return }
        let display = actorDisplayName.isEmpty ? actorUsername : actorDisplayName
        let n = AppNotification(
            type:                 .follow,
            actorID:              actorID,
            actorUsername:        actorUsername,
            actorDisplayName:     display,
            actorProfilePhotoURL: actorPhotoURL,
            message:              "\(display) (@\(actorUsername)) started following you."
        )
        await save(n, to: targetID)
    }

    func sendRep(to targetID: String, postID: String, postHeadline: String,
                 actorID: String, actorUsername: String, actorDisplayName: String,
                 actorPhotoURL: String = "") async {
        guard !targetID.isEmpty, targetID != actorID else { return }
        let display  = actorDisplayName.isEmpty ? actorUsername : actorDisplayName
        let headline = postHeadline.isEmpty ? "your post" : "\"\(postHeadline)\""
        let n = AppNotification(
            type:                 .rep,
            actorID:              actorID,
            actorUsername:        actorUsername,
            actorDisplayName:     display,
            actorProfilePhotoURL: actorPhotoURL,
            message:              "\(display) (@\(actorUsername)) repped \(headline).",
            postID:               postID,
            postHeadline:         postHeadline
        )
        await save(n, to: targetID)
    }

    func sendComment(to targetID: String, postID: String, postHeadline: String,
                     actorID: String, actorUsername: String, actorDisplayName: String,
                     actorPhotoURL: String = "") async {
        guard !targetID.isEmpty, targetID != actorID else { return }
        let display  = actorDisplayName.isEmpty ? actorUsername : actorDisplayName
        let headline = postHeadline.isEmpty ? "your post" : "\"\(postHeadline)\""
        let n = AppNotification(
            type:                 .comment,
            actorID:              actorID,
            actorUsername:        actorUsername,
            actorDisplayName:     display,
            actorProfilePhotoURL: actorPhotoURL,
            message:              "\(display) (@\(actorUsername)) commented on \(headline).",
            postID:               postID,
            postHeadline:         postHeadline
        )
        await save(n, to: targetID)
    }

    func sendLeaderboard(to userID: String, rank: Int, scope: String) async {
        guard !userID.isEmpty else { return }
        let weekKey  = weekString(for: Date())
        let docID    = "leaderboard-\(scope)-\(weekKey)"
        let ref      = col(userID).document(docID)
        let existing = try? await ref.getDocument()
        guard existing?.exists != true else { return }
        let scopeLabel = scope == "local" ? "Local" : "Arena"
        let n = AppNotification(
            id:               docID,
            type:             .leaderboard,
            actorID:          "",
            actorUsername:    "",
            actorDisplayName: "",
            message:          "You ranked #\(rank) on the \(scopeLabel) leaderboard this week!",
            leaderboardRank:  rank,
            leaderboardScope: scope
        )
        await save(n, to: userID, ref: ref)
    }

    // MARK: - Private save helper

    private func save(_ n: AppNotification, to userID: String, ref: DocumentReference? = nil) async {
        guard let data = try? Firestore.Encoder().encode(n) else { return }
        let docRef = ref ?? col(userID).document(n.id)
        try? await docRef.setData(data)
    }

    // MARK: - Helpers

    private func weekString(for date: Date) -> String {
        let cal  = Calendar.current
        let week = cal.component(.weekOfYear, from: date)
        let year = cal.component(.yearForWeekOfYear, from: date)
        return "\(year)-W\(String(format: "%02d", week))"
    }
}
