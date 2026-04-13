//
// commissionExport.js
//
// Two Cloud Functions for affiliate commission accounting:
//
//   • affiliateCommissionReport (callable, admin-only)
//       Input:  { month: "2026-04", code?: "INFLUENCER25", format?: "json"|"csv" }
//       Output: per-user rows + totals. Pulls from `promoRedemptions` +
//               `transactions` so refunds and the 6-month commission cap are
//               applied accurately.
//
//   • affiliateCommissionCSV (HTTP, admin-only via bearer token)
//       Same report, returned as downloadable text/csv. Convenient for
//       sending to bookkeeping or a spreadsheet without a tool.
//
// Commission policy (matches the deal we modelled):
//   - 15% of revenue collected from the user during the first 6 months of
//     their subscription lifetime.
//   - Refunded transactions are excluded from commissionable revenue.
//   - The 6-month window starts at `originalPurchaseDate`.
//
// Output columns:
//   code, offerID, productID, userID, originalPurchaseDate,
//   periodsPaid, periodsRefunded, eligibleRevenue, refundedRevenue,
//   commission, status
//

const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

// Bearer token guarding the HTTP CSV export. Set via:
//   firebase functions:secrets:set COMMISSION_EXPORT_TOKEN
const COMMISSION_EXPORT_TOKEN = defineSecret("COMMISSION_EXPORT_TOKEN");

// Admin UIDs allowed to call the callable variant. Stored in Firestore as
// `config/admins.uids: [string]` so you can add/remove without redeploying.
async function assertAdmin(db, uid) {
  if (!uid) throw new HttpsError("unauthenticated", "Must be signed in.");
  const doc = await db.collection("config").doc("admins").get();
  const uids = (doc.exists && doc.data().uids) || [];
  if (!uids.includes(uid)) {
    throw new HttpsError("permission-denied", "Admin access required.");
  }
}

const COMMISSION_RATE      = 0.15;
const COMMISSION_WINDOW_MO = 6;

/**
 * Given `YYYY-MM`, return start and end Timestamps covering that calendar
 * month in UTC. Close enough for monthly accounting.
 */
function monthBounds(monthStr) {
  if (!/^\d{4}-\d{2}$/.test(monthStr)) {
    throw new HttpsError("invalid-argument", 'month must be "YYYY-MM"');
  }
  const [y, m] = monthStr.split("-").map(Number);
  const start = new Date(Date.UTC(y, m - 1, 1));
  const end   = new Date(Date.UTC(y, m, 1));
  return { start: Timestamp.fromDate(start), end: Timestamp.fromDate(end) };
}

/**
 * Computes the commission-eligible window for a single affiliate-code
 * subscriber: [originalPurchaseDate, originalPurchaseDate + 6 months).
 */
function eligibilityWindow(originalPurchaseDate) {
  const start = originalPurchaseDate.toDate();
  const end   = new Date(start);
  end.setUTCMonth(end.getUTCMonth() + COMMISSION_WINDOW_MO);
  return {
    start: Timestamp.fromDate(start),
    end:   Timestamp.fromDate(end),
  };
}

/**
 * Builds the per-user commission rows for a given month. A row represents
 * revenue COLLECTED during `month` on a subscription that was opened with an
 * affiliate code — regardless of when the user originally signed up, as long
 * as they are still within their 6-month commission window.
 */
