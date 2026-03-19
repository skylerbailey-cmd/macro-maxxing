//
//  BalanceScoreService.swift
//  Wellness
//
//  Persists daily balance scores to Firestore.
//  Collection path: users/{userID}/balanceScoreHistory/{yyyy-MM-dd}
//

import Foundation
import FirebaseFirestore

final class BalanceScoreService {

    // MARK: - Singleton

    static let shared = BalanceScoreService()
    private init() {}

    // MARK: - Private refs

    private var db: Firestore { FirebaseManager.shared.db }

    private func collection(userID: String) -> CollectionReference {
        db.collection("users").document(userID).collection("balanceScoreHistory")
    }

    private func dateKey(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.calendar   = Calendar.current
        return fmt.string(from: date)
    }

    // MARK: - Write

    /// Saves (overwrites) the balance score for today.
    func saveScore(_ score: Int, userID: String) async throws {
        guard !userID.isEmpty else { return }
        let data: [String: Any] = [
            "score":   score,
            "date":    dateKey(Date()),
            "savedAt": FieldValue.serverTimestamp()
        ]
        try await collection(userID: userID).document(dateKey(Date())).setData(data)
    }

    // MARK: - Read

    /// Returns the stored score for the given date, or nil if none exists.
    func fetchScore(for date: Date, userID: String) async -> Int? {
        guard !userID.isEmpty else { return nil }
        guard let snap = try? await collection(userID: userID).document(dateKey(date)).getDocument(),
              snap.exists,
              let score = snap.data()?["score"] as? Int else { return nil }
        return score
    }

    /// Returns the top-percentile rank for `score` among all users who logged a
    /// balance score today. E.g. returns 8 when the user is in the top 8%.
    /// Uses a Firestore collection group query across all users' balanceScoreHistory.
    func fetchTopPercent(score: Int) async -> Int? {
        let today = dateKey(Date())
        guard let snaps = try? await db
            .collectionGroup("balanceScoreHistory")
            .whereField("date", isEqualTo: today)
            .getDocuments() else { return nil }

        let allScores = snaps.documents.compactMap { $0.data()["score"] as? Int }
        guard !allScores.isEmpty else { return nil }

        // "Top X%" = the fraction of users who scored >= the current score.
        let atOrAbove = allScores.filter { $0 >= score }.count
        let pct       = max(1, Int((Double(atOrAbove) / Double(allScores.count) * 100).rounded()))
        return pct
    }
}
