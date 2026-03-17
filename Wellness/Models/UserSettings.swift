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
    var instagramHandle:  String = ""
    var tiktokHandle:     String = ""
    var isPrivateAccount: Bool   = false

    // MARK: - Body (in-memory only)

    var currentWeight: Double = 160
    var goalWeight:    Double = 160
    var proteinPerLb:  Double = 0.9

    // MARK: - Fasting (side-effect only, no UserDefaults write)

    var fastingEnabled: Bool = false {
        didSet {
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

    /// Current macro streak — kept in sync by HomeViewModel so LeaderboardView can read it.
    var macroStreak: Int = 0 {
        didSet { UserDefaults.standard.set(macroStreak, forKey: "macroStreak") }
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
    /// The Sunday 11:59 PM EST cutoff on which leaderboard points were last awarded.
    private var lastLeaderboardAwardDate: Date = Date.distantPast {
        didSet { UserDefaults.standard.set(lastLeaderboardAwardDate.timeIntervalSince1970, forKey: "lastLeaderboardAwardDate") }
    }
    /// Comma-separated streak milestones already awarded, e.g. "3,7,14"
    private var achievedMilestonesRaw: String = "" {
        didSet { UserDefaults.standard.set(achievedMilestonesRaw, forKey: "achievedMilestones") }
    }
    /// Comma-separated "yyyy-MM-dd" dates on which ALL macro goals were met.
    private var goalsMetDatesRaw: String = "" {
        didSet { UserDefaults.standard.set(goalsMetDatesRaw, forKey: "goalsMetDates") }
    }
    /// The calendar date on which the macro-goals celebration was last shown (once per day).
    var lastCelebrationDate: Date = .distantPast {
        didSet { UserDefaults.standard.set(lastCelebrationDate.timeIntervalSince1970, forKey: "lastCelebrationDate") }
    }

    var goalsMetDates: Set<String> {
        Set(goalsMetDatesRaw.split(separator: ",").map { String($0) })
    }

    /// Records or removes a date from the goals-met set.
    /// Call this whenever the daily totals are reloaded so the set stays accurate.
    func setGoalsMet(_ met: Bool, for date: Date) {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let key = fmt.string(from: date)
        var dates = goalsMetDates
        if met { dates.insert(key) } else { dates.remove(key) }
        goalsMetDatesRaw = dates.joined(separator: ",")
    }

    /// Whether to show the aura gain popup when points are earned.
    var auraPopupsEnabled: Bool = true
    /// Set whenever points are awarded (when popups enabled). Observe to show popup.
    var pendingAuraGain: AuraGain? = nil

    // MARK: Computed aura properties

    var auraLevel: Int { min(auraPoints / 1000, 100) }

    var auraTitle: String {
        switch auraLevel {
        case 0:       return ""
        case 1...9:   return "Initiate"
        case 10...24: return "Disciple"
        case 25...39: return "Ascender"
        case 40...59: return "Mog Apprentice"
        case 60...79: return "Aura Farmer"
        case 80...94: return "Elite Aesthetic"
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
        let id  = userID
        let pts = auraPoints
        Task {
            try? await UserProfileService.shared.updateProfile(
                userID: id,
                fields: ["auraPoints": pts]
            )
        }
    }

    func checkWeeklyReset() {
        let start = UserSettings.currentWeekStart()
        if start > weeklyAuraWeekStart {
            weeklyAuraPoints    = 0
            weeklyAuraWeekStart = start
        }
    }

    static func currentWeekStart() -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Monday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return cal.date(from: comps) ?? cal.startOfDay(for: Date())
    }

    /// True when Sunday 11:59 PM EST has passed but leaderboard points haven't been awarded yet.
    var hasUnclaimedLeaderboardAward: Bool {
        guard let cutoff = UserSettings.lastSundayAwardCutoff() else { return false }
        return cutoff > lastLeaderboardAwardDate
    }

    /// The most recent Sunday at 11:59 PM EST that has already passed.
    static func lastSundayAwardCutoff() -> Date? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        let now = Date()
        // weekday: 1 = Sunday, 2 = Monday … 7 = Saturday
        let weekday = cal.component(.weekday, from: now)
        let daysSinceSunday = weekday - 1
        guard let lastSunday = cal.date(byAdding: .day, value: -daysSinceSunday, to: now) else { return nil }
        var comps = cal.dateComponents([.year, .month, .day], from: lastSunday)
        comps.hour = 23; comps.minute = 59; comps.second = 0
        comps.timeZone = TimeZone(identifier: "America/New_York")
        guard let cutoff = cal.date(from: comps) else { return nil }
        // If that cutoff hasn't passed yet (it's still before Sunday 11:59 PM), go back one week
        return cutoff > now ? cal.date(byAdding: .weekOfYear, value: -1, to: cutoff) : cutoff
    }

    /// Awards leaderboard placement points based on ranks (1-indexed, nil = not in top 10).
    /// Marks the current Sunday cutoff as claimed so it only fires once per week.
    func awardLeaderboardPoints(localRank: Int?, arenaRank: Int?) {
        guard hasUnclaimedLeaderboardAward,
              let cutoff = UserSettings.lastSundayAwardCutoff() else { return }
        lastLeaderboardAwardDate = cutoff

        var total = 0
        if let rank = localRank, rank <= 10 {
            switch rank {
            case 1:     total += 75
            case 2...3: total += 50
            default:    total += 25
            }
        }
        if let rank = arenaRank, rank <= 10 {
            switch rank {
            case 1:     total += 150
            case 2...3: total += 100
            default:    total += 50
            }
        }
        if total > 0 { awardAura(points: total) }
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
            let url = UserSettings.profileImageURL
            if let data = profileImageData { try? data.write(to: url) }
            else { try? FileManager.default.removeItem(at: url) }
        }
    }
    static let profileImageURL: URL =
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_image.jpg")

    // MARK: - SessionManager integration

    /// Called by SessionManager after a successful Firestore profile fetch.
    /// Populates all identity fields in-memory. Does NOT touch UserDefaults.
    func populate(from profile: UserProfile) {
        userID            = profile.userID ?? ""
        username          = profile.username
        name              = profile.name
        location          = profile.location
        instagramHandle   = profile.instagramHandle
        tiktokHandle      = profile.tiktokHandle
        isPrivateAccount  = profile.isPrivateAccount
        currentWeight     = profile.currentWeight
        goalWeight        = profile.goalWeight
        proteinPerLb      = profile.proteinPerLb
        fastingEnabled    = profile.fastingEnabled
        auraPopupsEnabled = profile.auraPopupsEnabled
        auraPoints        = profile.auraPoints
        macroStreak       = profile.streakDays
    }

    /// Called by SessionManager on sign-out. Clears all identity fields.
    func clearProfile() {
        userID            = ""
        username          = ""
        name              = ""
        location          = ""
        instagramHandle   = ""
        tiktokHandle      = ""
        isPrivateAccount  = false
        currentWeight     = 160
        goalWeight        = 160
        proteinPerLb      = 0.9
        fastingEnabled    = false
        auraPopupsEnabled = true
        auraPoints        = 0
        profileImageData  = nil
        macroStreak       = 0
    }

    // MARK: - Init

    init() {
        // Restore only device-local tracking fields from UserDefaults.
        // Profile identity fields start at their zero/default values —
        // they will be set by populate(from:) after SessionManager resolves auth.

        self.weeklyAuraPoints = UserDefaults.standard.integer(forKey: "weeklyAuraPoints")
        let storedWeekStart = UserDefaults.standard.double(forKey: "weeklyAuraWeekStart")
        self.weeklyAuraWeekStart = storedWeekStart > 0
            ? Date(timeIntervalSince1970: storedWeekStart) : .distantPast
        let storedLBDate = UserDefaults.standard.double(forKey: "lastLeaderboardAwardDate")
        self.lastLeaderboardAwardDate = storedLBDate > 0
            ? Date(timeIntervalSince1970: storedLBDate) : .distantPast
        self.achievedMilestonesRaw = UserDefaults.standard.string(forKey: "achievedMilestones") ?? ""
        self.goalsMetDatesRaw      = UserDefaults.standard.string(forKey: "goalsMetDates") ?? ""
        let storedCelebDate = UserDefaults.standard.double(forKey: "lastCelebrationDate")
        self.lastCelebrationDate = storedCelebDate > 0
            ? Date(timeIntervalSince1970: storedCelebDate) : .distantPast
        self.macroStreak           = UserDefaults.standard.integer(forKey: "macroStreak")
        self.brainstormUsageCount  = UserDefaults.standard.integer(forKey: "brainstormUsageCount")
        let storedBSDate = UserDefaults.standard.double(forKey: "brainstormUsageDate")
        self.brainstormUsageDate   = storedBSDate > 0
            ? Date(timeIntervalSince1970: storedBSDate) : .distantPast
        self.lastBrainstormResult  = UserDefaults.standard.string(forKey: "lastBrainstormResult") ?? ""
        let storedBSResultDate = UserDefaults.standard.double(forKey: "lastBrainstormDate")
        self.lastBrainstormDate    = storedBSResultDate > 0
            ? Date(timeIntervalSince1970: storedBSResultDate) : .distantPast
        self.profileImageData = try? Data(contentsOf: UserSettings.profileImageURL)
    }
}
