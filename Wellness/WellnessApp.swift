//
//  WellnessApp.swift
//  Wellness
//
//  Created by Skyler Bailey on 3/11/26.
//

import UIKit
import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import BackgroundTasks
import UserNotifications
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {

    static let feedRefreshTaskID  = "com.sbailey.Wellness.feedRefresh"
    static let streakResetTaskID  = "com.sbailey.Wellness.streakReset"

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        NotificationService.shared.requestAuthorization()

        // 50 MB memory + 200 MB disk cache so food photos survive across sessions
        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity:   200 * 1024 * 1024,
            diskPath:       "image_cache"
        )

        // Register background feed-refresh task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.feedRefreshTaskID,
            using: nil
        ) { task in
            self.handleFeedRefresh(task as! BGAppRefreshTask)
        }

        // Register nightly streak-reset task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.streakResetTaskID,
            using: nil
        ) { task in
            self.handleStreakReset(task as! BGAppRefreshTask)
        }

        return true
    }

    // Schedule both tasks when app moves to background
    func applicationDidEnterBackground(_ application: UIApplication) {
        Self.scheduleFeedRefresh()
        Self.scheduleStreakReset()
    }

    // MARK: - Feed refresh

    static func scheduleFeedRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: feedRefreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleFeedRefresh(_ task: BGAppRefreshTask) {
        Self.scheduleFeedRefresh()
        let fetchTask = Task {
            _ = try? await PostService.shared.fetchFeedPosts(limit: 20)
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = { fetchTask.cancel() }
    }

    // MARK: - Streak reset (nightly at 12:01 AM)

    /// Schedules the streak-reset task to run at 12:01 AM tonight.
    /// Each time it fires it reschedules itself for the following midnight.
    static func scheduleStreakReset() {
        let request = BGAppRefreshTaskRequest(identifier: streakResetTaskID)
        let cal = Calendar.current
        // Next midnight = start of tomorrow
        let tomorrow   = cal.date(byAdding: .day, value: 1, to: Date())!
        let midnight   = cal.startOfDay(for: tomorrow)
        // Add 61 seconds so it fires just after 12:01 AM
        request.earliestBeginDate = midnight.addingTimeInterval(61)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleStreakReset(_ task: BGAppRefreshTask) {
        // Streak is now checked on app launch via StreakService.checkAndUpdateStreak.
        // This background slot is kept registered so the OS doesn't penalise the app,
        // but no streak logic runs here.
        Self.scheduleStreakReset()
        task.setTaskCompleted(success: true)
    }
}

@main
struct WellnessApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @State private var showSplash   = true
    @State private var session:     SessionManager
    @State private var userSettings: UserSettings

    init() {
        // Configure Firebase before any Firebase service (Auth, Firestore) is touched.
        FirebaseApp.configure()
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }

        // Wire SessionManager ↔ UserSettings before either is stored in @State.
        let settings = UserSettings()
        let mgr = SessionManager()
        mgr.userSettings = settings
        _userSettings = State(initialValue: settings)
        _session = State(initialValue: mgr)
    }

    let modelContainer: ModelContainer = {
        let schema = Schema([FoodEntry.self, SocialPost.self, SocialComment.self, FuelLogEntry.self, WorkoutLogEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do { return try ModelContainer(for: schema, configurations: [config]) }
        catch { fatalError("Failed to create ModelContainer: \(error)") }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView(onComplete: { showSplash = false })
                        .preferredColorScheme(.dark)
                } else {
                    switch session.authState {
                    case .unknown:
                        // Briefly shown while Firebase resolves the auth token
                        Color.black.ignoresSafeArea()

                    case .unauthenticated:
                        AuthView()
                            .environment(session)
                            .preferredColorScheme(.dark)

                    case .authenticated:
                        if session.needsOnboarding {
                            OnboardingView()
                                .environment(session)
                                .environment(userSettings)
                                .preferredColorScheme(.dark)
                        } else {
                            ContentView()
                                .modelContainer(modelContainer)
                                .environment(session)
                                .environment(userSettings)
                                .preferredColorScheme(.dark)
                        }
                    }
                }
            }
            .task { await userSettings.loadCachedImage() }
        }
    }
}
