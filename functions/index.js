const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");

// Secrets (stored via firebase functions:secrets:set, never in source)
const ANTHROPIC_API_KEY      = defineSecret("ANTHROPIC_API_KEY");
const USDA_API_KEY           = defineSecret("USDA_API_KEY");
const FATSECRET_CLIENT_ID    = defineSecret("FATSECRET_CLIENT_ID");
const FATSECRET_CLIENT_SECRET = defineSecret("FATSECRET_CLIENT_SECRET");

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

// ---------------------------------------------------------------------------
// computeStreak  (callable — invoked by iOS on every app open)
// ---------------------------------------------------------------------------

/**
 * Incremental streak check: only queries yesterday's food entries and trusts
 * the stored `streakDays` + `lastStreakDate` for all prior days.
 *
 * Algorithm:
 *   yesterday = today(local) - 1 day
 *
 *   if lastStreakDate == yesterday → already counted, return streakDays unchanged
 *   if lastStreakDate <  day-before-yesterday → streak already broken → 0
 *   otherwise (lastStreakDate == day-before-yesterday OR streak == 0):
 *     query yesterday's foodEntries, sum macros, check 85-115% of goals
 *     met  → streakDays + 1, lastStreakDate = yesterday
 *     miss → streakDays = 0, lastStreakDate = yesterday
 *
 * shieldedDates are treated as met without querying foodEntries.
 *
 * Firestore path:  users/{uid}
 * Fields read:     streakDays, lastStreakDate
 * Fields written:  streakDays, lastStreakDate
 *
 * Request:  { goalCalories, goalProtein, goalCarbs, goalFat, shieldedDates, timeZone }
 * Response: { streakDays }
 */
exports.computeStreak = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }

  const uid = request.auth.uid;
  const {
    goalCalories,
    goalProtein,
    goalCarbs,
    goalFat,
    shieldedDates = [],
    timeZone = "UTC",
  } = request.data;

  if (!goalCalories || !goalProtein || !goalCarbs || !goalFat) {
    throw new HttpsError("invalid-argument", "All goal values are required.");
  }

  const db          = getFirestore();
  const shieldedSet = new Set(shieldedDates);
  const today       = localDateStr(timeZone);
  const yesterday   = previousDay(today);
  const dayBeforeYesterday = previousDay(yesterday);

  console.log(`[computeStreak] uid=${uid} today=${today} yesterday=${yesterday} tz=${timeZone}`);

  // Read current stored streak.
  const userRef  = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  const stored   = userSnap.data() ?? {};
  const currentStreak    = stored.streakDays    ?? 0;
  const lastStreakDate    = stored.lastStreakDate ?? "";

  // Already counted yesterday — nothing to do.
  if (lastStreakDate === yesterday) {
    console.log(`[computeStreak] lastStreakDate already ${yesterday} → returning ${currentStreak}`);
    return { streakDays: currentStreak };
  }

  // Gap of 2+ days means a day was skipped — streak is broken.
  // (The nightly resetExpiredStreaks job handles this too, but the user may open
  //  the app before 8 AM UTC on the day after a miss.)
  if (lastStreakDate !== "" && lastStreakDate < dayBeforeYesterday) {
    console.log(`[computeStreak] lastStreakDate ${lastStreakDate} is stale → streak broken`);
    await userRef.set({ streakDays: 0, lastStreakDate: yesterday }, { merge: true });
    return { streakDays: 0 };
  }

  // Shielded dates count as met without touching foodEntries.
  if (shieldedSet.has(yesterday)) {
    const newStreak = currentStreak + 1;
    console.log(`[computeStreak] ${yesterday} shielded → streak ${newStreak}`);
    await userRef.set({ streakDays: newStreak, lastStreakDate: yesterday }, { merge: true });
    return { streakDays: newStreak };
  }

  // Read the goals that were in effect yesterday from macroHistory.
  // This prevents a streak break caused by goal changes (e.g. weight update
  // recalculating macros) — yesterday's food is evaluated against yesterday's goals.
  const historySnap = await db.collection("users").doc(uid)
    .collection("macroHistory").doc(yesterday).get();
  const historyData = historySnap.exists ? historySnap.data() : null;

  const effectiveGoalCal  = historyData?.goalCalories ?? goalCalories;
  const effectiveGoalPro  = historyData?.goalProtein  ?? goalProtein;
  const effectiveGoalCarb = historyData?.goalCarbs    ?? goalCarbs;
  const effectiveGoalFat  = historyData?.goalFat      ?? goalFat;

  if (historyData) {
    console.log(`[computeStreak] Using stored goals from ${yesterday}: cal=${effectiveGoalCal} pro=${effectiveGoalPro} carb=${effectiveGoalCarb} fat=${effectiveGoalFat}`);
  } else {
    console.log(`[computeStreak] No macroHistory for ${yesterday}, using current goals: cal=${effectiveGoalCal} pro=${effectiveGoalPro} carb=${effectiveGoalCarb} fat=${effectiveGoalFat}`);
  }

  // Query yesterday's food entries.
  const { start, end } = dayBounds(yesterday, timeZone);
  const snap = await db
    .collection("users").doc(uid)
    .collection("foodEntries")
    .where("loggedAt", ">=", Timestamp.fromDate(start))
    .where("loggedAt", "<",  Timestamp.fromDate(end))
    .get();

  if (snap.empty) {
    console.log(`[computeStreak] ${yesterday} — no entries → streak broken`);
    await userRef.set({ streakDays: 0, lastStreakDate: yesterday }, { merge: true });
    return { streakDays: 0 };
  }

  let totalCal = 0, totalProt = 0, totalCarb = 0, totalFat = 0;
  for (const doc of snap.docs) {
    const d = doc.data();
    totalCal  += (d.calories ?? 0);
    totalProt += (d.protein  ?? 0);
    totalCarb += (d.carbs    ?? 0);
    totalFat  += (d.fat      ?? 0);
  }

  const LOW = 0.85, HIGH = 1.15;
  const calOk  = totalCal  >= effectiveGoalCal  * LOW && totalCal  <= effectiveGoalCal  * HIGH;
  const protOk = totalProt >= effectiveGoalPro  * LOW && totalProt <= effectiveGoalPro  * HIGH;
  const carbOk = totalCarb >= effectiveGoalCarb * LOW && totalCarb <= effectiveGoalCarb * HIGH;
  const fatOk  = totalFat  >= effectiveGoalFat  * LOW && totalFat  <= effectiveGoalFat  * HIGH;
  const met    = calOk && protOk && carbOk && fatOk;

  console.log(
    `[computeStreak] ${yesterday} — ` +
    `cal:${Math.round(totalCal)}/${effectiveGoalCal} ${calOk ? "✓" : "✗"}  ` +
    `pro:${Math.round(totalProt)}/${effectiveGoalPro} ${protOk ? "✓" : "✗"}  ` +
    `carb:${Math.round(totalCarb)}/${effectiveGoalCarb} ${carbOk ? "✓" : "✗"}  ` +
    `fat:${Math.round(totalFat)}/${effectiveGoalFat} ${fatOk ? "✓" : "✗"}`
  );

  const newStreak = met ? currentStreak + 1 : 0;
  console.log(`[computeStreak] ${yesterday} ${met ? "met" : "missed"} → streak ${newStreak}`);
  await userRef.set({ streakDays: newStreak, lastStreakDate: yesterday }, { merge: true });
  return { streakDays: newStreak };
});

