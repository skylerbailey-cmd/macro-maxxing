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
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
