//
//  UserProfileService.swift
//  Wellness
//
//  Handles all Firestore + Firebase Storage operations for user profiles.
//  Collection: "users"   Storage path: profile_photos/{userID}.jpg
//

import UIKit
import FirebaseFirestore
import FirebaseStorage

final class UserProfileService {

    // MARK: - Singleton

    static let shared = UserProfileService()
    private init() {}

    // MARK: - Private refs

    private var db:      Firestore        { FirebaseManager.shared.db }
    private var storage: StorageReference { FirebaseManager.shared.storage }

    private let collectionName = "users"

    // MARK: - Errors

    enum UserProfileError: LocalizedError {
        case profileNotFound
        case imageCompressionFailed

        var errorDescription: String? {
            switch self {
            case .profileNotFound:        return "User profile could not be found."
            case .imageCompressionFailed: return "Could not compress the profile photo for upload."
            }
        }
    }

    // MARK: - 1. Create Profile

    /// Writes a new user document to Firestore at `users/{profile.userID}`.
    /// Sensitive fields (DOB, weight, height, gender, dietary) are stored in
    /// `users/{uid}/private/profile` so other users cannot read them.
    /// Uses `setData(merge: true)` so calling this on an existing profile is safe.
    func createProfile(_ profile: UserProfile) async throws {
        let userID = profile.userID
        guard !userID.isEmpty else { return }
        let publicData  = try profile.publicFieldsData()
        let privateData = profile.privateFieldsData()
        try await db.collection(collectionName).document(userID).setData(publicData, merge: true)
        try await db.collection(collectionName).document(userID)
            .collection("private").document("profile").setData(privateData, merge: true)
        AppLogger.log("[UserProfileService] Profile created/merged for \(userID)")
    }

    // MARK: - 2. Fetch Profile

    /// Returns true if a Firestore document exists for `userID`, regardless of whether
    /// it can be fully decoded into a UserProfile. Use this instead of fetchProfile()
    /// when you only need to know whether the document is present (e.g. before creating
    /// a new profile to avoid overwriting an existing one).
    ///
    /// Throws on network / permission errors rather than returning false, so callers
    /// don't silently create a fresh profile (and merge over the real one) on a
    /// transient fetch failure.
    func profileExists(userID: String) async throws -> Bool {
        guard !userID.isEmpty else { return false }
        let doc = try await db.collection(collectionName).document(userID).getDocument()
        return doc.exists
    }

