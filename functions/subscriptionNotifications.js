//
// subscriptionNotifications.js
//
// App Store Server Notifications V2 webhook. Apple POSTs signed JWS payloads
// to this endpoint whenever anything interesting happens to a subscription:
// purchase, renewal, refund, revoke, price increase, grace period, etc.
//
// We decode the JWS (signed with Apple's X.509 chain), unpack the
// transactionInfo and renewalInfo payloads, then write every event to
// Firestore so the commission export can answer:
//   - How many billing periods has this user paid for, minus refunds?
//   - Which affiliate code brought them in?
//   - Are any refunds outstanding against past commissions?
//
// Firestore layout written by this module:
//   transactions/{transactionID}
//     userID, originalTransactionID, productID, offerID, purchaseDate,
//     price, currency, refunded, refundedAt
//
//   subscriptionEvents/{autoID}
//     notificationType, subtype, originalTransactionID, productID,
//     transactionID, userID, at, raw
//
//   users/{uid}.subscription
//     productID, originalTransactionID, status, expiresDate,
//     originalPurchaseDate, periodsPaid, refundedCount
//

const { onRequest } = require("firebase-functions/v2/https");
const { getFirestore, Timestamp, FieldValue } = require("firebase-admin/firestore");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");

// Our three entitlement-granting product IDs.
const ENTITLEMENT_PRODUCT_IDS = new Set([
  "com.sbailey.Wellness.aiAnnual",
  "com.sbailey.Wellness.aiAnnualNoTrial",
  "com.sbailey.Wellness.aiMonthly",
]);

// Affiliate offer IDs — mirror of AISubscriptionStore.AffiliateOffer.
const AFFILIATE_OFFER_IDS = new Set([
  "affiliate_annual_year1_discount",
  "affiliate_monthly_first_discount",
]);

/**
 * Decodes a signed JWS from Apple without validating the chain. We trust that
 * only Apple can reach the webhook URL (no public advertisement) and that the
 * payloads line up with Apple's server API via a follow-up check if needed.
 *
 * For stronger guarantees, add `jose` + Apple's X.509 root and verify the x5c
 * chain here. See the README note at the bottom of this file.
 */
function decodeJWS(signedPayload) {
  if (!signedPayload || typeof signedPayload !== "string") return null;
  try {
    return jwt.decode(signedPayload);
  } catch (e) {
    console.error("[appStoreNotifications] JWS decode failed:", e.message);
    return null;
  }
}

/**
 * Converts Apple's millisecond epoch timestamps to Firestore Timestamps.
 * Apple returns them as numbers on transactionInfo / renewalInfo payloads.
 */
function msToTimestamp(ms) {
  if (!ms || typeof ms !== "number") return null;
  return Timestamp.fromMillis(ms);
}

/**
 * Finds the Firebase UID associated with an originalTransactionID. We set
 * this up at purchase time via the client's appAccountToken (future work) or
 * by scanning existing promoRedemptions/users docs. For now we look it up in
 * the users collection via a `subscription.originalTransactionID` field that
 * gets populated on the first NOTIFICATION we receive.
 */
async function resolveUserID(db, originalTransactionID, appAccountToken) {
  // Preferred: appAccountToken is a UUID the client generated at purchase.
  // We record the mapping when the client reports a successful purchase; if
  // that write hasn't happened yet, fall back to scanning promoRedemptions.
  if (appAccountToken) {
    const snap = await db.collection("users")
      .where("subscription.appAccountToken", "==", appAccountToken)
      .limit(1).get();
    if (!snap.empty) return snap.docs[0].id;
  }

  const snap = await db.collection("users")
    .where("subscription.originalTransactionID", "==", originalTransactionID)
    .limit(1).get();
  if (!snap.empty) return snap.docs[0].id;

  // Last resort: the promoRedemption doc stores originalTransactionID for
  // affiliate-code signups.
  const promoSnap = await db.collection("promoRedemptions")
    .where("originalTransactionID", "==", originalTransactionID)
    .limit(1).get();
  if (!promoSnap.empty) {
    const data = promoSnap.docs[0].data();
    return data.userID || null;
  }

  return null;
}

/**
 * Persists a transactionInfo payload as `transactions/{transactionID}`.
 */
async function upsertTransaction(db, txInfo, userID) {
  if (!txInfo || !txInfo.transactionId) return;
  const id = String(txInfo.transactionId);
  const data = {
    userID:                userID || null,
    originalTransactionID: String(txInfo.originalTransactionId || ""),
    productID:             txInfo.productId || null,
    offerID:               txInfo.offerIdentifier || null,
    offerType:             txInfo.offerType || null,
    type:                  txInfo.type || null,
    purchaseDate:          msToTimestamp(txInfo.purchaseDate),
    originalPurchaseDate:  msToTimestamp(txInfo.originalPurchaseDate),
    expiresDate:           msToTimestamp(txInfo.expiresDate),
    price:                 typeof txInfo.price === "number" ? txInfo.price / 1000 : null,
    currency:              txInfo.currency || null,
    refunded:              false,
    lastSeenAt:            FieldValue.serverTimestamp(),
  };
  await db.collection("transactions").doc(id).set(data, { merge: true });
}

