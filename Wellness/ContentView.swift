//
//  ContentView.swift
//  Wellness
//
//  Created by Skyler Bailey on 3/11/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext)  private var modelContext
    @Environment(UserSettings.self) private var userSettings
    @Environment(SessionManager.self) private var auth
    @State private var selectedDate     = Calendar.current.startOfDay(for: Date())
    @State private var locationManager  = LocationManager()

    @Query(sort: \SocialPost.postedAt, order: .reverse) private var allPosts: [SocialPost]

    @Environment(\.scenePhase) private var scenePhase
    @State private var notificationState = NotificationState()
    @State private var selectedTab = 0

    @AppStorage("hasSeenAppTour") private var hasSeenAppTour = false
    @State private var showingAppTour = false
    @State private var tutorialAnchors: [String: Anchor<CGRect>] = [:]

    // Aura popup
    @State private var pendingAuraGain: AuraGain? = nil
    // Celebration popup
    @State private var pendingCelebration: CelebrationPostData? = nil
    // Firestore error alert
    @State private var firestoreErrorMessage: String? = nil
    // Streak congrats alert
    @State private var streakCongratsCount: Int? = nil
    // Streak shield sheet
    @State private var streakBreakCount: Int? = nil

    // FAB state
    @State private var fabExpanded           = false
    @State private var fabShowingNewPost     = false
    @State private var fabShowingSearch      = false
    @State private var fabShowingLogWorkout  = false
    @State private var fabOpenLogMeal        = false

    var body: some View {
        // Convert the @Environment-bound SessionManager into a @Bindable so
        // we can build proper $-bindings against its observable properties
        // (e.g. for the post-onboarding paywall fullScreenCover).
        @Bindable var auth = auth

        return ZStack(alignment: .bottomTrailing) {
            Color.pageBg.ignoresSafeArea()

            // Email verification nudge — full-width gold bar at the top until dismissed
            if auth.needsEmailVerification {
                VStack(spacing: 0) {
                    EmailVerificationBannerView()
                        .environment(auth)
                    Spacer()
                }
                .zIndex(10)
            }

            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView(modelContext: modelContext, selectedDate: $selectedDate, userSettings: userSettings)
                }
                .tabItem { Label("Hub", systemImage: "bolt.fill") }
                .tag(0)

                NavigationStack {
                    FoodLogView(modelContext: modelContext, selectedDate: $selectedDate,
                                userSettings: userSettings, openLogMealTrigger: $fabOpenLogMeal)
                }
                .tabItem { Label("Log", systemImage: "flame.fill") }
                .tag(1)

                NavigationStack {
                    SocialView(userSettings: userSettings)
                }
                .tabItem { Label("Feed", systemImage: "bolt.heart.fill") }
                .tag(2)

                NavigationStack {
                    LeaderboardView(userSettings: userSettings)
                }
                .tabItem { Label("Board", systemImage: "crown.fill") }
                .tag(3)
            }
            .environment(locationManager)
            .environment(notificationState)
            .onPreferenceChange(TutorialAnchorKey.self) { tutorialAnchors = $0 }
            .task { await notificationState.refresh(userID: userSettings.userID) }
            .task {
                // Lock past fasting windows once at app launch (not every HomeView appear)
                // to avoid expensive batch writes on each tab switch.
                guard !userSettings.userID.isEmpty else { return }
                await FastingWindowService.shared.lockPastWindows(userID: userSettings.userID)
            }
            .task(id: userSettings.userID) {
                // Always notify the listener of the current uid — an empty string
                // tells it to stop the previous user's listener, which prevents
                // stale listeners from producing permissions errors after sign-out.
                InAppNotificationService.shared.startNewPostListener(userID: userSettings.userID)
                guard !userSettings.userID.isEmpty else { return }
                if !hasSeenAppTour {
                    try? await Task.sleep(for: .seconds(0.6))
                    // Don't race the post-onboarding paywall — the tutorial
                    // waits for it to dismiss (see onChange below).
                    if !auth.showPostOnboardPaywall {
                        showingAppTour = true
                    }
                }
            }
            // When the post-onboarding paywall closes, kick off the app tour
            // for users who still haven't seen it (e.g. brand-new signups).
            .onChange(of: auth.showPostOnboardPaywall) { _, isShowing in
                if isShowing == false && !hasSeenAppTour {
                    Task {
                        try? await Task.sleep(for: .seconds(0.4))
                        showingAppTour = true
                    }
                }
            }
            .fullScreenCover(isPresented: $auth.showPostOnboardPaywall) {
                AISubscriptionPaywallView(
                    onSubscribed: {
                        auth.showPostOnboardPaywall      = false
                        auth.pendingOnboardingPromoCode  = nil
                    },
                    onDismiss: {
                        auth.showPostOnboardPaywall      = false
                        auth.pendingOnboardingPromoCode  = nil
                    },
                    prefilledPromoCode: auth.pendingOnboardingPromoCode
                )
            }
            .onChange(of: userSettings.userID) { _, newID in
                guard !newID.isEmpty else { return }
                Task { await notificationState.refresh(userID: newID) }
            }
            .onChange(of: userSettings.pendingAuraGain) { _, gain in
                if let gain { pendingAuraGain = gain }
            }
            .onChange(of: userSettings.pendingCelebration) { _, data in
                if let data { pendingCelebration = data }
            }
            .onChange(of: userSettings.firestoreError) { _, err in
                if let err {
                    firestoreErrorMessage = err
                    userSettings.firestoreError = nil
                }
            }
            .onChange(of: userSettings.pendingStreakCongrats) { _, count in
                if let count {
                    streakCongratsCount = count
                    userSettings.pendingStreakCongrats = nil
                }
            }
            .onChange(of: userSettings.pendingStreakBreak) { _, count in
                if let count {
                    streakBreakCount = count
                    userSettings.pendingStreakBreak = nil
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    // Reset to Hub tab and dismiss any open sheets/FAB
                    // so the app feels fresh after force-quit or background return
                    selectedTab = 0
                    fabExpanded = false
                    fabShowingNewPost = false
                    fabShowingSearch = false
                    fabShowingLogWorkout = false
                    fabOpenLogMeal = false
                    selectedDate = Calendar.current.startOfDay(for: Date())
                }
            }
            .alert("Firestore Write Error", isPresented: Binding(
                get: { firestoreErrorMessage != nil },
                set: { if !$0 { firestoreErrorMessage = nil } }
            )) {
                Button("OK") { firestoreErrorMessage = nil }
            } message: {
                Text(firestoreErrorMessage ?? "")
            }
            .alert("🔥 Streak Extended!", isPresented: Binding(
                get: { streakCongratsCount != nil },
                set: { if !$0 { streakCongratsCount = nil } }
            )) {
                Button("Let's Go!") { streakCongratsCount = nil }
            } message: {
                if let n = streakCongratsCount {
                    Text("You hit all your macro goals today. That's \(n) day\(n == 1 ? "" : "s") in a row. Keep it up.")
                }
            }

            // Celebration popup — shown on top of all tabs
            if let data = pendingCelebration {
                CelebrationView(
                    macroGoalsMet: [true, true, true, true],
                    userName:      userSettings.name,
                    userSettings:  userSettings,
                    postData:      data,
                    onDismiss: {
                        pendingCelebration = nil
                        userSettings.pendingCelebration = nil
                    }
                )
                .environment(locationManager)
                .transition(.opacity)
                .zIndex(20)
            }

            // Aura popup — shown on top of all tabs
            if let gain = pendingAuraGain {
                AuraPopupView(
                    gain:         gain,
                    userSettings: userSettings,
                    onDismiss: {
                        pendingAuraGain = nil
                        userSettings.pendingAuraGain = nil
                    }
                )
                .transition(.opacity)
                .zIndex(20)
            }

            // Full app tour — shown once after first login
            if showingAppTour {
                TutorialOverlayView(
                    steps: TutorialSteps.appTour,
                    selectedTab: $selectedTab,
                    anchors: tutorialAnchors,
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.25)) { showingAppTour = false }
                        hasSeenAppTour = true
                    }
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                .zIndex(30)
            }

            // Tap-to-dismiss overlay when FAB is open
            if fabExpanded {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.25)) { fabExpanded = false }
                    }
            }

            QuickActionFAB(
                expanded: $fabExpanded,
                onLogMeal: {
                    fabExpanded = false
                    selectedTab = 1
                    fabOpenLogMeal = true
                },
                onLogWorkout: {
                    fabExpanded = false
                    selectedTab = 1
                    fabShowingLogWorkout = true
                },
                onMakePost: {
                    fabExpanded = false
                    fabShowingNewPost = true
                },
                onFindPeople: {
                    fabExpanded = false
                    fabShowingSearch = true
                }
            )
            .padding(.trailing, 20)
            .padding(.bottom, 88)
        }
        .sheet(isPresented: $fabShowingLogWorkout) {
            LogWorkoutSheet(
                userID:              userSettings.userID,
                selectedDate:        selectedDate,
                bodyWeightLbs:       userSettings.currentWeight,
                autoAdjustByDefault: userSettings.autoAdjustMacrosForWorkout,
                userSettings:        userSettings,
                onSaved:             {}
            )
            .environment(locationManager)
        }
        .sheet(isPresented: $fabShowingNewPost) {
            NewPostView(userSettings: userSettings)
                .environment(locationManager)
        }
        .sheet(isPresented: $fabShowingSearch) {
            UserSearchView(currentUserSettings: userSettings)
                .environment(locationManager)
        }
        .sheet(isPresented: Binding(
            get: { streakBreakCount != nil },
            set: { if !$0 { streakBreakCount = nil } }
        )) {
            if let broken = streakBreakCount {
                StreakShieldView(
                    brokenStreak: broken,
                    onRestore: {
                        userSettings.applyStreakShield(userID: userSettings.userID)
                        streakBreakCount = nil
                    },
                    onDismiss: {
                        // Clear so the popup never re-shows for this break
                        userSettings.lastStreakBeforeBreak = 0
                        userSettings.streakBreakDate       = ""
                        streakBreakCount = nil
                    }
                )
            }
        }
    }

}

