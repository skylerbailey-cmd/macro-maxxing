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

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(viewModel: HomeViewModel(modelContext: modelContext))
                    .navigationTitle("Today")
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationStack {
                FoodLogView(viewModel: FoodLogViewModel(modelContext: modelContext))
                    .navigationTitle("Food Log")
            }
            .tabItem {
                Label("Food Log", systemImage: "fork.knife")
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodEntry.self, configurations: config)
    return ContentView()
        .modelContainer(container)
}