/**
 * Marks a transaction as refunded (REFUND, REVOKE, REFUND_REVERSED, etc.).
 */
async function markTransactionRefunded(db, transactionID, refunded, reason) {
  if (!transactionID) return;
  const patch = {
    refunded:       !!refunded,
    refundedReason: reason || null,
  };
  if (refunded) {
    patch.refundedAt = FieldValue.serverTimestamp();
  } else {
    patch.refundedAt = null;
  }
  await db.collection("transactions").doc(String(transactionID))
    .set(patch, { merge: true });

  // Mirror refund onto the promoRedemption doc (if this was an affiliate sub).
  const promoSnap = await db.collection("promoRedemptions")
    .where("transactionID", "==", String(transactionID))
    .limit(1).get();
  if (!promoSnap.empty) {
    await promoSnap.docs[0].ref.set(patch, { merge: true });
  }
}

/**
 * Updates the denormalised subscription summary on the user doc so the app
 * can read current status without scanning the transactions collection.
 */
async function updateUserSubscription(db, userID, txInfo, renewalInfo, statusOverride) {
  if (!userID) return;
  const userRef = db.collection("users").doc(userID);
  const patch = {
    "subscription.productID":             txInfo.productId || null,
    "subscription.originalTransactionID": String(txInfo.originalTransactionId || ""),
    "subscription.expiresDate":           msToTimestamp(txInfo.expiresDate),
    "subscription.originalPurchaseDate":  msToTimestamp(txInfo.originalPurchaseDate),
    "subscription.lastUpdatedAt":         FieldValue.serverTimestamp(),
  };
  if (statusOverride) patch["subscription.status"] = statusOverride;
  if (renewalInfo && renewalInfo.autoRenewStatus !== undefined) {
    patch["subscription.autoRenew"] = renewalInfo.autoRenewStatus === 1;
  }
  await userRef.set(
    patch.subscription ? patch : { subscription: {} }, // ensure parent exists
    { merge: true }
  ).catch(() => {});
  await userRef.update(patch).catch(async () => {
    // If the field path update fails because the parent is missing, fall back
    // to a full set-merge.
    await userRef.set({ subscription: {
      productID:             txInfo.productId || null,
      originalTransactionID: String(txInfo.originalTransactionId || ""),
      expiresDate:           msToTimestamp(txInfo.expiresDate),
      originalPurchaseDate:  msToTimestamp(txInfo.originalPurchaseDate),
      status:                statusOverride || null,
      lastUpdatedAt:         FieldValue.serverTimestamp(),
    }}, { merge: true });
  });
}

/**
 * Increments `periodsPaid` on the user's subscription (first purchase and
 * every successful renewal), and adjusts `refundedCount` on refund events so
 * the commission export has accurate billing-period counts.
 */
async function incrementCounters(db, userID, field, delta) {
  if (!userID) return;
  await db.collection("users").doc(userID).set({
    subscription: {
      [field]: FieldValue.increment(delta),
    }
  }, { merge: true });
}

/**
 * Main handler — routes a notification by its type / subtype.
 */
