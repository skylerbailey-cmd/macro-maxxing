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
    /// The caller passes already-compressed JPEG bytes so the raw UIImage doesn't
    /// get re-encoded here on every retry — re-encoding a 12 MP photo repeatedly
    /// was inflating memory enough for the OS to kill the process. Use
    /// `FoodEntryService.compress(image:)` to produce the bytes once at capture
    /// time and pass the same `Data` to the model entry AND this method.
    ///
    /// Throws if photo bytes are provided and the upload fails — the Firestore write is
    /// skipped so the caller can retry instead of leaving a meal stranded without a
    /// photoURL in the database.
    @discardableResult
    func save(entry: FoodEntry, imageData: Data?, existingPhotoURL: String = "") async throws -> (docID: String, photoURL: String) {
        guard !entry.userID.isEmpty else { return ("", "") }

        let entryID = entry.firebaseEntryID.isEmpty ? entry.id.uuidString : entry.firebaseEntryID

        // Upload photo first so the URL can be included in the Firestore write.
        // If no new image but an existing URL is provided (e.g. from a saved meal), use that.
        // If photo bytes ARE provided, we require the upload to succeed — silently swallowing
        // upload errors used to leave entries in Firestore with an empty photoURL, which
        // is unrecoverable once the in-memory imageData is dropped on the next refetch.
        var photoURL = existingPhotoURL
        if let imageData {
            photoURL = try await uploadPhoto(data: imageData, userID: entry.userID, entryID: entryID)
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

    private func uploadPhoto(data: Data, userID: String, entryID: String) async throws -> String {
        // `data` must already be under the 2 MB Storage rule limit —
        // `FoodEntryService.compress(image:)` is the canonical way to
        // produce it. We avoid re-encoding here so repeated flush
        // retries don't inflate the bitmap into memory again and again.

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
    /// used by PostService and UserProfileService.
    ///
    /// Exposed as static so callers can compress ONCE at capture time
    /// and pass the same bytes to both the SwiftData entry and `save`.
    /// Repeatedly encoding a 12 MP UIImage caused the app to be killed
    /// for excessive memory use.
    static func compress(image: UIImage, targetBytes: Int = 600_000) -> Data? {
        compress(image, targetBytes: targetBytes)
    }

    private static func compress(_ image: UIImage, targetBytes: Int = 600_000) -> Data? {
        // Downscale FIRST so we never iterate JPEG quality on a
        // full-resolution bitmap. A 12 MP camera UIImage is ~48 MB
        // decoded; encoding it 7 times in sequence was driving the
        // app over iOS's memory limit and getting it OS-killed.
        // After downscaling to 1600 px longest edge the decoded
        // bitmap is ~8 MB, and each quality pass is cheap.
        let source = Self.downscale(image, maxEdge: 1600)

        return autoreleasepool { () -> Data? in
            let steps: [CGFloat] = [0.85, 0.75, 0.65, 0.55, 0.45, 0.35, 0.20]
            for q in steps {
                if let data = source.jpegData(compressionQuality: q),
                   data.count <= targetBytes {
                    return data
                }
            }
            // Still too big at q=0.20 — resize further and re-encode once.
            guard let oversized = source.jpegData(compressionQuality: 0.20) else { return nil }
            let ratio   = sqrt(Double(targetBytes) / Double(oversized.count))
            let newSize = CGSize(width: (source.size.width * ratio).rounded(),
                                 height: (source.size.height * ratio).rounded())
            let format = UIGraphicsImageRendererFormat.default()
            // scale = 1 gives a true 1:1 pixel-to-point bitmap; the
            // default device scale (3 on most iPhones) would triple
            // the bitmap size for no visible benefit.
            format.scale = 1
            let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
            let resized  = renderer.image { _ in source.draw(in: CGRect(origin: .zero, size: newSize)) }
            return resized.jpegData(compressionQuality: 0.85)
        }
    }

    /// Downscales a UIImage so its longest edge is at most `maxEdge` in
    /// pixels (accounting for UIImage.scale). Returns the original image
    /// if it's already small enough. Always renders at scale = 1 so the
    /// output bitmap's memory footprint matches its point dimensions.
    private static func downscale(_ image: UIImage, maxEdge: CGFloat) -> UIImage {
        // image.size is in points; the actual pixel dimensions are
        // size * image.scale. Compare in pixels so a scale-3 UIImage
        // from the photo library isn't left at ~3x the intended size.
        let pxW = image.size.width  * image.scale
        let pxH = image.size.height * image.scale
        let longestPx = max(pxW, pxH)
        guard longestPx > maxEdge else { return image }

        let ratio = maxEdge / longestPx
        let newSize = CGSize(width: (pxW * ratio).rounded(),
                             height: (pxH * ratio).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return autoreleasepool {
            renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        }
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

    // MARK: - Meal Plans (Firestore)

    private func encodeDays(_ days: [PlanDay]) -> [[String: Any]] {
        days.map { ["id": $0.id, "label": $0.label, "itemIDs": $0.itemIDs] }
    }

    private func decodeDays(_ raw: [[String: Any]]) -> [PlanDay] {
        raw.compactMap { d in
            guard let id    = d["id"]    as? String,
                  let label = d["label"] as? String else { return nil }
            let ids = d["itemIDs"] as? [String] ?? []
            return PlanDay(id: id, label: label, itemIDs: ids)
        }
    }

    func fetchMealPlans(userID: String) async -> [MealPlan] {
        guard !userID.isEmpty else { return [] }
        do {
            let snapshot = try await db.collection("users").document(userID)
                .collection("mealPlans")
                .order(by: "createdAt", descending: false)
                .getDocuments()
            return snapshot.documents.compactMap { doc in
                let d = doc.data()
                guard let name = d["name"] as? String else { return nil }
                let createdAt = (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()

                var days: [PlanDay]
                if let rawDays = d["days"] as? [[String: Any]] {
                    days = decodeDays(rawDays)
                } else if let flat = d["mealIDs"] as? [String], !flat.isEmpty {
                    days = [PlanDay(label: "Day 1", itemIDs: flat)]
                } else {
                    days = []
                }

                return MealPlan(id: doc.documentID, name: name,
                                days: days, createdAt: createdAt)
            }
        } catch {
            AppLogger.log("[FoodEntryService] Failed to fetch meal plans: \(error.localizedDescription)")
            return []
        }
    }

    func addMealPlan(_ plan: MealPlan, userID: String) {
        guard !userID.isEmpty else { return }
        let data: [String: Any] = [
            "name":      plan.name,
            "days":      encodeDays(plan.days),
            "createdAt": Timestamp(date: plan.createdAt)
        ]
        db.collection("users").document(userID)
            .collection("mealPlans").document(plan.id)
            .setData(data)
    }

    func updateMealPlan(_ plan: MealPlan, userID: String) {
        guard !userID.isEmpty else { return }
        let data: [String: Any] = [
            "name": plan.name,
            "days": encodeDays(plan.days),
        ]
        db.collection("users").document(userID)
            .collection("mealPlans").document(plan.id)
            .updateData(data)
    }

    func deleteMealPlan(id: String, userID: String) {
        guard !userID.isEmpty, !id.isEmpty else { return }
        db.collection("users").document(userID)
            .collection("mealPlans").document(id)
            .delete()
    }
}
