//
//  UserSettings.swift
//  Wellness
//

import Foundation

// MARK: - Aura Gain

struct AuraGain: Identifiable, Equatable {
    let id           = UUID()
    let pointsEarned: Int
    /// Optional label shown in the popup explaining why XP was earned (e.g. "🔥 7-Day Streak").
    let reason:       String?

    init(pointsEarned: Int, reason: String? = nil) {
        self.pointsEarned = pointsEarned
        self.reason       = reason
    }

    static func == (lhs: AuraGain, rhs: AuraGain) -> Bool {
        lhs.id == rhs.id && lhs.pointsEarned == rhs.pointsEarned
    }
}

// MARK: - Aura History Entry

struct AuraHistoryEntry: Codable, Identifiable {
    var id: String { "\(timestamp)-\(points)-\(reason)" }
    let points: Int
    let reason: String
    let timestamp: Double // timeIntervalSince1970

    var date: Date { Date(timeIntervalSince1970: timestamp) }
}

@MainActor @Observable final class UserSettings {

    // MARK: - Identity (in-memory only — populated by SessionManager from Firestore)

    /// True once populate(from:) has run and Firestore data (including achievedMilestones)
    /// has been restored. Guards against streak milestones re-firing before data is ready.
    var profileLoaded: Bool = false

    /// Timestamp of the last local settings save. Used to prevent populate(from:)
    /// from overwriting freshly-edited fields with stale Firestore data.
    var lastLocalSettingsSave: Date = .distantPast

    /// True once the user has consented to sending food photos to Anthropic's Claude AI.
    /// No AI features are available until this is true. Persisted to UserDefaults.
    var aiConsentGiven: Bool = false {
        didSet { UserDefaults.standard.set(aiConsentGiven, forKey: "aiConsentGiven") }
    }

    /// Identity fields are cached to UserDefaults via didSet so a failed
    /// Firestore fetch on the next launch doesn't leave the UI blank —
    /// the user sees their last-known values until populate(from:) runs.
    var userID:           String = "" {
        didSet { UserDefaults.standard.set(userID, forKey: "cached_userID") }
    }
    var username:         String = "" {
        didSet { UserDefaults.standard.set(username, forKey: "cached_username") }
    }
    var name:             String = "" {
        didSet { UserDefaults.standard.set(name, forKey: "cached_name") }
    }
    var location:         String = "" {
        didSet { UserDefaults.standard.set(location, forKey: "cached_location") }
    }
    var profilePhotoURL:  String = "" {
        didSet { UserDefaults.standard.set(profilePhotoURL, forKey: "cached_profilePhotoURL") }
    }
    var bio:              String = "" {
        didSet { UserDefaults.standard.set(bio, forKey: "cached_bio") }
    }
    var instagramHandle:  String = "" {
        didSet { UserDefaults.standard.set(instagramHandle, forKey: "cached_instagramHandle") }
    }
    var tiktokHandle:     String = "" {
        didSet { UserDefaults.standard.set(tiktokHandle, forKey: "cached_tiktokHandle") }
    }
    // Home gym — user's default workout location (stored as flat fields so
    // they can be written as a single Firestore merge). Empty `homeGymName`
    // = no home gym set.
    var homeGymName:      String = "" {
        didSet { UserDefaults.standard.set(homeGymName, forKey: "cached_homeGymName") }
    }
    var homeGymAddress:   String = "" {
        didSet { UserDefaults.standard.set(homeGymAddress, forKey: "cached_homeGymAddress") }
    }
    var homeGymLatitude:  Double = 0 {
        didSet { UserDefaults.standard.set(homeGymLatitude, forKey: "cached_homeGymLatitude") }
    }
    var homeGymLongitude: Double = 0 {
        didSet { UserDefaults.standard.set(homeGymLongitude, forKey: "cached_homeGymLongitude") }
    }

    /// Convenience accessor — rebuilds a `WorkoutLocation` from the flat
    /// fields, or nil when no home gym is set.
    var homeGym: WorkoutLocation? {
        guard !homeGymName.isEmpty else { return nil }
        return WorkoutLocation(name: homeGymName, address: homeGymAddress,
                               latitude: homeGymLatitude, longitude: homeGymLongitude)
    }
    var isPrivateAccount: Bool   = false {
        didSet { UserDefaults.standard.set(isPrivateAccount, forKey: "cached_isPrivateAccount") }
    }
    /// Date of birth as "yyyy-MM-dd". Empty string if not set.
    var dateOfBirth:      String = "" {
        didSet { UserDefaults.standard.set(dateOfBirth, forKey: "cached_dateOfBirth") }
    }

