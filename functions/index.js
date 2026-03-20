const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

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
  const calOk  = totalCal  >= goalCalories * LOW && totalCal  <= goalCalories * HIGH;
  const protOk = totalProt >= goalProtein  * LOW && totalProt <= goalProtein  * HIGH;
  const carbOk = totalCarb >= goalCarbs    * LOW && totalCarb <= goalCarbs    * HIGH;
  const fatOk  = totalFat  >= goalFat      * LOW && totalFat  <= goalFat      * HIGH;
  const met    = calOk && protOk && carbOk && fatOk;

  console.log(
    `[computeStreak] ${yesterday} — ` +
    `cal:${Math.round(totalCal)}/${goalCalories} ${calOk ? "✓" : "✗"}  ` +
    `pro:${Math.round(totalProt)}/${goalProtein} ${protOk ? "✓" : "✗"}  ` +
    `carb:${Math.round(totalCarb)}/${goalCarbs} ${carbOk ? "✓" : "✗"}  ` +
    `fat:${Math.round(totalFat)}/${goalFat} ${fatOk ? "✓" : "✗"}`
  );

  const newStreak = met ? currentStreak + 1 : 0;
  console.log(`[computeStreak] ${yesterday} ${met ? "met" : "missed"} → streak ${newStreak}`);
  await userRef.set({ streakDays: newStreak, lastStreakDate: yesterday }, { merge: true });
  return { streakDays: newStreak };
});

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
