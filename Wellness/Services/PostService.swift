//
//  PostService.swift
//  Wellness
//
//  Handles all Firestore + Firebase Storage operations for social feed posts.
//  Uses FirebaseManager.shared for all connections.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage

final class PostService {

    // MARK: - Singleton

    static let shared = PostService()
    private init() {}

    // MARK: - Private refs (pulled from shared manager)

    private var db:      Firestore         { FirebaseManager.shared.db }
    private var storage: StorageReference  { FirebaseManager.shared.storage }

    private let collectionName = "posts"
    private let feedPageSize   = 20

    // MARK: - Nested Types

    /// Meal context for a post — drives the auto-generated title.
    enum MealType: String, Codable, CaseIterable {
        case breakfast   = "Breakfast"
        case lunch       = "Lunch"
        case dinner      = "Dinner"
        case snack       = "Snack"
        case preWorkout  = "Pre-Workout"
        case postWorkout = "Post-Workout"
    }

    /// Snapshot of author info at post time, assembled by the caller (ViewModel → UserSettings).
    struct PostAuthor {
        let userID:              String
        let username:            String
        let whoName:             String
        let userProfilePhotoURL: String
        let auraLevel:           Int
        let auraPoints:          Int
        let streak:              Int
        /// Meme badge key matching asset names (e.g. "sigma", "gigachad").
        let memeType:            String
        let isPublic:            Bool
    }

    enum PostServiceError: LocalizedError {
        case imageCompressionFailed
        case missingPostID
        case postNotFound
        case transactionFailed(String)

        var errorDescription: String? {
            switch self {
            case .imageCompressionFailed:     return "Could not compress the photo for upload."
            case .missingPostID:              return "Post is missing a document ID."
            case .postNotFound:               return "The post could not be found."
            case .transactionFailed(let msg): return "Transaction failed: \(msg)"
            }
        }
    }

    // MARK: - 1. Create Post

