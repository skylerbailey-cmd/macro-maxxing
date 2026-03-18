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
    @Environment(UserSettings.self) private var userSettings
    @Environment(SessionManager.self) private var auth
    @State private var selectedDate     = Calendar.current.startOfDay(for: Date())
    @State private var locationManager  = LocationManager()

    @Query(sort: \SocialPost.postedAt, order: .reverse) private var allPosts: [SocialPost]

    @State private var notificationState = NotificationState()
    @State private var selectedTab = 0

    // FAB state
    @State private var fabExpanded        = false
    @State private var fabShowingCamera   = false
    @State private var fabShowingLibrary  = false
    @State private var fabShowingNewPost  = false
    @State private var fabShowingSearch   = false
    @State private var fabSelectedImage: UIImage? = nil

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Email verification nudge — full-width gold bar at the top until dismissed
            if auth.needsEmailVerification {
                VStack(spacing: 0) {
                    EmailVerificationBannerView()
                        .environment(auth)
                    Spacer()
                }
                .zIndex(10)
            }

            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView(modelContext: modelContext, selectedDate: $selectedDate, userSettings: userSettings)
                }
                .tabItem { Label("Hub", systemImage: "bolt.fill") }
                .tag(0)

                NavigationStack {
                    FoodLogView(modelContext: modelContext, selectedDate: $selectedDate,
                                userSettings: userSettings, externalImage: $fabSelectedImage)
                }
                .tabItem { Label("Log", systemImage: "flame.fill") }
                .tag(1)

                NavigationStack {
                    SocialView(userSettings: userSettings)
                }
                .tabItem { Label("Feed", systemImage: "bolt.heart.fill") }
                .tag(2)

                NavigationStack {
                    LeaderboardView(userSettings: userSettings)
                }
                .tabItem { Label("Board", systemImage: "crown.fill") }
                .tag(3)
            }
            .environment(locationManager)
            .environment(notificationState)
            .onAppear { checkLeaderboardAward() }
            .task { await notificationState.refresh(userID: userSettings.userID) }
            .task(id: userSettings.userID) {
                guard !userSettings.userID.isEmpty else { return }
                InAppNotificationService.shared.startNewPostListener(userID: userSettings.userID)
            }
            .onChange(of: userSettings.userID) { _, newID in
                guard !newID.isEmpty else { return }
                Task { await notificationState.refresh(userID: newID) }
            }

            // Tap-to-dismiss overlay when FAB is open
            if fabExpanded {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.25)) { fabExpanded = false }
                    }
            }

            QuickActionFAB(
                expanded: $fabExpanded,
                onLogMealCamera: {
                    fabExpanded = false
                    selectedTab = 1
                    fabShowingCamera = true
                },
                onLogMealLibrary: {
                    fabExpanded = false
                    selectedTab = 1
                    fabShowingLibrary = true
                },
                onMakePost: {
                    fabExpanded = false
                    fabShowingNewPost = true
                },
                onFindPeople: {
                    fabExpanded = false
                    fabShowingSearch = true
                }
            )
            .padding(.trailing, 20)
            .padding(.bottom, 88)
        }
        .sheet(isPresented: $fabShowingNewPost) {
            NewPostView(userSettings: userSettings)
                .environment(locationManager)
        }
        .sheet(isPresented: $fabShowingSearch) {
            UserSearchView(currentUserSettings: userSettings)
                .environment(locationManager)
        }
        .sheet(isPresented: $fabShowingCamera) {
            ImagePickerView(sourceType: .camera, selectedImage: $fabSelectedImage)
        }
        .sheet(isPresented: $fabShowingLibrary) {
            ImagePickerView(sourceType: .photoLibrary, selectedImage: $fabSelectedImage)
        }
        .onChange(of: fabSelectedImage) { _, image in
            if image != nil { selectedTab = 1 }
        }
    }

    // MARK: - Leaderboard award on app open

    private func checkLeaderboardAward() {
        guard userSettings.hasUnclaimedLeaderboardAward else { return }

        let weekStart = UserSettings.currentWeekStart()

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
        Task {
            if let rank = arenaRank {
                await InAppNotificationService.shared.sendLeaderboard(
                    to: userSettings.userID, rank: rank, scope: "arena")
            }
            if let rank = localRank {
                await InAppNotificationService.shared.sendLeaderboard(
                    to: userSettings.userID, rank: rank, scope: "local")
            }
            await notificationState.refresh(userID: userSettings.userID)
        }
    }
}

// MARK: - Quick Action FAB

private struct QuickActionFAB: View {
    @Binding var expanded: Bool
    let onLogMealCamera:  () -> Void
    let onLogMealLibrary: () -> Void
    let onMakePost:       () -> Void
    let onFindPeople:     () -> Void

    @State private var logMealExpanded = false

    private let gold  = Color(red: 1.00, green: 0.80, blue: 0.20)
    private let purpl = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let teal  = Color(red: 0.20, green: 0.80, blue: 0.70)

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if expanded {
                // Sub-actions under Log a Meal
                if logMealExpanded {
                    actionPill(icon: "photo.on.rectangle", label: "Photo Library", color: purpl,
                               action: onLogMealLibrary)

                    actionPill(icon: "camera.fill", label: "Camera",
                               color: purpl,
                               disabled: !UIImagePickerController.isSourceTypeAvailable(.camera),
                               action: onLogMealCamera)
                }

                actionPill(
                    icon: logMealExpanded ? "chevron.down" : "flame.fill",
                    label: "Log a Meal",
                    color: purpl
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        logMealExpanded.toggle()
                    }
                }

                actionPill(icon: "square.and.pencil", label: "Make a Post", color: gold,
                           action: onMakePost)

                actionPill(icon: "person.2.fill", label: "Find People", color: teal,
                           action: onFindPeople)
            }

            // Main FAB button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if expanded { logMealExpanded = false }
                    expanded.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: expanded
                                    ? [Color(red: 0.18, green: 0.13, blue: 0.30),
                                       Color(red: 0.12, green: 0.09, blue: 0.22)]
                                    : [gold, Color(red: 1.00, green: 0.60, blue: 0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: expanded ? .clear : gold.opacity(0.45), radius: 14, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(expanded ? .white.opacity(0.60) : .black)
                        .rotationEffect(.degrees(expanded ? 45 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: expanded)
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func actionPill(icon: String, label: String, color: Color,
                            disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(disabled ? .white.opacity(0.30) : .white)

                ZStack {
                    Circle()
                        .fill(color.opacity(disabled ? 0.06 : 0.18))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(disabled ? color.opacity(0.30) : color)
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 6)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(disabled ? 0.10 : 0.30), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.85, anchor: .bottomTrailing).combined(with: .opacity),
                removal:   .scale(scale: 0.85, anchor: .bottomTrailing).combined(with: .opacity)
            )
        )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodEntry.self, configurations: config)
    return ContentView()
        .modelContainer(container)
}
