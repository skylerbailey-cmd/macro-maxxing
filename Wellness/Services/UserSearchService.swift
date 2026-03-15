//
//  UserSearchService.swift
//  Wellness
//
//  Searches the Firestore "users" collection by username prefix, name prefix,
//  or location-based suggestions. Uses Firestore's range-query trick for
//  prefix matching:  field >= query  &&  field < query + "\u{f8ff}"
//

import Foundation
import FirebaseFirestore

final class UserSearchService {

    // MARK: - Singleton

    static let shared = UserSearchService()
    private init() {}

    // MARK: - Private

    private var db: Firestore { FirebaseManager.shared.db }
    private let collection = "users"

    // Unicode sentinel — anything that sorts after all normal characters
    private let sentinel = "\u{f8ff}"

    // MARK: - 1. Search by username prefix (case-insensitive)
    //
    // Usernames are stored lowercase, so converting the query to lowercase
    // gives us true case-insensitive prefix matching.

    func searchByUsername(
        query: String,
        excludingUserID: String,
        limit: Int = 20
    ) async throws -> [UserProfile] {
        let lower = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !lower.isEmpty else { return [] }

        let snapshot = try await db.collection(collection)
            .whereField("username", isGreaterThanOrEqualTo: lower)
            .whereField("username", isLessThan: lower + sentinel)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents
            .compactMap { UserProfile(document: $0) }
            .filter { $0.userID != excludingUserID }
    }

    // MARK: - 2. Search by name prefix (case-insensitive)
    //
    // Names may be mixed-case. We issue two parallel queries — one with the
    // raw lowercased query and one with the first letter capitalised — then
    // merge and deduplicate. This handles the most common casing styles.

    func searchByName(
        query: String,
        excludingUserID: String,
        limit: Int = 20
    ) async throws -> [UserProfile] {
        let lower = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !lower.isEmpty else { return [] }

        let capitalized = lower.prefix(1).uppercased() + lower.dropFirst()

        async let lowerSnap = db.collection(collection)
            .whereField("name", isGreaterThanOrEqualTo: lower)
            .whereField("name", isLessThan: lower + sentinel)
            .limit(to: limit)
            .getDocuments()

        async let capSnap = db.collection(collection)
            .whereField("name", isGreaterThanOrEqualTo: capitalized)
            .whereField("name", isLessThan: capitalized + sentinel)
            .limit(to: limit)
            .getDocuments()

        let (lowerDocs, capDocs) = try await (lowerSnap, capSnap)

        var seen     = Set<String>()
        var profiles = [UserProfile]()

        for doc in lowerDocs.documents + capDocs.documents {
            guard let p = UserProfile(document: doc),
                  p.userID != excludingUserID,
                  seen.insert(p.id).inserted else { continue }
            profiles.append(p)
        }
        return profiles
    }

    // MARK: - 3. Combined search (username + name, merged, username matches first)

    func search(
        query: String,
        excludingUserID: String
    ) async throws -> [UserProfile] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }

        async let byUsername = searchByUsername(query: trimmed, excludingUserID: excludingUserID)
        async let byName     = searchByName(query: trimmed, excludingUserID: excludingUserID)

        let (usernameResults, nameResults) = try await (byUsername, byName)

        var seen   = Set<String>()
        var merged = [UserProfile]()
        for p in usernameResults + nameResults {
            guard seen.insert(p.id).inserted else { continue }
            merged.append(p)
        }
        return merged
    }

    // MARK: - 4. Suggested users based on location
    //
    // Returns up to `limit` users who share the same location string,
    // excluding the current user and anyone already followed.
    // Falls back to fetching recent users when location is blank.

    func fetchSuggestedUsers(
        currentUserID: String,
        location: String,
        followingIDs: Set<String>,
        limit: Int = 10
    ) async throws -> [UserProfile] {
        let excluded = followingIDs.union([currentUserID])

        let snapshot: QuerySnapshot
        if location.trimmingCharacters(in: .whitespaces).isEmpty {
            snapshot = try await db.collection(collection)
                .limit(to: limit + excluded.count + 5)
                .getDocuments()
        } else {
            snapshot = try await db.collection(collection)
                .whereField("location", isEqualTo: location)
                .limit(to: limit + excluded.count + 5)
                .getDocuments()
        }

        return snapshot.documents
            .compactMap { UserProfile(document: $0) }
            .filter { !excluded.contains($0.id) }
            .prefix(limit)
            .map { $0 }
    }
}