async function buildRows(db, monthStr, codeFilter) {
  const { start: monthStart, end: monthEnd } = monthBounds(monthStr);

  // 1) All affiliate redemptions — small collection, safe to scan.
  let redemptionsQuery = db.collection("promoRedemptions");
  if (codeFilter) {
    redemptionsQuery = redemptionsQuery.where("code", "==", codeFilter);
  }
  const redemptionsSnap = await redemptionsQuery.get();

  const rows = [];

  for (const doc of redemptionsSnap.docs) {
    const r = doc.data();
    const userID                = r.userID;
    const code                  = r.code || null;
    const offerID               = r.offerID;
    const productID             = r.productID;
    const originalTransactionID = r.originalTransactionID || r.transactionID;
    const originalPurchaseDate  = r.originalPurchaseDate || r.redeemedAt;

    if (!userID || !originalTransactionID || !originalPurchaseDate) continue;

    const { start: eligStart, end: eligEnd } = eligibilityWindow(originalPurchaseDate);

    // Skip rows whose eligibility window is entirely outside the month.
    if (eligEnd.toMillis() <= monthStart.toMillis()) continue;
    if (eligStart.toMillis() >= monthEnd.toMillis()) continue;

    // 2) Pull transactions for this subscription within the month AND within
    // the 6-month eligibility window. Firestore can't combine an inequality
    // across two fields, so we fetch the wider range and filter in-memory —
    // a subscription has at most ~12 transactions so this is cheap.
    const txSnap = await db.collection("transactions")
      .where("originalTransactionID", "==", String(originalTransactionID))
      .get();

    let eligibleRevenue  = 0;
    let refundedRevenue  = 0;
    let periodsPaid      = 0;
    let periodsRefunded  = 0;

    for (const txDoc of txSnap.docs) {
      const tx = txDoc.data();
      if (!tx.purchaseDate) continue;
      const purchaseMs = tx.purchaseDate.toMillis();
      if (purchaseMs < eligStart.toMillis() || purchaseMs >= eligEnd.toMillis()) continue;
      if (purchaseMs < monthStart.toMillis() || purchaseMs >= monthEnd.toMillis()) continue;

      const price = Number(tx.price) || 0;
      if (tx.refunded) {
        refundedRevenue += price;
        periodsRefunded += 1;
      } else {
        eligibleRevenue += price;
        periodsPaid     += 1;
      }
    }

    // Also catch REFUNDs that happened in `month` on transactions that were
    // *originally* charged in a previous month — we claw back commission we
    // already paid out by emitting a negative row for them.
    const refundSnap = await db.collection("transactions")
      .where("originalTransactionID", "==", String(originalTransactionID))
      .where("refunded", "==", true)
      .get();

    for (const txDoc of refundSnap.docs) {
      const tx = txDoc.data();
      if (!tx.refundedAt) continue;
      const refundedMs = tx.refundedAt.toMillis();
      if (refundedMs < monthStart.toMillis() || refundedMs >= monthEnd.toMillis()) continue;
      // Only count refunds of transactions whose original purchase was
      // within the 6-month commission window.
      if (!tx.purchaseDate) continue;
      const purchaseMs = tx.purchaseDate.toMillis();
      if (purchaseMs < eligStart.toMillis() || purchaseMs >= eligEnd.toMillis()) continue;
      // Skip if already counted above (refunded in same month it was charged).
      if (purchaseMs >= monthStart.toMillis() && purchaseMs < monthEnd.toMillis()) continue;

      const price = Number(tx.price) || 0;
      refundedRevenue += price;
      periodsRefunded += 1;
    }

    if (eligibleRevenue === 0 && refundedRevenue === 0) continue;

    const netRevenue = eligibleRevenue - refundedRevenue;
    const commission = +(netRevenue * COMMISSION_RATE).toFixed(2);

    rows.push({
      code:                 code || "(no-code)",
      offerID,
      productID,
      userID,
      originalPurchaseDate: originalPurchaseDate.toDate().toISOString(),
      periodsPaid,
      periodsRefunded,
      eligibleRevenue:      +eligibleRevenue.toFixed(2),
      refundedRevenue:      +refundedRevenue.toFixed(2),
      netRevenue:           +netRevenue.toFixed(2),
      commission,
      status:               netRevenue >= 0 ? "owed" : "clawback",
    });
  }

  // Summarise totals per code for convenience.
  const totalsByCode = {};
  for (const r of rows) {
    const k = r.code;
    if (!totalsByCode[k]) {
      totalsByCode[k] = {
        code:            k,
        subscribers:     0,
        eligibleRevenue: 0,
        refundedRevenue: 0,
        netRevenue:      0,
        commission:      0,
      };
    }
    totalsByCode[k].subscribers     += 1;
    totalsByCode[k].eligibleRevenue += r.eligibleRevenue;
    totalsByCode[k].refundedRevenue += r.refundedRevenue;
    totalsByCode[k].netRevenue      += r.netRevenue;
    totalsByCode[k].commission      += r.commission;
  }
  for (const k of Object.keys(totalsByCode)) {
    const t = totalsByCode[k];
    t.eligibleRevenue = +t.eligibleRevenue.toFixed(2);
    t.refundedRevenue = +t.refundedRevenue.toFixed(2);
    t.netRevenue      = +t.netRevenue.toFixed(2);
    t.commission      = +t.commission.toFixed(2);
  }

  return {
    month:   monthStr,
    rows,
    totals:  Object.values(totalsByCode),
  };
}

