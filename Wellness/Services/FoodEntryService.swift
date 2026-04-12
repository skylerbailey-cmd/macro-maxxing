//
//  FoodEntryService.swift
//  Wellness
//
//  Syncs food log entries to Firestore and food photos to Firebase Storage.
//
//  Firestore:  users/{userID}/foodEntries/{entryID}
//  Storage:    food_photos/{userID}/{entryID}.jpg
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class FoodEntryService {

    // MARK: - Singleton

    static let shared = FoodEntryService()
    private init() {}

    // MARK: - Private refs

    private var db:      Firestore        { FirebaseManager.shared.db }
    private var storage: StorageReference { FirebaseManager.shared.storage }

    // MARK: - 1. Save

    /// Uploads the photo (if any) to Storage then writes all fields to Firestore.
    /// Returns the Firestore document ID and the photo download URL (empty string if no photo).
    ///
    /// Throws if a photo is provided and the upload fails — the Firestore write is
    /// skipped so the caller can retry instead of leaving a meal stranded without a
    /// photoURL in the database.
    @discardableResult
    func save(entry: FoodEntry, image: UIImage?, existingPhotoURL: String = "") async throws -> (docID: String, photoURL: String) {
        guard !entry.userID.isEmpty else { return ("", "") }

        let entryID = entry.firebaseEntryID.isEmpty ? entry.id.uuidString : entry.firebaseEntryID

        // Upload photo first so the URL can be included in the Firestore write.
        // If no new image but an existing URL is provided (e.g. from a saved meal), use that.
        // If a photo IS provided, we require the upload to succeed — silently swallowing
        // upload errors used to leave entries in Firestore with an empty photoURL, which
        // is unrecoverable once the in-memory imageData is dropped on the next refetch.
        var photoURL = existingPhotoURL
        if let image {
            photoURL = try await uploadPhoto(image: image, userID: entry.userID, entryID: entryID)
        }

        let data: [String: Any] = [
            "entryID":     entryID,
            "userID":      entry.userID,
            "foodName":    entry.foodName,
            "calories":    entry.calories,
            "protein":     entry.protein,
            "carbs":       entry.carbs,
            "fat":         entry.fat,
            "loggedAt":    Timestamp(date: entry.loggedAt),
            "photoURL":    photoURL,
            "isSavedMeal": entry.isSavedMeal
        ]

        let docRef = db.collection("users").document(entry.userID)
            .collection("foodEntries").document(entryID)
        try await docRef.setData(data)

        return (entryID, photoURL)
    }

    // MARK: - 2. Delete

    /// Removes the Firestore document and the Storage photo (if any).
    func delete(entryID: String, userID: String) async {
        guard !entryID.isEmpty, !userID.isEmpty else { return }

        let docRef = db.collection("users").document(userID)
            .collection("foodEntries").document(entryID)
        try? await docRef.delete()

        // Best-effort photo deletion — ignore errors if there's no photo
        let photoRef = storage.child("food_photos/\(userID)/\(entryID).jpg")
        try? await photoRef.delete()
    }

    // MARK: - 3. Update (fields only — photo is not re-uploaded on edit)

    func update(entryID: String, userID: String, foodName: String, calories: Double,
                protein: Double, carbs: Double, fat: Double, loggedAt: Date? = nil) async {
        guard !entryID.isEmpty, !userID.isEmpty else { return }

        let docRef = db.collection("users").document(userID)
            .collection("foodEntries").document(entryID)
        var fields: [String: Any] = [
            "foodName": foodName,
            "calories": calories,
            "protein":  protein,
            "carbs":    carbs,
            "fat":      fat
        ]
        if let loggedAt { fields["loggedAt"] = Timestamp(date: loggedAt) }
        try? await docRef.updateData(fields)
    }

    // MARK: - 4. Fetch

    /// Fetches all food entries for a user on a given date, ordered newest first.
    func fetch(userID: String, date: Date) async throws -> [FoodEntry] {
        guard !userID.isEmpty else { return [] }
        let calendar = Calendar.current
        let start    = calendar.startOfDay(for: date)
        let end      = calendar.date(byAdding: .day, value: 1, to: start)!

        let snapshot = try await db.collection("users").document(userID)
            .collection("foodEntries")
            .whereField("loggedAt", isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField("loggedAt", isLessThan: Timestamp(date: end))
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            let data     = doc.data()
            guard let foodName = data["foodName"] as? String,
                  let calories = data["calories"] as? Double,
                  let protein  = data["protein"]  as? Double,
                  let carbs    = data["carbs"]    as? Double,
                  let fat      = data["fat"]      as? Double,
                  let ts       = data["loggedAt"] as? Timestamp else { return nil }

            let entryID  = data["entryID"]  as? String ?? doc.documentID
            let uid      = data["userID"]   as? String ?? userID
            let photoURL = data["photoURL"] as? String ?? ""

            let entry = FoodEntry(
                id:       UUID(uuidString: entryID) ?? UUID(),
                loggedAt: ts.dateValue(),
                userID:   uid,
                foodName: foodName,
                calories: calories,
                protein:  protein,
                carbs:    carbs,
                fat:      fat
            )
            entry.firebaseEntryID = entryID
            entry.photoURL        = photoURL
            entry.isSavedMeal     = data["isSavedMeal"] as? Bool ?? false
            return entry
        }
        .sorted { $0.loggedAt > $1.loggedAt }
    }

    // MARK: - 5. Saved meals

    /// Fetches all food entries marked as saved meals for a user, ordered newest first.
    func fetchSavedMeals(userID: String) async throws -> [FoodEntry] {
        guard !userID.isEmpty else { return [] }

        let snapshot = try await db.collection("users").document(userID)
            .collection("foodEntries")
            .whereField("isSavedMeal", isEqualTo: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            let data     = doc.data()
            guard let foodName = data["foodName"] as? String,
                  let calories = data["calories"] as? Double,
                  let protein  = data["protein"]  as? Double,
                  let carbs    = data["carbs"]    as? Double,
                  let fat      = data["fat"]      as? Double,
                  let ts       = data["loggedAt"] as? Timestamp else { return nil }

            let entryID  = data["entryID"]  as? String ?? doc.documentID
            let uid      = data["userID"]   as? String ?? userID
            let photoURL = data["photoURL"] as? String ?? ""

            let entry = FoodEntry(
                id:       UUID(uuidString: entryID) ?? UUID(),
                loggedAt: ts.dateValue(),
                userID:   uid,
                foodName: foodName,
                calories: calories,
                protein:  protein,
                carbs:    carbs,
                fat:      fat
            )
            entry.firebaseEntryID = entryID
            entry.photoURL        = photoURL
            entry.isSavedMeal     = true
            return entry
        }
        .sorted { $0.loggedAt > $1.loggedAt }
    }

    // MARK: - Private: Photo upload

    private func uploadPhoto(image: UIImage, userID: String, entryID: String) async throws -> String {
        // The Storage rule enforces request.resource.size < 2 MB. A raw
        // iPhone photo at jpegData(compressionQuality: 0.75) is 3-5 MB,
        // so the rule rejected every upload — which the SDK surfaces as
        // "User does not have permission" (rule evaluation failed), not
        // as a size error. Compress to ~600 KB, resizing if needed, so
        // we stay comfortably under the cap.
        guard let data = Self.compress(image) else {
            throw URLError(.cannotCreateFile)
        }

        // Force-refresh the Firebase ID token before talking to Storage.
        // On cold launch or after a long idle, the cached token can be close
        // to expiry; Storage then rejects downloadURL / putData with
        // "User does not have permission" even though the rules match. A
        // proactive refresh here gives GTMSessionFetcher a fresh bearer.
        _ = try? await Auth.auth().currentUser?.getIDTokenResult(forcingRefresh: true)

        let ref      = storage.child("food_photos/\(userID)/\(entryID).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Upload. If this throws with "object already exists / upload
        // already finalized" (HTTP 400 from a resumable retry after a
        // partial success), the bytes are already on the server — fall
        // through to the downloadURL step instead of reporting failure.
        do {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                ref.putData(data, metadata: metadata) { _, error in
                    if let error { cont.resume(throwing: error) }
                    else         { cont.resume() }
                }
            }
        } catch {
            if !Self.isAlreadyFinalizedError(error) {
                throw error
            }
            AppLogger.log("[FoodEntryService] putData reported 'already finalized' — treating as success for \(entryID)")
        }

        // Fetch the download URL with one retry after a token refresh.
        // A "permission denied" here usually means the Storage bearer
        // expired mid-upload, not that the rule actually rejects the read.
        do {
            return try await fetchDownloadURL(ref: ref).absoluteString
        } catch {
            let ns = error as NSError
            let isPermission = ns.domain == StorageErrorDomain
                && ns.code == StorageErrorCode.unauthorized.rawValue
            guard isPermission else { throw error }

            AppLogger.log("[FoodEntryService] downloadURL unauthorized — refreshing token and retrying")
            _ = try? await Auth.auth().currentUser?.getIDTokenResult(forcingRefresh: true)
            return try await fetchDownloadURL(ref: ref).absoluteString
        }
    }

    private func fetchDownloadURL(ref: StorageReference) async throws -> URL {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
            ref.downloadURL { url, error in
                if let url   { cont.resume(returning: url) }
                else         { cont.resume(throwing: error ?? URLError(.badServerResponse)) }
            }
        }
    }

    /// Compresses the image to stay under the Storage rule's 2 MB cap.
    /// Steps down JPEG quality first; if even quality 0.20 is too big,
    /// resizes the image and re-encodes at 0.85. Mirrors the helper
    /// used by PostService / UserProfileService / FuelLogService.
    private static func compress(_ image: UIImage, targetBytes: Int = 600_000) -> Data? {
        let steps: [CGFloat] = [0.85, 0.75, 0.65, 0.55, 0.45, 0.35, 0.20]
        for q in steps {
            if let data = image.jpegData(compressionQuality: q), data.count <= targetBytes { return data }
        }
        guard let oversized = image.jpegData(compressionQuality: 0.20) else { return nil }
        let ratio   = sqrt(Double(targetBytes) / Double(oversized.count))
        let newSize = CGSize(width: (image.size.width * ratio).rounded(),
                             height: (image.size.height * ratio).rounded())
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized  = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: 0.85)
    }

    /// Detects the "Upload has already been finalized" HTTP 400 that
    /// GTMSessionFetcher surfaces when a resumable upload is retried
    /// after the object has already been committed server-side. The
    /// object exists — the retry is just noise.
    private static func isAlreadyFinalizedError(_ error: Error) -> Bool {
        let ns = error as NSError
        if ns.domain == "com.google.HTTPStatus" && ns.code == 400 {
            if let data = ns.userInfo["data"] as? Data,
               let body = String(data: data, encoding: .utf8),
               body.lowercased().contains("already been finalized") {
                return true
            }
        }
        // Firebase Storage sometimes wraps the same condition in
        // StorageErrorCode.objectNotFound or .unknown with the body
        // text in localizedDescription.
        if ns.localizedDescription.lowercased().contains("already been finalized") {
            return true
        }
        return false
    }
}
