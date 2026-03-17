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

    static let feedRefreshTaskID = "com.sbailey.Wellness.feedRefresh"

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        NotificationService.shared.requestAuthorization()

        // 50 MB memory + 200 MB disk cache so food photos survive across sessions
        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity:   200 * 1024 * 1024,
            diskPath:       "image_cache"
        )

        // Register the background feed-refresh task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.feedRefreshTaskID,
            using: nil
        ) { task in
            self.handleFeedRefresh(task as! BGAppRefreshTask)
        }

        return true
    }

    // Schedule next refresh when app moves to background
    func applicationDidEnterBackground(_ application: UIApplication) {
        Self.scheduleFeedRefresh()
    }

    // MARK: - BGAppRefreshTask

    /// Schedules a background feed refresh to run no earlier than 30 minutes from now.
    static func scheduleFeedRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: feedRefreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleFeedRefresh(_ task: BGAppRefreshTask) {
        // Immediately reschedule so the 30-minute cycle continues
        Self.scheduleFeedRefresh()

        let fetchTask = Task {
            // Fetching from Firestore populates the offline persistence cache.
            // Next time the user opens the app the feed loads instantly from that cache.
            _ = try? await PostService.shared.fetchFeedPosts(limit: 20)
            task.setTaskCompleted(success: true)
        }

        // iOS calls this when the background time budget runs out
        task.expirationHandler = { fetchTask.cancel() }
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
        let schema = Schema([FoodEntry.self, SocialPost.self, SocialComment.self, FuelLogEntry.self])
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
                        ContentView()
                            .modelContainer(modelContainer)
                            .environment(session)
                            .environment(userSettings)
                            .preferredColorScheme(.dark)
                    }
                }
            }
        }
    }
}
