//
//  WellnessApp.swift
//  Wellness
//
//  Created by Skyler Bailey on 3/11/26.
//

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

    @State private var showSplash    = true
    @State private var authViewModel: AuthViewModel
    @State private var userSettings  = UserSettings()

    init() {
        // Configure Firebase before any Firebase service (Auth, Firestore) is touched.
        FirebaseApp.configure()
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        _authViewModel = State(initialValue: AuthViewModel())
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
                    switch authViewModel.authState {
                    case .unknown:
                        // Briefly shown while Firebase resolves the auth token
                        Color.black.ignoresSafeArea()

                    case .unauthenticated:
                        AuthView()
                            .environment(authViewModel)
                            .preferredColorScheme(.dark)

                    case .authenticated(let uid):
                        ContentView()
                            .modelContainer(modelContainer)
                            .environment(authViewModel)
                            .environment(userSettings)
                            .preferredColorScheme(.dark)
                            .task(id: uid) {
                                await syncUserSettings(uid: uid)
                            }
                    }
                }
            }
            .onChange(of: authViewModel.authState) { oldState, newState in
                if case .authenticated = oldState, case .unauthenticated = newState {
                    userSettings.clearAllUserData()
                }
            }
        }
    }

    // MARK: - Profile Sync

    /// Called whenever the authenticated uid changes.
    /// UserDefaults is guaranteed clean at this point (cleared on sign-out),
    /// so we just stamp the uid and fetch the profile from Firestore.
    @MainActor
    private func syncUserSettings(uid: String) async {
        userSettings.userID = uid

        if let profile = try? await UserProfileService.shared.fetchProfile(userID: uid) {
            userSettings.username          = profile.username
            userSettings.name              = profile.name
            userSettings.location          = profile.location
            userSettings.auraPoints        = profile.auraPoints
            userSettings.macroStreak       = profile.streakDays
            userSettings.instagramHandle   = profile.instagramHandle
            userSettings.tiktokHandle      = profile.tiktokHandle
            userSettings.isPrivateAccount  = profile.isPrivateAccount
            userSettings.currentWeight     = profile.currentWeight
            userSettings.goalWeight        = profile.goalWeight
            userSettings.proteinPerLb      = profile.proteinPerLb
            userSettings.fastingEnabled    = profile.fastingEnabled
            userSettings.auraPopupsEnabled = profile.auraPopupsEnabled
        }
    }
}