    /// Age in years derived from `dateOfBirth`. Returns 20 as a fallback.
    var ageInYears: Int {
        guard !dateOfBirth.isEmpty else { return 20 }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        guard let dob = fmt.date(from: dateOfBirth) else { return 20 }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 20
    }

    // MARK: - Body (cached to UserDefaults so stale values survive fetch failures)

    var currentWeight: Double = 160 {
        didSet { UserDefaults.standard.set(currentWeight, forKey: "cached_currentWeight") }
    }
    var goalWeight:    Double = 160 {
        didSet { UserDefaults.standard.set(goalWeight, forKey: "cached_goalWeight") }
    }
    var heightInches:  Int    = 0 {
        didSet { UserDefaults.standard.set(heightInches, forKey: "cached_heightInches") }
    }
    var proteinPerLb:  Double = 0.9 {
        didSet { UserDefaults.standard.set(proteinPerLb, forKey: "cached_proteinPerLb") }
    }
    /// "male", "female", or "" (not set). Used for Mifflin-St Jeor BMR calculation.
    var gender:        String = "" {
        didSet { UserDefaults.standard.set(gender, forKey: "cached_gender") }
    }

    // MARK: - Location

    /// When true, posts use the device's GPS-derived city instead of the profile location.
    var useGPSLocation: Bool = true {
        didSet { UserDefaults.standard.set(useGPSLocation, forKey: "useGPSLocation") }
    }

    /// Returns the location string to use on posts, respecting the GPS toggle.
    func postLocation(gpsCity: String) -> String {
        if useGPSLocation && !gpsCity.isEmpty { return gpsCity }
        return location
    }

    // MARK: - Dietary exclusions

    var excludeDairy: Bool = false {
        didSet { UserDefaults.standard.set(excludeDairy, forKey: "excludeDairy") }
    }
    var excludeGluten: Bool = false {
        didSet { UserDefaults.standard.set(excludeGluten, forKey: "excludeGluten") }
    }

    // MARK: - Fasting

