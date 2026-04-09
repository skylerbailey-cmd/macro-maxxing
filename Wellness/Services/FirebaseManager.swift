//
//  FirebaseManager.swift
//  Wellness
//

import FirebaseFirestore
import FirebaseStorage

final class FirebaseManager {
    static let shared = FirebaseManager()

    let db: Firestore
    let storage: StorageReference

    private init() {
        // Enable offline persistence with a 50 MB cache
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 50_000_000 as NSNumber)
        let firestore = Firestore.firestore()
        firestore.settings = settings
        db = firestore
        storage = Storage.storage().reference()

        // Start with network disabled so the app launches from cache instantly
        // instead of blocking on Firestore backend connectivity (which caused
        // 10s+ "Could not reach Cloud Firestore backend" stalls).
        // Call enableNetwork() after auth resolves.
        firestore.disableNetwork { error in
            if let error {
                print("[FirebaseManager] disableNetwork failed: \(error.localizedDescription)")
            }
        }
    }

    /// Re-enable the Firestore network connection.
    /// Call once after auth resolves so writes sync to the backend.
    func enableNetwork() async {
        do {
            try await db.enableNetwork()
            print("[FirebaseManager] Network enabled")
        } catch {
            print("[FirebaseManager] enableNetwork failed: \(error.localizedDescription)")
        }
    }
}
