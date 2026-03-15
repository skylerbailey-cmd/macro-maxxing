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
        guard let userID = profile.userID, !userID.isEmpty else { return }
        let data = try profile.firestoreData()
        try await db.collection(collectionName).document(userID).setData(data, merge: true)
        print("[UserProfileService] Profile created/merged for \(userID)")
    }

    // MARK: - 2. Fetch Profile

    /// Fetches the user document for `userID` and decodes it into a `UserProfile`.
    func fetchProfile(userID: String) async throws -> UserProfile {
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

    // MARK: - 4. Update Profile Fields

    /// Merges `fields` into the existing user document.
    /// Pass only the keys you want to change, e.g. `["username": "newname", "auraPoints": 500]`.
    func updateProfile(userID: String, fields: [String: Any]) async throws {
        try await db.collection(collectionName).document(userID).updateData(fields)
        print("[UserProfileService] Updated fields \(fields.keys.joined(separator: ", ")) for \(userID)")
    }

    // MARK: - 4. Sync Profile Fields (convenience)

    /// Pushes the current local UserSettings values to Firestore.
    /// Fire-and-forget — errors are logged but not rethrown.
    func syncProfile(from userSettings: UserSettings) async {
        let userID = userSettings.userID
        guard !userID.isEmpty else { return }
        let fields: [String: Any] = [
            "username":   userSettings.username,
            "name":       userSettings.name,
            "location":   userSettings.location,
            "auraPoints": userSettings.auraPoints,
            "streakDays": userSettings.macroStreak,
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
