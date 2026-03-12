//
//  WellnessApp.swift
//  Wellness
//
//  Created by Skyler Bailey on 3/11/26.
//

import SwiftUI
import SwiftData

@main
struct WellnessApp: App {
    @State private var showSplash      = true
    @State private var modelContainer: ModelContainer?

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Dark background always painted first — no white flash
                // between the system launch screen and the splash view.
                Color(red: 0.07, green: 0.04, blue: 0.12)
                    .ignoresSafeArea()

                // ContentView only mounts once the container is ready
                if let mc = modelContainer {
                    ContentView()
                        .modelContainer(mc)
                        .opacity(showSplash ? 0 : 1)
                }

                if showSplash {
                    SplashView(onComplete: { showSplash = false })
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showSplash)
            .task {
                // Build the ModelContainer in a detached task so the first
                // frame (dark background + splash) renders before the
                // SQLite store is opened — eliminates the blank-screen delay.
                modelContainer = await Task.detached(priority: .userInitiated) {
                    let schema = Schema([FoodEntry.self])
                    let config = ModelConfiguration(schema: schema,
                                                    isStoredInMemoryOnly: false)
                    return try? ModelContainer(for: schema, configurations: [config])
                }.value
            }
        }
    }
}
