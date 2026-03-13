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

    @Query(sort: \SocialPost.postedAt, order: .reverse) private var allPosts: [SocialPost]

    @State private var selectedTab = 0
    private let tabCount = 4

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(modelContext: modelContext, selectedDate: $selectedDate, userSettings: userSettings)
            }
            .tabItem { Label("Hub", systemImage: "bolt.fill") }
            .tag(0)

            NavigationStack {
                FoodLogView(modelContext: modelContext, selectedDate: $selectedDate, userSettings: userSettings)
                    .navigationTitle("Fuel Log")
            }
            .tabItem { Label("Fuel Log", systemImage: "flame.fill") }
            .tag(1)

            NavigationStack {
                SocialView(userSettings: userSettings)
            }
            .tabItem { Label("Aura Stream", systemImage: "bolt.heart.fill") }
            .tag(2)

            NavigationStack {
                LeaderboardView(userSettings: userSettings)
            }
            .tabItem { Label("Mog Board", systemImage: "crown.fill") }
            .tag(3)
        }
        .onAppear { checkLeaderboardAward() }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical   = abs(value.translation.height)
                    guard abs(horizontal) > vertical else { return }
                    if horizontal < 0 {
                        selectedTab = min(selectedTab + 1, tabCount - 1)
                    } else {
                        selectedTab = max(selectedTab - 1, 0)
                    }
                }
        )
    }

    // MARK: - Leaderboard award on app open

    private func checkLeaderboardAward() {
        guard userSettings.hasUnclaimedLeaderboardAward else { return }

        let weekStart = UserSettings.currentWeekStart()

        // Build weekly aura scores (mirrors LeaderboardView logic)
        var scores: [String: (score: Int, location: String)] = [:]
        scores[userSettings.userID] = (userSettings.weeklyAuraPoints, userSettings.location)

        for post in allPosts where post.postedAt >= weekStart && post.authorID != userSettings.userID {
            let pts = post.goalCalories > 0 ? 50 : 10
            let loc = post.authorLocation
            if var existing = scores[post.authorID] {
                existing.score += pts
                scores[post.authorID] = existing
            } else {
                scores[post.authorID] = (pts, loc)
            }
        }

        let sorted = scores.sorted {
            $0.value.score != $1.value.score
                ? $0.value.score > $1.value.score
                : $0.key < $1.key
        }

        let arenaRank = sorted.firstIndex(where: { $0.key == userSettings.userID }).map { $0 + 1 }

        let myLocation = userSettings.location.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let localRank: Int?
        if myLocation.isEmpty {
            localRank = nil
        } else {
            let localSorted = sorted.filter {
                $0.key == userSettings.userID ||
                $0.value.location.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == myLocation
            }
            localRank = localSorted.firstIndex(where: { $0.key == userSettings.userID }).map { $0 + 1 }
        }

        userSettings.awardLeaderboardPoints(localRank: localRank, arenaRank: arenaRank)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodEntry.self, configurations: config)
    return ContentView()
        .modelContainer(container)
}
