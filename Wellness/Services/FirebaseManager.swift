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
    /// Bumped whenever the cache-recovery logic changes. If the stored
    /// version is lower (or missing), persistence is cleared once so
    /// any corruption left by earlier builds is wiped automatically.
    ///
    /// v2: earlier builds shipped with `NSFileProtectionComplete` as
    /// the default data-protection class, which meant every LevelDB
    /// file Firestore wrote inherited `Complete` protection and became
    /// unwritable whenever the device locked — causing the index
    /// backfiller to crash with "Operation not permitted". The
    /// entitlement is now `CompleteUntilFirstUserAuthentication`, but
    /// files that were created on-disk under the old entitlement keep
    /// their original class forever. Bumping the schema version forces
    /// a one-shot `clearPersistence()` on upgrade so those files are
    /// wiped and recreated with the correct class.
    private static let cacheSchemaVersion = 2
    private static let cacheSchemaKey     = "firestoreCacheSchema"

    private init() {
        // ── Crash recovery ──────────────────────────────────────────────
        // Clear the persistence cache when:
        //   1. This is the first launch with the new recovery code
        //      (cacheSchemaVersion is missing / outdated), OR
        //   2. The previous session crashed (sessionActive flag is
        //      still true because markCleanExit() never ran).
        //
        // This guarantees corrupted LevelDB files left by earlier
        // builds are cleaned up on the very first run of the fix.
        let storedSchema    = UserDefaults.standard.integer(forKey: Self.cacheSchemaKey)
        let previousCrashed = UserDefaults.standard.bool(forKey: Self.sessionActiveKey)
        let needsCacheClear = storedSchema < Self.cacheSchemaVersion || previousCrashed

        if needsCacheClear {
            // Clear persistence synchronously — avoid blocking main thread with semaphore
            // which can deadlock when Firestore dispatches the completion on the main queue.
            try? Firestore.firestore().clearPersistence()
            AppLogger.log("[FirebaseManager] Cleared persistence cache (schema \(storedSchema)→\(Self.cacheSchemaVersion), crashed=\(previousCrashed))")
            UserDefaults.standard.set(Self.cacheSchemaVersion, forKey: Self.cacheSchemaKey)
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
                AppLogger.log("[FirebaseManager] disableNetwork failed: \(error.localizedDescription)")
            }
        }
    }

    /// Call when the app is backgrounding or terminating to record a clean exit.
    func markCleanExit() {
        UserDefaults.standard.set(false, forKey: Self.sessionActiveKey)
    }

    // MARK: - File Protection

    /// Ensures the Firestore LevelDB cache uses
    /// `.completeUntilFirstUserAuthentication` so background threads
    /// and index-backfill operations can always write to it — even
    /// while the device is locked.
    ///
    /// The app's default data-protection entitlement is set to
    /// `CompleteUntilFirstUserAuthentication`, so any files Firestore
    /// creates from now on will already inherit that class. This
    /// function exists as a defence-in-depth retrofit for installs
    /// that already have LevelDB files left over from a build that
    /// shipped with `NSFileProtectionComplete` — those files keep
    /// their original (too-strict) protection class and must be
    /// downgraded explicitly.
    ///
    /// Firestore's actual on-disk path is:
    ///   Library/Application Support/firestore/__FIRAPP_DEFAULT/<project>/main/
    private static func relaxFirestoreCacheProtection() {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else { return }

        let fm = FileManager.default
        // Cover both the lowercase path Firestore actually uses
        // and the capitalised name some older Firebase SDK builds
        // used, just in case either exists on disk.
        let candidates = [
            appSupport.appendingPathComponent("firestore"),
            appSupport.appendingPathComponent("Firebase")
        ]

        let protection: [FileAttributeKey: Any] = [
            .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
        ]

        for root in candidates {
            guard fm.fileExists(atPath: root.path) else { continue }
            try? fm.setAttributes(protection, ofItemAtPath: root.path)
            if let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: nil) {
                while let fileURL = enumerator.nextObject() as? URL {
                    try? fm.setAttributes(protection, ofItemAtPath: fileURL.path)
                }
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
            AppLogger.log("[FirebaseManager] Network enabled")
        } catch {
            AppLogger.log("[FirebaseManager] enableNetwork failed: \(error.localizedDescription)")
        }
    }
}