// ---------------------------------------------------------------------------
// resetWeeklyAura  (scheduled — runs every Sunday at 8 PM Eastern time)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// resetExpiredStreaks  (scheduled — runs daily at 8 AM UTC)
// ---------------------------------------------------------------------------

/**
 * Safety net for users who don't open the app every day.
 * Any user whose `lastStreakDate` is before yesterday has missed at least one
 * day, so their streak is reset to 0.
 *
 * Firestore path:  users/{userID}
 * Fields read:     streakDays (> 0 filter), lastStreakDate
 * Fields written:  streakDays → 0
 */
exports.resetExpiredStreaks = onSchedule(
  { schedule: "0 8 * * *", timeZone: "UTC" },
  async (_event) => {
    const db = getFirestore();

    const now = new Date();
    const yesterday = new Date(Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth(),
      now.getUTCDate() - 1
    ));
    const yesterdayStr = yesterday.toISOString().split("T")[0];

    console.log(`Streak reset job started. Threshold: ${yesterdayStr}`);

    const snapshot = await db.collection("users")
      .where("streakDays", ">", 0)
      .get();

    if (snapshot.empty) {
      console.log("No users with active streaks. Nothing to do.");
      return;
    }

    const BATCH_LIMIT = 499;
    let batch = db.batch();
    let pendingWrites = 0;
    let resetCount = 0;

    for (const doc of snapshot.docs) {
      const lastStreakDate = doc.data().lastStreakDate ?? "";

      // If lastStreakDate is before yesterday the user missed at least one day.
      if (lastStreakDate < yesterdayStr) {
        batch.update(doc.ref, { streakDays: 0 });
        pendingWrites++;
        resetCount++;

        if (pendingWrites === BATCH_LIMIT) {
          await batch.commit();
          batch = db.batch();
          pendingWrites = 0;
        }
      }
    }

    if (pendingWrites > 0) {
      await batch.commit();
    }

    console.log(`Streak reset complete. ${resetCount} of ${snapshot.size} active-streak users reset.`);
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
exports.deleteAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }
  const uid = request.auth.uid;
  const db  = getFirestore();
  const bucket = getStorage().bucket();

  console.log(`[deleteAccount] Starting cascading delete for uid=${uid}`);

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
    "balanceScoreHistory",
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
  const commentsSnap = await db.collectionGroup("comments")
    .where("authorID", "==", uid).get();
  const commentBatch = db.batch();
  let commentCount = 0;
  for (const doc of commentsSnap.docs) {
    commentBatch.delete(doc.ref);
    commentCount++;
    if (commentCount % 499 === 0) {
      await commentBatch.commit();
    }
  }
  if (commentCount % 499 !== 0) await commentBatch.commit();
  console.log(`[deleteAccount] Deleted ${commentCount} comments on other posts`);

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
});

