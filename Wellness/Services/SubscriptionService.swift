//
//  SubscriptionService.swift
//  Wellness
//
//  Firestore path: users/{targetUserID}/subscribers/{subscriberUserID}
//

import Foundation
import FirebaseFirestore

final class SubscriptionService {
    static let shared = SubscriptionService()
    private init() {}
    private var db: Firestore { FirebaseManager.shared.db }

    private func col(_ targetUserID: String) -> CollectionReference {
        db.collection("users").document(targetUserID).collection("subscribers")
    }

    func subscribe(subscriberID: String,
                   subscriberUsername: String,
                   subscriberDisplayName: String,
                   targetUserID: String) async throws {
        let data: [String: Any] = [
            "subscriberID":          subscriberID,
            "subscriberUsername":    subscriberUsername,
            "subscriberDisplayName": subscriberDisplayName,
            "subscribedAt":          Timestamp(date: Date())
        ]
        try await col(targetUserID).document(subscriberID).setData(data)
    }

    func unsubscribe(subscriberID: String, targetUserID: String) async throws {
        try await col(targetUserID).document(subscriberID).delete()
    }

    func isSubscribed(subscriberID: String, targetUserID: String) async throws -> Bool {
        let doc = try await col(targetUserID).document(subscriberID).getDocument(source: .server)
        return doc.exists
    }

    func fetchSubscriberIDs(targetUserID: String) async throws -> [String] {
        let snapshot = try await col(targetUserID).getDocuments()
        return snapshot.documents.compactMap { $0.data()["subscriberID"] as? String }
    }
}