    var fastingEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(fastingEnabled, forKey: "fastingEnabled")
            if fastingEnabled && fastingWindowNotificationEnabled {
                let hour   = UserDefaults.standard.integer(forKey: "windowStartHour")
                let minute = UserDefaults.standard.integer(forKey: "windowStartMinute")
                NotificationService.shared.scheduleFastingWindowNotification(
                    windowStartHour: hour, windowStartMinute: minute)
            } else {
                NotificationService.shared.cancelFastingWindowNotification()
            }
        }
    }

    /// Controls whether the "eating window closing in 90 minutes" push is scheduled.
    /// Only has an effect when `fastingEnabled` is also true.
    var fastingWindowNotificationEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(fastingWindowNotificationEnabled, forKey: "fastingWindowNotificationEnabled")
            if fastingEnabled && fastingWindowNotificationEnabled {
                let hour   = UserDefaults.standard.integer(forKey: "windowStartHour")
                let minute = UserDefaults.standard.integer(forKey: "windowStartMinute")
                NotificationService.shared.scheduleFastingWindowNotification(
                    windowStartHour: hour, windowStartMinute: minute)
            } else {
                NotificationService.shared.cancelFastingWindowNotification()
            }
        }
    }

    // MARK: - Meal Logging Reminder

    var mealReminderEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(mealReminderEnabled, forKey: "mealReminderEnabled")
            if mealReminderEnabled {
                NotificationService.shared.scheduleMealReminder(
                    hour: mealReminderHour, minute: mealReminderMinute)
            } else {
                NotificationService.shared.cancelMealReminder()
            }
        }
    }

    /// Hour component of the daily meal reminder (0-23). Default 12 (noon).
    var mealReminderHour: Int = 12 {
        didSet {
            UserDefaults.standard.set(mealReminderHour, forKey: "mealReminderHour")
            if mealReminderEnabled {
                NotificationService.shared.scheduleMealReminder(
                    hour: mealReminderHour, minute: mealReminderMinute)
            }
        }
    }

    /// Minute component of the daily meal reminder (0-59). Default 0.
    var mealReminderMinute: Int = 0 {
        didSet {
            UserDefaults.standard.set(mealReminderMinute, forKey: "mealReminderMinute")
            if mealReminderEnabled {
                NotificationService.shared.scheduleMealReminder(
                    hour: mealReminderHour, minute: mealReminderMinute)
            }
        }
    }

    // MARK: - Weigh-In Reminder

    var weighReminderEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(weighReminderEnabled, forKey: "weighReminderEnabled")
            if weighReminderEnabled {
                NotificationService.shared.scheduleWeighInReminder(
                    hour: weighReminderHour, minute: weighReminderMinute,
                    weekdays: weighReminderWeekdays)
            } else {
                NotificationService.shared.cancelWeighInReminder()
            }
        }
    }

    var weighReminderHour: Int = 7 {
        didSet {
            UserDefaults.standard.set(weighReminderHour, forKey: "weighReminderHour")
            if weighReminderEnabled {
                NotificationService.shared.scheduleWeighInReminder(
                    hour: weighReminderHour, minute: weighReminderMinute,
                    weekdays: weighReminderWeekdays)
            }
        }
    }

    var weighReminderMinute: Int = 0 {
        didSet {
            UserDefaults.standard.set(weighReminderMinute, forKey: "weighReminderMinute")
            if weighReminderEnabled {
                NotificationService.shared.scheduleWeighInReminder(
                    hour: weighReminderHour, minute: weighReminderMinute,
                    weekdays: weighReminderWeekdays)
            }
        }
    }

    /// Selected weekdays for weigh-in reminders (1 = Sun, 2 = Mon, … 7 = Sat).
    /// Stored as comma-separated ints in UserDefaults.
    var weighReminderWeekdays: Set<Int> = [2] {  // Default: Monday
        didSet {
            let raw = weighReminderWeekdays.sorted().map(String.init).joined(separator: ",")
            UserDefaults.standard.set(raw, forKey: "weighReminderWeekdays")
            if weighReminderEnabled {
                NotificationService.shared.scheduleWeighInReminder(
                    hour: weighReminderHour, minute: weighReminderMinute,
                    weekdays: weighReminderWeekdays)
            }
        }
    }

    // MARK: - Streak (Firestore is source of truth)

    /// Current running streak — read from Firestore, incremented when all 4 macros are met.
    var macroStreak: Int = 0 {
        didSet { UserDefaults.standard.set(macroStreak, forKey: "macroStreak") }
    }
    /// All-time best streak.
    var longestStreak: Int = 0 {
        didSet { UserDefaults.standard.set(longestStreak, forKey: "longestStreak") }
    }
    /// "yyyy-MM-dd" of the last day all macro goals were met. Used to detect streak breaks.
    var lastGoalsMetDate: String = "" {
        didSet { UserDefaults.standard.set(lastGoalsMetDate, forKey: "lastGoalsMetDate") }
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
            AppLogger.log("[UserSettings] Streak shield applied — restored to \(restored), shielded \(breakDate)")
        }
    }

    // MARK: - Cheat Day

    /// Dates where a cheat day was purchased. Treated as "goals met" for streak purposes.
    var cheatDayDates: [String] {
        get { UserDefaults.standard.stringArray(forKey: "cheatDayDates") ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: "cheatDayDates") }
    }

    /// Whether today has already been marked as a cheat day.
    var isTodayCheatDay: Bool {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let todayKey = fmt.string(from: Date())
        return cheatDayDates.contains(todayKey)
    }

    /// Applies a cheat day after a successful purchase.
    /// Marks today as "goals met" so the streak continues without logging food.
    func applyCheatDay(userID: String) {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let todayKey = fmt.string(from: Date())

        // Add today to cheat day dates
        var dates = cheatDayDates
        guard !dates.contains(todayKey) else { return }
        dates.append(todayKey)
        cheatDayDates = dates

        // Also add to shieldedDates so the streak engine counts today as met
        var shielded = shieldedDates
        if !shielded.contains(todayKey) { shielded.append(todayKey) }
        shieldedDates = shielded

        // Mark today as goals met so the streak chain isn't broken
        if lastGoalsMetDate < todayKey {
            lastGoalsMetDate = todayKey
        }

        // Increment streak if today hasn't already been counted
        let newStreak = macroStreak + 1
        macroStreak = newStreak
        if newStreak > longestStreak {
            longestStreak = newStreak
        }

        // Also record in the local goals-met cache
        setGoalsMet(true, for: Date())

        guard !userID.isEmpty else { return }
        let streak     = newStreak
        let longest    = longestStreak
        let allShielded = shielded
        let goalDate   = todayKey
        Task {
            try? await UserProfileService.shared.updateProfile(
                userID: userID,
                fields: [
                    "streakDays":       streak,
                    "longestStreak":    longest,
                    "lastGoalsMetDate": goalDate,
                    "shieldedDates":    allShielded,
                ]
            )
            AppLogger.log("[UserSettings] Cheat day applied for \(todayKey) — streak now \(streak)")
        }
    }

    // MARK: - Streak Extension (7-day)

    /// The date the current streak extension expires (stored as "yyyy-MM-dd").
    var streakExtensionExpiry: String {
        get { UserDefaults.standard.string(forKey: "streakExtensionExpiry") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "streakExtensionExpiry") }
    }

    /// Whether a streak extension is currently active.
    var isStreakExtensionActive: Bool {
        guard !streakExtensionExpiry.isEmpty else { return false }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        guard let expiry = fmt.date(from: streakExtensionExpiry) else { return false }
        return Calendar.current.startOfDay(for: Date()) <= expiry
    }

    /// Applies a 7-day streak extension after a successful purchase.
    /// Shields the next 7 days so the streak continues without logging.
    func applyStreakExtension(userID: String) {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Shield the next 7 days (today + 6 more)
        var shielded = shieldedDates
        for dayOffset in 0..<7 {
            guard let date = cal.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let key = fmt.string(from: date)
            if !shielded.contains(key) { shielded.append(key) }
        }
        shieldedDates = shielded

        // Set the expiry date (6 days from today = 7th day inclusive)
        let expiryDate = cal.date(byAdding: .day, value: 6, to: today) ?? today
        streakExtensionExpiry = fmt.string(from: expiryDate)

        // Mark today as goals met
        let todayKey = fmt.string(from: today)
        if lastGoalsMetDate < todayKey {
            lastGoalsMetDate = todayKey
        }

        // Increment streak for today if not already counted
        let newStreak = macroStreak + 1
        macroStreak = newStreak
        if newStreak > longestStreak {
            longestStreak = newStreak
        }
        setGoalsMet(true, for: Date())

        // Schedule expiration notification
        NotificationService.shared.scheduleStreakExtensionExpiry(daysFromNow: 6)

        // Sync to Firestore
        guard !userID.isEmpty else { return }
        let streak  = newStreak
        let longest = longestStreak
        let allShielded = shielded
        let goalDate = todayKey
        Task {
            try? await UserProfileService.shared.updateProfile(
                userID: userID,
                fields: [
                    "streakDays":       streak,
                    "longestStreak":    longest,
                    "lastGoalsMetDate": goalDate,
                    "shieldedDates":    allShielded,
                ]
            )
            AppLogger.log("[UserSettings] Streak extension applied — 7 days shielded, streak now \(streak)")
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

    // MARK: - Food Scan Daily Limit

    private static let scanDailyLimit = 15

    private var scanUsageCount: Int = 0 {
        didSet { UserDefaults.standard.set(scanUsageCount, forKey: "scanUsageCount") }
    }
    private var scanUsageDate: Date = .distantPast {
        didSet { UserDefaults.standard.set(scanUsageDate.timeIntervalSince1970, forKey: "scanUsageDate") }
    }

    var scanUsesRemaining: Int {
        resetScanIfNewDay()
        return max(0, UserSettings.scanDailyLimit - scanUsageCount)
    }

    var scanLimitReached: Bool { scanUsesRemaining == 0 }

    /// Returns true if a use was successfully consumed, false if limit already reached.
    @discardableResult
    func consumeScanUse() -> Bool {
        resetScanIfNewDay()
        guard scanUsageCount < UserSettings.scanDailyLimit else { return false }
        scanUsageCount += 1
        return true
    }

    private func resetScanIfNewDay() {
        if !Calendar.current.isDateInToday(scanUsageDate) {
            scanUsageCount = 0
            scanUsageDate  = Date()
        }
    }

    // MARK: - Aura (identity points cached; weekly/leaderboard fields device-local)

    var auraPoints: Int = 0 {
        didSet { UserDefaults.standard.set(auraPoints, forKey: "cached_auraPoints") }
    }
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
    /// Set by populate(from:) when the Cloud Function tagged this user as a weekly arena winner.
    /// Observed by LeaderboardView to trigger the winner popup.
    var pendingWeeklyWinnerRank: Int? = nil
    /// XP awarded for the pending arena winner finish.
    var pendingWeeklyWinnerXP:   Int  = 0
    /// "YYYY-MM-DD" of the last weekly reset for which a local winner award was already claimed.
    var lastClaimedLocalWinnerWeek: String = "" {
        didSet { UserDefaults.standard.set(lastClaimedLocalWinnerWeek, forKey: "lastClaimedLocalWinnerWeek") }
    }
    /// Set by populate(from:) when the Cloud Function tagged this user as a local weekly winner.
    var pendingLocalWinnerRank: Int? = nil
    /// XP awarded for the pending local winner finish.
    var pendingLocalWinnerXP:   Int  = 0
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

    /// Whether to include current/goal weight on posts (goal, fuel log, workout).
    var showWeightOnPosts: Bool = true {
        didSet { UserDefaults.standard.set(showWeightOnPosts, forKey: "showWeightOnPosts") }
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
    var auraPopupsEnabled: Bool = true {
        didSet { UserDefaults.standard.set(auraPopupsEnabled, forKey: "cached_auraPopupsEnabled") }
    }
    /// Set whenever points are awarded (when popups enabled). Observe to show popup.
    var pendingAuraGain: AuraGain? = nil
    /// Set whenever all macro goals are met for the first time today. Observe to show celebration.
    var pendingCelebration: CelebrationPostData? = nil
    /// Set when a Firestore write fails. Observed by ContentView to surface an alert.
    var firestoreError: String? = nil

    // MARK: - Aura Level Curve
    //
    // Quadratic: perLevel(n) = a + (n-1)*d, cumulative threshold is the sum.
    // Anchors: threshold(2) = 75, threshold(100) = 100,000.
    // Incremental cost grows from 75 XP (Lv 1→2) to ~1,932 XP (Lv 99→100).

    /// Cumulative aura points required to *reach* `level` (0–100).
    ///
    /// Per-level cost starts at 75 XP (level 1→2) and increases by ~19.08 XP
    /// each level, so every level always costs more than the one before it.
    /// Anchors: threshold(1) = 0, threshold(2) = 75, threshold(100) = 100,000.
    /// Early levels are intentionally cheap; the curve steepens significantly at higher levels.
    static func auraThreshold(_ level: Int) -> Int {
        guard level > 1   else { return 0 }
        guard level < 100 else { return 100_000 }
        let n = Double(level)
        // perLevel(n) = a + (n-1)*d  →  threshold(n) = (n-1)*a + d*(n-1)*(n-2)/2
        // Anchors: threshold(2)=75 → a=75; threshold(100)=100,000 → d=92,575/4,851
        let a = 75.0
        let d = 92_575.0 / 4_851.0
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

    func awardAura(points: Int, silent: Bool = false, reason: String? = nil) {
        checkWeeklyReset()
        auraPoints += points
        weeklyAuraPoints += points
        pendingAuraGain = AuraGain(pointsEarned: points, reason: reason)
        Self.logAuraHistory(points: points, reason: reason ?? Self.inferReason(points: points))
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
                AppLogger.log("[UserSettings] awardAura: synced +\(points) xp (total \(pts), weekly \(wkPts))")
            } catch {
                let msg = error.localizedDescription
                AppLogger.log("[UserSettings] awardAura Firestore error: \(msg)")
                await MainActor.run { self.firestoreError = "XP sync failed: \(msg)" }
            }
        }
    }

    // MARK: - Aura History

    private static let auraHistoryKey = "auraHistory"
    private static let maxHistoryEntries = 50

    private static func inferReason(points: Int) -> String {
        switch points {
        case 50:  return "Hit all macro goals"
        case 25:  return "Posted a workout"
        case 5:   return "Logged with photo"
        case 1:   return "Engagement"
        default:  return "+\(points) XP"
        }
    }

    static func logAuraHistory(points: Int, reason: String) {
        var history = loadAuraHistory()
        let entry = AuraHistoryEntry(
            points: points,
            reason: reason,
            timestamp: Date().timeIntervalSince1970
        )
        history.insert(entry, at: 0)
        if history.count > maxHistoryEntries {
            history = Array(history.prefix(maxHistoryEntries))
        }
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: auraHistoryKey)
        }
    }

    static func loadAuraHistory() -> [AuraHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: auraHistoryKey),
              let history = try? JSONDecoder().decode([AuraHistoryEntry].self, from: data)
        else { return [] }
        return history
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
        // Persist to Firestore so milestones survive reinstalls / device switches
        let uid = userID
        let raw = achievedMilestonesRaw
        guard !uid.isEmpty else { return }
        Task {
            try? await UserProfileService.shared.updateProfile(
                userID: uid, fields: ["achievedMilestones": raw])
        }
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
        // Cache userID to Keychain so background tasks can access it without the auth stack
        KeychainService.set(profile.userID, forKey: "cachedUserID")
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
        // Skip overwriting body/nutrition fields if the user just saved
        // settings locally — the Firestore document may still have stale
        // data from before the write landed.
        let recentlySaved = Date().timeIntervalSince(lastLocalSettingsSave) < 10
        if !recentlySaved {
            currentWeight     = profile.currentWeight
            goalWeight        = profile.goalWeight
            heightInches      = profile.heightInches
            proteinPerLb      = profile.proteinPerLb
            gender            = profile.gender
        }
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
        excludeDairy      = profile.excludeDairy
        excludeGluten     = profile.excludeGluten
        autoAdjustMacrosForWorkout = profile.autoAdjustMacrosForWorkout
        showWeightOnPosts          = profile.showWeightOnPosts
        aiConsentGiven             = profile.aiConsentGiven
        mealReminderEnabled        = profile.mealReminderEnabled
        mealReminderHour           = profile.mealReminderHour
        mealReminderMinute         = profile.mealReminderMinute
        fastingWindowNotificationEnabled = profile.fastingWindowNotificationEnabled
        // Sync accent color from Firestore so a fresh device picks up the
        // user's previous choice. Empty string = never-set → leave whatever
        // UserDefaults had (or the default purple for a brand-new install).
        if !profile.accentColor.isEmpty {
            Task { @MainActor in
                ThemeStore.shared.applyRemoteAccent(profile.accentColor)
            }
        }
        // Sync home gym from Firestore.
        homeGymName      = profile.homeGymName
        homeGymAddress   = profile.homeGymAddress
        homeGymLatitude  = profile.homeGymLatitude
        homeGymLongitude = profile.homeGymLongitude
        // Merge achieved milestones from Firestore with any local values
        if !profile.achievedMilestones.isEmpty {
            var local = achievedMilestones   // existing local Set<Int>
            let remote = Set(profile.achievedMilestones.split(separator: ",").compactMap { Int($0) })
            local.formUnion(remote)
            achievedMilestonesRaw = local.map { String($0) }.joined(separator: ",")
        }
        auraPoints        = profile.auraPoints
        // Restore streak from Firestore (source of truth)
        macroStreak       = profile.streakDays
        longestStreak     = max(longestStreak, profile.longestStreak)
        if profile.lastGoalsMetDate > lastGoalsMetDate {
            lastGoalsMetDate = profile.lastGoalsMetDate
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

        // Check for pending arena winner award set by the Cloud Function.
        if profile.weeklyWinnerXP > 0 && profile.weeklyWinnerWeek != lastClaimedWinnerWeek {
            lastClaimedWinnerWeek   = profile.weeklyWinnerWeek
            pendingWeeklyWinnerRank = profile.weeklyWinnerRank
            pendingWeeklyWinnerXP   = profile.weeklyWinnerXP
            auraPoints              = profile.auraPoints   // Cloud Function already incremented
            let uid = profile.userID
            Task {
                try? await UserProfileService.shared.updateProfile(
                    userID: uid,
                    fields: ["weeklyWinnerRank": 0, "weeklyWinnerXP": 0, "weeklyWinnerWeek": ""])
            }
        }

        // Check for pending local winner award set by the Cloud Function.
        if profile.localWinnerXP > 0 && profile.localWinnerWeek != lastClaimedLocalWinnerWeek {
            lastClaimedLocalWinnerWeek = profile.localWinnerWeek
            pendingLocalWinnerRank     = profile.localWinnerRank
            pendingLocalWinnerXP       = profile.localWinnerXP
            auraPoints                 = profile.auraPoints   // Cloud Function already incremented
            let uid = profile.userID
            Task {
                try? await UserProfileService.shared.updateProfile(
                    userID: uid,
                    fields: ["localWinnerRank": 0, "localWinnerXP": 0, "localWinnerWeek": ""])
            }
        }

        profileLoaded = true
    }

    /// Called by SessionManager on sign-out.
    /// Clears all identity fields AND all device-local UserDefaults state so a
    /// new user on the same device starts completely fresh.
    func clearProfile() {
        profileLoaded     = false
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
        longestStreak         = 0
        lastGoalsMetDate      = ""
        lastStreakBeforeBreak = 0
        streakBreakDate       = ""
        shieldedDates         = []
        cheatDayDates         = []
        goalsMetDatesRaw      = ""
        achievedMilestonesRaw = ""
        lastCelebrationDate   = .distantPast

        // Aura / leaderboard
        weeklyAuraPoints         = 0
        weeklyAuraWeekStart      = .distantPast
        lastClaimedWinnerWeek      = ""
        pendingWeeklyWinnerRank    = nil
        pendingWeeklyWinnerXP      = 0
        lastClaimedLocalWinnerWeek = ""
        pendingLocalWinnerRank     = nil
        pendingLocalWinnerXP       = 0

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
            // cachedUserID is in Keychain, cleared separately below
            // Tutorial flags — reset so a new account gets all tutorials
            "hasSeenAppTour",
            "hasSeenProfileTutorial",
            // Identity cache (written via didSet on profile identity fields) —
            // must be wiped on logout so the next user on this device starts fresh.
            "cached_userID", "cached_username", "cached_name", "cached_location",
            "cached_profilePhotoURL", "cached_bio", "cached_instagramHandle",
            "cached_tiktokHandle", "cached_isPrivateAccount", "cached_dateOfBirth",
            "cached_homeGymName", "cached_homeGymAddress",
            "cached_homeGymLatitude", "cached_homeGymLongitude",
            "cached_currentWeight", "cached_goalWeight", "cached_heightInches",
            "cached_proteinPerLb", "cached_gender", "cached_auraPoints",
            "cached_auraPopupsEnabled",
            // aiConsentGiven intentionally NOT cleared — consent is per-device, not per-account
        ] { ud.removeObject(forKey: key) }

        // Clear Keychain
        KeychainService.delete(key: "cachedUserID")

        // Clear URL, Firestore, and in-memory image caches so the next user starts fresh
        URLCache.shared.removeAllCachedResponses()
        ImageCache.shared.removeAll()
    }

    // MARK: - Init

    init() {
        // Restore cached identity fields from UserDefaults so the UI shows
        // the user's last-known name/username/photo/weights immediately on
        // launch, even if the Firestore fetch in SessionManager is still
        // pending or fails transiently. populate(from:) overwrites these
        // once the fresh profile arrives.
        let ud = UserDefaults.standard
        self.userID           = ud.string(forKey: "cached_userID")           ?? ""
        self.username         = ud.string(forKey: "cached_username")         ?? ""
        self.name             = ud.string(forKey: "cached_name")             ?? ""
        self.location         = ud.string(forKey: "cached_location")         ?? ""
        self.profilePhotoURL  = ud.string(forKey: "cached_profilePhotoURL")  ?? ""
        self.bio              = ud.string(forKey: "cached_bio")              ?? ""
        self.instagramHandle  = ud.string(forKey: "cached_instagramHandle")  ?? ""
        self.tiktokHandle     = ud.string(forKey: "cached_tiktokHandle")     ?? ""
        self.homeGymName      = ud.string(forKey: "cached_homeGymName")      ?? ""
        self.homeGymAddress   = ud.string(forKey: "cached_homeGymAddress")   ?? ""
        self.homeGymLatitude  = ud.double(forKey: "cached_homeGymLatitude")
        self.homeGymLongitude = ud.double(forKey: "cached_homeGymLongitude")
        self.isPrivateAccount = ud.bool(forKey: "cached_isPrivateAccount")
        self.dateOfBirth      = ud.string(forKey: "cached_dateOfBirth")      ?? ""
        // Body metrics — fall back to existing defaults when no cache exists
        self.currentWeight = ud.object(forKey: "cached_currentWeight") != nil
            ? ud.double(forKey: "cached_currentWeight") : 160
        self.goalWeight    = ud.object(forKey: "cached_goalWeight") != nil
            ? ud.double(forKey: "cached_goalWeight")    : 160
        self.heightInches  = ud.integer(forKey: "cached_heightInches")
        self.proteinPerLb  = ud.object(forKey: "cached_proteinPerLb") != nil
            ? ud.double(forKey: "cached_proteinPerLb")  : 0.9
        self.gender        = ud.string(forKey: "cached_gender")        ?? ""
        self.auraPoints    = ud.integer(forKey: "cached_auraPoints")
        self.auraPopupsEnabled = ud.object(forKey: "cached_auraPopupsEnabled") != nil
            ? ud.bool(forKey: "cached_auraPopupsEnabled") : true

        self.autoAdjustMacrosForWorkout = UserDefaults.standard.bool(forKey: "autoAdjustMacrosForWorkout")
        self.weeklyAuraPoints = UserDefaults.standard.integer(forKey: "weeklyAuraPoints")
        let storedWeekStart = UserDefaults.standard.double(forKey: "weeklyAuraWeekStart")
        self.weeklyAuraWeekStart = storedWeekStart > 0
            ? Date(timeIntervalSince1970: storedWeekStart) : .distantPast
        self.useGPSLocation = UserDefaults.standard.object(forKey: "useGPSLocation") == nil
            ? true : UserDefaults.standard.bool(forKey: "useGPSLocation")
        self.aiConsentGiven = UserDefaults.standard.bool(forKey: "aiConsentGiven")
        // Default to true when the key has never been written — existing users
        // keep the notification they've always had unless they explicitly turn it off.
        self.fastingWindowNotificationEnabled = UserDefaults.standard.object(forKey: "fastingWindowNotificationEnabled") == nil
            ? true : UserDefaults.standard.bool(forKey: "fastingWindowNotificationEnabled")
        self.mealReminderEnabled = UserDefaults.standard.bool(forKey: "mealReminderEnabled")
        let storedReminderHour = UserDefaults.standard.object(forKey: "mealReminderHour")
        self.mealReminderHour = storedReminderHour != nil
            ? UserDefaults.standard.integer(forKey: "mealReminderHour") : 12
        self.mealReminderMinute = UserDefaults.standard.integer(forKey: "mealReminderMinute")
        self.weighReminderEnabled = UserDefaults.standard.bool(forKey: "weighReminderEnabled")
        let storedWeighHour = UserDefaults.standard.object(forKey: "weighReminderHour")
        self.weighReminderHour = storedWeighHour != nil
            ? UserDefaults.standard.integer(forKey: "weighReminderHour") : 7
        self.weighReminderMinute = UserDefaults.standard.integer(forKey: "weighReminderMinute")
        if let rawDays = UserDefaults.standard.string(forKey: "weighReminderWeekdays"), !rawDays.isEmpty {
            self.weighReminderWeekdays = Set(rawDays.split(separator: ",").compactMap { Int($0) })
        }
        self.excludeDairy  = UserDefaults.standard.bool(forKey: "excludeDairy")
        self.excludeGluten = UserDefaults.standard.bool(forKey: "excludeGluten")
        self.autoAdjustMacrosForWorkout = UserDefaults.standard.bool(forKey: "autoAdjustMacrosForWorkout")
        self.showWeightOnPosts = UserDefaults.standard.object(forKey: "showWeightOnPosts") == nil
            ? true : UserDefaults.standard.bool(forKey: "showWeightOnPosts")
        self.achievedMilestonesRaw = UserDefaults.standard.string(forKey: "achievedMilestones") ?? ""
        let storedCelebDate = UserDefaults.standard.double(forKey: "lastCelebrationDate")
        self.lastCelebrationDate = storedCelebDate > 0
            ? Date(timeIntervalSince1970: storedCelebDate) : .distantPast
        self.goalsMetDatesRaw      = UserDefaults.standard.string(forKey: "goalsMetDates") ?? ""
        self.macroStreak           = UserDefaults.standard.integer(forKey: "macroStreak")
        self.longestStreak         = UserDefaults.standard.integer(forKey: "longestStreak")
        self.lastGoalsMetDate      = UserDefaults.standard.string(forKey: "lastGoalsMetDate") ?? ""
        self.lastStreakBeforeBreak  = UserDefaults.standard.integer(forKey: "lastStreakBeforeBreak")
        self.streakBreakDate        = UserDefaults.standard.string(forKey: "streakBreakDate") ?? ""
        self.brainstormUsageCount  = UserDefaults.standard.integer(forKey: "brainstormUsageCount")
        let storedBSDate = UserDefaults.standard.double(forKey: "brainstormUsageDate")
        self.brainstormUsageDate   = storedBSDate > 0
            ? Date(timeIntervalSince1970: storedBSDate) : .distantPast
        self.lastClaimedWinnerWeek      = UserDefaults.standard.string(forKey: "lastClaimedWinnerWeek") ?? ""
        self.lastClaimedLocalWinnerWeek = UserDefaults.standard.string(forKey: "lastClaimedLocalWinnerWeek") ?? ""
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
