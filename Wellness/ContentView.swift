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
            .tabItem { Label("Hub", systemImage: "bolt.fill") }              // ⚡ energy / power

            NavigationStack {
                FoodLogView(modelContext: modelContext, selectedDate: $selectedDate)
                    .navigationTitle("Fuel Log")
            }
            .tabItem { Label("Fuel Log", systemImage: "flame.fill") }         // 🔥 fuel / fire

            NavigationStack {
                SocialView(userSettings: userSettings)
            }
            .tabItem { Label("Mog Board", systemImage: "trophy.fill") }       // 🏆 winning

            NavigationStack {
                SettingsView(userSettings: userSettings)
            }
            .tabItem { Label("Account", systemImage: "crown.fill") }          // 👑 status
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodEntry.self, configurations: config)
    return ContentView()
        .modelContainer(container)
}