    /// Uploads `photo` to Storage, writes a post document to Firestore, and returns the saved post.
    ///
    /// Storage path: `posts/{author.userID}/{postID}.jpg`
    /// Firestore collection: `posts`
    func createPost(
        photo:        UIImage,
        author:       PostAuthor,
        foodName:     String,
        mealType:     MealType,
        caption:      String,
        calories:     Int,
        protein:      Double,
        carbs:        Double,
        fat:          Double,
        goalCalories: Int    = 0,
        goalProtein:  Double = 0,
        goalCarbs:    Double = 0,
        goalFat:      Double = 0,
        locationName: String = "",
        latitude:     Double = 0,
        longitude:    Double = 0,
        macroDate:    Date   = Date()
    ) async throws -> FeedPost {

        // -- Compress image
        guard let imageData = compress(photo) else {
            throw PostServiceError.imageCompressionFailed
        }

        // -- Reserve a document ID up-front so Storage and Firestore share the same key
        let postID  = UUID().uuidString
        let docRef  = db.collection(collectionName).document(postID)

        // -- Upload to Firebase Storage
        let imageRef = storage.child("posts/\(author.userID)/\(postID).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        print("[PostService] Uploading photo to \(imageRef.fullPath) (\(imageData.count / 1024) KB)")
        do {
            try await uploadData(imageData, to: imageRef, metadata: metadata)
        } catch {
            print("[PostService] Storage upload FAILED: \(error.localizedDescription)")
            throw error
        }

        let downloadURL: URL
        do {
            downloadURL = try await fetchDownloadURL(for: imageRef)
            print("[PostService] Photo upload succeeded: \(downloadURL)")
        } catch {
            print("[PostService] downloadURL FAILED: \(error.localizedDescription)")
            try? await imageRef.delete()
            throw error
        }

        // -- Build the post model
        var post = FeedPost(
            userID:              author.userID,
            username:            author.username,
            whoName:             author.whoName,
            userProfilePhotoURL: author.userProfilePhotoURL,
            foodPhotoURL:        downloadURL.absoluteString,
            caption:             caption,
            title:               "\(mealType.rawValue): \(foodName)",
            calories:            calories,
            protein:             protein,
            carbs:               carbs,
            fat:                 fat,
            goalCalories:        goalCalories,
            goalProtein:         goalProtein,
            goalCarbs:           goalCarbs,
            goalFat:             goalFat,
            auraLevel:           author.auraLevel,
            auraPoints:          author.auraPoints,
            streak:              author.streak,
            memeType:            author.memeType,
            locationName:        locationName,
            latitude:            latitude,
            longitude:           longitude,
            isPublic:            author.isPublic,
            macroDate:           macroDate
        )

        // -- Write to Firestore (setData preserves the pre-generated document ID)
        do {
            let data = try post.firestoreData()
            try await docRef.setData(data)
        } catch {
            // Rollback the Storage upload so we don't leave orphaned images
            try? await imageRef.delete()
            throw error
        }

        // -- Return post with document ID populated
        post.postID = postID
        return post
    }

    // MARK: - 2. Fetch Feed Posts

    /// Fetches the `limit` most recent public posts across all users, ordered by `createdAt` descending.
    ///
    /// Pass `after` the last `DocumentSnapshot` from a prior call for cursor-based pagination.
    ///
    /// Firestore requires a composite index on: `isPublic (ASC) + createdAt (DESC)`.
    /// Xcode/Firebase Console will surface a direct link to create it on first run.
    func fetchFeedPosts(
        limit: Int = 20,
        after lastDocument: DocumentSnapshot? = nil
    ) async throws -> (posts: [FeedPost], lastDocument: DocumentSnapshot?) {

        var query: Query = db.collection(collectionName)
            .whereField("isPublic", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        if let cursor = lastDocument {
            query = query.start(afterDocument: cursor)
        }

        let snapshot = try await query.getDocuments()
        let posts = snapshot.documents.compactMap { FeedPost(document: $0) }
        return (posts, snapshot.documents.last)
    }

    // MARK: - 3. Fetch User Posts

    /// Fetches all posts for a specific user, newest first.
    /// Includes private posts so a user can always see their own history.
    func fetchUserPosts(userID: String) async throws -> [FeedPost] {
        let snapshot = try await db.collection(collectionName)
            .whereField("userID", isEqualTo: userID)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { FeedPost(document: $0) }
    }

    // MARK: - 4. Delete Post

    /// Deletes the Firestore document and every associated photo from Storage.
    ///
    /// Both upload conventions are covered:
    ///   • `createPost`       →  posts/{userID}/{postID}.jpg          (single photo)
    ///   • `createCustomPost` →  posts/{userID}/{postID}_0.jpg … _3.jpg (up to 4 photos)
    ///
    /// The Firestore delete is attempted first; if it fails the function throws immediately
    /// and no Storage deletes happen. Storage errors are handled per-file: object-not-found
    /// is silently ignored (file already gone / never uploaded), while unexpected errors are
    /// logged but do NOT prevent the other files from being cleaned up.
    func deletePost(_ post: FeedPost) async throws {
        guard let postID = post.postID else {
            throw PostServiceError.missingPostID
        }

        // 1. Remove the Firestore document — this is the authoritative step.
        //    If this fails we throw immediately so the UI is not cleared.
        try await db.collection(collectionName).document(postID).delete()

        // 2. Delete every possible Storage file for this post.
        //    We try all paths because we can't know at delete-time which convention was used.
        let candidates: [StorageReference] = [
            // Single-photo posts (createPost)
            storage.child("posts/\(post.userID)/\(postID).jpg"),
            // Multi-photo posts (createCustomPost) — up to 4 images
            storage.child("posts/\(post.userID)/\(postID)_0.jpg"),
            storage.child("posts/\(post.userID)/\(postID)_1.jpg"),
            storage.child("posts/\(post.userID)/\(postID)_2.jpg"),
            storage.child("posts/\(post.userID)/\(postID)_3.jpg"),
        ]

        for ref in candidates {
            do {
                try await ref.delete()
            } catch {
                let nsErr = error as NSError
                // Object-not-found is expected for paths that were never used — skip silently
                let isNotFound = (nsErr.domain == StorageErrorDomain &&
                                  nsErr.code  == StorageErrorCode.objectNotFound.rawValue)
                if !isNotFound {
                    // Unexpected error: log it but continue cleaning up remaining files
                    print("[PostService] Storage delete warning (\(ref.fullPath)): \(error.localizedDescription)")
                }
            }
        }
    }

    /// Delete a post by its Firestore document ID and author userID.
    /// Used when deleting from the Aura Stream tab (SwiftData `SocialPost`),
    /// where only the pre-generated `firebasePostID` and `authorID` are available.
    func deletePostByID(postID: String, userID: String) async throws {
        // 1. Remove the Firestore document
        try await db.collection(collectionName).document(postID).delete()

        // 2. Delete every possible Storage file for this post
        let candidates: [StorageReference] = [
            storage.child("posts/\(userID)/\(postID).jpg"),
            storage.child("posts/\(userID)/\(postID)_0.jpg"),
            storage.child("posts/\(userID)/\(postID)_1.jpg"),
            storage.child("posts/\(userID)/\(postID)_2.jpg"),
            storage.child("posts/\(userID)/\(postID)_3.jpg"),
        ]

        for ref in candidates {
            do {
                try await ref.delete()
            } catch {
                let nsErr = error as NSError
                let isNotFound = (nsErr.domain == StorageErrorDomain &&
                                  nsErr.code  == StorageErrorCode.objectNotFound.rawValue)
                if !isNotFound {
                    print("[PostService] Storage delete warning (\(ref.fullPath)): \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - 5. Toggle Rep (Like / Unlike)

    /// Atomically toggles the rep (like) state for `currentUserID` on the given post.
    /// - If the user hasn't repped: increments `reps` and adds to `reppedBy`.
    /// - If already repped: decrements `reps` and removes from `reppedBy`.
    ///
    /// Uses a Firestore transaction to prevent race conditions when multiple users
    /// like a post simultaneously.
    func toggleRep(postID: String, currentUserID: String) async throws {
        let docRef = db.collection(collectionName).document(postID)

        _ = try await db.runTransaction { transaction, errorPointer in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(docRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            guard snapshot.exists,
                  let data = snapshot.data() else {
                errorPointer?.pointee = NSError(
                    domain: "PostService",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Post not found"]
                )
                return nil
            }

            let currentReps    = data["reps"] as? Int ?? 0
            let reppedBy       = data["reppedBy"] as? [String] ?? []
            let alreadyRepped  = reppedBy.contains(currentUserID)

            if alreadyRepped {
                transaction.updateData([
                    "reps":     max(0, currentReps - 1),
                    "reppedBy": FieldValue.arrayRemove([currentUserID])
                ], forDocument: docRef)
            } else {
                transaction.updateData([
                    "reps":     currentReps + 1,
                    "reppedBy": FieldValue.arrayUnion([currentUserID])
                ], forDocument: docRef)
            }

            return nil
        }
    }

    // MARK: - 6. Create Custom Post (text + optional photos, no macro data)

    /// Saves a general-purpose post (from NewPostView) to Firestore.
    /// Uploads up to 4 photos to Storage; posts with no photos use an empty foodPhotoURL.
    /// Each image is stored at: posts/{userID}/{postID}_0.jpg, _1.jpg, etc.
    @discardableResult
    public func createCustomPost(
        photos:       [UIImage],
        author:       PostAuthor,
        title:        String,
        caption:      String,
        locationName: String = "",
        latitude:     Double = 0,
        longitude:    Double = 0,
        postID:       String = UUID().uuidString
    ) async throws -> String {
        let postID = postID
        let docRef = db.collection(collectionName).document(postID)

        // Upload photos in order; collect download URLs
        var primaryURL      = ""
        var additionalURLs  = [String]()

        for (idx, image) in photos.prefix(4).enumerated() {
            guard let imageData = compress(image) else {
                print("[PostService] Photo \(idx): compression failed, skipping")
                continue
            }
            let ref      = storage.child("posts/\(author.userID)/\(postID)_\(idx).jpg")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            print("[PostService] Uploading photo \(idx) to \(ref.fullPath) (\(imageData.count / 1024) KB)")
            do {
                try await uploadData(imageData, to: ref, metadata: metadata)
                let url = try await fetchDownloadURL(for: ref)
                print("[PostService] Photo \(idx) upload succeeded: \(url)")
                if idx == 0 { primaryURL = url.absoluteString }
                else         { additionalURLs.append(url.absoluteString) }
            } catch {
                // Non-fatal: log the error and continue. The post will save without this photo.
                // Common cause: Firebase Storage security rules require auth — update rules in
                // Firebase Console → Storage → Rules to allow writes from your app.
                print("[PostService] Photo \(idx) upload FAILED: \(error.localizedDescription)")
            }
        }

        var post = FeedPost(
            userID:              author.userID,
            username:            author.username,
            whoName:             author.whoName,
            userProfilePhotoURL: author.userProfilePhotoURL,
            foodPhotoURL:        primaryURL,
            additionalPhotoURLs: additionalURLs,
            caption:             caption,
            title:               title,
            calories:            0,
            protein:             0,
            carbs:               0,
            fat:                 0,
            auraLevel:           author.auraLevel,
            auraPoints:          author.auraPoints,
            streak:              author.streak,
            memeType:            author.memeType,
            locationName:        locationName,
            latitude:            latitude,
            longitude:           longitude,
            isPublic:            author.isPublic
        )

        let data = try post.firestoreData()
        try await docRef.setData(data)
        post.postID = postID
        return postID
    }

    // MARK: - 7. Real-time new-posts listener

    /// Attaches a Firestore snapshot listener that fires whenever a new public post
    /// is created *after* `since`. Returns the `ListenerRegistration` so the caller
    /// can detach it on `deinit`.
    func addNewPostsListener(
        since date: Date,
        onNew: @escaping ([FeedPost]) -> Void
    ) -> ListenerRegistration {
        db.collection(collectionName)
            .whereField("isPublic",   isEqualTo: true)
            .whereField("createdAt",  isGreaterThan: Timestamp(date: date))
            .order(by: "createdAt",   descending: true)
            .limit(to: 20)
            .addSnapshotListener { snapshot, _ in
                guard let snapshot else { return }
                let added = snapshot.documentChanges
                    .filter { $0.type == .added }
                    .compactMap { FeedPost(document: $0.document) }
                if !added.isEmpty { onNew(added) }
            }
    }

    // MARK: - Helpers

    /// Convenience: fetch a single post by ID.
    func fetchPost(postID: String) async throws -> FeedPost {
        let doc = try await db.collection(collectionName).document(postID).getDocument()
        guard let post = FeedPost(document: doc) else {
            throw PostServiceError.postNotFound
        }
        return post
    }

    /// Increments the `commentsCount` field when a new comment is added.
    /// Call this after successfully writing a comment document.
    func incrementCommentCount(postID: String) async throws {
        try await db.collection(collectionName).document(postID).updateData([
            "commentsCount": FieldValue.increment(Int64(1))
        ])
    }

    /// Decrements the `commentsCount` field when a comment is deleted.
    func decrementCommentCount(postID: String) async throws {
        try await db.collection(collectionName).document(postID).updateData([
            "commentsCount": FieldValue.increment(Int64(-1))
        ])
    }

    /// Uploads `data` to `ref` using the callback API wrapped in a continuation.
    /// More reliable than `putDataAsync` under task cancellation or context switching.
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

    /// Fetches the download URL for `ref` using the callback API wrapped in a continuation.
    private func fetchDownloadURL(for ref: StorageReference) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            ref.downloadURL { url, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: PostServiceError.missingPostID) // unreachable but satisfies compiler
                }
            }
        }
    }

    /// Compresses `image` to JPEG data ≤ `targetBytes` (default 800 KB).
    /// Steps down quality in 0.10 increments; resizes proportionally as a last resort.
    private func compress(_ image: UIImage, targetBytes: Int = 800_000) -> Data? {
        let steps: [CGFloat] = [0.85, 0.75, 0.65, 0.55, 0.45, 0.35, 0.20]
        for q in steps {
            if let data = image.jpegData(compressionQuality: q), data.count <= targetBytes {
                return data
            }
        }
        // Still too large — scale dimensions proportionally
        guard let oversized = image.jpegData(compressionQuality: 0.20) else { return nil }
        let ratio  = sqrt(Double(targetBytes) / Double(oversized.count))
        let newSize = CGSize(
            width:  (image.size.width  * ratio).rounded(),
            height: (image.size.height * ratio).rounded()
        )
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized  = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: 0.85)
    }
}
