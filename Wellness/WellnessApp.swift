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
    @State private var showSplash = true

    let modelContainer: ModelContainer = {
        let schema = Schema([FoodEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .modelContainer(modelContainer)
                    .opacity(showSplash ? 0 : 1)

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showSplash)
            .task {
                try? await Task.sleep(for: .seconds(0.8))
                showSplash = false
            }
        }
    }
}
