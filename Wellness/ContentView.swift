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
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(modelContext: modelContext, selectedDate: $selectedDate)
                    .navigationTitle("Today")
            }
            .tabItem { Label("Home", systemImage: "house") }

            NavigationStack {
                FoodLogView(modelContext: modelContext, selectedDate: $selectedDate)
                    .navigationTitle("Food Log")
            }
            .tabItem { Label("Food Log", systemImage: "fork.knife") }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodEntry.self, configurations: config)
    return ContentView()
        .modelContainer(container)
}
