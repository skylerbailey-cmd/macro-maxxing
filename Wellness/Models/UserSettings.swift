//
//  UserSettings.swift
//  Wellness
//

import Foundation

// MARK: - Aura Gain

struct AuraGain: Identifiable, Equatable {
    let id           = UUID()
    let pointsEarned: Int

    static func == (lhs: AuraGain, rhs: AuraGain) -> Bool {
        lhs.id == rhs.id && lhs.pointsEarned == rhs.pointsEarned
    }
}

@Observable final class UserSettings {

    // MARK: - Identity (in-memory only — populated by SessionManager from Firestore)

    var userID:           String = ""
    var username:         String = ""
    var name:             String = ""
    var location:         String = ""
    var profilePhotoURL:  String = ""
    var bio:              String = ""
    var instagramHandle:  String = ""
    var tiktokHandle:     String = ""
    var isPrivateAccount: Bool   = false
    /// Date of birth as "yyyy-MM-dd". Empty string if not set.
    var dateOfBirth:      String = ""

    // MARK: - Body (in-memory only)

    var currentWeight: Double = 160
    var goalWeight:    Double = 160
    var heightInches:  Int    = 0
    var proteinPerLb:  Double = 0.9

    // MARK: - Fasting

    var fastingEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(fastingEnabled, forKey: "fastingEnabled")
            if fastingEnabled {
                let hour   = UserDefaults.standard.integer(forKey: "windowStartHour")
                let minute = UserDefaults.standard.integer(forKey: "windowStartMinute")
                NotificationService.shared.scheduleFastingWindowNotification(
                    windowStartHour: hour, windowStartMinute: minute)
            } else {
                NotificationService.shared.cancelFastingWindowNotification()
            }
        }
    }

    // MARK: - Streak (device-local — persisted to UserDefaults)

    /// Display streak shown in the UI (baseStreak + 1 if today is also met).
    var macroStreak: Int = 0 {
        didSet { UserDefaults.standard.set(macroStreak, forKey: "macroStreak") }
    }
    /// Consecutive historical days met, ending yesterday. Computed once per day
    /// and persisted so it survives app restarts within the same calendar day.
    var baseStreak: Int = 0 {
        didSet { UserDefaults.standard.set(baseStreak, forKey: "baseStreak") }
    }
    /// All-time best streak.
    var longestStreak: Int = 0 {
        didSet { UserDefaults.standard.set(longestStreak, forKey: "longestStreak") }
    }
    /// "yyyy-MM-dd" of the last day the historical streak walk ran. Prevents
    /// re-fetching all of Firestore on every meal load.
    var lastStreakCheckDate: String = "" {
        didSet { UserDefaults.standard.set(lastStreakCheckDate, forKey: "lastStreakCheckDate") }
    }
    /// Set when the user first hits all macro goals for the day.
    /// Observed by ContentView to show a streak congrats popup.
    var pendingStreakCongrats: Int? = nil
    /// Set when a streak break is detected. Observed by ContentView to show the shield popup.
    var pendingStreakBreak: Int? = nil

    // MARK: - Streak Shield

    /// The streak count just before it reset to 0. Non-zero means a restorable break exists.
    var lastStreakBeforeBreak: Int = 0 {
        didSet { UserDefaults.standard.set(lastStreakBeforeBreak, forKey: "lastStreakBeforeBreak") }
    }
    /// "yyyy-MM-dd" of the day the streak broke. Used to show the popup once per break.
    var streakBreakDate: String = "" {
        didSet { UserDefaults.standard.set(streakBreakDate, forKey: "streakBreakDate") }
    }
    /// Dates where a streak shield was applied. StreakService treats these as "goals met"
    /// even if no food was logged, preserving the restored streak going forward.
    var shieldedDates: [String] {
        get { UserDefaults.standard.stringArray(forKey: "shieldedDates") ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: "shieldedDates") }
    }

    /// Restores the streak after a successful shield purchase.
    /// Adds the break date to shieldedDates so StreakService counts it as met going forward.
    func applyStreakShield(userID: String) {
        guard lastStreakBeforeBreak > 0, !streakBreakDate.isEmpty else { return }

        var dates = shieldedDates
        if !dates.contains(streakBreakDate) { dates.append(streakBreakDate) }
        shieldedDates = dates

        macroStreak  = lastStreakBeforeBreak
        baseStreak   = lastStreakBeforeBreak

        let restored = lastStreakBeforeBreak
        let shielded = dates
        let breakDate = streakBreakDate

        lastStreakBeforeBreak = 0
        streakBreakDate       = ""

        guard !userID.isEmpty else { return }
        Task {
            try? await UserProfileService.shared.updateProfile(
                userID: userID,
                fields: [
                    "streakDays":            restored,
                    "lastStreakBeforeBreak":  0,
                    "streakBreakDate":        "",
                    "shieldedDates":          shielded,
                ]
            )
            print("[UserSettings] Streak shield applied — restored to \(restored), shielded \(breakDate)")
        }
    }

    // MARK: - Brainstorm result persistence (device-local)

    /// The AI meal-planner result text from the most recent brainstorm run.
    var lastBrainstormResult: String = "" {
        didSet { UserDefaults.standard.set(lastBrainstormResult, forKey: "lastBrainstormResult") }
    }
    /// The calendar day on which `lastBrainstormResult` was generated.
    var lastBrainstormDate: Date = .distantPast {
        didSet { UserDefaults.standard.set(lastBrainstormDate.timeIntervalSince1970, forKey: "lastBrainstormDate") }
    }

    /// True if the stored brainstorm result was generated today and is still valid.
    var hasTodayBrainstormResult: Bool {
        !lastBrainstormResult.isEmpty && Calendar.current.isDateInToday(lastBrainstormDate)
    }

    // MARK: - Brainstorm daily limit (device-local)

    private static let brainstormDailyLimit = 2

    private var brainstormUsageCount: Int = 0 {
        didSet { UserDefaults.standard.set(brainstormUsageCount, forKey: "brainstormUsageCount") }
    }
    private var brainstormUsageDate: Date = .distantPast {
        didSet { UserDefaults.standard.set(brainstormUsageDate.timeIntervalSince1970, forKey: "brainstormUsageDate") }
    }

    var brainstormUsesRemaining: Int {
        resetBrainstormIfNewDay()
        return max(0, UserSettings.brainstormDailyLimit - brainstormUsageCount)
    }

    var brainstormLimitReached: Bool { brainstormUsesRemaining == 0 }

    /// Returns true if a use was successfully consumed, false if limit already reached.
    @discardableResult
    func consumeBrainstormUse() -> Bool {
        resetBrainstormIfNewDay()
        guard brainstormUsageCount < UserSettings.brainstormDailyLimit else { return false }
        brainstormUsageCount += 1
        return true
    }

    private func resetBrainstormIfNewDay() {
        if !Calendar.current.isDateInToday(brainstormUsageDate) {
            brainstormUsageCount = 0
            brainstormUsageDate  = Date()
        }
    }

    // MARK: - Aura (in-memory for identity fields; weekly/leaderboard fields device-local)

    var auraPoints: Int = 0
    /// Aura earned since the most recent Monday 00:00 local time.
    var weeklyAuraPoints: Int = 0 {
        didSet { UserDefaults.standard.set(weeklyAuraPoints, forKey: "weeklyAuraPoints") }
    }
    /// The Monday that started the current weekly window (stored as TimeInterval).
    private var weeklyAuraWeekStart: Date = Date.distantPast {
        didSet { UserDefaults.standard.set(weeklyAuraWeekStart.timeIntervalSince1970, forKey: "weeklyAuraWeekStart") }
    }
    /// "YYYY-MM-DD" of the last weekly reset for which a winner award was already claimed.
    /// Prevents the winner popup from re-showing on subsequent app opens.
    var lastClaimedWinnerWeek: String = "" {
        didSet { UserDefaults.standard.set(lastClaimedWinnerWeek, forKey: "lastClaimedWinnerWeek") }
    }
    /// Set by populate(from:) when the Cloud Function tagged this user as a weekly winner.
    /// Observed by LeaderboardView to trigger the winner popup.
    var pendingWeeklyWinnerRank: Int? = nil
    /// XP awarded for the pending winner finish.
    var pendingWeeklyWinnerXP:   Int  = 0
    /// Comma-separated streak milestones already awarded, e.g. "3,7,14"
    private var achievedMilestonesRaw: String = "" {
        didSet { UserDefaults.standard.set(achievedMilestonesRaw, forKey: "achievedMilestones") }
    }
    /// Comma-separated "yyyy-MM-dd" dates on which ALL macro goals were confirmed met.
    /// Acts as a local fallback so the streak survives even when Firestore history is missing.
    var goalsMetDatesRaw: String = "" {
        didSet { UserDefaults.standard.set(goalsMetDatesRaw, forKey: "goalsMetDates") }
    }
    var goalsMetDates: Set<String> {
        Set(goalsMetDatesRaw.split(separator: ",").map { String($0) })
    }
    /// Records or removes a date from the local goals-met cache.
    func setGoalsMet(_ met: Bool, for date: Date) {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let key = fmt.string(from: date)
        var dates = goalsMetDates
        if met { dates.insert(key) } else { dates.remove(key) }
        goalsMetDatesRaw = dates.joined(separator: ",")
    }
    /// The calendar date on which the macro-goals celebration was last shown (once per day).
    var lastCelebrationDate: Date = .distantPast {
        didSet { UserDefaults.standard.set(lastCelebrationDate.timeIntervalSince1970, forKey: "lastCelebrationDate") }
    }

    /// Whether to automatically apply macro adjustments when a workout is logged.
    var autoAdjustMacrosForWorkout: Bool = false {
        didSet { UserDefaults.standard.set(autoAdjustMacrosForWorkout, forKey: "autoAdjustMacrosForWorkout") }
    }

    /// Last date the user earned aura points by posting with the Workout label (once per day).
    var lastWorkoutPostDate: Date = .distantPast {
        didSet { UserDefaults.standard.set(lastWorkoutPostDate.timeIntervalSince1970, forKey: "lastWorkoutPostDate") }
    }

    /// True if workout-post aura has already been awarded today.
    var hasEarnedWorkoutPostAuraToday: Bool {
        Calendar.current.isDateInToday(lastWorkoutPostDate)
    }

    /// Whether to show the aura gain popup when points are earned.
    var auraPopupsEnabled: Bool = true
    /// Set whenever points are awarded (when popups enabled). Observe to show popup.
    var pendingAuraGain: AuraGain? = nil
    /// Set whenever all macro goals are met for the first time today. Observe to show celebration.
    var pendingCelebration: CelebrationPostData? = nil
    /// Set when a Firestore write fails. Observed by ContentView to surface an alert.
    var firestoreError: String? = nil

    // MARK: - Aura Level Curve
    //
    // Quadratic: cumulativePoints(level) = a·n + b·n²
    // Constraints: threshold(1) = 300, threshold(100) = 100,000
    // → b = 700/99 ≈ 7.07,  a = 300 − b ≈ 292.93
    // Incremental cost grows from 300 pts (Lv 1) to 1,700 pts (Lv 100).

    /// Cumulative aura points required to *reach* `level` (0–100).
    ///
    /// Per-level cost starts at 150 XP (level 1→2) and increases by ~17.55 XP
    /// each level, so every level always costs more than the one before it.
    /// Anchors: threshold(1) = 0, threshold(2) = 150, threshold(100) = 100,000.
    static func auraThreshold(_ level: Int) -> Int {
        guard level > 1   else { return 0 }
        guard level < 100 else { return 100_000 }
        let n = Double(level)
        // perLevel(n) = a + (n-1)*d  →  threshold(n) = (n-1)*a + d*(n-1)*(n-2)/2
        // Anchors: threshold(2)=300 → a=300; threshold(100)=100,000 → d=70,300/4,851
        let a = 150.0
        let d = 85_150.0 / 4_851.0
        return Int(((n - 1) * a + d * (n - 1) * (n - 2) / 2).rounded())
    }

    /// Level (0–100) for a given point total, using the quadratic curve.
    static func auraLevel(for points: Int) -> Int {
        guard points > 0        else { return 1 }
        guard points < 100_000  else { return 100 }
        var lo = 1, hi = 99
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if auraThreshold(mid) <= points { lo = mid } else { hi = mid - 1 }
        }
        return lo
    }

    // MARK: Computed aura properties

    var auraLevel: Int { UserSettings.auraLevel(for: auraPoints) }

    var auraTitle: String {
        switch auraLevel {
        case 1...5:   return "Initiate"
        case 6...10:  return "Rookie"
        case 11...15: return "Grinder"
        case 16...20: return "Disciple"
        case 21...25: return "Ascender"
        case 26...35: return "Mog Apprentice"
        case 36...45: return "Aura Seeker"
        case 46...55: return "Aura Farmer"
        case 56...65: return "Aesthetic"
        case 66...75: return "Elite Aesthetic"
        case 76...90: return "Transcendent"
        default:      return "Final Form"
        }
    }

    var achievedMilestones: Set<Int> {
        Set(achievedMilestonesRaw.split(separator: ",").compactMap { Int($0) })
    }

    // MARK: Aura award

    func awardAura(points: Int, silent: Bool = false) {
        checkWeeklyReset()
        auraPoints += points
        weeklyAuraPoints += points
        if auraPopupsEnabled && !silent {
            pendingAuraGain = AuraGain(pointsEarned: points)
        }
        let id     = userID
        let pts    = auraPoints
        let wkPts  = weeklyAuraPoints
        let wkTs   = weeklyAuraWeekStart.timeIntervalSince1970
        Task {
            do {
                try await UserProfileService.shared.updateProfile(
                    userID: id,
                    fields: [
                        "auraPoints":                   pts,
                        "weeklyAuraPoints":              wkPts,
                        "weeklyAuraWeekStartTimestamp":  wkTs,
                    ]
                )
                print("[UserSettings] awardAura: synced +\(points) xp (total \(pts), weekly \(wkPts))")
            } catch {
                let msg = error.localizedDescription
                print("[UserSettings] awardAura Firestore error: \(msg)")
                await MainActor.run { self.firestoreError = "XP sync failed: \(msg)" }
            }
        }
    }

    func checkWeeklyReset() {
        let start = UserSettings.currentWeekStart()
        if start > weeklyAuraWeekStart {
            weeklyAuraPoints    = 0
            weeklyAuraWeekStart = start
            let id  = userID
            let ts  = start.timeIntervalSince1970
            Task {
                try? await UserProfileService.shared.updateProfile(
                    userID: id,
                    fields: [
                        "weeklyAuraPoints":             0,
                        "weeklyAuraWeekStartTimestamp": ts,
                    ]
                )
            }
        }
    }

    /// Returns the most recent Sunday at 8 PM Eastern time (the weekly reset boundary).
    static func currentWeekStart() -> Date {
        let etZone = TimeZone(identifier: "America/New_York")!
        var cal    = Calendar(identifier: .gregorian)
        cal.timeZone = etZone

        let now     = Date()
        // weekday: 1 = Sunday … 7 = Saturday in ET
        let weekday  = cal.component(.weekday, from: now)
        let daysBack = weekday - 1   // 0 when today is Sunday

        guard let lastSunday = cal.date(byAdding: .day, value: -daysBack, to: now) else {
            return now
        }

        // Build "last Sunday at 20:00 ET"
        var comps        = cal.dateComponents([.year, .month, .day], from: lastSunday)
        comps.hour       = 20
        comps.minute     = 0
        comps.second     = 0
        comps.timeZone   = etZone

        guard let sunday8PM = cal.date(from: comps) else { return now }

        // If that moment is still in the future (it's Sunday before 8 PM ET),
        // step back one full week.
        if sunday8PM > now {
            return cal.date(byAdding: .weekOfYear, value: -1, to: sunday8PM) ?? sunday8PM
        }
        return sunday8PM
    }

    /// Returns the next upcoming Sunday at 8 PM Eastern time (the next weekly reset).
    static func nextWeekReset() -> Date {
        let last = currentWeekStart()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        return cal.date(byAdding: .weekOfYear, value: 1, to: last) ?? last
    }

    func markMilestoneAchieved(_ milestone: Int) {
        var set = achievedMilestones
        set.insert(milestone)
        achievedMilestonesRaw = set.map { String($0) }.joined(separator: ",")
    }

    // MARK: - Profile image (local file in Documents dir)

    /// Profile picture — persisted as a JPEG file in the Documents directory.
    var profileImageData: Data? {
        didSet {
            let url  = UserSettings.profileImageURL
            let data = profileImageData
            Task.detached(priority: .utility) {
                if let data { try? data.write(to: url) }
                else { try? FileManager.default.removeItem(at: url) }
            }
        }
    }
    static let profileImageURL: URL =
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_image.jpg")

    /// Downloads the profile photo from `profilePhotoURL` and caches it in
    /// `profileImageData` (and to disk). No-ops if the image is already cached
    /// or if `profilePhotoURL` is empty.
    func downloadProfileImageIfNeeded() async {
        guard profileImageData == nil,
              !profilePhotoURL.isEmpty,
              let url = URL(string: profilePhotoURL) else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
        profileImageData = data
    }

    // MARK: - SessionManager integration

    /// Called by SessionManager after a successful Firestore profile fetch.
    /// Populates all identity fields in-memory. Does NOT touch UserDefaults.
    func populate(from profile: UserProfile) {
        // Cache userID to UserDefaults so background tasks can access it without the auth stack
        UserDefaults.standard.set(profile.userID, forKey: "cachedUserID")
        userID            = profile.userID
        username          = profile.username
        name              = profile.name
        location          = profile.location
        profilePhotoURL   = profile.profilePhotoURL
        bio               = profile.bio
        instagramHandle   = profile.instagramHandle
        tiktokHandle      = profile.tiktokHandle
        isPrivateAccount  = profile.isPrivateAccount
        dateOfBirth       = profile.dateOfBirth
        currentWeight     = profile.currentWeight
        goalWeight        = profile.goalWeight
        heightInches      = profile.heightInches
        proteinPerLb      = profile.proteinPerLb
        fastingEnabled    = profile.fastingEnabled
        // Write window settings to UserDefaults so HomeViewModel and FoodLogView
        // (which read from UserDefaults) pick up the synced values on next appear.
        UserDefaults.standard.set(profile.windowStartHour,     forKey: "windowStartHour")
        UserDefaults.standard.set(profile.windowStartMinute,   forKey: "windowStartMinute")
        UserDefaults.standard.set(profile.windowDurationHours, forKey: "windowDurationHours")

        // Merge Firestore goalsMetDates into local cache so streak is accurate
        // across devices and after sign-out/sign-in.
        if !profile.goalsMetDates.isEmpty {
            var local = goalsMetDates               // existing local Set<String>
            for d in profile.goalsMetDates { local.insert(d) }
            goalsMetDatesRaw = local.joined(separator: ",")
        }
        auraPopupsEnabled = profile.auraPopupsEnabled
        auraPoints        = profile.auraPoints
        // Restore streak fields from Firestore. Take the higher streak value so a
        // local cache never overwrites a streak that was already correctly computed.
        macroStreak         = max(macroStreak, profile.streakDays)
        // baseStreak must also be seeded from Firestore so the hub calculation
        // (display = baseStreak + todayAllMet) doesn't start from 0 on a fresh
        // install or after UserDefaults is cleared.
        baseStreak          = max(baseStreak, profile.streakDays)
        longestStreak       = max(longestStreak, profile.longestStreak)
        // Take whichever check date is more recent (non-empty string comparison works
        // because "yyyy-MM-dd" sorts lexicographically).
        if profile.lastStreakCheckDate > lastStreakCheckDate {
            lastStreakCheckDate = profile.lastStreakCheckDate
        }

        // Restore weekly aura from Firestore, then check if a new week has started
        // (checkWeeklyReset handles the reset + Firestore update if needed).
        if profile.weeklyAuraPoints > 0 {
            weeklyAuraPoints    = profile.weeklyAuraPoints
            weeklyAuraWeekStart = profile.weeklyAuraWeekStartTimestamp > 0
                ? Date(timeIntervalSince1970: profile.weeklyAuraWeekStartTimestamp)
                : UserSettings.currentWeekStart()
        }
        checkWeeklyReset()

        // Check for pending weekly winner award set by the Cloud Function.
        // weeklyWinnerXP > 0 means the server tagged this user as a top-3 finisher.
        // lastClaimedWinnerWeek prevents showing the popup more than once.
        if profile.weeklyWinnerXP > 0 && profile.weeklyWinnerWeek != lastClaimedWinnerWeek {
            lastClaimedWinnerWeek   = profile.weeklyWinnerWeek
            pendingWeeklyWinnerRank = profile.weeklyWinnerRank
            pendingWeeklyWinnerXP   = profile.weeklyWinnerXP
            auraPoints              = profile.auraPoints   // Cloud Function already incremented
            // Clear winner fields from Firestore so they don't re-trigger on next open
            let uid = profile.userID
            Task {
                try? await UserProfileService.shared.updateProfile(
                    userID: uid,
                    fields: ["weeklyWinnerRank": 0, "weeklyWinnerXP": 0, "weeklyWinnerWeek": ""])
            }
        }

    }

    /// Called by SessionManager on sign-out.
    /// Clears all identity fields AND all device-local UserDefaults state so a
    /// new user on the same device starts completely fresh.
    func clearProfile() {
        // Identity
        userID            = ""
        username          = ""
        name              = ""
        location          = ""
        profilePhotoURL   = ""
        bio               = ""
        instagramHandle   = ""
        tiktokHandle      = ""
        isPrivateAccount  = false
        dateOfBirth       = ""
        currentWeight     = 160
        goalWeight        = 160
        heightInches      = 0
        proteinPerLb      = 0.9
        fastingEnabled    = false
        auraPopupsEnabled = true
        auraPoints        = 0
        profileImageData  = nil

        // Streak & goals-met history
        macroStreak           = 0
        baseStreak            = 0
        longestStreak         = 0
        lastStreakCheckDate   = ""
        lastStreakBeforeBreak = 0
        streakBreakDate       = ""
        shieldedDates         = []
        goalsMetDatesRaw      = ""
        achievedMilestonesRaw = ""
        lastCelebrationDate   = .distantPast

        // Aura / leaderboard
        weeklyAuraPoints         = 0
        weeklyAuraWeekStart      = .distantPast
        lastClaimedWinnerWeek    = ""
        pendingWeeklyWinnerRank  = nil
        pendingWeeklyWinnerXP    = 0

        // Brainstorm
        lastBrainstormResult = ""
        lastBrainstormDate   = .distantPast
        brainstormUsageCount = 0
        brainstormUsageDate  = .distantPast

        // Misc device-local keys not owned by UserSettings properties.
        // Note: fasting window (windowStartHour/Minute/Duration), macro goals
        // (goalCalories/Protein/Carbs/Fat), and autoAdjustMacrosForWorkout are
        // intentionally NOT cleared — they are device preferences restored from
        // Firestore on next login, so wiping them would lose the user's settings.
        let ud = UserDefaults.standard
        for key in [
            "base_goalCalories", "base_goalProtein", "base_goalCarbs", "base_goalFat",
            "workoutAdjustmentDate",
            "savedWorkoutTemplates",
            "wt_startTime", "wt_pausedAt", "wt_pausedSeconds",
            "cachedUserID"
        ] { ud.removeObject(forKey: key) }
    }

    // MARK: - Init

    init() {
        // Restore only device-local tracking fields from UserDefaults.
        // Profile identity fields start at their zero/default values —
        // they will be set by populate(from:) after SessionManager resolves auth.

        self.autoAdjustMacrosForWorkout = UserDefaults.standard.bool(forKey: "autoAdjustMacrosForWorkout")
        self.weeklyAuraPoints = UserDefaults.standard.integer(forKey: "weeklyAuraPoints")
        let storedWeekStart = UserDefaults.standard.double(forKey: "weeklyAuraWeekStart")
        self.weeklyAuraWeekStart = storedWeekStart > 0
            ? Date(timeIntervalSince1970: storedWeekStart) : .distantPast
        self.achievedMilestonesRaw = UserDefaults.standard.string(forKey: "achievedMilestones") ?? ""
        let storedCelebDate = UserDefaults.standard.double(forKey: "lastCelebrationDate")
        self.lastCelebrationDate = storedCelebDate > 0
            ? Date(timeIntervalSince1970: storedCelebDate) : .distantPast
        self.goalsMetDatesRaw      = UserDefaults.standard.string(forKey: "goalsMetDates") ?? ""
        self.macroStreak           = UserDefaults.standard.integer(forKey: "macroStreak")
        self.baseStreak            = UserDefaults.standard.integer(forKey: "baseStreak")
        self.longestStreak         = UserDefaults.standard.integer(forKey: "longestStreak")
        self.lastStreakCheckDate    = UserDefaults.standard.string(forKey: "lastStreakCheckDate") ?? ""
        self.lastStreakBeforeBreak  = UserDefaults.standard.integer(forKey: "lastStreakBeforeBreak")
        self.streakBreakDate        = UserDefaults.standard.string(forKey: "streakBreakDate") ?? ""
        self.brainstormUsageCount  = UserDefaults.standard.integer(forKey: "brainstormUsageCount")
        let storedBSDate = UserDefaults.standard.double(forKey: "brainstormUsageDate")
        self.brainstormUsageDate   = storedBSDate > 0
            ? Date(timeIntervalSince1970: storedBSDate) : .distantPast
        self.lastClaimedWinnerWeek = UserDefaults.standard.string(forKey: "lastClaimedWinnerWeek") ?? ""
        self.lastBrainstormResult  = UserDefaults.standard.string(forKey: "lastBrainstormResult") ?? ""
        let storedBSResultDate = UserDefaults.standard.double(forKey: "lastBrainstormDate")
        self.lastBrainstormDate    = storedBSResultDate > 0
            ? Date(timeIntervalSince1970: storedBSResultDate) : .distantPast
        let storedWPDate = UserDefaults.standard.double(forKey: "lastWorkoutPostDate")
        self.lastWorkoutPostDate   = storedWPDate > 0
            ? Date(timeIntervalSince1970: storedWPDate) : .distantPast
        // Profile image is loaded asynchronously via loadCachedImage() to avoid
        // blocking the main thread at launch (file can be 1–3 MB).
    }

    /// Loads the cached profile image from disk on a background thread.
    /// Call this once from the app root's .task modifier.
    func loadCachedImage() async {
        guard profileImageData == nil else { return }
        let url = UserSettings.profileImageURL
        let data = await Task.detached(priority: .userInitiated) {
            try? Data(contentsOf: url)
        }.value
        profileImageData = data
    }
}
