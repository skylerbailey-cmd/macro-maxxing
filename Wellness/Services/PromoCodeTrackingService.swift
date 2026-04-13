//
//  PromoCodeTrackingService.swift
//  Wellness
//
//  Records affiliate promo-code redemptions in Firestore so we can attribute
//  subscribers back to the affiliate / campaign that brought them in.
//
//  Why Firestore: the redemption happens client-side (Apple owns the
//  offer-code redemption sheet) and we already have every user's Firebase UID
//  via SessionManager. Writing a single document per redemption keeps the data
//  simple to query for commission reports without standing up a new backend.
//
//  Firestore layout:
//    promoRedemptions/{autoID}
//      userID:          String     — Firebase UID (nil for anonymous)
//      productID:       String     — com.sbailey.Wellness.aiAnnual / aiMonthly
//      offerID:         String     — "affiliate_annual_year1_discount" etc.
//      transactionID:   String     — StoreKit original transaction ID
//      code:            String?    — the actual code entered (best-effort; Apple
//                                   does not always expose the code itself, but
//                                   when it does — via paywall entry — we log it)
//      redeemedAt:      Timestamp
//
//  We also mirror a marker onto the user doc so `users/{uid}.activePromoOffer`
//  is easy to read from other parts of the app (e.g. to suppress upsells or to
//  show "thanks to AFFILIATE" in settings).
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class PromoCodeTrackingService {

    static let shared = PromoCodeTrackingService()
    private init() {}

    private var db: Firestore { FirebaseManager.shared.db }

    /// Writes a new redemption record. Safe to call from any actor.
    func recordRedemption(productID: String,
                          offerID: String,
                          transactionID: String,
                          code: String?) async {
        let uid = Auth.auth().currentUser?.uid
        var data: [String: Any] = [
            "productID":     productID,
            "offerID":       offerID,
            "transactionID": transactionID,
            "redeemedAt":    Timestamp(date: Date())
        ]
        if let uid { data["userID"] = uid }
        if let code, !code.isEmpty { data["code"] = code }

        do {
            _ = try await db.collection("promoRedemptions").addDocument(data: data)

            // Mirror onto user doc so other features can react without scanning.
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

    /// Stores the code the user typed into the in-app field right before we
    /// hand off to Apple's redemption sheet. Apple's transaction callback does
    /// not always echo the raw code back, so we stash it locally and attach it
    /// to the redemption record once the transaction arrives.
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
