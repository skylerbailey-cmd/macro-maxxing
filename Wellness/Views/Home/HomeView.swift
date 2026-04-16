//
//  HomeView.swift
//  Wellness
//

import SwiftUI
import SwiftData

// MARK: - HomeView

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @Binding var selectedDate: Date
    @Environment(NotificationState.self) private var notificationState
    @Environment(\.scenePhase) private var scenePhase
    /// Calendar date when data was last loaded — used to detect midnight crossings.
    @State private var lastLoadedDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedMacro: MacroType? = nil
    @State private var showingShare       = false
    @State private var showingTutorial    = false
    @State private var tutorialAnchors:   [String: Anchor<CGRect>] = [:]
    @State private var showingSettings    = false
    @State private var showingGoalPost    = false
    @State private var showingAIConsent   = false
    @State private var goalPostMeme       = GymMeme.random()
    @State private var brainstormAlert: BrainstormAlert? = nil
    @State private var showingNotifications = false
    @State private var showingCheatDay       = false
    @State private var showingStreakExtension = false
    @State private var showingAIPaywall       = false
    @State private var aiSubscription = AISubscriptionStore.shared
    /// Whether the macros section is showing the full 2×2 grid. When false,
    /// a single summary card stands in with four mini gauges. Tapping the
    /// summary expands it; the chevron in the expanded header collapses it.
    @State private var macrosExpanded = false

    /// Whether the workouts card is showing its full detail view (7-day dot
    /// strip + weekly aggregates + recent workouts list) instead of the
    /// compact half-width summary.
    @State private var workoutsExpanded = false

    /// Recent workouts (last 90 days) used to build the weekly summary and
    /// the recent-workouts list in the expanded card. Refreshed on appear,
    /// on scene foregrounding, and after a workout is saved elsewhere in the
    /// app. 90 days gives the user enough history to page backwards through
    /// roughly a quarter of weeks from the expanded card's week strip.
    @State private var recentWorkouts: [WorkoutEntry] = []

    /// Week the expanded workouts card is currently showing. 0 = current week,
    /// -1 = last week, and so on. Can't go positive (no future weeks).
    @State private var workoutsWeekOffset: Int = 0

    /// Day pinned to the top of the "Recent" list in the expanded card. When
    /// the user taps a day in the strip, that day's workouts bubble above the
    /// rest of the list. Cleared when the user navigates to a different week.
    @State private var selectedWorkoutDay: Date? = nil

    private enum BrainstormAlert: Identifiable {
        case confirm, limitReached
        var id: Self { self }
    }

    init(modelContext: ModelContext, selectedDate: Binding<Date>, userSettings: UserSettings) {
        _viewModel    = State(wrappedValue: HomeViewModel(
            selectedDate: selectedDate.wrappedValue,
            userSettings: userSettings
        ))
        _selectedDate = selectedDate
    }

    // MARK: - Greeting

    private static let greetingPhrases: [String] = [
        "Stay Locked In",
        "Stay Disciplined",
        "Stay Sharp",
        "Stay Strong",
        "Stay Consistent",
        "Stay Hungry",
        "Keep Maxxing",
        "Keep Grinding",
        "Keep Pushing",
        "Trust the Process",
        "No Days Off",
        "Eyes on the Prize",
        "Rise and Grind",
        "Level Up",
        "Mog the Competition",
        "Fueled and Focused",
        "Optimize Everything",
        "Maximum Effort",
    ]

    private var greetingText: String {
        // Rotate daily so it feels fresh but stays stable throughout the day
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return Self.greetingPhrases[dayOfYear % Self.greetingPhrases.count]
    }

    private func timeString(hour: Int, minute: Int) -> String {
        var comps = DateComponents()
        comps.hour = hour; comps.minute = minute
        guard let date = Calendar.current.date(from: comps) else { return "" }
        let f = DateFormatter(); f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    var body: some View {
        @Bindable var bvm      = viewModel
        @Bindable var settings = viewModel.userSettings
        
        let contentWithModifiers = mainContent
            .preferredColorScheme(.dark)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingShare) { shareSheet }
            .sheet(isPresented: $showingNotifications) {
                NotificationsView(userSettings: viewModel.userSettings, notificationState: notificationState)
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView(userSettings: viewModel.userSettings)
                }
            }
            .onAppear { handleAppear() }
            .onReceive(NotificationCenter.default.publisher(for: FuelLogService.mealChangedNotification)) { _ in
                Task { viewModel.loadTodayTotals() }
            }
            .onReceive(NotificationCenter.default.publisher(for: MacroAdjustmentEngine.macroAdjustedNotification)) { _ in
                viewModel.reloadGoalsFromDefaults()
            }
            .onReceive(NotificationCenter.default.publisher(for: WorkoutService.workoutSavedNotification)) { _ in
                Task { await loadRecentWorkouts() }
            }
            .onChange(of: selectedDate) { _, newDate in handleDateChange(newDate) }
            .onChange(of: viewModel.userSettings.macroStreak) { _, newStreak in
                // Update immediately when populate(from:) loads the streak from Firestore
                if newStreak > viewModel.macroStreak {
                    viewModel.macroStreak = newStreak
                }
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                let today = Calendar.current.startOfDay(for: Date())
                if !Calendar.current.isDate(today, inSameDayAs: lastLoadedDay) {
                    // App came to foreground on a new calendar day — reset to today and reload
                    selectedDate  = today
                    lastLoadedDay = today
                    Task { viewModel.loadTodayTotals() }
                }
                // Refresh the workouts card whenever we foreground — cheap
                // and covers the case where a workout was logged while the
                // Hub wasn't on screen.
                Task { await loadRecentWorkouts() }
            }
        
        let contentWithGoalChanges = contentWithModifiers
            .onChange(of: viewModel.userSettings.goalWeight) { _, newVal in handleGoalWeightChange(newVal) }
            .onChange(of: viewModel.userSettings.proteinPerLb) { _, _ in handleProteinPerLbChange() }
            .onChange(of: viewModel.userSettings.heightInches) { _, _ in handleBodyStatsChange() }
            .onChange(of: viewModel.userSettings.gender) { _, _ in handleBodyStatsChange() }
            .onChange(of: viewModel.userSettings.dateOfBirth) { _, _ in handleBodyStatsChange() }
        let contentWithOverlays = contentWithGoalChanges
            .onChange(of: viewModel.macrosMetToday) { oldVal, newVal in handleMacrosMetChange(oldVal, newVal) }

        return contentWithOverlays
            .sheet(item: $selectedMacro) { macro in macroHistorySheet(macro: macro) }
            .sheet(isPresented: $showingGoalPost) { goalPostSheet() }
            .sheet(isPresented: $showingAIConsent) {
                AIConsentSheet(
                    onAgree: { viewModel.userSettings.aiConsentGiven = true },
                    onDecline: { }
                )
            }
            .sheet(isPresented: $showingCheatDay) {
                CheatDayView(
                    currentStreak: viewModel.macroStreak,
                    onPurchased: {
                        viewModel.userSettings.applyCheatDay(userID: viewModel.userSettings.userID)
                        viewModel.macroStreak = viewModel.userSettings.macroStreak
                        showingCheatDay = false
                    },
                    onDismiss: {
                        showingCheatDay = false
                    }
                )
            }
            .sheet(isPresented: $showingStreakExtension) {
                StreakExtensionView(
                    currentStreak: viewModel.macroStreak,
                    onPurchased: {
                        viewModel.userSettings.applyStreakExtension(userID: viewModel.userSettings.userID)
                        viewModel.macroStreak = viewModel.userSettings.macroStreak
                        showingStreakExtension = false
                    },
                    onDismiss: {
                        showingStreakExtension = false
                    }
                )
            }
            .sheet(isPresented: $showingAIPaywall) {
                AISubscriptionPaywallView(
                    onSubscribed: {
                        // Re-enter the brainstorm flow now that access is unlocked.
                        showingAIPaywall = false
                        if !viewModel.userSettings.aiConsentGiven {
                            showingAIConsent = true
                        } else if viewModel.userSettings.brainstormLimitReached {
                            brainstormAlert = .limitReached
                        } else {
                            brainstormAlert = .confirm
                        }
                    },
                    onDismiss: { showingAIPaywall = false }
                )
            }
    }
    
    // MARK: - Body Helpers
    
    private var mainContent: some View {
        ZStack {
            Color.pageBg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    greetingHeader
                    DateNavigatorView(selectedDate: $selectedDate)
                    goalsSection
                    macrosSection
                    brainstormSection
                        .tutorialAnchor("hub.mealPlanner")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            if showingTutorial {
                TutorialOverlayView(
                    steps: TutorialSteps.hub,
                    anchors: tutorialAnchors,
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.25)) { showingTutorial = false }
                    })
                .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                .zIndex(100)
            }
        }
        .onPreferenceChange(TutorialAnchorKey.self) { tutorialAnchors = $0 }
    }
    
    private var greetingHeader: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.purpleHi.opacity(0.20), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(Color.purpleHi.opacity(0.13))
                        .frame(width: 220, height: 220)
                        .offset(x: -40, y: -90)
                        .blur(radius: 50)
                        .allowsHitTesting(false)
                        .clipped()
                }
                .tutorialAnchor("hub.header")
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greetingText)
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.purpleHi.opacity(i == 0 ? 1.0 : i == 1 ? 0.35 : 0.12))
                                    .frame(width: i == 0 ? 28 : i == 1 ? 16 : 10, height: 3)
                            }
                        }
                    }
                    Spacer()
                    HStack(spacing: 12) {
                        Button { showingTutorial = true } label: {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 20))
                                .foregroundStyle(.white.opacity(0.65))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Help")
                        .accessibilityHint("Shows the tutorial")
                        BellButton(showingNotifications: $showingNotifications, notificationState: notificationState)
                        Button { showingSettings = true } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(ThemeStore.shared.accent)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Settings")
                        .accessibilityHint("Opens settings")
                    }
                    .tutorialAnchor("hub.notifications")
                }
                // Level + title line
                let _level = UserSettings.auraLevel(for: viewModel.userSettings.auraPoints)
                let _title = viewModel.userSettings.auraTitle
                HStack(spacing: 6) {
                    Text("Lv \(_level)")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(Color.purpleHi)
                    Text("·")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.30))
                    Text(_title.uppercased())
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.5)
                        .foregroundStyle(ThemeStore.shared.accent)
                    Spacer()
                    Text("🔥 \(viewModel.macroStreak) day streak")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                }

                auraXPBar
                    .tutorialAnchor("hub.stats")

                // Cheat Day button — only show if streak > 0, today isn't already a cheat day,
                // and today's macros haven't already been met.
                if viewModel.macroStreak > 0
                    && !viewModel.userSettings.isTodayCheatDay
                    && viewModel.macrosMetToday < 4 {
                    HStack(spacing: 8) {
                        Button { showingCheatDay = true } label: {
                            HStack(spacing: 6) {
                                Text("\u{1F3D6}\u{FE0F}")
                                    .font(.system(size: 14))
                                Text("Cheat Day")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.20, green: 0.85, blue: 0.75),
                                             Color(red: 0.10, green: 0.65, blue: 0.90)],
                                    startPoint: .leading, endPoint: .trailing
                                ).opacity(0.25),
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color(red: 0.20, green: 0.85, blue: 0.75).opacity(0.40), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        if !viewModel.userSettings.isStreakExtensionActive {
                            Button { showingStreakExtension = true } label: {
                                HStack(spacing: 6) {
                                    Text("\u{1F525}")
                                        .font(.system(size: 14))
                                    Text("7-Day Extension")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 1.00, green: 0.65, blue: 0.10),
                                                 Color(red: 1.00, green: 0.45, blue: 0.05)],
                                        startPoint: .leading, endPoint: .trailing
                                    ).opacity(0.25),
                                    in: Capsule()
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color(red: 1.00, green: 0.65, blue: 0.10).opacity(0.40), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .fixedSize(horizontal: false, vertical: true)
        .clipped()
    }

    private func headerStat(icon: String, iconColor: Color, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(iconColor)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.38))
                    .lineLimit(1)
            }
        }
        .padding(.trailing, 16)
    }

    private var headerStatDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(width: 1, height: 22)
            .padding(.trailing, 16)
    }

    /// Returns a brighter / less saturated version of the accent for the
    /// starting (left) edge of the XP bar gradient. Kept as a static helper
    /// so it can be called from inside the `auraXPBar` body without
    /// introducing a captured-self reference.
    private static func lightenedAccent(_ base: Color) -> Color {
        let ui = UIColor(base)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(UIColor(hue: h,
                             saturation: max(0, s * 0.55),
                             brightness: min(1, b * 1.10),
                             alpha: a))
    }

    /// Returns a deeper / more saturated version of the accent for the far
    /// (right) edge of the XP bar gradient — reached only as progress fills.
    private static func deepenedAccent(_ base: Color) -> Color {
        let ui = UIColor(base)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(UIColor(hue: h,
                             saturation: min(1, s * 1.20),
                             brightness: max(0, b * 0.62),
                             alpha: a))
    }

    private var auraXPBar: some View {
        let pts        = viewModel.userSettings.auraPoints
        let level      = UserSettings.auraLevel(for: pts)
        let levelStart = level <= 1 ? 0 : UserSettings.auraThreshold(level)
        let levelEnd   = UserSettings.auraThreshold(level + 1)
        let inLevel    = max(0, pts - levelStart)
        let forLevel   = max(1, levelEnd - levelStart)
        let progress   = level >= 100 ? 1.0 : Double(inLevel) / Double(forLevel)
        let pctText    = level >= 100 ? "MAX" : "\(Int(progress * 100))%"
        let nextLabel  = level >= 100 ? "Max level" : "to Lv \(level + 1)"
        // Gradient spans the ENTIRE bar: light-accent on the left fading into
        // a deeper, more saturated accent on the right. Because we mask the
        // fill to the progress width, only a small slice of the left end is
        // visible early in a level — the deep right end is revealed as the
        // user approaches the next level.
        let barGradient = LinearGradient(
            colors: [
                Self.lightenedAccent(ThemeStore.shared.accent),
                ThemeStore.shared.accent,
                Self.deepenedAccent(ThemeStore.shared.accent)
            ],
            startPoint: .leading, endPoint: .trailing
        )

        let ptsToNext = level >= 100 ? 0 : forLevel - inLevel

        return VStack(spacing: 4) {
            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 5)
                        // Full-width gradient masked to the progress slice, so
                        // the "deeper accent" right edge only appears as the
                        // user nears the next level.
                        Capsule()
                            .fill(barGradient)
                            .frame(width: geo.size.width, height: 5)
                            .mask(
                                HStack(spacing: 0) {
                                    Capsule()
                                        .frame(width: max(5, geo.size.width * progress), height: 5)
                                    Spacer(minLength: 0)
                                }
                            )
                            .animation(.easeOut(duration: 0.6), value: progress)
                    }
                }
                .frame(height: 5)

                Text(pctText)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(ThemeStore.shared.accent)
                    .frame(width: 34, alignment: .trailing)

                Text(nextLabel)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.32))
                    .lineLimit(1)
            }
            HStack {
                Text("\(pts) XP")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                Spacer()
                if level < 100 {
                    Text("\(ptsToNext) XP to Lv \(level + 1)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            EmptyView()
        }
    }

    private var shareSheet: some View {
        ShareView(viewModel: viewModel)
            .presentationDetents([.large])
    }
    
    private func goalPostSheet() -> some View {
        CelebrationPostEditorSheet(
            meme: goalPostMeme,
            postData: CelebrationPostData(
                totalCalories: viewModel.totalCalories, goalCalories: viewModel.displayGoalCalories,
                totalProtein:  viewModel.totalProtein,  goalProtein:  viewModel.displayGoalProtein,
                totalCarbs:    viewModel.totalCarbs,    goalCarbs:    viewModel.displayGoalCarbs,
                totalFat:      viewModel.totalFat,      goalFat:      viewModel.displayGoalFat,
                date:          viewModel.selectedDate,
                fastingWindowDisplay: viewModel.userSettings.fastingEnabled
                    ? "\(timeString(hour: viewModel.windowStartHour, minute: viewModel.windowStartMinute)) – \(timeString(hour: viewModel.windowEndHour, minute: viewModel.windowEndMinute)) · \(viewModel.windowDurationHours)h window"
                    : ""
            ),
            userSettings: viewModel.userSettings,
            onPosted: {}
        )
    }

    private func macroHistorySheet(macro: MacroType) -> some View {
        MacroHistorySheet(
            macro:     macro,
            goalValue: goalForMacro(macro),
            userID:    viewModel.userSettings.userID
        )
        .presentationDetents([.medium, .large])
    }
    
    private func handleAppear() {
        viewModel.selectedDate = selectedDate
        lastLoadedDay = Calendar.current.startOfDay(for: Date())
        // Show the streak immediately from whatever UserSettings has right now
        // (populated from Firestore or UserDefaults), before the async compute runs.
        viewModel.macroStreak = viewModel.userSettings.macroStreak
        // Self-heal macro goals from current body stats. Covers users whose
        // goals were computed with incomplete data earlier (e.g. heightInches=0
        // before Settings was filled in) and got pinned at the minimum floor.
        // Idempotent — no-op if goalWeight is unset.
        if viewModel.userSettings.goalWeight > 0 && viewModel.userSettings.heightInches > 0 {
            viewModel.recalculateMacrosFromGoalWeight()
        }
        // Defer the DB fetch to after the first frame so the UI renders immediately
        Task { viewModel.loadTodayTotals() }
        // lockPastWindows is now called once at app launch (ContentView.onAppear)
        // instead of every time this view appears, to avoid expensive batch writes.
        // Load the AI subscription product + entitlement so the brainstorm
        // button reflects the correct locked/unlocked state on first render.
        Task {
            await aiSubscription.loadProduct()
            await aiSubscription.refreshEntitlement()
        }
        // Workouts card data — 14-day window for weekly aggregates + recent list.
        Task { await loadRecentWorkouts() }
    }
    
    private func handleDateChange(_ newDate: Date) {
        viewModel.selectedDate = newDate
        viewModel.resetBrainstorm()
    }
    
    private func handleGoalWeightChange(_ newVal: Double) {
        if newVal > 0 { viewModel.recalculateMacrosFromGoalWeight() }
    }
    
    private func handleProteinPerLbChange() {
        viewModel.recalculateMacrosFromGoalWeight()
    }

    /// Recompute macro goals when height, gender, or date-of-birth changes in
    /// Settings. Without this, BMR inputs could update while the goals stayed
    /// stale — e.g. a new user whose first calculation ran with heightInches=0
    /// would be pinned at the 1200 kcal minimum floor until goalWeight or
    /// proteinPerLb happened to change.
    private func handleBodyStatsChange() {
        guard viewModel.userSettings.goalWeight > 0 else { return }
        viewModel.recalculateMacrosFromGoalWeight()
    }
    
    private func handleMacrosMetChange(_ oldVal: Int, _ newVal: Int) {
        guard newVal == 4 && oldVal < 4 && Calendar.current.isDateInToday(viewModel.selectedDate) else { return }
        let stored = UserDefaults.standard.double(forKey: "lastCelebrationDate")
        let lastShown = stored > 0 ? Date(timeIntervalSince1970: stored) : Date.distantPast
        guard !Calendar.current.isDateInToday(lastShown) else { return }
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastCelebrationDate")
        viewModel.userSettings.pendingCelebration = CelebrationPostData(
            totalCalories: viewModel.totalCalories, goalCalories: viewModel.displayGoalCalories,
            totalProtein:  viewModel.totalProtein,  goalProtein:  viewModel.displayGoalProtein,
            totalCarbs:    viewModel.totalCarbs,    goalCarbs:    viewModel.displayGoalCarbs,
            totalFat:      viewModel.totalFat,      goalFat:      viewModel.displayGoalFat,
            date:          viewModel.selectedDate,
            fastingWindowDisplay: viewModel.userSettings.fastingEnabled
                ? "\(timeString(hour: viewModel.windowStartHour, minute: viewModel.windowStartMinute)) – \(timeString(hour: viewModel.windowEndHour, minute: viewModel.windowEndMinute)) · \(viewModel.windowDurationHours)h window"
                : ""
        )
    }

    private var goalsTitle: String {
        let current = viewModel.userSettings.currentWeight
        let goal    = viewModel.userSettings.goalWeight
        guard goal > 0, current > 0 else { return "Goals" }
        if goal > current   { return "Goals: Bulking" }
        if goal < current   { return "Goals: Cutting" }
        return "Goals: Maintaining"
    }

    // MARK: - Goals section

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text(goalsTitle)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("DISCIPLINE")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.35))
                    Text("\(Int(disciplineProgress * 100))%")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(disciplineProgress >= 1.0
                            ? Color(red: 0.35, green: 1.00, blue: 0.60)
                            : ThemeStore.shared.accent)
                        .animation(.easeOut(duration: 0.5), value: disciplineProgress)
                }
                .tutorialAnchor("hub.discipline")
            }
            let current = viewModel.userSettings.currentWeight
            let goal    = viewModel.userSettings.goalWeight
            if current > 0 && goal > 0 {
                Text("Based on your current weight of \(String(format: "%.1f", current)) lbs and your goal to reach \(String(format: "%.0f", goal)) lbs.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineSpacing(2)
            }
        }
    }

    // 2×2 grid of colored dots — lights up when each macro goal is met
    private var macroIndicatorGrid: some View {
        let met    = viewModel.macroGoalsMet
        let colors: [Color] = [.orange, .macroBlue, .macroMint, .macroRose]
        return LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 6
        ) {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(met[i] ? colors[i] : colors[i].opacity(0.13))
                    .frame(width: 14, height: 14)
                    .shadow(color: met[i] ? colors[i].opacity(0.7) : .clear, radius: 4)
            }
        }
    }

    private var macrosKPIColor: Color {
        switch viewModel.macrosMetToday {
        case 4:    return .macroMint
        case 3:    return .macroBlue
        case 1, 2: return .orange
        default:   return .white.opacity(0.35)
        }
    }

    // MARK: - Macros section

    private var disciplineProgress: Double {
        let pairs: [(Double, Double)] = [
            (viewModel.totalCalories, viewModel.displayGoalCalories),
            (viewModel.totalProtein,  viewModel.displayGoalProtein),
            (viewModel.totalCarbs,    viewModel.displayGoalCarbs),
            (viewModel.totalFat,      viewModel.displayGoalFat),
        ]
        let active = pairs.filter { $0.1 > 0 }
        guard !active.isEmpty else { return 0 }
        let sum = active.reduce(0.0) { $0 + max(0, 1.0 - abs($1.0 / $1.1 - 1.0)) }
        return sum / Double(active.count)
    }

    /// Layout rule: when BOTH cards are collapsed they share a row as
    /// half-width siblings. As soon as either one expands we break out of
    /// that row and stack both sections vertically full-width — that way we
    /// never leave a half-width summary floating next to empty space.
    /// Layout rule: when both tiles are collapsed they share a row as
    /// half-width siblings. When one is expanded, it takes the full width
    /// and the other tile is hidden entirely — keeps focus on what the
    /// user just opened without a floating summary card next to it.
    private var macrosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if macrosExpanded {
                macrosExpandedHeader
                macrosGrid
                    .tutorialAnchor("hub.macros")
                    .transition(cardTransition)
            } else if workoutsExpanded {
                workoutsExpandedView
                    .transition(cardTransition)
            } else {
                // `maxHeight: .infinity` on each card + `fixedSize(vertical:)`
                // on the HStack makes both cards grow to match the taller
                // sibling — so the macros and workouts tiles stay the same
                // size regardless of their individual content height.
                HStack(alignment: .top, spacing: 12) {
                    macroSummaryCard(compact: true)
                        .tutorialAnchor("hub.macros")
                        .frame(maxHeight: .infinity)
                    workoutSummaryCard(compact: true)
                        .frame(maxHeight: .infinity)
                }
                .fixedSize(horizontal: false, vertical: true)
                .transition(cardTransition)
            }
        }
    }

    private var cardTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .top)),
            removal:   .opacity.combined(with: .scale(scale: 0.96, anchor: .top))
        )
    }

    private var macrosExpandedHeader: some View {
        HStack {
            Text("MACROS")
                .font(.system(size: 11, weight: .black))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.40))
            Spacer()
            Button {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                    macrosExpanded = false
                }
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.60))
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Collapse macros")
        }
    }

    private var macrosGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MacroGaugeCard(label: "Calories", value: viewModel.totalCalories,
                           goal: viewModel.displayGoalCalories, unit: "kcal",
                           format: "%.0f", color: .orange,
                           action: { selectedMacro = .calories },
                           rangeText: caloriesRange)
            MacroGaugeCard(label: "Protein",  value: viewModel.totalProtein,
                           goal: viewModel.displayGoalProtein,  unit: "g",
                           format: "%.0f", color: .macroBlue,
                           action: { selectedMacro = .protein },
                           rangeText: minRange(viewModel.displayGoalProtein))
            MacroGaugeCard(label: "Carbs",    value: viewModel.totalCarbs,
                           goal: viewModel.displayGoalCarbs,    unit: "g",
                           format: "%.0f", color: .macroMint,
                           action: { selectedMacro = .carbs },
                           rangeText: minRange(viewModel.displayGoalCarbs))
            MacroGaugeCard(label: "Fat",      value: viewModel.totalFat,
                           goal: viewModel.displayGoalFat,      unit: "g",
                           format: "%.0f", color: .macroRose,
                           action: { selectedMacro = .fat },
                           rangeText: minRange(viewModel.displayGoalFat))
        }
    }

    /// - Parameter compact: When `true`, renders in a half-width layout with
    ///   a 2×2 mini-gauge grid (used when it sits next to the workouts card).
    ///   When `false`, renders full-width with all four gauges in a single
    ///   row (used when the workouts card is expanded below it).
    private func macroSummaryCard(compact: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                macrosExpanded = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(compact ? "MACROS" : "TODAY'S MACROS")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.40))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.45))
                }

                if compact {
                    // Half-width layout — 4 concentric rings (calories outer,
                    // then protein, carbs, fat). Condenses all four macro KPIs
                    // into one glanceable visual that matches the workouts
                    // card's footprint. Center shows "X/4 met".
                    VStack(spacing: 8) {
                        macroRingStack
                            .frame(width: 92, height: 92)
                        Text("\(viewModel.macrosMetToday)/4 macros")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    // Full-width layout — single row of four mini gauges.
                    HStack(spacing: 6) {
                        miniGaugeCalories
                        miniGaugeProtein
                        miniGaugeCarbs
                        miniGaugeFat
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity,
                   maxHeight: compact ? .infinity : nil,
                   alignment: .topLeading)
            .background(Color.cardBg)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Expand macros")
        .accessibilityHint("Shows calories, protein, carbs, and fat cards")
    }

    /// 4 concentric macro rings — calories (orange) outermost, then protein
    /// (blue), carbs (mint), fat (rose). Each ring's trimmed fraction is
    /// `value / goal` capped at 1.0. Draws a faint full-circle track behind
    /// each ring so 0-progress macros are still visible.
    private var macroRingStack: some View {
        let lineWidth: CGFloat = 6
        let spacing:   CGFloat = 3   // gap between adjacent rings
        let step = lineWidth + spacing
        return ZStack {
            macroRing(progress: macroRingProgress(viewModel.totalCalories,
                                                  viewModel.displayGoalCalories),
                      color: .orange,    inset: 0,        lineWidth: lineWidth)
            macroRing(progress: macroRingProgress(viewModel.totalProtein,
                                                  viewModel.displayGoalProtein),
                      color: .macroBlue, inset: step,     lineWidth: lineWidth)
            macroRing(progress: macroRingProgress(viewModel.totalCarbs,
                                                  viewModel.displayGoalCarbs),
                      color: .macroMint, inset: step * 2, lineWidth: lineWidth)
            macroRing(progress: macroRingProgress(viewModel.totalFat,
                                                  viewModel.displayGoalFat),
                      color: .macroRose, inset: step * 3, lineWidth: lineWidth)
        }
    }

    private func macroRing(progress: Double, color: Color,
                           inset: CGFloat, lineWidth: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.14),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: progress)
        }
        .padding(inset)
    }

    private func macroRingProgress(_ value: Double, _ goal: Double) -> Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }

    // Individual mini-gauge builders — kept separate so both layouts share
    // the exact same gauge parameters.
    private var miniGaugeCalories: some View {
        MiniMacroGauge(label: "Calories", value: viewModel.totalCalories,
                       goal:  viewModel.displayGoalCalories, unit: "kcal",
                       color: .orange)
    }
    private var miniGaugeProtein: some View {
        MiniMacroGauge(label: "Protein", value: viewModel.totalProtein,
                       goal:  viewModel.displayGoalProtein, unit: "g",
                       color: .macroBlue)
    }
    private var miniGaugeCarbs: some View {
        MiniMacroGauge(label: "Carbs", value: viewModel.totalCarbs,
                       goal:  viewModel.displayGoalCarbs, unit: "g",
                       color: .macroMint)
    }
    private var miniGaugeFat: some View {
        MiniMacroGauge(label: "Fat", value: viewModel.totalFat,
                       goal:  viewModel.displayGoalFat, unit: "g",
                       color: .macroRose)
    }

    // MARK: - Workouts card

    /// Aggregate for the currently displayed week (summary card always uses
    /// this-week; the expanded card uses `displayedWeekMonday` which follows
    /// the user's week-navigation offset).
    private func weeklyWorkoutStats(weekStart: Date) -> (count: Int, minutes: Int, calories: Int) {
        let cal = Calendar.current
        guard let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) else {
            return (0, 0, 0)
        }
        let entries = recentWorkouts.filter {
            $0.loggedAt >= weekStart && $0.loggedAt < weekEnd && $0.workoutType != .restDay
        }
        return (
            entries.count,
            entries.reduce(0) { $0 + $1.durationMinutes },
            entries.reduce(0) { $0 + $1.caloriesBurned }
        )
    }

    /// Monday (ISO week start) of this week.
    private var currentWeekMonday: Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekdayOffset = (cal.component(.weekday, from: today) + 5) % 7
        return cal.date(byAdding: .day, value: -weekdayOffset, to: today) ?? today
    }

    /// Monday of the week the expanded card is currently showing, offset from
    /// the current week by `workoutsWeekOffset`.
    private var displayedWeekMonday: Date {
        let cal = Calendar.current
        return cal.date(byAdding: .weekOfYear,
                        value: workoutsWeekOffset,
                        to: currentWeekMonday) ?? currentWeekMonday
    }

    /// Short "Apr 10 – Apr 16" style label for the displayed week. Swaps in
    /// "This Week" / "Last Week" for the two most recent weeks so the common
    /// case stays glanceable.
    private var displayedWeekLabel: String {
        if workoutsWeekOffset == 0  { return "This Week" }
        if workoutsWeekOffset == -1 { return "Last Week" }
        let cal = Calendar.current
        guard let sunday = cal.date(byAdding: .day, value: 6, to: displayedWeekMonday) else { return "" }
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return "\(f.string(from: displayedWeekMonday)) – \(f.string(from: sunday))"
    }

    /// Consecutive number of days ending today that have at least one logged
    /// workout. Stops at the first gap day; rest days don't count toward the
    /// streak but also don't break it (matches typical fitness-app behavior).
    private var workoutStreakDays: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let days = Set(recentWorkouts
            .filter { $0.workoutType != .restDay }
            .map { cal.startOfDay(for: $0.loggedAt) })
        var streak = 0
        var cursor = today
        while days.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    private func workoutSummaryCard(compact: Bool) -> some View {
        let stats   = weeklyWorkoutStats(weekStart: currentWeekMonday)
        let streak  = workoutStreakDays
        return Button {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                workoutsExpanded = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("WORKOUTS")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.40))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.45))
                }

                if compact {
                    // Half-width layout — single big number stacked vertically.
                    VStack(spacing: 6) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(ThemeStore.shared.accent)
                        Text("\(stats.count)")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText(value: Double(stats.count)))
                        Text("this week")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    // Full-width layout — horizontal row of icon + count + streak.
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(ThemeStore.shared.accent.opacity(0.16))
                                .frame(width: 44, height: 44)
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(ThemeStore.shared.accent)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(stats.count) this week")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            if streak > 0 {
                                Text("🔥 \(streak) day\(streak == 1 ? "" : "s") streak")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.55))
                            } else {
                                Text("Log a workout to start a streak")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.35))
                            }
                        }
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity,
                   maxHeight: compact ? .infinity : nil,
                   alignment: .topLeading)
            .background(Color.cardBg)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Expand workouts")
        .accessibilityHint("Shows this week's workouts and recent history")
    }

    /// Expanded workouts card — 7-day dot strip, weekly aggregates, and a
    /// recent-workouts list. Matches the macros expanded pattern: tappable
    /// chevron-up to collapse back to the summary.
    private var workoutsExpandedView: some View {
        let stats = weeklyWorkoutStats(weekStart: displayedWeekMonday)
        let sortedList = sortedRecentWorkouts

        return VStack(alignment: .leading, spacing: 16) {
            // Header with collapse chevron
            HStack {
                Text("WORKOUTS")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.40))
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                        workoutsExpanded = false
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.60))
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Collapse workouts")
            }

            // Week navigator + 7-day dot strip
            workoutWeekNavigator
            workoutWeekStrip

            // Aggregate row (reflects the displayed week)
            HStack(spacing: 12) {
                aggregateBadge(value: "\(stats.count)",
                               unit:  stats.count == 1 ? "workout" : "workouts")
                aggregateBadge(value: formatMinutes(stats.minutes),
                               unit:  "time")
                aggregateBadge(value: "\(stats.calories)",
                               unit:  "kcal burned")
            }

            Divider().background(Color.white.opacity(0.08))

            // Recent workouts list — header changes when a day is pinned so
            // the user knows why the order is different.
            HStack(spacing: 8) {
                Text(selectedWorkoutDay == nil ? "RECENT" : "SELECTED DAY")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.40))
                if let day = selectedWorkoutDay {
                    Text(selectedDayLabel(day))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(ThemeStore.shared.accent)
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.20)) {
                            selectedWorkoutDay = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear selected day")
                } else {
                    Spacer()
                }
            }

            if recentWorkouts.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.25))
                    Text("No workouts yet. Tap the + button to log one.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.40))
                    Spacer()
                }
                .padding(.vertical, 8)
            } else if let day = selectedWorkoutDay,
                      !sortedList.contains(where: { Calendar.current.isDate($0.loggedAt, inSameDayAs: day) }) {
                // Day was tapped but has no workouts — tell the user, then
                // show the rest of the recent list below.
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.35))
                        Text("No workouts on \(selectedDayLabel(day))")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.45))
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    ForEach(sortedList.prefix(5)) { entry in
                        recentWorkoutRow(entry)
                    }
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(sortedList.prefix(8)) { entry in
                        recentWorkoutRow(entry)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBg)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    /// Header row above the week strip: back/forward chevrons and a label for
    /// the displayed week. Forward is disabled on the current week so the
    /// user can't navigate into the future.
    private var workoutWeekNavigator: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.20)) {
                    workoutsWeekOffset -= 1
                    selectedWorkoutDay = nil
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.70))
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous week")

            Spacer()
            Text(displayedWeekLabel)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.75))
            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.20)) {
                    workoutsWeekOffset = min(0, workoutsWeekOffset + 1)
                    selectedWorkoutDay = nil
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(workoutsWeekOffset >= 0 ? 0.25 : 0.70))
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(workoutsWeekOffset >= 0)
            .accessibilityLabel("Next week")
        }
    }

    /// Mon–Sun strip for the displayed week. Each day is a tap target: tapping
    /// pins that day to the top of the recent-workouts list. Tapping an
    /// already-selected day toggles it off. Filled dot = at least one non-rest
    /// workout that day; ring = today; accent fill = selected day.
    private var workoutWeekStrip: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let monday = displayedWeekMonday
        let days: [Date] = (0..<7).compactMap {
            cal.date(byAdding: .day, value: $0, to: monday)
        }
        let workoutDays = Set(recentWorkouts
            .filter { $0.workoutType != .restDay }
            .map { cal.startOfDay(for: $0.loggedAt) })

        return HStack(spacing: 8) {
            ForEach(days, id: \.self) { day in
                let isFuture  = day > today
                let hasWorkout = workoutDays.contains(day)
                let isToday    = cal.isDateInToday(day)
                let isSelected = selectedWorkoutDay.map { cal.isDate($0, inSameDayAs: day) } ?? false
                Button {
                    // Don't allow selecting a future day — nothing to show.
                    guard !isFuture else { return }
                    withAnimation(.easeInOut(duration: 0.20)) {
                        selectedWorkoutDay = isSelected ? nil : day
                    }
                } label: {
                    VStack(spacing: 6) {
                        Circle()
                            .fill(isSelected
                                  ? ThemeStore.shared.accent
                                  : (hasWorkout
                                     ? ThemeStore.shared.accent.opacity(0.85)
                                     : Color.white.opacity(isFuture ? 0.05 : 0.10)))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Circle()
                                    .stroke(isToday ? Color.white.opacity(0.75) : .clear,
                                            lineWidth: 1.5)
                            )
                            .shadow(color: (hasWorkout || isSelected)
                                    ? ThemeStore.shared.accent.opacity(0.50)
                                    : .clear,
                                    radius: 4)
                        Text(weekdayInitial(day))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(
                                isSelected ? .white
                                : (isToday ? .white.opacity(0.85)
                                           : .white.opacity(isFuture ? 0.25 : 0.45))
                            )
                        Text("\(cal.component(.day, from: day))")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(
                                isSelected ? .white.opacity(0.90)
                                           : .white.opacity(isFuture ? 0.20 : 0.35)
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isFuture)
                .accessibilityLabel(accessibilityLabel(for: day, hasWorkout: hasWorkout,
                                                       isToday: isToday, isSelected: isSelected))
            }
        }
    }

    private func accessibilityLabel(for day: Date,
                                    hasWorkout: Bool,
                                    isToday: Bool,
                                    isSelected: Bool) -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMM d"
        var label = f.string(from: day)
        if isToday     { label += ", today" }
        if hasWorkout  { label += ", has workout" }
        if isSelected  { label += ", selected" }
        return label
    }

    private func selectedDayLabel(_ day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day)     { return "Today" }
        if cal.isDateInYesterday(day) { return "Yesterday" }
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d"
        return f.string(from: day)
    }

    /// Sort workouts by recency, but bubble the selected day's workouts to
    /// the top so tapping a day in the strip "pins" that day.
    private var sortedRecentWorkouts: [WorkoutEntry] {
        let cal = Calendar.current
        let byDateDesc: (WorkoutEntry, WorkoutEntry) -> Bool = { $0.loggedAt > $1.loggedAt }
        guard let day = selectedWorkoutDay else {
            return recentWorkouts.sorted(by: byDateDesc)
        }
        let onDay   = recentWorkouts.filter { cal.isDate($0.loggedAt, inSameDayAs: day) }
                                     .sorted(by: byDateDesc)
        let offDay  = recentWorkouts.filter { !cal.isDate($0.loggedAt, inSameDayAs: day) }
                                     .sorted(by: byDateDesc)
        return onDay + offDay
    }

    private func weekdayInitial(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEEEE"  // narrow: M, T, W, T, F, S, S
        return f.string(from: date)
    }

    private func aggregateBadge(value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(unit)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.50))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }

    private func recentWorkoutRow(_ entry: WorkoutEntry) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ThemeStore.shared.accent.opacity(0.14))
                    .frame(width: 34, height: 34)
                Image(systemName: entry.workoutType.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ThemeStore.shared.accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(entry.workoutType.shortLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.45))
                    if let loc = entry.location, loc.isValid {
                        Text("·")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.30))
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(ThemeStore.shared.accent.opacity(0.80))
                        Text(loc.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(ThemeStore.shared.accent.opacity(0.80))
                            .lineLimit(1)
                    }
                }
                if !entry.taggedFriends.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 9, weight: .semibold))
                        Text(entry.taggedFriends.map { "@\($0.username)" }.joined(separator: ", "))
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(ThemeStore.shared.accent.opacity(0.80))
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.formattedDuration)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(relativeDay(entry.loggedAt))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.40))
            }
        }
    }

    private func formatMinutes(_ m: Int) -> String {
        if m <= 0   { return "0m" }
        if m < 60   { return "\(m)m" }
        let h = m / 60, rem = m % 60
        return rem == 0 ? "\(h)h" : "\(h)h \(rem)m"
    }

    private func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date),
                                      to: cal.startOfDay(for: Date())).day ?? 0
        return "\(days)d ago"
    }

    /// Loads the last 90 days of workouts for the workouts card. Called on
    /// appear, when the user returns to the foreground, and when a workout
    /// is saved elsewhere in the app (via WorkoutService's notification).
    /// 90 days is enough for the week strip to page back roughly a quarter.
    @MainActor
    private func loadRecentWorkouts() async {
        let userID = viewModel.userSettings.userID
        guard !userID.isEmpty else { return }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let start = cal.date(byAdding: .day, value: -90, to: today),
              let end   = cal.date(byAdding: .day, value:   1, to: today) else { return }
        do {
            recentWorkouts = try await WorkoutService.shared.fetchRange(
                userID: userID, from: start, to: end)
        } catch {
            AppLogger.log("Failed to load recent workouts for Hub card: \(error)")
        }
    }

    // Range helpers — displayed as "lo – hi" under each macro goal
    private var caloriesRange: String {
        "\(Int(viewModel.displayGoalCalories * 0.85)) – \(Int(viewModel.displayGoalCalories * 1.15))"
    }
    private func minRange(_ goal: Double) -> String {
        "\(Int(goal * 0.85)) – \(Int(goal * 1.15))"
    }

    // MARK: - Brainstorm section

    private var brainstormSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(ThemeStore.shared.accent.opacity(0.16))
                        .frame(width: 30, height: 30)
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ThemeStore.shared.accent)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("AI Meal Planner")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Personalized to your macro gaps")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.35))
                }
            }

            switch viewModel.brainstormState {
            case .idle:
                Text("See what to eat to hit your remaining macro goals for the rest of the day — specific meals and snacks suggested holistically.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.50))
                    .lineSpacing(2)
            case .loading:
                BrainstormSkeletonView()
            case .result(let text):
                macroGapSummary
                brainstormResult(text)
            case .error(let msg):
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text(msg).font(.caption).foregroundStyle(.white.opacity(0.65))
                    }
                    Button {
                        Task { await viewModel.brainstorm() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(ThemeStore.shared.accent.opacity(0.5))
                        .cornerRadius(10)
                    }
                }
            }

            Button {
                if !aiSubscription.isSubscribed {
                    showingAIPaywall = true
                } else if !viewModel.userSettings.aiConsentGiven {
                    showingAIConsent = true
                } else if viewModel.userSettings.brainstormLimitReached {
                    brainstormAlert = .limitReached
                } else {
                    brainstormAlert = .confirm
                }
            } label: {
                // Inner label — styled as a gold pill with the shimmer
                // overlay placed DIRECTLY on the background. Using a plain
                // button (rather than .borderedProminent) means the system
                // doesn't re-wrap the view and swallow the shimmer.
                let limitReached = aiSubscription.isSubscribed
                    && viewModel.userSettings.brainstormLimitReached
                let background: Color = limitReached ? .gray : .premiumGold
                HStack(spacing: 6) {
                    if !aiSubscription.isSubscribed {
                        Image(systemName: "sparkles")
                        Text(aiSubscription.isEligibleForIntroOffer
                             ? "Try AI Free for 3 Days"
                             : "Unlock AI Meal Planner")
                    } else if viewModel.userSettings.brainstormLimitReached {
                        Image(systemName: "xmark.circle.fill")
                        Text("Daily limit reached (2/2)")
                    } else {
                        Image(systemName: "lightbulb.fill")
                        Text(viewModel.brainstormState == .idle ? "Brainstorm next meal" : "Re-Brainstorm")
                        Text("(\(viewModel.userSettings.brainstormUsesRemaining) left today)")
                            .opacity(0.65)
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(background, in: RoundedRectangle(cornerRadius: 10))
                .shimmering(cornerRadius: 10)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.brainstormState == .loading)
            .alert(item: $brainstormAlert) { alert in
                switch alert {
                case .confirm:
                    Alert(
                        title: Text("Brainstorm Next Meal"),
                        message: Text("AI will suggest a specific meal based on your current macro balance. You have \(viewModel.userSettings.brainstormUsesRemaining) use\(viewModel.userSettings.brainstormUsesRemaining == 1 ? "" : "s") left today."),
                        primaryButton: .default(Text("Let's Go")) {
                            let doBrainstorm = {
                                if viewModel.userSettings.consumeBrainstormUse() {
                                    Task { await viewModel.brainstorm() }
                                }
                            }
                            if RemoteConfigService.shared.brainstormAdRequired {
                                AdManager.shared.showRewarded(onReward: doBrainstorm)
                            } else {
                                doBrainstorm()
                            }
                        },
                        secondaryButton: .cancel()
                    )
                case .limitReached:
                    Alert(
                        title: Text("Daily Limit Reached"),
                        message: Text("You've used both brainstorm suggestions for today. Come back tomorrow for 2 more."),
                        dismissButton: .default(Text("Got it"))
                    )
                }
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(18)
        .overlay(
            ShootingStarBorder(
                cornerRadius: 18,
                color: ThemeStore.shared.accent,
                lineWidth: 1.5,
                duration: 2.8,
                reversed: true
            )
        )
    }

    @ViewBuilder
    private var macroGapSummary: some View {
        let goalCal  = viewModel.displayGoalCalories
        let goalPro  = viewModel.displayGoalProtein
        let goalCarb = viewModel.displayGoalCarbs
        let goalFat  = viewModel.displayGoalFat

        // Room to the upper limit (goal + 15%) — this is the real budget.
        let roomCal = max(0, goalCal * 1.15 - viewModel.totalCalories)
        let overGoalCal = viewModel.totalCalories > goalCal

        // Determine which macros still need significant intake (>15% of goal remaining)
        let remainPro  = max(0, goalPro  - viewModel.totalProtein)
        let remainCarb = max(0, goalCarb - viewModel.totalCarbs)
        let remainFat  = max(0, goalFat  - viewModel.totalFat)
        var needs: [String] = []
        if remainPro  > goalPro  * 0.15 { needs.append("protein") }
        if remainCarb > goalCarb * 0.15 { needs.append("carbs") }
        if remainFat  > goalFat  * 0.15 { needs.append("fat") }

        let summary: String
        if roomCal <= 0 {
            summary = "You've hit your calorie limit. Check tomorrow's plan below."
        } else if needs.isEmpty {
            summary = "You're close to hitting all your macros — just \(Int(roomCal)) cal of room left. Here's a light option to finish the day."
        } else {
            let joined = needs.count == 1 ? needs[0]
                : needs.dropLast().joined(separator: ", ") + " and " + needs.last!
            if overGoalCal {
                summary = "You're over your calorie goal but have \(Int(roomCal)) cal of room left. You just need more \(joined) — grab a quick lean snack."
            } else {
                summary = "You have \(Int(roomCal)) cal of room and need more \(joined). Here's what to eat next."
            }
        }

        return Text(summary)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(ThemeStore.shared.accent.opacity(0.85))
            .lineSpacing(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4)
    }

    private func brainstormResult(_ text: String) -> some View {
        if let attr = try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) {
            Text(attr)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func goalForMacro(_ macro: MacroType) -> Double {
        switch macro {
        case .calories: return viewModel.displayGoalCalories
        case .protein:  return viewModel.displayGoalProtein
        case .carbs:    return viewModel.displayGoalCarbs
        case .fat:      return viewModel.displayGoalFat
        }
    }
}

// MARK: - Date Navigator (internal — shared with FoodLogView)

struct DateNavigatorView: View {
    @Binding var selectedDate: Date
    @State private var showingPicker = false

    private let calendar = Calendar.current

    private var isToday: Bool { calendar.isDateInToday(selectedDate) }

    private var displayText: String {
        if isToday { return "Today" }
        if calendar.isDateInYesterday(selectedDate) { return "Yesterday" }
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d"
        return f.string(from: selectedDate)
    }

    var body: some View {
        HStack(spacing: 0) {
            Button {
                guard let prev = calendar.date(byAdding: .day, value: -1, to: selectedDate) else { return }
                selectedDate = calendar.startOfDay(for: prev)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 38)
            }
            .accessibilityLabel("Previous day")

            Button { showingPicker = true } label: {
                Text(displayText)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
            }
            .accessibilityLabel("Selected date: \(displayText)")
            .accessibilityHint("Opens date picker")

            Button {
                guard !isToday,
                      let next = calendar.date(byAdding: .day, value: 1, to: selectedDate) else { return }
                selectedDate = calendar.startOfDay(for: next)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isToday ? .white.opacity(0.20) : .white)
                    .frame(width: 44, height: 38)
            }
            .disabled(isToday)
            .accessibilityLabel("Next day")

            if !isToday {
                Button("Today") {
                    selectedDate = calendar.startOfDay(for: Date())
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ThemeStore.shared.accent)
                .buttonStyle(.plain)
                .padding(.leading, 6)
                .padding(.trailing, 12)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .padding(.leading, 4)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.11, green: 0.11, blue: 0.14))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: isToday)
        .sheet(isPresented: $showingPicker) {
            DatePickerSheet(selectedDate: $selectedDate)
                .presentationDetents([.medium])
        }
    }
}

private struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker("Select Date", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding(.horizontal)
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
                }
                .onChange(of: selectedDate) { _, newDate in
                    selectedDate = Calendar.current.startOfDay(for: newDate)
                }
        }
    }
}

// MARK: - Goal KPI Card

private struct GoalKPICard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    var action: (() -> Void)? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        Group {
            if let action {
                Button(action: action) { cardBody }.buttonStyle(.plain)
            } else {
                cardBody
            }
        }
    }

    @ViewBuilder
    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.16))
                        .frame(width: 22, height: 22)
                    Image(systemName: icon)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(iconColor)
                }
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.40))
                    .tracking(0.8)
                if action != nil {
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.18))
                }
            }
            content().frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.11, green: 0.08, blue: 0.20))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

// MARK: - Macro Gauge Card

private struct MacroGaugeCard: View {
    let label: String
    let value: Double
    let goal: Double
    let unit: String
    let format: String
    let color: Color
    var action: (() -> Void)? = nil
    var rangeText: String? = nil

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }
    private var isGoalMet: Bool {
        guard goal > 0 else { return false }
        let pct = value / goal
        return pct >= 0.85 && pct <= 1.15
    }
    private let trackFraction: Double = 0.75
    private let lineWidth: CGFloat = 12

    /// How far under or over the goal the current value is.
    private var delta: Double { goal - value }

    /// Text shown below the number: "–X left" when under goal, "+X over" when over.
    private var deltaLabel: String? {
        guard goal > 0, abs(delta) >= 1 else { return nil }
        let n = String(format: format, abs(delta))
        return delta > 0 ? "+\(n) left" : "–\(n) over"
    }

    private var deltaColor: Color {
        guard goal > 0 else { return .yellow }
        let pct = value / goal
        if pct >= 0.85 && pct <= 1.15 { return .green }
        return pct > 1.15 ? Color(red: 1.0, green: 0.35, blue: 0.35) : .yellow
    }

    /// How much room is left before exceeding 115% of the goal. Shown when over 100% but still in range.
    private var bufferLabel: String? {
        guard goal > 0 else { return nil }
        let pct = value / goal
        guard pct > 1.0 && pct <= 1.15 else { return nil }
        let remaining = (goal * 1.15) - value
        guard remaining >= 1 else { return nil }
        return "\(String(format: format, remaining)) until over"
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .trim(from: 0, to: trackFraction)
                    .stroke(color.opacity(0.12), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(135))
                Circle()
                    .trim(from: 0, to: progress * trackFraction)
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: color.opacity(0.55), location: 0),
                                .init(color: color, location: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                    .animation(.easeOut(duration: 0.6), value: progress)
                    .shadow(color: isGoalMet ? color.opacity(0.55) : .clear, radius: 8)
                VStack(spacing: 1) {
                    if isGoalMet {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(color)
                    }
                    Text(String(format: format, value))
                        .font(.system(size: isGoalMet ? 15 : 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(unit)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.35))
                    if let label = deltaLabel {
                        Text(label)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(deltaColor)
                            .padding(.top, 2)
                    }
                    if let buf = bufferLabel {
                        Text(buf)
                            .font(.system(size: 8, weight: .semibold, design: .rounded))
                            .foregroundStyle(.yellow)
                    }
                }
            }
            .frame(width: 118, height: 118)
            .padding(.top, 4)
            VStack(spacing: 3) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(isGoalMet
                     ? "Goal: \(String(format: format, goal)) \(unit) ✓"
                     : "Goal: \(String(format: format, goal)) \(unit)")
                    .font(.caption2)
                    .foregroundStyle(isGoalMet ? color.opacity(0.85) : .white.opacity(0.45))
                if let rangeText {
                    Text("Range: \(rangeText) \(unit)")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(
            ZStack {
                Color.cardBg
                if isGoalMet {
                    color.opacity(0.06)
                }
            }
        )
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isGoalMet ? color.opacity(0.28) : Color.white.opacity(0.07), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { action?() }
        .overlay(alignment: .topTrailing) {
            if action != nil {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(color.opacity(0.40))
                    .padding(10)
            }
        }
    }
}

