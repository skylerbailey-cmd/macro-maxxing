//
//  FirebaseManager.swift
//  Wellness
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

final class FirebaseManager {
    static let shared = FirebaseManager()

    let db: Firestore
    let storage: StorageReference

    /// Serialises disableNetwork / enableNetwork so they never overlap.
    /// The task completes once the initial disableNetwork finishes;
    /// enableNetwork() awaits it first so the two calls can never race.
    private let networkReady: Task<Void, Never>

    private static let sessionActiveKey = "firestoreSessionActive"

    private init() {
        // ── Crash recovery ──────────────────────────────────────────────
        // If the flag is still true the previous session didn't terminate
        // cleanly, which means LevelDB may be corrupted.  Clear the
        // persistence cache so Firestore can start fresh and re-sync.
        let previousCrashed = UserDefaults.standard.bool(forKey: Self.sessionActiveKey)
        if previousCrashed {
            let sem = DispatchSemaphore(value: 0)
            Firestore.firestore().clearPersistence { error in
                if let error {
                    print("[FirebaseManager] clearPersistence failed: \(error.localizedDescription)")
                } else {
                    print("[FirebaseManager] Cleared corrupted persistence cache after crash")
                }
                sem.signal()
            }
            sem.wait()
        }
        // Mark this session as active; cleared in markCleanExit().
        UserDefaults.standard.set(true, forKey: Self.sessionActiveKey)

        // ── Relax file protection on the Firestore cache directory ──────
        // Default iOS Data Protection can block LevelDB writes on
        // background threads.  Downgrade to "until first user
        // authentication" so the cache stays writable after unlock.
        Self.relaxFirestoreCacheProtection()

        // ── Configure Firestore ─────────────────────────────────────────
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
        networkReady = Task {
            do {
                try await firestore.disableNetwork()
            } catch {
                print("[FirebaseManager] disableNetwork failed: \(error.localizedDescription)")
            }
        }
    }

    /// Call when the app is backgrounding or terminating to record a clean exit.
    func markCleanExit() {
        UserDefaults.standard.set(false, forKey: Self.sessionActiveKey)
    }

    // MARK: - File Protection

    /// Ensures the Firestore / Firebase support directories use
    /// `.completeUntilFirstUserAuthentication` so background threads
    /// and index-backfill operations can always write to LevelDB.
    private static func relaxFirestoreCacheProtection() {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else { return }

        let firebaseDir = appSupport.appendingPathComponent("Firebase")
        let fm = FileManager.default
        guard fm.fileExists(atPath: firebaseDir.path) else { return }

        let protection: [FileAttributeKey: Any] = [
            .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
        ]
        // Apply to the Firebase directory and all children
        if let enumerator = fm.enumerator(at: firebaseDir, includingPropertiesForKeys: nil) {
            // Set on the root first
            try? fm.setAttributes(protection, ofItemAtPath: firebaseDir.path)
            while let fileURL = enumerator.nextObject() as? URL {
                try? fm.setAttributes(protection, ofItemAtPath: fileURL.path)
            }
        }
    }

    /// Re-enable the Firestore network connection.
    /// Call once after auth resolves so writes sync to the backend.
    func enableNetwork() async {
        // Wait for disableNetwork to finish so the two never overlap.
        await networkReady.value
        do {
            try await db.enableNetwork()
            print("[FirebaseManager] Network enabled")
        } catch {
            print("[FirebaseManager] enableNetwork failed: \(error.localizedDescription)")
        }
    }
}