    /// Fetches the user document for `userID` and decodes it into a `UserProfile`.
    ///
    /// - Parameter includePrivateFields: When `true` (default), also reads
    ///   `users/{uid}/private/profile` and merges the sensitive fields into the
    ///   result. Pass `false` when loading another user's profile for display
    ///   (leaderboard, feed, profile cards) so you never attempt to read data
    ///   the Firestore rules would deny.
    func fetchProfile(userID: String, includePrivateFields: Bool = true) async throws -> UserProfile {
        guard !userID.isEmpty else { throw UserProfileError.profileNotFound }
        let doc = try await db.collection(collectionName).document(userID).getDocument()
        guard var profile = UserProfile(document: doc) else {
            throw UserProfileError.profileNotFound
        }

        // Capture the RAW public-doc data so we can detect private fields
        // that got written to the public doc by the pre-fix saveProfile flow.
        // Those values represent the user's most recent saves and must win
        // over any stale values in the private subcollection, otherwise the
        // save appears to "reset" on next fetch.
        let rawPublicData = doc.data() ?? [:]
        let legacyPublicPrivateFields: [String: Any] = rawPublicData.filter {
            UserProfile.privateFieldKeys.contains($0.key)
        }

        // Merge private fields (only for the authenticated user's own profile).
        // Errors are logged rather than swallowed silently — a failed private
        // fetch leaves weight/gender/dietary at the public-doc defaults, which
        // is what caused the "settings reset after migration" bug.
        if includePrivateFields {
            do {
                let privateDoc = try await db.collection(collectionName).document(userID)
                    .collection("private").document("profile").getDocument()
                if let data = privateDoc.data() {
                    profile.dateOfBirth   = data["dateOfBirth"]   as? String ?? profile.dateOfBirth
                    profile.currentWeight = data["currentWeight"] as? Double ?? profile.currentWeight
                    profile.goalWeight    = data["goalWeight"]    as? Double ?? profile.goalWeight
                    profile.heightInches  = data["heightInches"]  as? Int    ?? profile.heightInches
                    profile.proteinPerLb  = data["proteinPerLb"]  as? Double ?? profile.proteinPerLb
                    profile.gender        = data["gender"]        as? String ?? profile.gender
                    profile.excludeDairy  = data["excludeDairy"]  as? Bool   ?? profile.excludeDairy
                    profile.excludeGluten = data["excludeGluten"] as? Bool   ?? profile.excludeGluten
                } else {
                    AppLogger.log("[UserProfileService] Private profile doc missing for \(userID) — using public-doc defaults for weight/gender/dietary")
                }
            } catch {
                AppLogger.log("[UserProfileService] Failed to read private profile doc for \(userID): \(error.localizedDescription)")
            }

            // RECOVERY: legacy saves (via SettingsView / OnboardingView before
            // the auto-split fix) wrote private fields to the public doc.
            // Those values represent the user's most recent intent, so they
            // override any stale values from the private subcollection.
            if !legacyPublicPrivateFields.isEmpty {
                if let v = legacyPublicPrivateFields["dateOfBirth"]   as? String { profile.dateOfBirth   = v }
                if let v = legacyPublicPrivateFields["currentWeight"] as? Double { profile.currentWeight = v }
                if let v = legacyPublicPrivateFields["goalWeight"]    as? Double { profile.goalWeight    = v }
                if let v = legacyPublicPrivateFields["heightInches"]  as? Int    { profile.heightInches  = v }
                if let v = legacyPublicPrivateFields["proteinPerLb"]  as? Double { profile.proteinPerLb  = v }
                if let v = legacyPublicPrivateFields["gender"]        as? String { profile.gender        = v }
                if let v = legacyPublicPrivateFields["excludeDairy"]  as? Bool   { profile.excludeDairy  = v }
                if let v = legacyPublicPrivateFields["excludeGluten"] as? Bool   { profile.excludeGluten = v }

                let recoveredKeys = legacyPublicPrivateFields.keys.joined(separator: ", ")
                AppLogger.log("[UserProfileService] Recovered \(legacyPublicPrivateFields.count) legacy private field(s) from public doc for \(userID): \(recoveredKeys)")

                // Self-heal: move the recovered values into the private
                // subcollection and delete them from the public doc so
                // sensitive data stops leaking and future fetches don't
                // need to run this recovery path.
                Task.detached {
                    await UserProfileService.shared.healLegacyPrivateFields(
                        userID: userID, fields: legacyPublicPrivateFields)
                }
            }
        }
        return profile
    }

    // MARK: - Legacy Private Field Self-Heal

    /// Moves legacy private field values from the public `users/{uid}` doc
    /// into `users/{uid}/private/profile`, then deletes them from the
    /// public doc. Called from fetchProfile when the public doc is detected
    /// to contain keys that belong in the private subcollection (because
    /// pre-fix SettingsView / OnboardingView code wrote them there).
    func healLegacyPrivateFields(userID: String, fields: [String: Any]) async {
        guard !userID.isEmpty, !fields.isEmpty else { return }
        do {
            try await db.collection(collectionName).document(userID)
                .collection("private").document("profile")
                .setData(fields, merge: true)
            var deletes: [String: Any] = [:]
            for key in fields.keys {
                deletes[key] = FieldValue.delete()
            }
            try await db.collection(collectionName).document(userID)
                .updateData(deletes)
            AppLogger.log("[UserProfileService] Self-heal complete: moved \(fields.count) field(s) from public doc to private subcollection for \(userID)")
        } catch {
            AppLogger.log("[UserProfileService] Self-heal failed for \(userID): \(error.localizedDescription)")
        }
    }

    // MARK: - 3. Username Availability

    /// Returns true if `username` is already claimed by a different user.
    /// Pass the current user's ID so their own username is never flagged as taken.
    func isUsernameTaken(_ username: String, excludingUserID: String) async -> Bool {
        guard !username.isEmpty else { return false }
        do {
            let snapshot = try await db.collection(collectionName)
                .whereField("username", isEqualTo: username)
                .getDocuments()
            // Available if no documents found, or the only match is the current user
            return snapshot.documents.contains { $0.documentID != excludingUserID }
        } catch {
            AppLogger.log("[UserProfileService] Username check failed: \(error.localizedDescription)")
            return false // fail open so the user isn't blocked by a network error
        }
    }

    // MARK: - Weekly Aura Board

    struct WeeklyAuraBoardEntry {
        let userID:                      String
        let name:                        String
        let username:                    String
        let auraPoints:                  Int
        let weeklyAuraPoints:            Int
        let weeklyAuraWeekStartTimestamp: Double
        let location:                    String
        let isPrivate:                   Bool
        let streakDays:                  Int
        let profilePhotoURL:             String
    }