function rowsToCSV(report) {
  const header = [
    "code", "offerID", "productID", "userID", "originalPurchaseDate",
    "periodsPaid", "periodsRefunded", "eligibleRevenue", "refundedRevenue",
    "netRevenue", "commission", "status",
  ];
  const lines = [header.join(",")];
  for (const r of report.rows) {
    lines.push(header.map(h => {
      const v = r[h] === undefined || r[h] === null ? "" : String(r[h]);
      return v.includes(",") ? `"${v.replace(/"/g, '""')}"` : v;
    }).join(","));
  }
  lines.push("");
  lines.push("# Totals by code");
  lines.push("code,subscribers,eligibleRevenue,refundedRevenue,netRevenue,commission");
  for (const t of report.totals) {
    lines.push([t.code, t.subscribers, t.eligibleRevenue, t.refundedRevenue, t.netRevenue, t.commission].join(","));
  }
  return lines.join("\n");
}

// ---------------------------------------------------------------------------
// Callable: affiliateCommissionReport
// ---------------------------------------------------------------------------

exports.affiliateCommissionReport = onCall(
  { timeoutSeconds: 120, memory: "512MiB" },
  async (request) => {
    const db = getFirestore();
    await assertAdmin(db, request.auth && request.auth.uid);

    const { month, code, format } = request.data || {};
    if (!month) throw new HttpsError("invalid-argument", "month is required");

    const report = await buildRows(db, month, code || null);
    if (format === "csv") {
      return { csv: rowsToCSV(report) };
    }
    return report;
  }
);

// ---------------------------------------------------------------------------
// HTTP: affiliateCommissionCSV
// ---------------------------------------------------------------------------
//
// Auth: pass header `Authorization: Bearer <COMMISSION_EXPORT_TOKEN>`.
// Query: ?month=2026-04 [&code=INFLUENCER25]
//
// Example:
//   curl -H "Authorization: Bearer $TOKEN" \
//        "https://<region>-<project>.cloudfunctions.net/affiliateCommissionCSV?month=2026-04" \
//        -o commissions-2026-04.csv
//

exports.affiliateCommissionCSV = onRequest(
  { secrets: [COMMISSION_EXPORT_TOKEN], timeoutSeconds: 120, memory: "512MiB" },
  async (req, res) => {
    if (req.method !== "GET") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const auth = req.headers.authorization || "";
    const expected = `Bearer ${COMMISSION_EXPORT_TOKEN.value()}`;
    if (auth !== expected) {
      res.status(401).send("Unauthorized");
      return;
    }

    const month = (req.query.month || "").toString();
    const code  = (req.query.code  || "").toString() || null;

    if (!/^\d{4}-\d{2}$/.test(month)) {
      res.status(400).send('month query param is required (YYYY-MM)');
      return;
    }

    try {
      const db = getFirestore();
      const report = await buildRows(db, month, code);
      const csv = rowsToCSV(report);

      res.setHeader("Content-Type", "text/csv; charset=utf-8");
      res.setHeader("Content-Disposition",
        `attachment; filename="commissions-${month}${code ? `-${code}` : ""}.csv"`);
      res.status(200).send(csv);
    } catch (e) {
      console.error("[affiliateCommissionCSV] error:", e.stack || e.message);
      res.status(500).send(`error: ${e.message}`);
    }
  }
);
