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
import FirebaseAppCheck
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
            guard let refreshTask = task as? BGAppRefreshTask else { task.setTaskCompleted(success: false); return }
            self.handleFeedRefresh(refreshTask)
        }

        // Register nightly streak-reset task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.streakResetTaskID,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { task.setTaskCompleted(success: false); return }
            self.handleStreakReset(refreshTask)
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

        // Firestore's LevelDB cache lives under the app's data directory.
        // When the device is locked, iOS Data Protection makes these files
        // inaccessible ("Operation not permitted"), causing a Firestore
        // internal assertion → abort().  Skip the fetch if the cache dir
        // isn't writable right now.
        let cacheDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        if let cacheDir, !FileManager.default.isWritableFile(atPath: cacheDir.path) {
            AppLogger.log("[AppDelegate] Skipping feed refresh — data directory not writable (device locked?)")
            task.setTaskCompleted(success: false)
            return
        }

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
        // Streak is now computed on app launch via StreakService.computeHistoricalStreak.
        // This background slot is kept registered so the OS doesn't penalise the app,
        // but no streak logic runs here.
        Self.scheduleStreakReset()
        task.setTaskCompleted(success: true)
    }
}

@main
struct WellnessApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @Environment(\.scenePhase) private var scenePhase

    @State private var showSplash   = true
    @State private var session:     SessionManager
    @State private var userSettings: UserSettings
    /// Falls back to unauthenticated if Firebase doesn't resolve within this window.
    @State private var authTimedOut = false

    init() {
        // Configure App Check BEFORE FirebaseApp.configure() so the provider
        // factory is set when Firebase services request App Check tokens.
        //
        // DEBUG: AppCheckDebugProvider resolves its token in this order:
        //   1. `FIRAAppCheckDebugToken` environment variable (scheme)
        //   2. `-FIRAAppCheckDebugToken <UUID>` launch argument (scheme)
        //   3. Keychain-cached token from a previous run on this install
        //   4. Auto-generate a new UUID and cache it in Keychain
        //
        // The Keychain cache persists across runs as long as the app is NOT
        // deleted/reinstalled. If every run shows a different UUID, Xcode is
        // wiping the app between builds — check Edit Scheme → Options and
        // disable any "Reset" toggles.
        //
        // Pick ONE mechanism and stick with it:
        //   • Launch arg — easiest, scoped to one dev machine
        //   • Info.plist build setting — shared across the team, Debug-only
        //   • Let Firebase auto-generate and register the UUID once per
        //     device/simulator in Firebase Console
        //
        // RELEASE: App Attest (hardware-backed, Secure Enclave, iOS 14+) with
        // a DeviceCheck fallback for the rare devices where App Attest isn't
        // available. Both are transparent to end users.
        #if DEBUG
        let providerFactory: AppCheckProviderFactory = AppCheckDebugProviderFactory()
        #else
        let providerFactory: AppCheckProviderFactory = AppAttestWithDeviceCheckFallbackProviderFactory()
        #endif
        AppCheck.setAppCheckProviderFactory(providerFactory)

        #if DEBUG
        // Diagnostic: show what the debug provider will see at launch so we
        // can tell which token source it's pulling from.
        let envToken = ProcessInfo.processInfo.environment["FIRAAppCheckDebugToken"]
        let launchArgToken = UserDefaults.standard.string(forKey: "FIRAAppCheckDebugToken")
        print("[AppCheck] env FIRAAppCheckDebugToken = \(envToken ?? "nil")")
        print("[AppCheck] UserDefaults FIRAAppCheckDebugToken = \(launchArgToken ?? "nil")")
        #endif

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
        // On a fresh install `Library/Application Support` doesn't exist
        // yet. SwiftData / CoreData will recover by creating it on demand,
        // but on the way it logs ~60 lines of stat-walk diagnostics which
        // drown out the rest of the launch logs. Pre-create the directory
        // so the store opens cleanly and those diagnostics never fire.
        if let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first {
            try? FileManager.default.createDirectory(
                at: appSupport, withIntermediateDirectories: true
            )
        }

        let schema = Schema([FoodEntry.self, SocialPost.self, SocialComment.self, FuelLogEntry.self, WorkoutLogEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do { return try ModelContainer(for: schema, configurations: [config]) }
        catch { fatalError("Failed to create ModelContainer: \(error)") }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash || session.authState == .unknown {
                    // Show splash while app initializes AND while Firebase resolves auth.
                    // The splash animation plays, then holds at 100% until auth is ready.
                    SplashView(onComplete: { showSplash = false })
                        .preferredColorScheme(.dark)
                        .task {
                            // If Firebase doesn't resolve within 5 seconds, time out
                            try? await Task.sleep(for: .seconds(5))
                            if case .unknown = session.authState {
                                authTimedOut = true
                            }
                        }
                } else if authTimedOut && session.authState == .unknown {
                    AuthView()
                        .environment(session)
                        .preferredColorScheme(.dark)
                } else {
                    switch session.authState {
                    case .unknown:
                        EmptyView() // Handled above

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
            .task {
                // AISubscriptionStore's init starts the Transaction.updates
                // listener, but we also need an initial entitlement pull so the
                // UI knows on first render whether the user is subscribed.
                await AISubscriptionStore.shared.loadProduct()
                await AISubscriptionStore.shared.refreshEntitlement()
            }
            .task {
                // Defer ads + remote config until the splash is dismissed and auth resolves.
                // Running these during launch competes for network and main thread,
                // causing 9-21s process stalls when connectivity is poor.
                while showSplash || session.authState == .unknown {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                }
                // Small extra delay so the first meaningful frame renders before
                // the ads SDK and remote config hit the network.
                try? await Task.sleep(nanoseconds: 500_000_000)
                await AdManager.shared.initialize()
                await RemoteConfigService.shared.fetchAndActivate()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background {
                    // Record clean exit so crash recovery knows
                    // the app didn't terminate unexpectedly.
                    FirebaseManager.shared.markCleanExit()
                }
                guard phase == .active else { return }
                // Reset auth timeout flag so a fresh resolve attempt can happen
                authTimedOut = false
                // Re-fetch user profile to ensure fresh state after returning to foreground
                Task {
                    await session.refreshProfile()
                }
            }
        }
    }
}

/// Prefers App Attest (hardware-backed, iOS 14+ on real devices) and falls back
/// to DeviceCheck on devices or environments where App Attest isn't available
/// (e.g. older hardware, some enterprise-managed devices). Firebase doesn't
/// ship a built-in App Attest factory, so we build one here.
final class AppAttestWithDeviceCheckFallbackProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        if #available(iOS 14.0, *), let provider = AppAttestProvider(app: app) {
            return provider
        }
        return DeviceCheckProvider(app: app)
    }
}
