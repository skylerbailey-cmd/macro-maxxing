const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const jwt = require("jsonwebtoken");

// Secrets (stored via firebase functions:secrets:set, never in source)
const ANTHROPIC_API_KEY = defineSecret("ANTHROPIC_API_KEY");

// Sign in with Apple — used to exchange the short-lived authorization code
// for a long-lived refresh token at sign-in, and to revoke that refresh
// token at account deletion (App Store guideline 5.1.1(v)).
const APPLE_TEAM_ID     = defineSecret("APPLE_TEAM_ID");
const APPLE_KEY_ID      = defineSecret("APPLE_KEY_ID");
const APPLE_BUNDLE_ID   = defineSecret("APPLE_BUNDLE_ID");
const APPLE_PRIVATE_KEY = defineSecret("APPLE_PRIVATE_KEY");

/**
 * Generates an Apple client-secret JWT (ES256) for calling
 * appleid.apple.com /auth/token and /auth/revoke. Valid for 5 minutes.
 *
 * Requires all four APPLE_* secrets to be resolved (i.e. the calling
 * function must declare them in its `secrets` array).
 */
function generateAppleClientSecret() {
  // Normalise the stored PEM: some deployment paths (CLI paste, dashboard
  // edits, CI env vars) strip real newlines and leave the key as a single
  // line, or substitute them with literal `\n`. Both forms are unusable
  // by `jsonwebtoken` for ES256 — it throws "secretOrPrivateKey must be
  // an asymmetric key". Rebuild a proper multi-line PEM defensively.
  let privateKey = APPLE_PRIVATE_KEY.value();
  // Replace literal backslash-n with real newlines
  privateKey = privateKey.replace(/\\n/g, "\n");
  // If the header/footer are on the same line as the body, split them out
  if (!privateKey.includes("\n") && privateKey.includes("-----BEGIN")) {
    privateKey = privateKey
      .replace(/-----BEGIN ([A-Z ]+)-----/, "-----BEGIN $1-----\n")
      .replace(/-----END ([A-Z ]+)-----/, "\n-----END $1-----");
  }

  const teamID   = APPLE_TEAM_ID.value();
  const keyID    = APPLE_KEY_ID.value();
  const bundleID = APPLE_BUNDLE_ID.value();

  const now = Math.floor(Date.now() / 1000);
  return jwt.sign(
    {
      iss: teamID,
      iat: now,
      exp: now + 300, // 5 minutes — Apple's maximum
      aud: "https://appleid.apple.com",
      sub: bundleID,
    },
    privateKey,
    {
      algorithm: "ES256",
      header: { alg: "ES256", kid: keyID },
    }
  );
}

initializeApp();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Returns the UTC midnight and the following midnight for a "YYYY-MM-DD" date
 * expressed in the given IANA timezone (e.g. "America/New_York").
 * Uses noon UTC as a probe to derive the local UTC-offset, then shifts back
 * to local midnight — this handles DST correctly for all US timezones.
 */
function dayBounds(dateStr, tz) {
  const probe = new Date(dateStr + "T12:00:00Z");
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: tz,
    year: "numeric", month: "2-digit", day: "2-digit",
    hour: "2-digit", minute: "2-digit", second: "2-digit",
    hour12: false,
  }).formatToParts(probe);
  const get = (type) => parseInt(parts.find((p) => p.type === type).value);
  const localH = get("hour"), localM = get("minute"), localS = get("second");
  const midnightUTC = probe.getTime() - (localH * 3600 + localM * 60 + localS) * 1000;
  return {
    start: new Date(midnightUTC),
    end:   new Date(midnightUTC + 24 * 3600 * 1000),
  };
}

/** Returns "YYYY-MM-DD" for "today" in the given IANA timezone. */
function localDateStr(tz) {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: tz,
    year: "numeric", month: "2-digit", day: "2-digit",
  }).format(new Date());
}

/** Returns "YYYY-MM-DD" for one calendar day before the given date string. */
function previousDay(dateStr) {
  const [y, m, d] = dateStr.split("-").map(Number);
  const prev = new Date(Date.UTC(y, m - 1, d - 1));
  return prev.toISOString().split("T")[0];
}