// ---------------------------------------------------------------------------
// proxyClaude  (callable — server-side proxy for Anthropic API)
// ---------------------------------------------------------------------------

exports.proxyClaude = onCall(
  { secrets: [ANTHROPIC_API_KEY], timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Must be signed in.");

    const { model, maxTokens, messages } = request.data;
    if (!model || !messages) throw new HttpsError("invalid-argument", "model and messages required.");

    const resp = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": ANTHROPIC_API_KEY.value(),
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model,
        max_tokens: maxTokens || 1024,
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

// ---------------------------------------------------------------------------
// proxyUSDA  (callable — server-side proxy for USDA FoodData Central)
// ---------------------------------------------------------------------------

exports.proxyUSDA = onCall(
  { secrets: [USDA_API_KEY] },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Must be signed in.");

    const { endpoint, query, fdcId, pageSize } = request.data;

    let url;
    if (endpoint === "search") {
      const q = encodeURIComponent(query || "");
      url = `https://api.nal.usda.gov/fdc/v1/foods/search?query=${q}&dataType=SR%20Legacy,Foundation&pageSize=${pageSize || 5}&api_key=${USDA_API_KEY.value()}`;
    } else if (endpoint === "detail" && fdcId) {
      url = `https://api.nal.usda.gov/fdc/v1/food/${fdcId}?api_key=${USDA_API_KEY.value()}`;
    } else {
      throw new HttpsError("invalid-argument", "endpoint must be 'search' or 'detail'.");
    }

    const resp = await fetch(url);
    if (!resp.ok) throw new HttpsError("internal", `USDA API error ${resp.status}`);
    return await resp.json();
  }
);

// ---------------------------------------------------------------------------
// proxyFatSecret  (callable — server-side proxy for FatSecret Platform API)
// ---------------------------------------------------------------------------

// In-memory token cache (lives as long as the function instance)
let fatSecretToken = null;
let fatSecretTokenExpiry = 0;

exports.proxyFatSecret = onCall(
  { secrets: [FATSECRET_CLIENT_ID, FATSECRET_CLIENT_SECRET] },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Must be signed in.");

    const { query, maxResults } = request.data;
    if (!query) throw new HttpsError("invalid-argument", "query is required.");

    // Ensure OAuth token
    if (!fatSecretToken || Date.now() >= fatSecretTokenExpiry) {
      const creds = Buffer.from(
        `${FATSECRET_CLIENT_ID.value()}:${FATSECRET_CLIENT_SECRET.value()}`
      ).toString("base64");

      const tokenResp = await fetch("https://oauth.fatsecret.com/connect/token", {
        method: "POST",
        headers: {
          "Authorization": `Basic ${creds}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: "grant_type=client_credentials&scope=basic",
      });

      if (!tokenResp.ok) throw new HttpsError("internal", `FatSecret OAuth error ${tokenResp.status}`);
      const tokenData = await tokenResp.json();
      fatSecretToken = tokenData.access_token;
      fatSecretTokenExpiry = Date.now() + (tokenData.expires_in - 60) * 1000;
    }

    // Search foods
    const params = new URLSearchParams({
      method: "foods.search",
      search_expression: query,
      format: "json",
      max_results: String(maxResults || 5),
    });

    const resp = await fetch(`https://platform.fatsecret.com/rest/server.api?${params}`, {
      headers: { "Authorization": `Bearer ${fatSecretToken}` },
    });

    if (!resp.ok) throw new HttpsError("internal", `FatSecret API error ${resp.status}`);
    return await resp.json();
  }
);
