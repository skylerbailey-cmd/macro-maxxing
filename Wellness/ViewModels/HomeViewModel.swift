//
//  HomeViewModel.swift
//  Wellness
//

import Foundation
import FirebaseFirestore

@MainActor @Observable final class HomeViewModel {
    // MARK: - Selected date
    var selectedDate: Date {
        didSet {
            if !Calendar.current.isDate(selectedDate, inSameDayAs: oldValue) {
                loadTodayTotals()
            }
        }
    }

    // MARK: - User settings (shared reference)
    let userSettings: UserSettings

    // MARK: - Fasting window (persisted — always today's editable values)
    var windowStartHour: Int {
        didSet {
            UserDefaults.standard.set(windowStartHour, forKey: "windowStartHour")
            snapshotTodayWindow()
            saveWindowToFirestore()
            if userSettings.fastingEnabled && userSettings.fastingWindowNotificationEnabled {
                NotificationService.shared.scheduleFastingWindowNotification(
                    windowStartHour: windowStartHour, windowStartMinute: windowStartMinute)
            }
        }
    }
    var windowStartMinute: Int {
        didSet {
            UserDefaults.standard.set(windowStartMinute, forKey: "windowStartMinute")
            snapshotTodayWindow()
            saveWindowToFirestore()
            if userSettings.fastingEnabled && userSettings.fastingWindowNotificationEnabled {
                NotificationService.shared.scheduleFastingWindowNotification(
                    windowStartHour: windowStartHour, windowStartMinute: windowStartMinute)
            }
        }
    }
    var windowDurationHours: Int {
        didSet {
            UserDefaults.standard.set(windowDurationHours, forKey: "windowDurationHours")
            snapshotTodayWindow()
            saveWindowToFirestore()
        }
    }

    var isSelectedDateToday: Bool { Calendar.current.isDateInToday(selectedDate) }

    // MARK: - Per-date window snapshots
    // Displayed properties return the snapshot for past dates, live values for today.
    // Past dates with no snapshot return 0/0/0 — callers should check hasWindowForSelectedDate first.
    var displayedWindowStartHour:   Int { windowForDisplayedDate["startHour"]     ?? windowStartHour }
    var displayedWindowStartMinute: Int { windowForDisplayedDate["startMinute"]   ?? windowStartMinute }
    var displayedWindowDuration:    Int { windowForDisplayedDate["durationHours"] ?? windowDurationHours }

    private var windowForDisplayedDate: [String: Int] {
        if isSelectedDateToday { return ["startHour": windowStartHour, "startMinute": windowStartMinute, "durationHours": windowDurationHours] }
        // Use snapshot if one exists; fall back to current setting for dates before snapshots existed
        return dailyWindowSnapshots[dateKey(selectedDate)] ?? ["startHour": windowStartHour, "startMinute": windowStartMinute, "durationHours": windowDurationHours]
    }

    private var dailyWindowSnapshots: [String: [String: Int]] {
        get {
            guard let outer = UserDefaults.standard.dictionary(forKey: "dailyWindowSnapshots") else { return [:] }
            // UserDefaults stores Int as NSNumber, so cast each value explicitly
            var result: [String: [String: Int]] = [:]
            for (dateKey, value) in outer {
                guard let inner = value as? [String: Any] else { continue }
                var innerInts: [String: Int] = [:]
                for (k, v) in inner {
                    if let i = v as? Int { innerInts[k] = i }
                    else if let n = v as? NSNumber { innerInts[k] = n.intValue }
                }
                result[dateKey] = innerInts
            }
            return result
        }
        set { UserDefaults.standard.set(newValue, forKey: "dailyWindowSnapshots") }
    }

    func snapshotTodayWindow() {
        let key = dateKey(Date())
        var snapshots = dailyWindowSnapshots
        snapshots[key] = ["startHour": windowStartHour, "startMinute": windowStartMinute, "durationHours": windowDurationHours]
        dailyWindowSnapshots = snapshots
    }