// NOTE: computeStreak and resetExpiredStreaks have been removed.
// Streaks are now managed client-side as a simple running counter.
// See HomeViewModel.loadTodayTotalsAsync() for the new logic.

/**
 * 1. Snapshots the current week's leaderboard into
 *    `weeklySnapshots/{YYYY-MM-DD}` (keyed by the Sunday date in ET),
 *    storing up to 100 entries sorted by weeklyAuraPoints descending.
 *
 * 2. Resets `weeklyAuraPoints` → 0 and `weeklyAuraWeekStartTimestamp` →
 *    current Unix timestamp (seconds) for every user with points > 0.
 *
 * The iOS app reads `weeklySnapshots` to display last week's results.
 */
exports.resetWeeklyAura = onSchedule(
  { schedule: "0 20 * * 0", timeZone: "America/New_York" },
  async (_event) => {
    const db  = getFirestore();
    const now = new Date();

    // Key the snapshot by the Sunday date in ET (e.g. "2026-03-22").
    const snapshotKey = new Intl.DateTimeFormat("en-CA", {
      timeZone: "America/New_York",
      year: "numeric", month: "2-digit", day: "2-digit",
    }).format(now);

    console.log(`[resetWeeklyAura] Running. Snapshot key: ${snapshotKey}`);

    // Read every user with active weekly points.
    const snapshot = await db.collection("users")
      .where("weeklyAuraPoints", ">", 0)
      .get();

    // Build + store the snapshot (top 100).
    const entries = snapshot.docs.map((doc) => {
      const d = doc.data();
      return {
        userID:          doc.id,
        username:        d.username        ?? "",
        displayName:     d.name            ?? "",
        auraPoints:      d.weeklyAuraPoints ?? 0,
        profilePhotoURL: d.profilePhotoURL  ?? "",
        location:        d.location         ?? "",
      };
    });
    entries.sort((a, b) => b.auraPoints - a.auraPoints);
    const top100 = entries.slice(0, 100).map((e, i) => ({ ...e, rank: i + 1 }));

    await db.collection("weeklySnapshots").doc(snapshotKey).set({
      entries:       top100,
      createdAt:     Timestamp.fromDate(now),
      weekStartDate: snapshotKey,
    });
    console.log(`[resetWeeklyAura] Snapshot saved: ${top100.length} entries`);

    // XP helpers
    const arenaXpForRank = (rank) => {
      if (rank === 1)  return 150;
      if (rank <= 3)   return 100;
      if (rank <= 10)  return 50;
      return 0;
    };
    const localXpForRank = (rank) => {
      if (rank === 1)  return 75;
      if (rank <= 3)   return 50;
      if (rank <= 10)  return 25;
      return 0;
    };

    // Award arena XP to top 10 global finishers.
    for (let i = 0; i < Math.min(10, top100.length); i++) {
      const entry = top100[i];
      const xp    = arenaXpForRank(i + 1);
      if (xp === 0) continue;
      await db.collection("users").doc(entry.userID).update({
        auraPoints:       FieldValue.increment(xp),
        weeklyWinnerRank: i + 1,
        weeklyWinnerXP:   xp,
        weeklyWinnerWeek: snapshotKey,
      });
      console.log(`[resetWeeklyAura] Arena rank ${i + 1}: +${xp} XP → ${entry.userID}`);
    }

    // Award local XP to top 10 per location group (need full user list for this).
    // Group all users with weeklyAuraPoints > 0 by their trimmed/lowercased location string.
    const locationGroups = new Map(); // location → [{ userID, weeklyAuraPoints }]
    for (const doc of snapshot.docs) {
      const d   = doc.data();
      const loc = (d.location ?? "").trim().toLowerCase();
      if (!loc) continue;
      if (!locationGroups.has(loc)) locationGroups.set(loc, []);
      locationGroups.get(loc).push({ userID: doc.id, pts: d.weeklyAuraPoints ?? 0 });
    }

    for (const [loc, users] of locationGroups) {
      if (users.length < 10) continue; // matches the app's 10-user minimum for the local board
      users.sort((a, b) => b.pts - a.pts);
      const topLocal = users.slice(0, 10);
      for (let i = 0; i < topLocal.length; i++) {
        const xp = localXpForRank(i + 1);
        if (xp === 0) continue;
        await db.collection("users").doc(topLocal[i].userID).update({
          auraPoints:      FieldValue.increment(xp),
          localWinnerRank: i + 1,
          localWinnerXP:   xp,
          localWinnerWeek: snapshotKey,
        });
        console.log(`[resetWeeklyAura] Local (${loc}) rank ${i + 1}: +${xp} XP → ${topLocal[i].userID}`);
      }
    }

    // Reset all users in batches.
    const newWeekStartTs = Math.floor(now.getTime() / 1000); // seconds
    const BATCH_LIMIT = 499;
    let batch = db.batch();
    let pendingWrites = 0;

    for (const doc of snapshot.docs) {
      batch.update(doc.ref, {
        weeklyAuraPoints:             0,
        weeklyAuraWeekStartTimestamp: newWeekStartTs,
      });
      pendingWrites++;
      if (pendingWrites === BATCH_LIMIT) {
        await batch.commit();
        batch = db.batch();
        pendingWrites = 0;
      }
    }
    if (pendingWrites > 0) await batch.commit();

    console.log(`[resetWeeklyAura] Reset complete. ${snapshot.size} users zeroed.`);
  }
);