// MARK: - Quick Action FAB

private struct QuickActionFAB: View {
    @Binding var expanded: Bool
    let onLogMeal:    () -> Void
    let onLogWorkout: () -> Void
    let onMakePost:   () -> Void
    let onFindPeople: () -> Void


    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)
    private let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let teal   = Color(red: 0.20, green: 0.80, blue: 0.70)
    private let green  = Color(red: 0.30, green: 0.90, blue: 0.55)

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if expanded {
                actionPill(icon: "flame.fill", label: "Log a Meal", color: purpl,
                           action: onLogMeal)

                actionPill(icon: "figure.strengthtraining.traditional", label: "Log a Workout",
                           color: green, action: onLogWorkout)

                actionPill(icon: "square.and.pencil", label: "Make a Post", color: gold,
                           action: onMakePost)

                actionPill(icon: "person.2.fill", label: "Find People", color: teal,
                           action: onFindPeople)
            }

            // Main FAB button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    expanded.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: expanded
                                    ? [Color(red: 0.18, green: 0.13, blue: 0.30),
                                       Color(red: 0.12, green: 0.09, blue: 0.22)]
                                    : [gold, Color(red: 1.00, green: 0.60, blue: 0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: expanded ? .clear : gold.opacity(0.45), radius: 14, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(expanded ? .white.opacity(0.60) : .black)
                        .rotationEffect(.degrees(expanded ? 45 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: expanded)
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func actionPill(icon: String, label: String, color: Color,
                            disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(disabled ? .white.opacity(0.30) : .white)

                ZStack {
                    Circle()
                        .fill(color.opacity(disabled ? 0.06 : 0.18))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(disabled ? color.opacity(0.30) : color)
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 6)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(disabled ? 0.10 : 0.30), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.85, anchor: .bottomTrailing).combined(with: .opacity),
                removal:   .scale(scale: 0.85, anchor: .bottomTrailing).combined(with: .opacity)
            )
        )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodEntry.self, configurations: config)
    return ContentView()
        .modelContainer(container)
}
