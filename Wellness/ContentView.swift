//
//  ContentView.swift
//  Wellness
//
//  Created by Skyler Bailey on 3/11/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate  = Calendar.current.startOfDay(for: Date())
    @State private var userSettings  = UserSettings()

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(modelContext: modelContext, selectedDate: $selectedDate, userSettings: userSettings)
            }
            .tabItem { Label("Home", systemImage: "house") }

            NavigationStack {
                FoodLogView(modelContext: modelContext, selectedDate: $selectedDate)
                    .navigationTitle("Food Log")
            }
            .tabItem { Label("Food Log", systemImage: "fork.knife") }

            NavigationStack {
                AnalyzeView(modelContext: modelContext, selectedDate: $selectedDate)
                    .navigationTitle("Analyze")
            }
            .tabItem { Label("Analyze", systemImage: "wand.and.stars") }

            NavigationStack {
                SettingsView(userSettings: userSettings)
            }
            .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodEntry.self, configurations: config)
    return ContentView()
        .modelContainer(container)
}