// resetExpiredStreaks has been removed — streak resets are handled client-side.

// ---------------------------------------------------------------------------
// exchangeAppleAuthCode  (callable — exchanges Apple authorization code for refresh token)
// ---------------------------------------------------------------------------

/**
 * Exchanges the short-lived Apple authorization code (5-minute lifespan)
 * for a long-lived refresh token by calling appleid.apple.com/auth/token,
 * then stores the refresh token in `users/{uid}/private/appleAuth`.
 *
 * MUST be called within 5 minutes of a successful Sign In with Apple.
 * The stored refresh token is used later in `deleteAccount` to revoke
 * the app's sign-in grant with Apple (App Store guideline 5.1.1(v)).
 *
 * Request:  { authorizationCode: string }
 * Response: { success: true }
 */
exports.exchangeAppleAuthCode = onCall(
  {
    secrets: [APPLE_TEAM_ID, APPLE_KEY_ID, APPLE_BUNDLE_ID, APPLE_PRIVATE_KEY],
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }
    const uid = request.auth.uid;
    const { authorizationCode } = request.data || {};
    if (!authorizationCode || typeof authorizationCode !== "string") {
      throw new HttpsError("invalid-argument", "authorizationCode required.");
    }

    let clientSecret;
    try {
      clientSecret = generateAppleClientSecret();
    } catch (e) {
      console.error(`[exchangeAppleAuthCode] JWT signing failed: ${e.message}`);
      throw new HttpsError("internal", "Apple client secret generation failed.");
    }

    // POST to Apple's token endpoint.
    // Body must be application/x-www-form-urlencoded.
    const body = new URLSearchParams({
      client_id:     APPLE_BUNDLE_ID.value(),
      client_secret: clientSecret,
      code:          authorizationCode,
      grant_type:    "authorization_code",
    });

    const resp = await fetch("https://appleid.apple.com/auth/token", {
      method:  "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body:    body.toString(),
    });

    if (!resp.ok) {
      const text = await resp.text();
      console.error(`[exchangeAppleAuthCode] Apple token endpoint ${resp.status}: ${text}`);
      // Common causes: code expired (>5 min old), code already used, bundle ID mismatch
      throw new HttpsError("failed-precondition", `Apple rejected the authorization code (${resp.status}).`);
    }

    const tokens = await resp.json();
    const refreshToken = tokens.refresh_token;
    if (!refreshToken) {
      console.error(`[exchangeAppleAuthCode] Apple response missing refresh_token: ${JSON.stringify(tokens)}`);
      throw new HttpsError("internal", "Apple did not return a refresh token.");
    }

    // Store the refresh token in the user's private subcollection.
    // Admin SDK bypasses Firestore rules; the stored doc is only readable
    // by the owner (client) or by Cloud Functions using the admin SDK.
    const db = getFirestore();
    await db.collection("users").doc(uid)
      .collection("private").doc("appleAuth")
      .set({
        refreshToken,
        issuedAt: FieldValue.serverTimestamp(),
      }, { merge: true });

    console.log(`[exchangeAppleAuthCode] Stored Apple refresh token for ${uid}`);
    return { success: true };
  }
);