    /// Fetches the top `limit` users by `weeklyAuraPoints` this week.
    /// Single-field index on `weeklyAuraPoints` is auto-created by Firestore.
    func fetchWeeklyAuraBoard(limit: Int = 200) async throws -> [WeeklyAuraBoardEntry] {
        let snapshot = try await db.collection(collectionName)
            .whereField("weeklyAuraPoints", isGreaterThan: 0)
            .order(by: "weeklyAuraPoints", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            return WeeklyAuraBoardEntry(
                userID:                       doc.documentID,
                name:                         data["name"]                        as? String ?? "",
                username:                     data["username"]                    as? String ?? "",
                auraPoints:                   data["auraPoints"]                  as? Int    ?? 0,
                weeklyAuraPoints:             data["weeklyAuraPoints"]            as? Int    ?? 0,
                weeklyAuraWeekStartTimestamp: data["weeklyAuraWeekStartTimestamp"] as? Double ?? 0,
                location:                     data["location"]                    as? String ?? "",
                isPrivate:                    data["isPrivateAccount"]            as? Bool   ?? false,
                streakDays:                   data["streakDays"]                  as? Int    ?? 0,
                profilePhotoURL:              data["profilePhotoURL"]             as? String ?? ""
            )
        }
    }

    // MARK: - Last week's snapshot

    struct WeeklySnapshotEntry: Identifiable {
        let id:             String   // userID
        let rank:           Int
        let username:       String
        let displayName:    String
        let auraPoints:     Int
        let location:       String
    }

    struct WeeklySnapshot {
        let weekStartDate: String
        let entries:       [WeeklySnapshotEntry]
    }

    /// Fetches the most recent `weeklySnapshots` document (last week's results).
    func fetchLastWeekSnapshot() async throws -> WeeklySnapshot? {
        let snap = try await db.collection("weeklySnapshots")
            .order(by: "createdAt", descending: true)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snap.documents.first else { return nil }
        let data         = doc.data()
        let weekStart    = data["weekStartDate"] as? String ?? doc.documentID
        let rawEntries   = data["entries"] as? [[String: Any]] ?? []

        let entries: [WeeklySnapshotEntry] = rawEntries.compactMap { e in
            guard let userID = e["userID"] as? String else { return nil }
            return WeeklySnapshotEntry(
                id:          userID,
                rank:        e["rank"]        as? Int    ?? 0,
                username:    e["username"]    as? String ?? "",
                displayName: e["displayName"] as? String ?? "",
                auraPoints:  e["auraPoints"]  as? Int    ?? 0,
                location:    e["location"]    as? String ?? ""
            )
        }
        return WeeklySnapshot(weekStartDate: weekStart, entries: entries)
    }

    // MARK: - 4. Update Profile Fields

    /// Merges `fields` into the user's profile, routing each key to the
    /// correct document automatically. Keys in `UserProfile.privateFieldKeys`
    /// go to `users/{uid}/private/profile`; everything else goes to the
    /// public `users/{uid}` document.
    ///
    /// This splitting is essential after commit 598f47d: before that, every
    /// caller wrote the full profile to the public doc. Callers like
    /// SettingsView.saveProfile and OnboardingView were never updated, so
    /// their saves landed in the wrong document and were then overridden on
    /// the next fetch by stale values in the private subcollection — which
    /// is what caused the "settings reset after save" bug.
    ///
    /// Pass only the keys you want to change, e.g.
    /// `["username": "newname", "currentWeight": 190]` — the first goes to
    /// the public doc, the second to the private subcollection.
    func updateProfile(userID: String, fields: [String: Any]) async throws {
        guard !userID.isEmpty else { return }

        var publicFields:  [String: Any] = [:]
        var privateFields: [String: Any] = [:]
        for (key, value) in fields {
            if UserProfile.privateFieldKeys.contains(key) {
                privateFields[key] = value
            } else {
                publicFields[key] = value
            }
        }

        if !publicFields.isEmpty {
            try await db.collection(collectionName).document(userID)
                .setData(publicFields, merge: true)
        }
        if !privateFields.isEmpty {
            try await db.collection(collectionName).document(userID)
                .collection("private").document("profile")
                .setData(privateFields, merge: true)
            // Also delete any legacy copies of these keys from the public doc
            // so sensitive data doesn't keep leaking there.
            var legacyDeletes: [String: Any] = [:]
            for key in privateFields.keys {
                legacyDeletes[key] = FieldValue.delete()
            }
            try? await db.collection(collectionName).document(userID)
                .updateData(legacyDeletes)
        }

        let allKeys = fields.keys.joined(separator: ", ")
        AppLogger.log("[UserProfileService] Updated fields \(allKeys) for \(userID) (public: \(publicFields.count), private: \(privateFields.count))")
    }

