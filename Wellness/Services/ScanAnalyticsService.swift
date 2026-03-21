//
//  ScanAnalyticsService.swift
//  Wellness
//
//  Tracks scan tier distribution in Firestore for cost monitoring.
//

import Foundation
import FirebaseFirestore

final class ScanAnalyticsService {
    static let shared = ScanAnalyticsService()
    private let db = Firestore.firestore()

    private init() {}

    /// Records a completed scan, incrementing the appropriate tier counter.
    func recordScan(userID: String, tier: Int, cacheHit: Bool) {
        guard !userID.isEmpty else { return }

        let docRef = db.collection("users").document(userID).collection("scanStats").document("summary")

        var updates: [String: Any] = [
            "totalScans": FieldValue.increment(Int64(1)),
            "lastScanDate": FieldValue.serverTimestamp()
        ]

        switch tier {
        case 1: updates["tier1Count"] = FieldValue.increment(Int64(1))
        case 2: updates["tier2Count"] = FieldValue.increment(Int64(1))
        case 3: updates["tier3Count"] = FieldValue.increment(Int64(1))
        default: break
        }

        if cacheHit {
            updates["cacheHitCount"] = FieldValue.increment(Int64(1))
        }

        docRef.setData(updates, merge: true)
    }
}