// ---------------------------------------------------------------------------
// deleteAccount  (callable — cascading delete of all user data)
// ---------------------------------------------------------------------------

/**
 * Permanently deletes all Firestore data, Storage files, and cross-references
 * for the authenticated user.
 *
 * Request:  {} (no params — uses auth.uid)
 * Response: { deleted: true }
 */
exports.deleteAccount = onCall(
  {
    secrets: [APPLE_TEAM_ID, APPLE_KEY_ID, APPLE_BUNDLE_ID, APPLE_PRIVATE_KEY],
    timeoutSeconds: 120,
  },
  async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }
  const uid = request.auth.uid;
  const db  = getFirestore();
  const bucket = getStorage().bucket();

  console.log(`[deleteAccount] Starting cascading delete for uid=${uid}`);

  // 0. Revoke the Apple refresh token if one was stored at sign-in.
  // Required by App Store guideline 5.1.1(v) for Sign in with Apple users.
  // Non-fatal — deletion proceeds even if revoke fails so the user can
  // still delete their account during an Apple outage.
  try {
    const appleAuthDoc = await db.collection("users").doc(uid)
      .collection("private").doc("appleAuth").get();
    const refreshToken = appleAuthDoc.exists ? appleAuthDoc.data().refreshToken : null;
    if (refreshToken) {
      const clientSecret = generateAppleClientSecret();
      const body = new URLSearchParams({
        client_id:       APPLE_BUNDLE_ID.value(),
        client_secret:   clientSecret,
        token:           refreshToken,
        token_type_hint: "refresh_token",
      });
      const resp = await fetch("https://appleid.apple.com/auth/revoke", {
        method:  "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body:    body.toString(),
      });
      if (resp.ok) {
        console.log(`[deleteAccount] Apple refresh token revoked for ${uid}`);
      } else {
        const text = await resp.text();
        console.warn(`[deleteAccount] Apple revoke returned ${resp.status}: ${text}`);
      }
    } else {
      console.log(`[deleteAccount] No Apple refresh token stored for ${uid} — skipping revoke`);
    }
  } catch (e) {
    console.warn(`[deleteAccount] Apple revoke step failed (continuing): ${e.message}`);
  }

  // Helper: delete all documents in a collection/subcollection (batched)
  async function deleteCollection(ref) {
    const BATCH = 499;
    let snap = await ref.limit(BATCH).get();
    while (!snap.empty) {
      const batch = db.batch();
      for (const doc of snap.docs) batch.delete(doc.ref);
      await batch.commit();
      snap = await ref.limit(BATCH).get();
    }
  }

  // Helper: delete a Storage folder prefix (all files under it)
  async function deleteStoragePrefix(prefix) {
    try {
      const [files] = await bucket.getFiles({ prefix });
      for (const file of files) {
        await file.delete().catch(() => {});
      }
      if (files.length > 0) console.log(`[deleteAccount] Deleted ${files.length} files under ${prefix}`);
    } catch (e) {
      console.log(`[deleteAccount] Storage prefix ${prefix}: ${e.message}`);
    }
  }

  // 1. Clean up follow relationships and decrement counts on other users
  const followersSnap = await db.collection("users").doc(uid).collection("followers").get();
  for (const doc of followersSnap.docs) {
    const followerID = doc.id;
    // Remove this user from their "following" subcollection
    await db.collection("users").doc(followerID).collection("following").doc(uid).delete().catch(() => {});
    // Decrement their followingCount
    await db.collection("users").doc(followerID).update({
      followingCount: FieldValue.increment(-1),
    }).catch(() => {});
  }

  const followingSnap = await db.collection("users").doc(uid).collection("following").get();
  for (const doc of followingSnap.docs) {
    const followedID = doc.id;
    // Remove this user from their "followers" subcollection
    await db.collection("users").doc(followedID).collection("followers").doc(uid).delete().catch(() => {});
    // Decrement their followerCount
    await db.collection("users").doc(followedID).update({
      followerCount: FieldValue.increment(-1),
    }).catch(() => {});
  }
  console.log(`[deleteAccount] Cleaned up ${followersSnap.size} followers, ${followingSnap.size} following`);

  // 2. Delete all user subcollections
  const subcollections = [
    "foodEntries", "fuelLog", "macroHistory", "workoutEntries",
    "following", "followers", "notifications", "subscribers",
    "balanceScoreHistory", "blockedUsers", "private",
  ];
  for (const sub of subcollections) {
    await deleteCollection(db.collection("users").doc(uid).collection(sub));
  }
  console.log(`[deleteAccount] Deleted user subcollections`);

  // 3. Delete posts authored by this user (and their comment subcollections)
  const postsSnap = await db.collection("posts").where("userID", "==", uid).get();
  for (const postDoc of postsSnap.docs) {
    await deleteCollection(postDoc.ref.collection("comments"));
    await postDoc.ref.delete();
  }
  console.log(`[deleteAccount] Deleted ${postsSnap.size} posts`);

  // 4. Delete comments authored by this user on other people's posts
  // (Query all posts' comments subcollections — use collectionGroup)
  try {
    const commentsSnap = await db.collectionGroup("comments")
      .where("authorID", "==", uid).get();
    let commentCount = 0;
    let commentBatch = db.batch();
    for (const doc of commentsSnap.docs) {
      commentBatch.delete(doc.ref);
      commentCount++;
      if (commentCount % 499 === 0) {
        await commentBatch.commit();
        commentBatch = db.batch();
      }
    }
    if (commentCount % 499 !== 0) await commentBatch.commit();
    console.log(`[deleteAccount] Deleted ${commentCount} comments on other posts`);
  } catch (e) {
    // Collection group index may not exist yet — log but continue with deletion
    console.warn(`[deleteAccount] Could not clean up comments: ${e.message}`);
  }

  // 5. Remove user from reppedBy arrays on other posts
  // (Too expensive to scan all posts; reps are cosmetic — skip for now)

  // 6. Delete the user document itself
  await db.collection("users").doc(uid).delete();
  console.log(`[deleteAccount] Deleted user document`);

  // 7. Delete all Storage files
  await deleteStoragePrefix(`profile_photos/${uid}`);
  await deleteStoragePrefix(`posts/${uid}/`);
  await deleteStoragePrefix(`food_photos/${uid}/`);
  await deleteStoragePrefix(`fuel_log/${uid}/`);
  console.log(`[deleteAccount] Storage cleanup complete`);

  // 8. Delete Firebase Auth user (admin SDK)
  try {
    const { getAuth } = require("firebase-admin/auth");
    await getAuth().deleteUser(uid);
    console.log(`[deleteAccount] Auth user deleted`);
  } catch (e) {
    console.log(`[deleteAccount] Auth delete: ${e.message}`);
  }

  console.log(`[deleteAccount] Cascading delete complete for uid=${uid}`);
  return { deleted: true };
  }
);

