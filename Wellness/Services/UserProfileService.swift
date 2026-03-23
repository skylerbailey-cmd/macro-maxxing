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
    /// Uses `setData(merge: true)` so calling this on an existing profile is safe.
    func createProfile(_ profile: UserProfile) async throws {
        let userID = profile.userID
        guard !userID.isEmpty else { return }
        let data = try profile.firestoreData()
        try await db.collection(collectionName).document(userID).setData(data, merge: true)
        print("[UserProfileService] Profile created/merged for \(userID)")
    }

    // MARK: - 2. Fetch Profile

    /// Returns true if a Firestore document exists for `userID`, regardless of whether
    /// it can be fully decoded into a UserProfile. Use this instead of fetchProfile()
    /// when you only need to know whether the document is present (e.g. before creating
    /// a new profile to avoid overwriting an existing one).
    func profileExists(userID: String) async -> Bool {
        guard !userID.isEmpty else { return false }
        return (try? await db.collection(collectionName).document(userID)
            .getDocument())?.exists == true
    }

    /// Fetches the user document for `userID` and decodes it into a `UserProfile`.
    func fetchProfile(userID: String) async throws -> UserProfile {
        guard !userID.isEmpty else { throw UserProfileError.profileNotFound }
        let doc = try await db.collection(collectionName).document(userID).getDocument()
        guard let profile = UserProfile(document: doc) else {
            throw UserProfileError.profileNotFound
        }
        return profile
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
            print("[UserProfileService] Username check failed: \(error.localizedDescription)")
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

    /// Merges `fields` into the existing user document.
    /// Pass only the keys you want to change, e.g. `["username": "newname", "auraPoints": 500]`.
    func updateProfile(userID: String, fields: [String: Any]) async throws {
        guard !userID.isEmpty else { return }
        try await db.collection(collectionName).document(userID).setData(fields, merge: true)
        print("[UserProfileService] Updated fields \(fields.keys.joined(separator: ", ")) for \(userID)")
    }

    // MARK: - 4. Sync Profile Fields (convenience)

    /// Pushes the current local UserSettings values to Firestore.
    /// Fire-and-forget — errors are logged but not rethrown.
    func syncProfile(from userSettings: UserSettings) async {
        let userID = userSettings.userID
        guard !userID.isEmpty else { return }
        let fields: [String: Any] = [
            "username":          userSettings.username,
            "name":              userSettings.name,
            "location":          userSettings.location,
            "auraPoints":        userSettings.auraPoints,
            // streakDays is owned by the computeStreak Cloud Function — do NOT overwrite
            "bio":               userSettings.bio,
            "instagramHandle":   userSettings.instagramHandle,
            "tiktokHandle":      userSettings.tiktokHandle,
            "isPrivateAccount":  userSettings.isPrivateAccount,
            "currentWeight":     userSettings.currentWeight,
            "goalWeight":        userSettings.goalWeight,
            "proteinPerLb":      userSettings.proteinPerLb,
            "gender":            userSettings.gender,
            "fastingEnabled":    userSettings.fastingEnabled,
            "auraPopupsEnabled": userSettings.auraPopupsEnabled,
            "excludeDairy":          userSettings.excludeDairy,
            "excludeGluten":         userSettings.excludeGluten,
            "lastStreakCheckDate":   userSettings.lastStreakCheckDate,
        ]
        do {
            try await updateProfile(userID: userID, fields: fields)
        } catch {
            print("[UserProfileService] syncProfile failed: \(error.localizedDescription)")
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

        print("[UserProfileService] Uploading profile photo to \(ref.fullPath) (\(imageData.count / 1024) KB)")
        try await uploadData(imageData, to: ref, metadata: metadata)

        let downloadURL = try await fetchDownloadURL(for: ref)
        print("[UserProfileService] Profile photo upload succeeded: \(downloadURL)")

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
