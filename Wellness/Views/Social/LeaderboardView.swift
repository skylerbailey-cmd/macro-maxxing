//
//  LeaderboardView.swift
//  Wellness
//

import SwiftUI
import SwiftData

// MARK: - Data model

struct LeaderboardEntry: Identifiable, Hashable {
    let id:              String   // userID
    let displayName:     String
    let username:        String
    let profileImageData: Data?
    let auraLevel:       Int
    let location:        String
    let score:           Int      // primary sort key
    let reps:            Int      // engagement board only
    let comments:        Int      // engagement board only
    let isCurrentUser:   Bool
    let isPrivate:       Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: LeaderboardEntry, rhs: LeaderboardEntry) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - LeaderboardView

struct LeaderboardView: View {
    let userSettings: UserSettings

    @Query(sort: \SocialPost.postedAt, order: .reverse) private var allPosts: [SocialPost]
    @Query private var friends: [Friend]

    @State private var selectedScope:   Scope = .team
    @State private var selectedProfile: LeaderboardEntry? = nil

    enum Scope: String, CaseIterable {
        case team  = "The Team"
        case local = "Local"
        case arena = "The Arena"
    }

    private let pageBg  = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg  = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let purpl   = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold    = Color(red: 1.00, green: 0.80, blue: 0.20)

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()
            VStack(spacing: 0) {
                scopePicker
                ScrollView {
                    VStack(spacing: 24) {
                        boardSection(
                            title: "Weekly Aura",
                            icon: "bolt.fill",
                            subtitle: "Resets \(nextMondayString)",
                            entries: weeklyAuraDisplayed,
                            board: .weeklyAura
                        )
                        boardSection(
                            title: "Engagement",
                            icon: "heart.fill",
                            subtitle: "All-time reps + comments received",
                            entries: engagementDisplayed,
                            board: .engagement
                        )
                        boardSection(
                            title: "Streak",
                            icon: "flame.fill",
                            subtitle: "Consecutive days hitting all macro goals",
                            entries: streakDisplayed,
                            board: .streak
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Mog Board")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { userSettings.checkWeeklyReset() }
        .navigationDestination(item: $selectedProfile) { entry in
            if entry.isCurrentUser {
                ProfileView(
                    profileUserID:      userSettings.userID,
                    profileUsername:    userSettings.username,
                    profileDisplayName: userSettings.name,
                    profileAuraLevel:   userSettings.auraLevel,
                    profileAuraPoints:  userSettings.auraPoints,
                    profileImageData:   userSettings.profileImageData,
                    profileLocation:    userSettings.location,
                    ownUserSettings:    userSettings
                )
            } else {
                ProfileView(
                    profileUserID:      entry.id,
                    profileUsername:    entry.username,
                    profileDisplayName: entry.displayName,
                    profileAuraLevel:   entry.auraLevel,
                    profileAuraPoints:  entry.score,
                    profileImageData:   entry.profileImageData,
                    profileLocation:    entry.location
                )
            }
        }
    }

    @ViewBuilder
    private func boardSection(title: String, icon: String, subtitle: String,
                               entries: [LeaderboardEntry], board: Board) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(purpl)
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.30))
            }
            if entries.isEmpty {
                let noLocation = selectedScope == .local && userSettings.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                Text(selectedScope == .team
                     ? "Add friends to see The Team leaderboard"
                     : noLocation
                     ? "Go to Settings → Account to set your city"
                     : "No local data yet")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.28))
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { rank, entry in
                        LeaderboardRow(rank: rank + 1, entry: entry, board: board,
                                       isCurrentUser: entry.isCurrentUser)
                            .onTapGesture { selectedProfile = entry }
                    }
                }
            }
        }
    }

    enum Board { case weeklyAura, engagement, streak }

    private var scopePicker: some View {
        Picker("Scope", selection: $selectedScope) {
            ForEach(Scope.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Displayed entries

    private var weeklyAuraDisplayed: [LeaderboardEntry] {
        Array(scopeFiltered(allWeeklyAuraEntries).prefix(10))
    }

    private var engagementDisplayed: [LeaderboardEntry] {
        Array(scopeFiltered(allEngagementEntries).prefix(10))
    }

    private var streakDisplayed: [LeaderboardEntry] {
        Array(scopeFiltered(allStreakEntries).prefix(10))
    }

    private var allStreakEntries: [LeaderboardEntry] {
        // Current user uses real-time streak from UserSettings.
        // Other users: use the highest authorStreak ever seen in their posts.
        var data: [String: (name: String, username: String, imgData: Data?, level: Int, streak: Int, location: String)] = [:]

        let selfName = userSettings.name.isEmpty ? userSettings.username : userSettings.name
        data[userSettings.userID] = (selfName, userSettings.username,
                                     userSettings.profileImageData,
                                     userSettings.auraLevel,
                                     userSettings.macroStreak,
                                     userSettings.location)

        for post in allPosts where post.authorID != userSettings.userID {
            let name = post.authorDisplayName.isEmpty ? post.authorUsername : post.authorDisplayName
            if let existing = data[post.authorID] {
                if post.authorStreak > existing.streak {
                    data[post.authorID] = (name, post.authorUsername,
                                           post.authorProfileImageData,
                                           post.authorAuraLevel,
                                           post.authorStreak,
                                           post.authorLocation)
                }
            } else {
                data[post.authorID] = (name, post.authorUsername,
                                       post.authorProfileImageData,
                                       post.authorAuraLevel,
                                       post.authorStreak,
                                       post.authorLocation)
            }
        }

        return data.map { id, d in
            let isPrivate = id == userSettings.userID
                ? userSettings.isPrivateAccount
                : (allPosts.first { $0.authorID == id }?.isAuthorPrivate ?? false)
            return LeaderboardEntry(id: id, displayName: d.name, username: d.username,
                             profileImageData: d.imgData, auraLevel: d.level,
                             location: d.location, score: d.streak, reps: 0, comments: 0,
                             isCurrentUser: id == userSettings.userID, isPrivate: isPrivate)
        }
        .sorted { $0.score != $1.score ? $0.score > $1.score : $0.displayName < $1.displayName }
    }

    private var localWeeklyAuraEntries: [LeaderboardEntry] {
        let myLocation = userSettings.location.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !myLocation.isEmpty else { return allWeeklyAuraEntries }
        return allWeeklyAuraEntries.filter {
            $0.isCurrentUser ||
            $0.location.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == myLocation
        }
    }

    private var allWeeklyAuraEntries: [LeaderboardEntry] {
        var scores: [String: (name: String, username: String, imgData: Data?, level: Int, score: Int)] = [:]

        // Current user — use real tracked weekly aura
        let selfName = userSettings.name.isEmpty ? userSettings.username : userSettings.name
        scores[userSettings.userID] = (selfName, userSettings.username,
                                       userSettings.profileImageData,
                                       userSettings.auraLevel,
                                       userSettings.weeklyAuraPoints)

        // Other post authors this week — approximate 50 pts per celebration post, 10 per other
        let weekStart = UserSettings.currentWeekStart()
        for post in allPosts where post.postedAt >= weekStart && post.authorID != userSettings.userID {
            let pts = post.goalCalories > 0 ? 50 : 10
            let name = post.authorDisplayName.isEmpty ? post.authorUsername : post.authorDisplayName
            if var existing = scores[post.authorID] {
                existing.score += pts
                scores[post.authorID] = existing
            } else {
                scores[post.authorID] = (name, post.authorUsername,
                                         post.authorProfileImageData,
                                         post.authorAuraLevel, pts)
            }
        }

        return scores.map { id, d in
            let loc = id == userSettings.userID ? userSettings.location
                : (allPosts.first { $0.authorID == id }?.authorLocation ?? "")
            let isPrivate = id == userSettings.userID
                ? userSettings.isPrivateAccount
                : (allPosts.first { $0.authorID == id }?.isAuthorPrivate ?? false)
            return LeaderboardEntry(id: id, displayName: d.name, username: d.username,
                             profileImageData: d.imgData, auraLevel: d.level, location: loc,
                             score: d.score, reps: 0, comments: 0,
                             isCurrentUser: id == userSettings.userID, isPrivate: isPrivate)
        }
        .sorted { $0.score != $1.score ? $0.score > $1.score : $0.displayName < $1.displayName }
    }

    private var allEngagementEntries: [LeaderboardEntry] {
        var data: [String: (name: String, username: String, imgData: Data?, level: Int, reps: Int, comments: Int)] = [:]

        // Seed current user so they appear even with zero
        let selfName = userSettings.name.isEmpty ? userSettings.username : userSettings.name
        data[userSettings.userID] = (selfName, userSettings.username,
                                     userSettings.profileImageData,
                                     userSettings.auraLevel, 0, 0)

        for post in allPosts {
            let name = post.authorDisplayName.isEmpty ? post.authorUsername : post.authorDisplayName
            if var existing = data[post.authorID] {
                existing.reps     += post.repsCount
                existing.comments += post.comments.count
                data[post.authorID] = existing
            } else {
                data[post.authorID] = (name, post.authorUsername,
                                       post.authorProfileImageData,
                                       post.authorAuraLevel,
                                       post.repsCount, post.comments.count)
            }
        }

        return data.map { id, d in
            let loc = id == userSettings.userID ? userSettings.location
                : (allPosts.first { $0.authorID == id }?.authorLocation ?? "")
            let isPrivate = id == userSettings.userID
                ? userSettings.isPrivateAccount
                : (allPosts.first { $0.authorID == id }?.isAuthorPrivate ?? false)
            return LeaderboardEntry(id: id, displayName: d.name, username: d.username,
                             profileImageData: d.imgData, auraLevel: d.level, location: loc,
                             score: d.reps + d.comments, reps: d.reps, comments: d.comments,
                             isCurrentUser: id == userSettings.userID, isPrivate: isPrivate)
        }
        .sorted { $0.score != $1.score ? $0.score > $1.score : $0.displayName < $1.displayName }
    }

    private func scopeFiltered(_ entries: [LeaderboardEntry]) -> [LeaderboardEntry] {
        let friendUsernames = Set(friends.map { $0.username.lowercased() })
        switch selectedScope {
        case .team:
            return entries.filter { $0.isCurrentUser || friendUsernames.contains($0.username.lowercased()) }
        case .local:
            let myCity = cityKey(userSettings.location)
            guard !myCity.isEmpty else { return [] }
            return entries.filter {
                $0.isCurrentUser ||
                (cityKey($0.location) == myCity && visibleEntry($0, friendUsernames: friendUsernames))
            }
        case .arena:
            return entries.filter { $0.isCurrentUser || visibleEntry($0, friendUsernames: friendUsernames) }
        }
    }

    /// Private accounts are hidden from arena/local unless they are already a friend.
    private func visibleEntry(_ entry: LeaderboardEntry, friendUsernames: Set<String>) -> Bool {
        guard entry.isPrivate else { return true }
        return friendUsernames.contains(entry.username.lowercased())
    }

    /// Normalizes a location string to just the city name for loose matching.
    private func cityKey(_ location: String) -> String {
        (location.split(separator: ",", maxSplits: 1).first ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    // MARK: - Helpers

    private var nextMondayString: String {
        let weekStart = UserSettings.currentWeekStart()
        guard let nextMonday = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: weekStart) else {
            return "Monday"
        }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: nextMonday)
    }
}

// MARK: - Leaderboard row

private struct LeaderboardRow: View {
    let rank:          Int
    let entry:         LeaderboardEntry
    let board:         LeaderboardView.Board
    let isCurrentUser: Bool

    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)
    private let silver = Color(red: 0.75, green: 0.75, blue: 0.82)
    private let bronze = Color(red: 0.80, green: 0.50, blue: 0.20)

    var body: some View {
        HStack(spacing: 12) {
            rankBadge
            avatarView
            nameStack
            Spacer()
            scoreStack
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isCurrentUser
                      ? purpl.opacity(0.12)
                      : cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isCurrentUser ? purpl.opacity(0.35) : Color.clear, lineWidth: 1)
                )
        )
    }

    private var rankBadge: some View {
        ZStack {
            switch rank {
            case 1:
                Circle()
                    .fill(gold.opacity(0.20))
                    .frame(width: 32, height: 32)
                Text("👑")
                    .font(.system(size: 16))
            case 2:
                Circle()
                    .fill(silver.opacity(0.18))
                    .frame(width: 32, height: 32)
                Text("🥈")
                    .font(.system(size: 16))
            case 3:
                Circle()
                    .fill(bronze.opacity(0.18))
                    .frame(width: 32, height: 32)
                Text("🥉")
                    .font(.system(size: 16))
            default:
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 32, height: 32)
                Text("\(rank)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .frame(width: 32)
    }

    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarCircle(size: 40, data: entry.profileImageData, initial: entry.displayName)
            if entry.auraLevel > 0 {
                Text("⭐")
                    .font(.system(size: 9))
                    .padding(2)
                    .background(Color.black.opacity(0.60))
                    .clipShape(Circle())
                    .offset(x: 2, y: 2)
            }
        }
    }

    private var nameStack: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Text(entry.displayName.isEmpty ? entry.username : entry.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if isCurrentUser {
                    Text("you")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(purpl)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(purpl.opacity(0.18))
                        .cornerRadius(4)
                }
            }
            HStack(spacing: 4) {
                Text("@\(entry.username)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.32))
                if entry.auraLevel > 0 {
                    Text("· Lv \(entry.auraLevel)")
                        .font(.caption2)
                        .foregroundStyle(Color(red: 1.0, green: 0.80, blue: 0.20).opacity(0.70))
                }
            }
        }
    }

    private var scoreStack: some View {
        VStack(alignment: .trailing, spacing: 2) {
            switch board {
            case .weeklyAura:
                Text("\(entry.score.formatted())")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(rankColor)
                Text("pts")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.30))
            case .engagement:
                Text("\(entry.score)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(rankColor)
                HStack(spacing: 4) {
                    Text("💪\(entry.reps)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.40))
                    Text("·")
                        .foregroundStyle(.white.opacity(0.20))
                        .font(.system(size: 9))
                    Text("💬\(entry.comments)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.40))
                }
            case .streak:
                Text("\(entry.score)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(rankColor)
                Text(entry.score == 1 ? "day" : "days")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.30))
            }
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 1.00, green: 0.80, blue: 0.20)
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.82)
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return .white
        }
    }
}
