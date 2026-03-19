//
//  FeedViewModel.swift
//  Wellness
//

import Foundation
import FirebaseFirestore

@Observable @MainActor final class FeedViewModel {

    // MARK: - Published state

    var posts:        [FeedPost] = []
    var isLoading:    Bool       = true    // true from the start → skeleton renders immediately
    var isRefreshing: Bool       = false
    var errorMessage: String?    = nil
    var hasMore:      Bool       = true

    // MARK: - Pagination cursor

    private var lastDocument:        DocumentSnapshot? = nil
    private let pageSize                               = 20
    private var isInitialLoadStarted                   = false   // prevents duplicate initial loads

    // MARK: - Initial load

    func loadInitialFeed() async {
        guard !isInitialLoadStarted else { return }
        isInitialLoadStarted = true
        isLoading    = true
        errorMessage = nil

        do {
            let (newPosts, cursor) = try await PostService.shared.fetchFeedPosts(limit: pageSize)
            posts        = newPosts
            lastDocument = cursor
            hasMore      = newPosts.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Pull-to-refresh

    func refresh() async {
        isRefreshing = true
        errorMessage = nil
        isInitialLoadStarted = false  // allow re-fetch

        do {
            let (newPosts, cursor) = try await PostService.shared.fetchFeedPosts(limit: pageSize)
            posts        = newPosts
            lastDocument = cursor
            hasMore      = newPosts.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }

        isRefreshing = false
    }

    // MARK: - Pagination

    func loadMoreIfNeeded(currentPost: FeedPost) async {
        guard hasMore,
              !isLoading,
              posts.last?.id == currentPost.id else { return }

        isLoading = true

        do {
            let (newPosts, cursor) = try await PostService.shared.fetchFeedPosts(
                limit: pageSize,
                after: lastDocument
            )
            posts        += newPosts
            lastDocument  = cursor
            hasMore       = newPosts.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Toggle rep (optimistic)

    func toggleRep(postID: String, currentUserID: String) async {
        guard let idx = posts.firstIndex(where: { $0.id == postID }) else { return }

        let original = posts[idx]
        var updated  = posts[idx]
        if updated.hasRepped(userID: currentUserID) {
            updated.reps     = max(0, updated.reps - 1)
            updated.reppedBy.removeAll { $0 == currentUserID }
        } else {
            updated.reps    += 1
            updated.reppedBy.append(currentUserID)
        }
        posts[idx] = updated

        do {
            try await PostService.shared.toggleRep(postID: postID, currentUserID: currentUserID)
        } catch {
            if let revertIdx = posts.firstIndex(where: { $0.id == postID }) {
                posts[revertIdx] = original
            }
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete (own posts)

    func deletePost(_ post: FeedPost) async {
        do {
            try await PostService.shared.deletePost(post)
            posts.removeAll { $0.id == post.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