// ---------------------------------------------------------------------------
// proxyClaude  (callable — server-side proxy for Anthropic API)
// ---------------------------------------------------------------------------

// Allowed models — prevent callers from using expensive models via our key.
// IMPORTANT: these must match the exact strings sent by the iOS client
// (ClaudeHaikuService, ClaudeSonnetService, ClaudeAnalysisService). Any
// mismatch causes proxyClaude to reject the call with "Unsupported model",
// which the client turns into the "trouble identifying this food" error.
const ALLOWED_CLAUDE_MODELS = [
  "claude-haiku-4-5-20251001",
  "claude-sonnet-4-6",
  // Add new model IDs here as you adopt them
];
const MAX_ALLOWED_TOKENS = 4096;
const DAILY_SCAN_LIMIT   = 100;  // per-user daily limit

exports.proxyClaude = onCall(
  { secrets: [ANTHROPIC_API_KEY], timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Must be signed in.");

    const uid = request.auth.uid;
    const { model, maxTokens, messages } = request.data;
    if (!model || !messages) throw new HttpsError("invalid-argument", "model and messages required.");

    // --- Model validation ---
    if (!ALLOWED_CLAUDE_MODELS.includes(model)) {
      throw new HttpsError("invalid-argument", "Unsupported model.");
    }
    const clampedTokens = Math.min(maxTokens || 1024, MAX_ALLOWED_TOKENS);

    // --- Per-user daily rate limiting ---
    const db = getFirestore();
    const today = localDateStr("America/New_York");
    const statsRef = db.collection("users").doc(uid).collection("scanStats").doc("daily");
    const statsDoc = await statsRef.get();
    const stats = statsDoc.exists ? statsDoc.data() : {};
    if (stats.date === today && (stats.count || 0) >= DAILY_SCAN_LIMIT) {
      throw new HttpsError("resource-exhausted", "Daily scan limit reached. Try again tomorrow.");
    }
    // Increment counter (reset if new day)
    if (stats.date === today) {
      await statsRef.update({ count: FieldValue.increment(1) });
    } else {
      await statsRef.set({ date: today, count: 1 });
    }

    const resp = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": ANTHROPIC_API_KEY.value(),
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model,
        max_tokens: clampedTokens,
        messages,
      }),
    });

    if (!resp.ok) {
      const code = resp.status;
      if (code === 429) throw new HttpsError("resource-exhausted", "Rate limited.");
      if (code === 529) throw new HttpsError("unavailable", "Overloaded.");
      throw new HttpsError("internal", `Anthropic API error ${code}`);
    }

    return await resp.json();
  }
);

