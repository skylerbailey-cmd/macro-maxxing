//
//  DataExportService.swift
//  Wellness
//
//  Exports all user data (profile, food logs, posts) as a JSON file
//  for GDPR/CCPA compliance ("right to data portability").
//

import Foundation
import FirebaseFirestore

final class DataExportService {

    static let shared = DataExportService()
    private init() {}

    private var db: Firestore { FirebaseManager.shared.db }

    struct ExportError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    /// Gathers all user data from Firestore and returns a temporary file URL
    /// containing the exported JSON. The caller is responsible for presenting
    /// a share sheet or other mechanism to let the user save it.
    func exportAllData(userID: String) async throws -> URL {
        guard !userID.isEmpty else {
            throw ExportError(message: "No user ID provided.")
        }

        var exportData: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "userID": userID,
        ]

        // 1. Profile
        let profileDoc = try? await db.collection("users").document(userID).getDocument()
        if let profileData = profileDoc?.data() {
            exportData["profile"] = sanitize(profileData)
        }

        // 2. Food entries
        let foodSnapshot = try? await db.collection("users").document(userID)
            .collection("foodEntries")
            .order(by: "loggedAt", descending: true)
            .getDocuments()
        if let docs = foodSnapshot?.documents {
            exportData["foodEntries"] = docs.map { sanitize($0.data()) }
        }

        // 3. Posts
        let postsSnapshot = try? await db.collection("posts")
            .whereField("userID", isEqualTo: userID)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        if let docs = postsSnapshot?.documents {
            exportData["posts"] = docs.map { sanitize($0.data()) }
        }

        // 4. Fuel logs
        let fuelSnapshot = try? await db.collection("users").document(userID)
            .collection("fuelLogs")
            .getDocuments()
        if let docs = fuelSnapshot?.documents {
            exportData["fuelLogs"] = docs.map { sanitize($0.data()) }
        }

        // 5. Workout logs
        let workoutSnapshot = try? await db.collection("users").document(userID)
            .collection("workoutLogs")
            .getDocuments()
        if let docs = workoutSnapshot?.documents {
            exportData["workoutLogs"] = docs.map { sanitize($0.data()) }
        }

        // Serialize to JSON
        let jsonData = try JSONSerialization.data(
            withJSONObject: exportData,
            options: [.prettyPrinted, .sortedKeys]
        )

        // Write to a temporary file
        let fileName = "wellness_data_export_\(userID.prefix(8)).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try jsonData.write(to: tempURL)

        return tempURL
    }

    // MARK: - Private

    /// Converts Firestore Timestamp values to ISO 8601 strings so the
    /// dictionary is JSON-serializable.
    private func sanitize(_ dict: [String: Any]) -> [String: Any] {
        var result = [String: Any]()
        for (key, value) in dict {
            if let ts = value as? Timestamp {
                result[key] = ISO8601DateFormatter().string(from: ts.dateValue())
            } else if let nested = value as? [String: Any] {
                result[key] = sanitize(nested)
            } else if let array = value as? [[String: Any]] {
                result[key] = array.map { sanitize($0) }
            } else {
                result[key] = value
            }
        }
        return result
    }
}
