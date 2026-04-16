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
    @State private var showingProfile     = false
    @State private var showingGoalPost    = false
    @State private var showingAIConsent   = false
    @State private var goalPostMeme       = GymMeme.random()
    @State private var brainstormAlert: BrainstormAlert? = nil
    @State private var showingNotifications = false
    @State private var showingCheatDay       = false
    @State private var showingStreakExtension = false
    @State private var showingAIPaywall       = false
    @State private var aiSubscription = AISubscriptionStore.shared

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
        let name = viewModel.userSettings.name.trimmingCharacters(in: .whitespaces)
        let phrase = Self.greetingPhrases[dayOfYear % Self.greetingPhrases.count]
        return name.isEmpty ? phrase : "\(phrase), \(name)"
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
            .sheet(isPresented: $showingProfile) {
                NavigationStack {
                    ProfileView(
                        profileUserID:      viewModel.userSettings.userID,
                        profileUsername:    viewModel.userSettings.username,
                        profileDisplayName: viewModel.userSettings.name,
                        profileAuraLevel:   viewModel.userSettings.auraLevel,
                        profileAuraPoints:  viewModel.userSettings.auraPoints,
                        profileImageData:   viewModel.userSettings.profileImageData,
                        profileLocation:    viewModel.userSettings.location,
                        ownUserSettings:    viewModel.userSettings,
                        isDismissable:      true
                    )
                }
            }
            .onAppear { handleAppear() }
            .onReceive(NotificationCenter.default.publisher(for: FuelLogService.mealChangedNotification)) { _ in
                Task { viewModel.loadTodayTotals() }
            }
            .onReceive(NotificationCenter.default.publisher(for: MacroAdjustmentEngine.macroAdjustedNotification)) { _ in
                viewModel.reloadGoalsFromDefaults()
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
                        Button { showingProfile = true } label: {
                            profileAvatarIcon
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Profile")
                        .accessibilityHint("Opens your profile")
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
        let barColor  = LinearGradient(
            colors: [ThemeStore.shared.accent,
                     ThemeStore.shared.accent],
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
                        Capsule()
                            .fill(barColor)
                            .frame(width: max(5, geo.size.width * progress), height: 5)
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

    private var profileAvatarIcon: some View {
        let purpl = ThemeStore.shared.accent
        let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)
        return Group {
            if let data = viewModel.userSettings.profileImageData,
               let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(purpl, lineWidth: 1.5))
            } else {
                ZStack {
                    Circle()
                        .fill(cardBg)
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(purpl, lineWidth: 1.5))
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(purpl)
                }
            }
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
                let met = viewModel.macrosMetToday
                let macroColor: Color = met == 4 ? Color.macroMint : met >= 2 ? .orange : .red
                Text("\(met)/4 macros")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(macroColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(macroColor.opacity(0.14))
                    .cornerRadius(8)
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

    private var macrosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
            .tutorialAnchor("hub.macros")
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
            }
            .buttonStyle(.borderedProminent)
            .tint(
                aiSubscription.isSubscribed && viewModel.userSettings.brainstormLimitReached
                ? Color.gray
                : ThemeStore.shared.accent
            )
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