    private func saveWindowToFirestore() {
        let uid = userSettings.userID
        guard !uid.isEmpty else { return }
        Task {
            try? await UserProfileService.shared.updateProfile(
                userID: uid,
                fields: [
                    "windowStartHour":     windowStartHour,
                    "windowStartMinute":   windowStartMinute,
                    "windowDurationHours": windowDurationHours
                ]
            )
        }
    }

    private static let dateKeyFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt
    }()

    private func dateKey(_ date: Date) -> String {
        Self.dateKeyFormatter.string(from: date)
    }

    var windowEndHour: Int {
        let totalMinutes = displayedWindowStartHour * 60 + displayedWindowStartMinute + displayedWindowDuration * 60
        return (totalMinutes / 60) % 24
    }
    var windowEndMinute: Int {
        let totalMinutes = displayedWindowStartHour * 60 + displayedWindowStartMinute + displayedWindowDuration * 60
        return totalMinutes % 60
    }
    var windowStartFractional: Double { Double(displayedWindowStartHour) + Double(displayedWindowStartMinute) / 60.0 }
    var windowEndFractional: Double   { windowStartFractional + Double(displayedWindowDuration) }

    // MARK: - Historical goals (loaded from Firestore for past dates)
    /// Non-nil when a past date is selected and a saved snapshot was found.
    private var historicalGoals: (calories: Double, protein: Double, carbs: Double, fat: Double)? = nil

    // MARK: - Debounce for loadTodayTotals
    /// Coalesces rapid calls (notification + onAppear + scenePhase) into a single load.
    private var loadTotalsTask: Task<Void, Never>?

    // MARK: - Today's macro totals (for selectedDate)
    var totalCalories: Double = 0
    var totalProtein:  Double = 0
    var totalCarbs:    Double = 0
    var totalFat:      Double = 0

    // MARK: - Meal log times for today (fractional hours, e.g. 12.5 = 12:30)
    var mealLogTimes: [Double] = []

    // MARK: - Macro goals (persisted)
    var goalCalories: Double = 2000 {
        didSet { UserDefaults.standard.set(goalCalories, forKey: "goalCalories") }
    }
    var goalProtein: Double = 150 {
        didSet { UserDefaults.standard.set(goalProtein, forKey: "goalProtein") }
    }
    var goalCarbs: Double = 200 {
        didSet { UserDefaults.standard.set(goalCarbs, forKey: "goalCarbs") }
    }
    var goalFat: Double = 65 {
        didSet { UserDefaults.standard.set(goalFat, forKey: "goalFat") }
    }

    // MARK: - Macros met today (computed from totals vs goals)
    /// True/false for [calories, protein, carbs, fat]
    var macroGoalsMet: [Bool] {
        guard totalCalories > 0 else { return [false, false, false, false] }
        return [
            totalCalories >= goalCalories * 0.85 && totalCalories <= goalCalories * 1.15,
            totalProtein  >= goalProtein  * 0.85 && totalProtein  <= goalProtein  * 1.15,
            totalCarbs    >= goalCarbs    * 0.85 && totalCarbs    <= goalCarbs    * 1.15,
            totalFat      >= goalFat      * 0.85 && totalFat      <= goalFat      * 1.15
        ]
    }
    var macrosMetToday: Int { macroGoalsMet.filter { $0 }.count }

    /// True when at least one workout has been logged for the selected date.
    var hasLoggedWorkoutToday: Bool = false

    // MARK: - Brainstorm state
    enum BrainstormState: Equatable {
        case idle, loading, result(String), error(String)
    }
    var brainstormState: BrainstormState = .idle

    // MARK: - Streak (consecutive days where ALL macro goals were met, ending yesterday)
    var macroStreak: Int

    init(selectedDate: Date = Calendar.current.startOfDay(for: Date()),
         userSettings: UserSettings) {
        self.selectedDate  = selectedDate
        self.userSettings  = userSettings
        // Seed from the persisted value so the display isn't 0 while the async compute runs.
        self.macroStreak   = userSettings.macroStreak

        let storedHour = UserDefaults.standard.object(forKey: "windowStartHour")
        self.windowStartHour   = storedHour != nil ? UserDefaults.standard.integer(forKey: "windowStartHour") : 9
        self.windowStartMinute = UserDefaults.standard.integer(forKey: "windowStartMinute")

        let storedDuration = UserDefaults.standard.object(forKey: "windowDurationHours")
        self.windowDurationHours = storedDuration != nil
            ? UserDefaults.standard.integer(forKey: "windowDurationHours")
            : 8

        // Revert workout macro adjustments if they were applied on a previous day
        MacroAdjustmentEngine.revertIfNewDay()

        if UserDefaults.standard.object(forKey: "goalCalories") != nil {
            self.goalCalories = UserDefaults.standard.double(forKey: "goalCalories")
        }
        if UserDefaults.standard.object(forKey: "goalProtein") != nil {
            self.goalProtein = UserDefaults.standard.double(forKey: "goalProtein")
        }
        if UserDefaults.standard.object(forKey: "goalCarbs") != nil {
            self.goalCarbs = UserDefaults.standard.double(forKey: "goalCarbs")
        }
        if UserDefaults.standard.object(forKey: "goalFat") != nil {
            self.goalFat = UserDefaults.standard.double(forKey: "goalFat")
        }

        // Backfill any past days that have no snapshot with the current (pre-edit) window
        // values, so that editing today can't retroactively change how past days look.
        let currentSnapshot = ["startHour": windowStartHour, "startMinute": windowStartMinute, "durationHours": windowDurationHours]
        var snapshots = dailyWindowSnapshots
        let today = Date()
        for offset in 1...90 {
            guard let day = Calendar.current.date(byAdding: .day, value: -offset, to: today) else { break }
            let key = dateKey(day)
            if snapshots[key] == nil { snapshots[key] = currentSnapshot }
        }
        dailyWindowSnapshots = snapshots

        // Ensure today always has a snapshot so past days see their actual recorded window
        snapshotTodayWindow()

        // Schedule fasting window notification if enabled
        if userSettings.fastingEnabled && userSettings.fastingWindowNotificationEnabled {
            NotificationService.shared.scheduleFastingWindowNotification(
                windowStartHour: windowStartHour, windowStartMinute: windowStartMinute)
        }

        // Restore today's brainstorm result if it was generated today
        if userSettings.hasTodayBrainstormResult {
            brainstormState = .result(userSettings.lastBrainstormResult)
        }

        // Data is loaded lazily from the view's onAppear to avoid blocking init
    }

    func loadTodayTotals() {
        // Cancel any pending debounced call so rapid-fire triggers
        // (notification + onAppear + scenePhase) collapse into one load.
        loadTotalsTask?.cancel()
        loadTotalsTask = Task {
            // 300 ms debounce — short enough to feel instant,
            // long enough to coalesce back-to-back calls.
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await loadTodayTotalsAsync()
        }
    }

    /// Reloads macro goals from UserDefaults (called after a workout macro adjustment is applied).
    func reloadGoalsFromDefaults() {
        let ud = UserDefaults.standard
        if ud.object(forKey: "goalCalories") != nil { goalCalories = ud.double(forKey: "goalCalories") }
        if ud.object(forKey: "goalProtein")  != nil { goalProtein  = ud.double(forKey: "goalProtein")  }
        if ud.object(forKey: "goalCarbs")    != nil { goalCarbs    = ud.double(forKey: "goalCarbs")    }
        if ud.object(forKey: "goalFat")      != nil { goalFat      = ud.double(forKey: "goalFat")      }
    }

    // MARK: - Display goals (exact saved goals for past dates, live goals for today)

    /// The goal to display for the currently selected date.
    /// Past dates use the Firestore-saved snapshot so adjusted days show
    /// the adjusted goal and non-adjusted days show the base goal.
    /// Falls back to current goals if no snapshot exists for that date.
    var displayGoalCalories: Double {
        guard !isSelectedDateToday else { return goalCalories }
        if let h = historicalGoals { return h.calories }
        return MacroAdjustmentEngine.isAdjustedToday()
            ? MacroAdjustmentEngine.baseGoals().calories : goalCalories
    }
    var displayGoalProtein: Double {
        guard !isSelectedDateToday else { return goalProtein }
        if let h = historicalGoals { return h.protein }
        return MacroAdjustmentEngine.isAdjustedToday()
            ? MacroAdjustmentEngine.baseGoals().protein : goalProtein
    }
    var displayGoalCarbs: Double {
        guard !isSelectedDateToday else { return goalCarbs }
        if let h = historicalGoals { return h.carbs }
        return MacroAdjustmentEngine.isAdjustedToday()
            ? MacroAdjustmentEngine.baseGoals().carbs : goalCarbs
    }
    var displayGoalFat: Double {
        guard !isSelectedDateToday else { return goalFat }
        if let h = historicalGoals { return h.fat }
        return MacroAdjustmentEngine.isAdjustedToday()
            ? MacroAdjustmentEngine.baseGoals().fat : goalFat
    }

    func loadTodayTotalsAsync() async {
        let entries = (try? await FoodEntryService.shared.fetch(
            userID: userSettings.userID, date: selectedDate)) ?? []

        totalCalories = entries.reduce(0) { $0 + $1.calories }
        totalProtein  = entries.reduce(0) { $0 + $1.protein }
        totalCarbs    = entries.reduce(0) { $0 + $1.carbs }
        totalFat      = entries.reduce(0) { $0 + $1.fat }

        // Cache today's totals in UserDefaults so NewPostView (Goal label) can read
        // them without an extra Firestore round-trip or missing pending entries.
        if isSelectedDateToday {
            let ud = UserDefaults.standard
            ud.set(totalCalories, forKey: "cachedDailyCalories")
            ud.set(totalProtein,  forKey: "cachedDailyProtein")
            ud.set(totalCarbs,    forKey: "cachedDailyCarbs")
            ud.set(totalFat,      forKey: "cachedDailyFat")
            ud.set(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970,
                   forKey: "cachedDailyDate")
        }

        // Load the goals that were saved for this date so past-day views show
        // the exact targets (adjusted or base) that were in effect that day.
        if !isSelectedDateToday {
            historicalGoals = await MacroHistoryService.shared.fetchDayGoals(
                userID: userSettings.userID, date: selectedDate)
        } else {
            historicalGoals = nil
        }

        let cal = Calendar.current
        mealLogTimes = entries.map { entry in
            let h = Double(cal.component(.hour,   from: entry.loggedAt))
            let m = Double(cal.component(.minute, from: entry.loggedAt))
            return h + m / 60.0
        }

        // Check if a workout was logged today
        let todayWorkouts = (try? await WorkoutService.shared.fetch(
            userID: userSettings.userID, date: selectedDate)) ?? []
        hasLoggedWorkoutToday = !todayWorkouts.isEmpty

        // ── Streak calculation (today only) ───────────────────────────────────
        if isSelectedDateToday {
            let uid = userSettings.userID
            let todayKey = MacroHistoryService.dateString(for: Date())
            let yesterdayStr = MacroHistoryService.dateString(
                for: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
            let todayAllMet = totalCalories > 0 && macroGoalsMet.allSatisfy { $0 } && hasLoggedWorkoutToday
            let previousStreak = userSettings.macroStreak

            // 1. Check for streak break: if lastGoalsMetDate is NOT yesterday
            //    and NOT today, the streak is broken → reset to 0.
            let lastMet = userSettings.lastGoalsMetDate
            if !lastMet.isEmpty && lastMet != yesterdayStr && lastMet != todayKey && userSettings.macroStreak > 0 {
                userSettings.macroStreak = 0
                macroStreak = 0
                if !uid.isEmpty {
                    Task {
                        try? await UserProfileService.shared.updateProfile(
                            userID: uid, fields: ["streakDays": 0])
                    }
                }

                // Record the break for streak shield
                if previousStreak > 1
                    && userSettings.streakBreakDate != yesterdayStr
                    && userSettings.lastStreakBeforeBreak == 0 {
                    userSettings.lastStreakBeforeBreak = previousStreak
                    userSettings.streakBreakDate       = yesterdayStr
                    userSettings.pendingStreakBreak     = previousStreak
                    Task {
                        try? await UserProfileService.shared.updateProfile(
                            userID: uid,
                            fields: ["lastStreakBeforeBreak": previousStreak, "streakBreakDate": yesterdayStr])
                    }
                }
            }

            // 2. If all 4 macros are met today AND we haven't already counted today → increment
            if todayAllMet && userSettings.lastGoalsMetDate != todayKey {
                let newStreak = userSettings.macroStreak + 1
                userSettings.macroStreak    = newStreak
                userSettings.lastGoalsMetDate = todayKey
                macroStreak = newStreak

                if newStreak > userSettings.longestStreak {
                    userSettings.longestStreak = newStreak
                }

                // Write to Firestore immediately
                if !uid.isEmpty {
                    Task {
                        try? await UserProfileService.shared.updateProfile(
                            userID: uid,
                            fields: [
                                "streakDays":       newStreak,
                                "lastGoalsMetDate": todayKey,
                                "longestStreak":    max(newStreak, userSettings.longestStreak),
                            ])
                    }
                }

                // Congrats popup — fires once per day when goals are first met
                if !Calendar.current.isDateInToday(userSettings.lastCelebrationDate) {
                    userSettings.lastCelebrationDate  = Date()
                    userSettings.pendingStreakCongrats = newStreak
                }

                // Check milestones (only if Firestore data is restored)
                if userSettings.profileLoaded {
                    checkStreakMilestones(newStreak)
                }
            } else {
                macroStreak = userSettings.macroStreak
            }
        }

        // Schedule or cancel the 10 PM streak-warning notification based on today's progress
        if isSelectedDateToday {
            let allMet = totalCalories > 0 && macroGoalsMet.allSatisfy { $0 } && hasLoggedWorkoutToday
            if allMet || macroStreak == 0 {
                NotificationService.shared.cancelStreakWarningNotification()
            } else {
                NotificationService.shared.scheduleStreakWarningIfNeeded(streak: macroStreak)
            }

            // Cancel today's meal-logging reminder once all macro goals are met;
            // re-schedule it for tomorrow if goals were already met today.
            if userSettings.mealReminderEnabled {
                if allMet {
                    NotificationService.shared.cancelMealReminder()
                } else {
                    NotificationService.shared.scheduleMealReminder(
                        hour: userSettings.mealReminderHour,
                        minute: userSettings.mealReminderMinute)
                }
            }
        }

        // Persist today's macro snapshot and fasting window to Firestore (today only).
        // Both writes target the same macroHistory document, so they must be serialized
        // to avoid concurrent setData / setData(merge:) races that crash LevelDB.
        if isSelectedDateToday {
            await FastingWindowService.shared.logTodaysWindow(
                userID:         userSettings.userID,
                startHour:      windowStartHour,
                startMinute:    windowStartMinute,
                durationHours:  windowDurationHours,
                fastingEnabled: userSettings.fastingEnabled
            )
            await MacroHistoryService.shared.updateTodaysMacros(
                userID:        userSettings.userID,
                totalCalories: totalCalories,
                totalProtein:  totalProtein,
                totalCarbs:    totalCarbs,
                totalFat:      totalFat,
                goalCalories:  goalCalories,
                goalProtein:   goalProtein,
                goalCarbs:     goalCarbs,
                goalFat:       goalFat,
                mealCount:     entries.count,
                streakDay:     macroStreak
            )
        }
    }

    // MARK: - Brainstorm

    func brainstorm() {
        brainstormState = .loading
        let input = MacroRecommendationEngine.BrainstormInput(
            totalCalories: totalCalories, goalCalories: goalCalories,
            totalProtein:  totalProtein,  goalProtein:  goalProtein,
            totalCarbs:    totalCarbs,    goalCarbs:    goalCarbs,
            totalFat:      totalFat,      goalFat:      goalFat,
            excludeDairy:  userSettings.excludeDairy,
            excludeGluten: userSettings.excludeGluten
        )
        let result = MacroRecommendationEngine().recommend(input)
        brainstormState = .result(result)
        userSettings.lastBrainstormResult = result
        userSettings.lastBrainstormDate   = Date()
    }

    func resetBrainstorm() { brainstormState = .idle }


    // MARK: - Macro recalculation from goal weight

    func recalculateMacrosFromGoalWeight() {
        let gw = userSettings.goalWeight
        guard gw > 0 else { return }
        // Mifflin-St Jeor + sedentary baseline (1.2). Auto-adjust handles workout days.
        let weightKg = gw * 0.453592
        let heightCm = Double(max(userSettings.heightInches, 1)) * 2.54
        let age      = Double(userSettings.ageInYears)
        let g        = userSettings.gender
        let genderOffset: Double = g == "male" ? 5.0 : g == "female" ? -161.0 : -78.0
        let bmr      = 10.0 * weightKg + 6.25 * heightCm - 5.0 * age + genderOffset
        let cals     = bmr * 1.2
        let protein  = gw * userSettings.proteinPerLb
        let fat      = (cals * 0.25) / 9.0
        let carbs    = (cals - protein * 4.0 - fat * 9.0) / 4.0

        let newCal = max(cals,    1200)
        let newPrt = max(protein,   50)
        let newFat = max(fat,       30)
        let newCrb = max(carbs,     50)

        if MacroAdjustmentEngine.isAdjustedToday() {
            // Preserve the existing workout adjustment deltas on top of the new base
            MacroAdjustmentEngine.updateBaseGoals(
                newCalories: newCal, newProtein: newPrt,
                newCarbs: newCrb, newFat: newFat)
            reloadGoalsFromDefaults()
        } else {
            goalCalories = newCal
            goalProtein  = newPrt
            goalFat      = newFat
            goalCarbs    = newCrb
        }
    }

    // MARK: - Private

    private func checkStreakMilestones(_ streak: Int) {
        let milestones: [(days: Int, pts: Int, reason: String, msg: String)] = [
            (3,    20,  "🔥 3-Day Streak",   "3 days of hitting every goal. that's discipline."),
            (7,    60,  "🔥 7-Day Streak",   "one full week of locking in on every macro. keep it going."),
            (14,  120,  "🔥 14-Day Streak",  "two straight weeks of meeting every goal. real consistency."),
            (30,  200,  "🔥 30-Day Streak",  "30 days of actually hitting your numbers. that's rare."),
            (60,  300,  "🔥 60-Day Streak",  "60 days of goal-hitting discipline. the results are showing."),
            (100, 1000, "🔥 100-Day Streak", "100 days of meeting every macro goal. you're built different."),
        ]
        for m in milestones where streak >= m.days && !userSettings.achievedMilestones.contains(m.days) {
            userSettings.markMilestoneAchieved(m.days)
            userSettings.awardAura(points: m.pts, reason: m.reason)

            // Request App Store review after 3-day or 7-day streak milestone
            if m.days == 3 || m.days == 7 {
                AppReviewService.requestReviewIfAppropriate()
            }
        }
    }
}
