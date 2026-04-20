//
//  PushTokenService.swift
//  Wellness
//
//  Stores the device's FCM push token in Firestore so Cloud Functions
//  can send push notifications when subscribed users post.
//
//  Firestore: users/{userID}/pushTokens/{tokenID}
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

final class PushTokenService {
    static let shared = PushTokenService()
    private init() {}

    private var db: Firestore { FirebaseManager.shared.db }

    /// Saves the current FCM token to the authenticated user's pushTokens
    /// subcollection. Called by the MessagingDelegate when the token is
    /// issued or refreshed, and again at login to ensure the mapping is fresh.
    func save(fcmToken: String) async {
        guard !fcmToken.isEmpty,
              let uid = Auth.auth().currentUser?.uid, !uid.isEmpty
        else { return }
        let data: [String: Any] = [
            "token":     fcmToken,
            "platform":  "ios",
            "updatedAt": Timestamp(date: Date())
        ]
        // Use the token itself as the document ID so re-saves are idempotent
        // and each device/token pair is unique.
        try? await db.collection("users").document(uid)
            .collection("pushTokens").document(fcmToken)
            .setData(data)
    }

    /// Removes the current device's FCM token on logout so the user
    /// stops receiving push notifications on this device.
    func removeCurrentToken() async {
        guard let token = Messaging.messaging().fcmToken,
              let uid = Auth.auth().currentUser?.uid, !uid.isEmpty
        else { return }
        try? await db.collection("users").document(uid)
            .collection("pushTokens").document(token)
            .delete()
    }
}
