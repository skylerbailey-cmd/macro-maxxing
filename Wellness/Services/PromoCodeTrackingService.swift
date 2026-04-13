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

    // MARK: - Validation
    //
    // Codes you hand to affiliates are stored in Firestore under
    // `promoCodes/{CODE}` (document ID is the uppercased code string). The
    // app reads this collection directly when the user taps "Apply" so we
    // can give instant in-app feedback before sending them to Apple's
    // redemption sheet.
    //
    // Document shape — see PROMO_CODES_README at the bottom of this file:
    //   active           Bool      — false to disable a code without deleting
    //   offerID          String    — must match an AffiliateOffer raw value
    //   productID        String    — com.sbailey.Wellness.aiAnnual / aiMonthly
    //   affiliate        String?   — human-readable label for reporting
    //   expiresAt        Timestamp?— optional cut-off
    //   maxRedemptions   Int?      — optional cap; we read but don't enforce
    //                                client-side (Apple is the authority)
    //
    // The webhook also writes `redemptionCount` here on successful redemptions,
    // so this collection is your single source of truth for "how many times
    // has each code been used".

    enum PromoValidationResult {
        case valid(productID: String, offerID: String)
        case unknown      // Code not found in Firestore
        case inactive     // Manually disabled
        case expired      // Past its expiresAt
        case error(Error) // Firestore call failed
    }

    func validatePromoCode(_ rawCode: String) async -> PromoValidationResult {
        let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else { return .unknown }
        do {
            let snap = try await db.collection("promoCodes").document(code).getDocument()
            guard snap.exists, let data = snap.data() else { return .unknown }

            if let active = data["active"] as? Bool, active == false {
                return .inactive
            }
            if let expiresAt = data["expiresAt"] as? Timestamp,
               expiresAt.dateValue() <= Date() {
                return .expired
            }

            let offerID   = data["offerID"]   as? String ?? ""
            let productID = data["productID"] as? String ?? ""
            guard !offerID.isEmpty, !productID.isEmpty else { return .unknown }

            return .valid(productID: productID, offerID: offerID)
        } catch {
            AppLogger.log("[PromoCodeTracking] Validation failed: \(error)")
            return .error(error)
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

// MARK: - PROMO_CODES_README
//
// Setting up a new affiliate code in production:
//
// 1. App Store Connect → AI Annual (or AI Monthly) → Subscription Offers →
//    Create Codes. Generate the actual redeemable string (e.g. INFLUENCER25).
//
// 2. Firebase Console → Firestore → `promoCodes` collection → Add document:
//      Document ID:     INFLUENCER25         (uppercase, no spaces)
//      Fields:
//        active         (bool)    true
//        offerID        (string)  affiliate_annual_year1_discount
//        productID      (string)  com.sbailey.Wellness.aiAnnual
//        affiliate      (string)  "Jane Smith"        (optional, for reports)
//        expiresAt      (timestamp) 2027-01-01           (optional)
//        maxRedemptions (number)  1000                  (optional)
//
// 3. Hand the code to the affiliate. The app validates against this doc the
//    moment a user taps Apply, and the Firestore promoRedemptions collection
//    captures every successful redemption with the code attached.
//
// To disable a code without deleting it, flip `active` to false. To cap a
// campaign, fill in `expiresAt`. To rebrand a code, just create a new doc —
// the AffiliateOffer enum in AISubscriptionStore.swift only needs to change
// when you add a NEW underlying App Store Connect offer.
//
// Firestore security rule (add to firestore.rules):
//   match /promoCodes/{code} {
//     allow read:  if request.auth != null;     // any signed-in user can validate
//     allow write: if false;                    // admin-only via console
//   }

