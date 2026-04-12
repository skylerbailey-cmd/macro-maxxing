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
    @State private var fabShowingCamera      = false
    @State private var fabShowingLibrary     = false
    @State private var fabShowingNewPost     = false
    @State private var fabShowingSearch      = false
    @State private var fabShowingLogWorkout  = false
    @State private var fabShowingSavedMeals  = false
    @State private var fabSelectedImage: UIImage? = nil

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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
                                userSettings: userSettings, externalImage: $fabSelectedImage)
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
                    showingAppTour = true
                }
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
                    fabShowingCamera = false
                    fabShowingLibrary = false
                    fabShowingNewPost = false
                    fabShowingSearch = false
                    fabShowingLogWorkout = false
                    fabShowingSavedMeals = false
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
                onLogMealCamera: {
                    fabExpanded = false
                    selectedTab = 1
                    fabShowingCamera = true
                },
                onLogMealLibrary: {
                    fabExpanded = false
                    selectedTab = 1
                    fabShowingLibrary = true
                },
                onLogMealSaved: {
                    fabExpanded = false
                    selectedTab = 1
                    fabShowingSavedMeals = true
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
        .sheet(isPresented: $fabShowingCamera) {
            ImagePickerView(sourceType: .camera, selectedImage: $fabSelectedImage)
        }
        .sheet(isPresented: $fabShowingLibrary) {
            ImagePickerView(sourceType: .photoLibrary, selectedImage: $fabSelectedImage)
        }
        .sheet(isPresented: $fabShowingSavedMeals) {
            SavedMealsSheet(userID: userSettings.userID, selectedDate: selectedDate)
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
        .onChange(of: fabSelectedImage) { _, image in
            if image != nil { selectedTab = 1 }
        }
    }

}

// MARK: - Quick Action FAB

private struct QuickActionFAB: View {
    @Binding var expanded: Bool
    let onLogMealCamera:  () -> Void
    let onLogMealLibrary: () -> Void
    let onLogMealSaved:   () -> Void
    let onLogWorkout:     () -> Void
    let onMakePost:       () -> Void
    let onFindPeople:     () -> Void


    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)
    private let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let teal   = Color(red: 0.20, green: 0.80, blue: 0.70)
    private let green  = Color(red: 0.30, green: 0.90, blue: 0.55)

    @State private var logMealExpanded = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if expanded {
                // Sub-actions under Log a Meal
                if logMealExpanded {
                    actionPill(icon: "bookmark.fill", label: "Saved Meals", color: purpl,
                               action: onLogMealSaved)

                    actionPill(icon: "photo.on.rectangle", label: "Photo Library", color: purpl,
                               action: onLogMealLibrary)

                    actionPill(icon: "camera.fill", label: "Camera",
                               color: purpl,
                               disabled: !UIImagePickerController.isSourceTypeAvailable(.camera),
                               action: onLogMealCamera)
                }

                actionPill(
                    icon: logMealExpanded ? "chevron.down" : "flame.fill",
                    label: "Log a Meal",
                    color: purpl
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        logMealExpanded.toggle()
                    }
                }

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
                    if expanded { logMealExpanded = false }
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

// MARK: - Saved Meals Sheet (loads meals and handles logging)

private struct SavedMealsSheet: View {
    let userID: String
    let selectedDate: Date
    @State private var savedMeals: [FoodEntry] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .preferredColorScheme(.dark)
            } else {
                SavedMealsView(savedMeals: savedMeals, onSelect: { meal in
                    logMeal(meal)
                }, onDelete: { meal in
                    savedMeals.removeAll { $0.id == meal.id }
                    Task { await FoodEntryService.shared.delete(entryID: meal.firebaseEntryID, userID: userID) }
                }, onEdit: { meal, name, cal, pro, carb, fat in
                    // Update locally
                    if let idx = savedMeals.firstIndex(where: { $0.id == meal.id }) {
                        savedMeals[idx].foodName = name
                        savedMeals[idx].calories = cal
                        savedMeals[idx].protein  = pro
                        savedMeals[idx].carbs    = carb
                        savedMeals[idx].fat      = fat
                    }
                    // Persist to Firestore
                    Task {
                        await FoodEntryService.shared.update(
                            entryID: meal.firebaseEntryID, userID: userID,
                            foodName: name, calories: cal, protein: pro, carbs: carb, fat: fat)
                    }
                })
            }
        }
        .task {
            savedMeals = (try? await FoodEntryService.shared.fetchSavedMeals(userID: userID)) ?? []
            isLoading = false
        }
    }

    private func logMeal(_ meal: FoodEntry) {
        let calendar = Calendar.current
        var comps    = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let now      = Date()
        comps.hour   = calendar.component(.hour,   from: now)
        comps.minute = calendar.component(.minute, from: now)
        comps.second = calendar.component(.second, from: now)
        let loggedAt = calendar.date(from: comps) ?? selectedDate

        let entry = FoodEntry(
            loggedAt: loggedAt,
            userID:   userID,
            foodName: meal.foodName,
            calories: meal.calories,
            protein:  meal.protein,
            carbs:    meal.carbs,
            fat:      meal.fat
        )
        // Carry over the photo URL from the saved meal
        entry.photoURL = meal.photoURL

        Task {
            _ = try? await FoodEntryService.shared.save(entry: entry, imageData: nil, existingPhotoURL: meal.photoURL)
            // Post notification so FoodLogView refreshes
            NotificationCenter.default.post(name: .init("FoodEntryAdded"), object: nil)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodEntry.self, configurations: config)
    return ContentView()
        .modelContainer(container)
}
