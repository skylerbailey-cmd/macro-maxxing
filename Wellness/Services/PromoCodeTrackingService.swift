//
//  PromoCodeTrackingService.swift
//  Wellness
//
//  Records affiliate promo-code redemptions in Firestore so we can attribute
//  subscribers back to the affiliate / campaign that brought them in, and
//  records every successful AI-subscription purchase so the App Store Server
//  Notifications webhook can resolve events back to a Firebase UID.
//
//  Firestore layout:
//    promoRedemptions/{autoID}
//      userID, productID, offerID, transactionID, originalTransactionID,
//      originalPurchaseDate, code?, redeemedAt, periodsPaid
//
//    users/{uid}.subscription
//      productID, originalTransactionID, appAccountToken, offerID?,
//      originalPurchaseDate, lastPurchaseDate, lastUpdatedAt
//
//    users/{uid}.activePromoOffer    (convenience mirror, affiliate only)
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class PromoCodeTrackingService {

    static let shared = PromoCodeTrackingService()
    private init() {}

    private var db: Firestore { FirebaseManager.shared.db }

    // MARK: - Promo redemptions

    func recordRedemption(productID: String,
                          offerID: String,
                          transactionID: String,
                          originalTransactionID: String,
                          originalPurchaseDate: Date,
                          code: String?) async {
        let uid = Auth.auth().currentUser?.uid
        var data: [String: Any] = [
            "productID":             productID,
            "offerID":               offerID,
            "transactionID":         transactionID,
            "originalTransactionID": originalTransactionID,
            "originalPurchaseDate":  Timestamp(date: originalPurchaseDate),
            "redeemedAt":            Timestamp(date: Date()),
            "periodsPaid":           1
        ]
        if let uid { data["userID"] = uid }
        if let code, !code.isEmpty { data["code"] = code }

        do {
            _ = try await db.collection("promoRedemptions").addDocument(data: data)

            if let uid {
                try await db.collection("users").document(uid).setData([
                    "activePromoOffer":   offerID,
                    "activePromoProduct": productID,
                    "activePromoCode":    code ?? NSNull(),
                    "activePromoAt":      Timestamp(date: Date())
                ], merge: true)
            }
            AppLogger.log("[PromoCodeTracking] Recorded redemption offer=\(offerID) tx=\(transactionID)")
        } catch {
            AppLogger.log("[PromoCodeTracking] Failed to record redemption: \(error)")
        }
    }

    // MARK: - Subscription mapping
    //
    // Called on EVERY successful AI subscription transaction (affiliate or
    // not). Writes a denormalised summary onto the user doc so the App Store
    // Server Notifications webhook can find the user from an incoming
    // originalTransactionID without scanning other collections.

    func recordSubscriptionStart(productID: String,
                                 transactionID: String,
                                 originalTransactionID: String,
                                 appAccountToken: String?,
                                 offerID: String?,
                                 purchaseDate: Date,
                                 originalPurchaseDate: Date) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var subscription: [String: Any] = [
            "productID":             productID,
            "originalTransactionID": originalTransactionID,
            "lastTransactionID":     transactionID,
            "offerID":               offerID ?? NSNull(),
            "originalPurchaseDate":  Timestamp(date: originalPurchaseDate),
            "lastPurchaseDate":      Timestamp(date: purchaseDate),
            "lastUpdatedAt":         Timestamp(date: Date()),
            "status":                "active"
        ]
        if let token = appAccountToken {
            subscription["appAccountToken"] = token
        }
        do {
            try await db.collection("users").document(uid).setData(
                ["subscription": subscription],
                merge: true
            )
            AppLogger.log("[PromoCodeTracking] Recorded subscription start tx=\(transactionID) orig=\(originalTransactionID)")
        } catch {
            AppLogger.log("[PromoCodeTracking] Failed to record subscription start: \(error)")
        }
    }

    // MARK: - Pending code stash
    //
    // Apple's redemption sheet doesn't echo the raw code back on the resulting
    // transaction, so we stash what the user typed before presenting the
    // sheet and pair it with the transaction once it arrives.

    private var pendingCode: String?

    func stashPendingCode(_ code: String?) {
        pendingCode = code?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    func consumePendingCode() -> String? {
        let code = pendingCode
        pendingCode = nil
        return code
    }
}