    // MARK: - 4. Sync Profile Fields (convenience)

    /// Pushes the current local UserSettings values to Firestore.
    /// Public fields go to `users/{uid}`, sensitive fields to `users/{uid}/private/profile`.
    /// Fire-and-forget — errors are logged but not rethrown.
    func syncProfile(from userSettings: UserSettings) async {
        let userID = userSettings.userID
        guard !userID.isEmpty else { return }
        let publicFields: [String: Any] = [
            "username":          userSettings.username,
            "name":              userSettings.name,
            "location":          userSettings.location,
            "auraPoints":        userSettings.auraPoints,
            // streakDays is owned by the computeStreak Cloud Function — do NOT overwrite
            "bio":               userSettings.bio,
            "instagramHandle":   userSettings.instagramHandle,
            "tiktokHandle":      userSettings.tiktokHandle,
            "isPrivateAccount":  userSettings.isPrivateAccount,
            "fastingEnabled":    userSettings.fastingEnabled,
            "auraPopupsEnabled": userSettings.auraPopupsEnabled,
            "lastGoalsMetDate":  userSettings.lastGoalsMetDate,
        ]
        let privateFields: [String: Any] = [
            "currentWeight": userSettings.currentWeight,
            "goalWeight":    userSettings.goalWeight,
            "proteinPerLb":  userSettings.proteinPerLb,
            "gender":        userSettings.gender,
            "excludeDairy":  userSettings.excludeDairy,
            "excludeGluten": userSettings.excludeGluten,
        ]
        do {
            try await updateProfile(userID: userID, fields: publicFields)
            try await db.collection(collectionName).document(userID)
                .collection("private").document("profile")
                .setData(privateFields, merge: true)
        } catch {
            AppLogger.log("[UserProfileService] syncProfile failed: \(error.localizedDescription)")
        }
    }

    // MARK: - 5. Update Profile Photo

    /// Uploads `image` to Storage at `profile_photos/{userID}.jpg`,
    /// then saves the download URL back to the Firestore profile document.
    /// Returns the new download URL string.
    @discardableResult
    func updateProfilePhoto(userID: String, image: UIImage) async throws -> String {
        guard !userID.isEmpty else { return "" }
        guard let imageData = compress(image) else {
            throw UserProfileError.imageCompressionFailed
        }

        let ref      = storage.child("profile_photos/\(userID).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        AppLogger.log("[UserProfileService] Uploading profile photo to \(ref.fullPath) (\(imageData.count / 1024) KB)")
        try await uploadData(imageData, to: ref, metadata: metadata)

        let downloadURL = try await fetchDownloadURL(for: ref)
        AppLogger.log("[UserProfileService] Profile photo upload succeeded: \(downloadURL)")

        // Use setData(merge:true) so this works whether or not the document exists yet
        try await db.collection(collectionName).document(userID).setData([
            "profilePhotoURL": downloadURL.absoluteString
        ], merge: true)

        return downloadURL.absoluteString
    }

    // MARK: - Helpers

    private func uploadData(_ data: Data, to ref: StorageReference, metadata: StorageMetadata) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.putData(data, metadata: metadata) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func fetchDownloadURL(for ref: StorageReference) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            ref.downloadURL { url, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: UserProfileError.profileNotFound)
                }
            }
        }
    }

    /// Compresses `image` to JPEG data ≤ 400 KB (profile photos are smaller than food photos).
    private func compress(_ image: UIImage, targetBytes: Int = 400_000) -> Data? {
        let steps: [CGFloat] = [0.85, 0.75, 0.65, 0.55, 0.45, 0.35, 0.20]
        for q in steps {
            if let data = image.jpegData(compressionQuality: q), data.count <= targetBytes {
                return data
            }
        }
        guard let oversized = image.jpegData(compressionQuality: 0.20) else { return nil }
        let ratio   = sqrt(Double(targetBytes) / Double(oversized.count))
        let newSize = CGSize(
            width:  (image.size.width  * ratio).rounded(),
            height: (image.size.height * ratio).rounded()
        )
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized  = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: 0.85)
    }
}