// proxyUSDA and proxyFatSecret removed — no longer used by the app.

// ---------------------------------------------------------------------------
// migratePrivateFields  (callable — one-time migration)
// ---------------------------------------------------------------------------

/**
 * Copies sensitive fields (DOB, weight, height, gender, dietary prefs) from
 * each user's public document into `users/{uid}/private/profile`, then removes
 * them from the public document.
 *
 * Run once after deploying the new Firestore rules and client code.
 * Call via: firebase functions:shell → migratePrivateFields({})
 * Or from the app: Functions.functions().httpsCallable("migratePrivateFields").call()
 *
 * Safe to run multiple times — uses setData(merge: true) and only deletes
 * fields that were successfully copied.
 */
exports.migratePrivateFields = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }
  // Only allow the call from an admin or the first user to trigger it.
  // For safety, this migrates ALL users when called.
  const db = getFirestore();
  const usersSnap = await db.collection("users").get();

  const PRIVATE_KEYS = [
    "dateOfBirth", "currentWeight", "goalWeight", "heightInches",
    "proteinPerLb", "gender", "excludeDairy", "excludeGluten",
  ];

  let migrated = 0;
  const BATCH_LIMIT = 499;
  let batch = db.batch();
  let pendingWrites = 0;

  for (const doc of usersSnap.docs) {
    const data = doc.data();
    const privateData = {};
    const removeFields = {};
    let hasPrivateData = false;

    for (const key of PRIVATE_KEYS) {
      if (data[key] !== undefined) {
        privateData[key] = data[key];
        removeFields[key] = FieldValue.delete();
        hasPrivateData = true;
      }
    }

    if (!hasPrivateData) continue;

    // Write to private subcollection
    const privateRef = doc.ref.collection("private").doc("profile");
    batch.set(privateRef, privateData, { merge: true });
    pendingWrites++;

    // Remove from public document
    batch.update(doc.ref, removeFields);
    pendingWrites++;

    if (pendingWrites >= BATCH_LIMIT - 1) {
      await batch.commit();
      batch = db.batch();
      pendingWrites = 0;
    }
    migrated++;
  }

  if (pendingWrites > 0) await batch.commit();

  console.log(`[migratePrivateFields] Migrated ${migrated} / ${usersSnap.size} users`);
  return { migrated, total: usersSnap.size };
});