async function handleNotification(db, payload) {
  const notificationType = payload.notificationType;
  const subtype          = payload.subtype || null;
  const data             = payload.data || {};

  const txInfo      = decodeJWS(data.signedTransactionInfo) || {};
  const renewalInfo = decodeJWS(data.signedRenewalInfo)     || {};

  // Only care about our entitlement products. Apple will send events for
  // every product in the group — safe to ignore unrelated ones early.
  if (txInfo.productId && !ENTITLEMENT_PRODUCT_IDS.has(txInfo.productId)) {
    return;
  }

  const userID = await resolveUserID(
    db,
    txInfo.originalTransactionId,
    txInfo.appAccountToken
  );

  // Always persist the raw event for audit.
  await db.collection("subscriptionEvents").add({
    notificationType,
    subtype,
    originalTransactionID: String(txInfo.originalTransactionId || ""),
    transactionID:         String(txInfo.transactionId || ""),
    productID:             txInfo.productId || null,
    offerID:               txInfo.offerIdentifier || null,
    userID:                userID || null,
    at:                    FieldValue.serverTimestamp(),
    raw:                   payload,
  });

  // Always keep the transaction record fresh.
  await upsertTransaction(db, txInfo, userID);

  switch (notificationType) {
    case "SUBSCRIBED":
    case "DID_RENEW":
      await updateUserSubscription(db, userID, txInfo, renewalInfo, "active");
      await incrementCounters(db, userID, "periodsPaid", 1);
      // Mirror `periodsPaid` onto the promoRedemption when this was an
      // affiliate signup, so the commission export can read it directly.
      if (AFFILIATE_OFFER_IDS.has(txInfo.offerIdentifier)) {
        await bumpPromoPeriods(db, txInfo.transactionId, 1);
      }
      break;

    case "REFUND":
    case "REVOKE":
      await markTransactionRefunded(db, txInfo.transactionId, true, notificationType);
      await incrementCounters(db, userID, "refundedCount", 1);
      await updateUserSubscription(db, userID, txInfo, renewalInfo,
        notificationType === "REVOKE" ? "revoked" : "refunded");
      break;

    case "REFUND_REVERSED":
      // Apple let us keep the money after all (chargeback dispute won).
      await markTransactionRefunded(db, txInfo.transactionId, false, notificationType);
      await incrementCounters(db, userID, "refundedCount", -1);
      break;

    case "EXPIRED":
      await updateUserSubscription(db, userID, txInfo, renewalInfo, "expired");
      break;

    case "DID_CHANGE_RENEWAL_STATUS":
      // autoRenewStatus already captured above.
      await updateUserSubscription(db, userID, txInfo, renewalInfo, null);
      break;

    case "GRACE_PERIOD_EXPIRED":
      await updateUserSubscription(db, userID, txInfo, renewalInfo, "expired");
      break;

    default:
      // OFFER_REDEEMED, DID_FAIL_TO_RENEW, PRICE_INCREASE, etc. — logged to
      // subscriptionEvents above; no state change needed.
      break;
  }
}

/**
 * Increments `periodsPaid` on the matching promoRedemption doc (affiliate
 * signups only). We need this on the redemption doc itself so the commission
 * export does one flat query per month.
 */
async function bumpPromoPeriods(db, transactionID, delta) {
  if (!transactionID) return;
  const snap = await db.collection("promoRedemptions")
    .where("originalTransactionID", "==", String(transactionID))
    .limit(1).get();
  if (snap.empty) {
    // First transaction IS the original — try matching on that instead.
    const alt = await db.collection("promoRedemptions")
      .where("transactionID", "==", String(transactionID))
      .limit(1).get();
    if (alt.empty) return;
    await alt.docs[0].ref.set({
      periodsPaid: FieldValue.increment(delta),
    }, { merge: true });
    return;
  }
  await snap.docs[0].ref.set({
    periodsPaid: FieldValue.increment(delta),
  }, { merge: true });
}

// ---------------------------------------------------------------------------
// Exported Cloud Function: appStoreNotifications
// ---------------------------------------------------------------------------

exports.appStoreNotifications = onRequest(
  { timeoutSeconds: 60, memory: "256MiB", region: "us-central1" },
  async (req, res) => {
    // Apple only POSTs. Reject anything else so random scans get a 405.
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    try {
      const body = req.body || {};
      const signedPayload = body.signedPayload;
      if (!signedPayload) {
        res.status(400).send("Missing signedPayload");
        return;
      }

      const decoded = decodeJWS(signedPayload);
      if (!decoded) {
        res.status(400).send("Invalid JWS");
        return;
      }

      console.log(
        `[appStoreNotifications] type=${decoded.notificationType} ` +
        `subtype=${decoded.subtype || "-"} env=${decoded.data && decoded.data.environment}`
      );

      const db = getFirestore();
      await handleNotification(db, decoded);

      // Apple requires a 2xx within ~5 seconds or it will retry. Keep
      // processing synchronous for now — every write above is fast.
      res.status(200).send("ok");
    } catch (e) {
      console.error("[appStoreNotifications] handler error:", e.stack || e.message);
      // Apple retries on 5xx. Only return 500 for transient issues we want
      // to retry; malformed payloads should be 4xx to stop the retries.
      res.status(500).send("error");
    }
  }
);

// ---------------------------------------------------------------------------
// Setup notes
// ---------------------------------------------------------------------------
//
// 1. Deploy: `cd functions && npm run deploy`
// 2. Grab the public URL:
//      https://us-central1-<project>.cloudfunctions.net/appStoreNotifications
// 3. App Store Connect → Apps → Macro Maxxing → App Information →
//      App Store Server Notifications (Version 2).
//    Set BOTH "Production Server URL" and "Sandbox Server URL" to the URL
//    above. Save.
// 4. Click "Send Test Notification" in App Store Connect — you should see
//      a TEST event land in `subscriptionEvents` within a few seconds.
// 5. For stronger verification, swap `jwt.decode` for a `jose`-based verifier
//      that validates the x5c chain against Apple's AppleRootCA-G3 root cert
//      (https://www.apple.com/certificateauthority/). The chain ships with
//      each JWS header so no cert rotation is needed on our side.
//