// MARK: - Mini Macro Gauge
//
// Compact radial gauge used inside the collapsed `MacroSummaryCard`. Shows
// four of these side-by-side so the user can see all macro progress at a
// glance without taking up the full 2×2 grid footprint.

private struct MiniMacroGauge: View {
    let label: String
    let value: Double
    let goal:  Double
    let unit:  String
    let color: Color

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }
    private var isGoalMet: Bool {
        guard goal > 0 else { return false }
        let pct = value / goal
        return pct >= 0.85 && pct <= 1.15
    }
    private let trackFraction: Double = 0.75
    private let lineWidth: CGFloat = 5

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .trim(from: 0, to: trackFraction)
                    .stroke(color.opacity(0.14),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(135))
                Circle()
                    .trim(from: 0, to: progress * trackFraction)
                    .stroke(color,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(135))
                    .animation(.easeOut(duration: 0.6), value: progress)
                    .shadow(color: isGoalMet ? color.opacity(0.55) : .clear, radius: 6)

                if isGoalMet {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(color)
                } else {
                    Text(String(format: "%.0f", value))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            }
            .frame(width: 56, height: 56)

            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.70))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Window Picker Sheet

struct WindowPickerSheet: View {
    @Binding var windowStartDate: Date
    @Binding var windowDurationHours: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Start Time") {
                    DatePicker("Start Time", selection: $windowStartDate, displayedComponents: .hourAndMinute)
                }
                Section {
                    Picker("Duration", selection: $windowDurationHours) {
                        ForEach(1...23, id: \.self) { h in
                            Text("\(h) hour\(h == 1 ? "" : "s")").tag(h)
                        }
                    }
                    .pickerStyle(.menu)
                } footer: {
                    Text("Common windows: 6, 8, 10, or 12 hours.")
                }
            }
            .navigationTitle("Intermittent Fasting Window")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}


/// MARK: - Brainstorm skeleton

private struct BrainstormSkeletonView: View {
    @State private var pulse = false

    private var purpl: Color { ThemeStore.shared.accent }
    private let lines = ["████████████████████", "████████████", "██████████████████"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ProgressView().scaleEffect(0.7).tint(purpl)
                Text("AI is thinking…")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.40))
            }
            VStack(alignment: .leading, spacing: 6) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.subheadline)
                        .foregroundStyle(purpl.opacity(0.25))
                        .redacted(reason: .placeholder)
                }
            }
        }
        .opacity(pulse ? 0.4 : 1.0)
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }
}

// MARK: - Preview

#Preview {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodEntry.self, configurations: config)
    return NavigationStack {
        HomeView(
            modelContext: container.mainContext,
            selectedDate: .constant(Calendar.current.startOfDay(for: Date())),
            userSettings: UserSettings()
        )
    }
}
