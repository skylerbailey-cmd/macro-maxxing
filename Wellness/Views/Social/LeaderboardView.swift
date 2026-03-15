//
//  LeaderboardView.swift
//  Wellness
//

import SwiftUI
import SwiftData
import CoreLocation

// MARK: - Data model

struct LeaderboardEntry: Identifiable, Hashable {
    let id:              String   // userID
    let displayName:     String
    let username:        String
    let profileImageData: Data?
    let auraLevel:       Int
    let location:        String
    let latitude:        Double
    let longitude:       Double
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

    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) private var locationManager
    @Query(sort: \SocialPost.postedAt, order: .reverse) private var allPosts: [SocialPost]
    @Query private var friends: [Friend]

    @State private var selectedScope:    Scope            = .team
    @State private var selectedProfile:  LeaderboardEntry? = nil
    @State private var showingSettings   = false
    @State private var showingProfile    = false
    @State private var showPostPicker    = false
    @State private var previewBoard:     ShareableBoard?  = nil

    enum Scope: String, CaseIterable {
        case team  = "Team"
        case local = "Local"
        case arena = "Arena"
    }

    struct ShareableBoard: Identifiable {
        let id = UUID()
        let title: String
        let scoreLabel: String
        let entries: [LeaderboardEntry]
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
                        if userSettings.isPrivateAccount && (selectedScope == .local || selectedScope == .arena) {
                            privateAccountBanner
                        }
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 14) {
                    Button { showPostPicker = true } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(gold)
                    }
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(purpl)
                    }
                    Button { showingProfile = true } label: {
                        leaderboardProfileAvatarIcon
                    }
                }
            }
        }
        .confirmationDialog("Post a Board", isPresented: $showPostPicker, titleVisibility: .visible) {
            Button("Weekly Aura") {
                previewBoard = ShareableBoard(title: "Weekly Aura", scoreLabel: "pts",
                                             entries: weeklyAuraDisplayed)
            }
            Button("Engagement") {
                previewBoard = ShareableBoard(title: "Engagement", scoreLabel: "score",
                                             entries: engagementDisplayed)
            }
            Button("Streak") {
                previewBoard = ShareableBoard(title: "Streak", scoreLabel: "days",
                                             entries: streakDisplayed)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose which board to post to the feed")
        }
        .sheet(item: $previewBoard) { board in
            BoardPreviewSheet(
                board:  board,
                scope:  selectedScope.rawValue,
                onPost: { image in postBoardToFeed(board: board, overrideImage: image) }
            )
        }
        .onAppear {
            userSettings.checkWeeklyReset()
            if selectedScope == .local { locationManager.requestLocationIfNeeded() }
        }
        .onChange(of: selectedScope) { _, scope in
            if scope == .local { locationManager.requestLocationIfNeeded() }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack { SettingsView(userSettings: userSettings) }
        }
        .sheet(isPresented: $showingProfile) {
            NavigationStack {
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
            }
        }
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

    private var leaderboardProfileAvatarIcon: some View {
        Group {
            if let data = userSettings.profileImageData, let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg)
                    .resizable().scaledToFill()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(purpl, lineWidth: 1.5))
            } else {
                ZStack {
                    Circle().fill(cardBg).frame(width: 30, height: 30)
                        .overlay(Circle().stroke(purpl, lineWidth: 1.5))
                    Image(systemName: "person.fill").font(.system(size: 14)).foregroundStyle(purpl)
                }
            }
        }
    }

    @MainActor
    private func postBoardToFeed(board: ShareableBoard, overrideImage: UIImage? = nil) {
        // Use provided (cropped) image or re-render from the share card
        let image: UIImage
        if let img = overrideImage {
            image = img
        } else {
            let card = MogBoardShareCard(
                boardTitle:  board.title,
                scope:       selectedScope.rawValue,
                scoreLabel:  board.scoreLabel,
                entries:     board.entries
            )
            let renderer = ImageRenderer(content: card)
            renderer.scale = 3.0
            guard let rendered = renderer.uiImage else { return }
            image = rendered
        }

        let title   = "\(selectedScope.rawValue) · \(board.title) Board 👑"
        let caption = "Check out who's topping the \(board.title.lowercased()) board! 🏆"
        let fbPostID = UUID().uuidString

        // Save locally to SwiftData
        let post = SocialPost(
            authorID:          userSettings.userID,
            authorUsername:    userSettings.username.isEmpty ? "me" : userSettings.username,
            authorDisplayName: userSettings.name,
            memeEmoji:         "👑",
            memeHeadline:      title,
            memeSub:           caption,
            macroDate:         Date(),
            totalCalories: 0, goalCalories: 0,
            totalProtein:  0, goalProtein:  0,
            totalCarbs:    0, goalCarbs:    0,
            totalFat:      0, goalFat:      0
        )
        post.isCustomPost           = true
        post.authorAuraLevel        = userSettings.auraLevel
        post.authorAuraPoints       = userSettings.auraPoints
        post.authorLocation         = userSettings.location
        post.authorLatitude         = locationManager.coordinate?.latitude  ?? 0
        post.authorLongitude        = locationManager.coordinate?.longitude ?? 0
        post.authorStreak           = userSettings.macroStreak
        post.isAuthorPrivate        = userSettings.isPrivateAccount
        post.authorProfileImageData = userSettings.profileImageData
        post.imageData              = image.jpegData(compressionQuality: 0.85)
        post.firebasePostID         = fbPostID
        modelContext.insert(post)

        // Mirror to Firebase
        let author = PostService.PostAuthor(
            userID:              userSettings.userID,
            username:            userSettings.username.isEmpty ? "me" : userSettings.username,
            whoName:             userSettings.name,
            userProfilePhotoURL: "",
            auraLevel:           userSettings.auraLevel,
            auraPoints:          userSettings.auraPoints,
            streak:              userSettings.macroStreak,
            memeType:            "",
            isPublic:            !userSettings.isPrivateAccount
        )
        Task {
            do {
                try await PostService.shared.createCustomPost(
                    photos:  [image],
                    author:  author,
                    title:   title,
                    caption: caption,
                    postID:  fbPostID
                )
            } catch {
                print("[LeaderboardView] Firebase post failed: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    private func presentShareSheet(board: ShareableBoard) {
        let card = MogBoardShareCard(
            boardTitle:  board.title,
            scope:       selectedScope.rawValue,
            scoreLabel:  board.scoreLabel,
            entries:     board.entries
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        guard let image = renderer.uiImage else { return }
        let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController?.present(av, animated: true)
    }

    @ViewBuilder
    private func boardSection(title: String, icon: String, subtitle: String,
                               entries: [LeaderboardEntry], board: Board) -> some View {
        let scoreLabel = board == .streak ? "days" : board == .engagement ? "score" : "pts"
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
                Button {
                    let sb = ShareableBoard(title: title, scoreLabel: scoreLabel, entries: entries)
                    presentShareSheet(board: sb)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(gold.opacity(0.80))
                        .padding(6)
                        .background(gold.opacity(0.12))
                        .clipShape(Circle())
                }
            }
            if entries.isEmpty {
                let noLocation = selectedScope == .local && locationManager.coordinate == nil
                if selectedScope == .local && !noLocation {
                    // Local tab, location available, but zero users found → invite banner
                    localInviteBanner(full: true)
                } else {
                    VStack(spacing: 10) {
                        Text(selectedScope == .team
                             ? "Add friends to see the Team leaderboard"
                             : noLocation
                             ? "Enable location access to see the local board"
                             : "No local data yet")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.28))
                            .multilineTextAlignment(.center)
                        if noLocation {
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(purpl)
                        }
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { rank, entry in
                        LeaderboardRow(rank: rank + 1, entry: entry, board: board,
                                       isCurrentUser: entry.isCurrentUser)
                            .onTapGesture { selectedProfile = entry }
                    }
                }
                // Fewer than 10 local competitors → invite nudge below the rows
                if selectedScope == .local && entries.count < 10 {
                    localInviteBanner(full: false)
                }
            }
        }
    }

    /// Banner shown on the Local tab when fewer than 10 nearby users exist.
    /// `full` = true when there are zero entries (replaces the section body).
    @ViewBuilder
    private func localInviteBanner(full: Bool) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "person.2.badge.plus")
                    .font(.system(size: full ? 32 : 22))
                    .foregroundStyle(gold)
                VStack(alignment: .leading, spacing: 4) {
                    Text(full ? "No local competitors yet" : "Not enough local competitors")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(full
                         ? "You're the first one here! Invite friends in your area to join and compete on the local board."
                         : "There are fewer than 10 people competing near you. Invite friends to join and climb the ranks!")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: presentInviteSheet) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Invite Friends")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(gold)
                .cornerRadius(12)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(gold.opacity(0.30), lineWidth: 1)
                )
        )
        .padding(.top, full ? 0 : 4)
    }

    @MainActor
    private func presentInviteSheet() {
        let text = "Hey! 💪 I've been crushing my macro goals on Macro Maxxing. Join me and compete on the local leaderboard! Download the app here: https://apps.apple.com/app/macro-maxxing"
        let av = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        // Limit to Messages and WhatsApp if available; otherwise show all options.
        av.excludedActivityTypes = [
            .postToFacebook, .postToTwitter, .postToWeibo,
            .postToFlickr, .postToVimeo, .postToTencentWeibo,
            .saveToCameraRoll, .addToReadingList, .assignToContact,
            .openInIBooks, .print, .copyToPasteboard, .markupAsPDF
        ]
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController?.present(av, animated: true)
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

    // MARK: - Private account banner

    private var privateAccountBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 22))
                .foregroundStyle(purpl)
            VStack(alignment: .leading, spacing: 4) {
                Text("You're off the board")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Private accounts don't appear on Local or Arena boards. Switch to a public profile in Settings to get ranked.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.50))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(purpl.opacity(0.30), lineWidth: 1)
                )
        )

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
        var data: [String: (name: String, username: String, imgData: Data?, level: Int, streak: Int, location: String, lat: Double, lon: Double)] = [:]

        let selfName = userSettings.name.isEmpty ? userSettings.username : userSettings.name
        data[userSettings.userID] = (selfName, userSettings.username,
                                     userSettings.profileImageData,
                                     userSettings.auraLevel,
                                     userSettings.macroStreak,
                                     userSettings.location,
                                     locationManager.coordinate?.latitude  ?? 0,
                                     locationManager.coordinate?.longitude ?? 0)

        for post in allPosts where post.authorID != userSettings.userID {
            let name = post.authorDisplayName.isEmpty ? post.authorUsername : post.authorDisplayName
            if let existing = data[post.authorID] {
                if post.authorStreak > existing.streak {
                    data[post.authorID] = (name, post.authorUsername,
                                           post.authorProfileImageData,
                                           post.authorAuraLevel,
                                           post.authorStreak,
                                           post.authorLocation,
                                           post.authorLatitude,
                                           post.authorLongitude)
                }
            } else {
                data[post.authorID] = (name, post.authorUsername,
                                       post.authorProfileImageData,
                                       post.authorAuraLevel,
                                       post.authorStreak,
                                       post.authorLocation,
                                       post.authorLatitude,
                                       post.authorLongitude)
            }
        }

        return data.map { id, d in
            let isPrivate = id == userSettings.userID
                ? userSettings.isPrivateAccount
                : (allPosts.first { $0.authorID == id }?.isAuthorPrivate ?? false)
            return LeaderboardEntry(id: id, displayName: d.name, username: d.username,
                             profileImageData: d.imgData, auraLevel: d.level,
                             location: d.location, latitude: d.lat, longitude: d.lon,
                             score: d.streak, reps: 0, comments: 0,
                             isCurrentUser: id == userSettings.userID, isPrivate: isPrivate)
        }
        .sorted { $0.score != $1.score ? $0.score > $1.score : $0.displayName < $1.displayName }
    }

    private var allWeeklyAuraEntries: [LeaderboardEntry] {
        var scores: [String: (name: String, username: String, imgData: Data?, level: Int, score: Int)] = [:]

        let selfName = userSettings.name.isEmpty ? userSettings.username : userSettings.name
        scores[userSettings.userID] = (selfName, userSettings.username,
                                       userSettings.profileImageData,
                                       userSettings.auraLevel,
                                       userSettings.weeklyAuraPoints)

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
            let lat = id == userSettings.userID ? (locationManager.coordinate?.latitude  ?? 0)
                : (allPosts.first { $0.authorID == id }?.authorLatitude  ?? 0)
            let lon = id == userSettings.userID ? (locationManager.coordinate?.longitude ?? 0)
                : (allPosts.first { $0.authorID == id }?.authorLongitude ?? 0)
            let isPrivate = id == userSettings.userID
                ? userSettings.isPrivateAccount
                : (allPosts.first { $0.authorID == id }?.isAuthorPrivate ?? false)
            return LeaderboardEntry(id: id, displayName: d.name, username: d.username,
                             profileImageData: d.imgData, auraLevel: d.level, location: loc,
                             latitude: lat, longitude: lon,
                             score: d.score, reps: 0, comments: 0,
                             isCurrentUser: id == userSettings.userID, isPrivate: isPrivate)
        }
        .sorted { $0.score != $1.score ? $0.score > $1.score : $0.displayName < $1.displayName }
    }

    private var allEngagementEntries: [LeaderboardEntry] {
        var data: [String: (name: String, username: String, imgData: Data?, level: Int, reps: Int, comments: Int)] = [:]

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
            let lat = id == userSettings.userID ? (locationManager.coordinate?.latitude  ?? 0)
                : (allPosts.first { $0.authorID == id }?.authorLatitude  ?? 0)
            let lon = id == userSettings.userID ? (locationManager.coordinate?.longitude ?? 0)
                : (allPosts.first { $0.authorID == id }?.authorLongitude ?? 0)
            let isPrivate = id == userSettings.userID
                ? userSettings.isPrivateAccount
                : (allPosts.first { $0.authorID == id }?.isAuthorPrivate ?? false)
            return LeaderboardEntry(id: id, displayName: d.name, username: d.username,
                             profileImageData: d.imgData, auraLevel: d.level, location: loc,
                             latitude: lat, longitude: lon,
                             score: d.reps + d.comments, reps: d.reps, comments: d.comments,
                             isCurrentUser: id == userSettings.userID, isPrivate: isPrivate)
        }
        .sorted { $0.score != $1.score ? $0.score > $1.score : $0.displayName < $1.displayName }
    }

    private static let localRadiusMeters: Double = 160_934 // 100 miles

    private func scopeFiltered(_ entries: [LeaderboardEntry]) -> [LeaderboardEntry] {
        let friendUsernames = Set(friends.map { $0.username.lowercased() })
        switch selectedScope {
        case .team:
            return entries.filter { $0.isCurrentUser || friendUsernames.contains($0.username.lowercased()) }
        case .local:
            guard let coord = locationManager.coordinate else { return [] }
            let userLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            let nearby = entries.filter {
                if $0.isCurrentUser { return !userSettings.isPrivateAccount }
                if $0.isPrivate { return false }
                guard $0.latitude != 0 || $0.longitude != 0 else { return false }
                return CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                    .distance(from: userLoc) <= Self.localRadiusMeters
            }
            return Array(nearby.prefix(500))
        case .arena:
            return entries.filter { $0.isCurrentUser ? !userSettings.isPrivateAccount : !$0.isPrivate }
        }
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

// MARK: - Share card rendered to image

private struct MogBoardShareCard: View {
    let boardTitle:  String
    let scope:       String
    let scoreLabel:  String
    let entries:     [LeaderboardEntry]

    private let purpl = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold  = Color(red: 1.00, green: 0.80, blue: 0.20)
    private let bg    = Color(red: 0.04, green: 0.03, blue: 0.08)
    private let card  = Color(red: 0.10, green: 0.08, blue: 0.18)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.06, blue: 0.25), bg],
                startPoint: .top, endPoint: .bottom
            )

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Text("MACRO MAXXING")
                        .font(.system(size: 11, weight: .black))
                        .tracking(3)
                        .foregroundStyle(purpl.opacity(0.70))

                    Text(boardTitle.uppercased())
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(scope.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(gold.opacity(0.80))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(gold.opacity(0.10))
                        .clipShape(Capsule())
                }
                .padding(.top, 32)
                .padding(.bottom, 20)

                // Entries
                VStack(spacing: 6) {
                    ForEach(Array(entries.prefix(10).enumerated()), id: \.offset) { idx, entry in
                        HStack(spacing: 12) {
                            // Rank
                            Text(rankEmoji(idx + 1))
                                .font(.system(size: 18))
                                .frame(width: 30)

                            // Avatar placeholder
                            if let data = entry.profileImageData, let img = UIImage(data: data) {
                                Image(uiImage: img)
                                    .resizable().scaledToFill()
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(purpl.opacity(0.40), lineWidth: 1))
                            } else {
                                Circle()
                                    .fill(purpl.opacity(0.20))
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        Text(String(entry.displayName.prefix(1)).uppercased())
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(purpl)
                                    }
                            }

                            // Name
                            VStack(alignment: .leading, spacing: 1) {
                                Text(entry.displayName.isEmpty ? entry.username : entry.displayName)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(entry.isCurrentUser ? gold : .white)
                                    .lineLimit(1)
                                if !entry.username.isEmpty {
                                    Text("@\(entry.username)")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.white.opacity(0.35))
                                }
                            }

                            Spacer()

                            // Score
                            Text("\(entry.score) \(scoreLabel)")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(entry.isCurrentUser ? gold : purpl)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(entry.isCurrentUser ? gold.opacity(0.08) : card)
                        )
                    }
                }
                .padding(.horizontal, 16)

                Spacer()

                // Footer
                Text("macrxmaxxing.app")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.20))
                    .padding(.bottom, 24)
            }
        }
        .frame(width: 390, height: 700)
        .preferredColorScheme(.dark)
    }

    private func rankEmoji(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)."
        }
    }
}

// MARK: - Board preview sheet

private struct BoardPreviewSheet: View {
    let board:  LeaderboardView.ShareableBoard
    let scope:  String
    let onPost: (UIImage?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isPosting    = false
    @State private var didPost      = false
    @State private var renderedImage: UIImage?  = nil
    @State private var showCrop     = false

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Section label
                        Text("Your post will look like this")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.40))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        // Preview: cropped image if available, otherwise rendered card
                        ZStack(alignment: .bottomTrailing) {
                            if let img = renderedImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .cornerRadius(20)
                                    .shadow(color: .black.opacity(0.50), radius: 20)
                            } else {
                                MogBoardShareCard(
                                    boardTitle: board.title,
                                    scope:      scope,
                                    scoreLabel: board.scoreLabel,
                                    entries:    board.entries
                                )
                                .scaleEffect(0.75)
                                .frame(height: 525)   // 700 × 0.75
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.50), radius: 20)
                            }

                            // Crop button overlay
                            Button { showCrop = true } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "crop")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Crop")
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                            }
                            .padding(12)
                        }
                        .padding(.horizontal, 16)

                        // Post caption preview
                        VStack(spacing: 6) {
                            Text("\(scope) · \(board.title) Board 👑")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                            Text("Posted to your Aura Stream and the global feed")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.40))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)

                        // Confirm / post button
                        Button(action: handlePost) {
                            ZStack {
                                if didPost {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        Text("Posted!")
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(.white)
                                    }
                                } else if isPosting {
                                    HStack(spacing: 10) {
                                        ProgressView().tint(.white)
                                        Text("Posting…")
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                    }
                                } else {
                                    HStack(spacing: 8) {
                                        Image(systemName: "paperplane.fill")
                                        Text("Post to Feed")
                                            .font(.headline.weight(.bold))
                                    }
                                    .foregroundStyle(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Group {
                                    if didPost {
                                        AnyView(Color.green.opacity(0.25))
                                    } else if isPosting {
                                        AnyView(purpl.opacity(0.30))
                                    } else {
                                        AnyView(LinearGradient(
                                            colors: [purpl, Color(red: 0.45, green: 0.25, blue: 0.90)],
                                            startPoint: .leading,
                                            endPoint:   .trailing
                                        ))
                                    }
                                }
                            )
                            .cornerRadius(16)
                            .animation(.easeInOut(duration: 0.2), value: didPost)
                            .animation(.easeInOut(duration: 0.2), value: isPosting)
                        }
                        .disabled(isPosting || didPost)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Post Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isPosting)
                }
            }
            .onAppear { renderCardImage() }
            .fullScreenCover(isPresented: $showCrop) {
                if let img = renderedImage {
                    CropImageView(
                        image: img,
                        onCrop: { cropped in
                            renderedImage = cropped
                            showCrop = false
                        },
                        onCancel: { showCrop = false }
                    )
                }
            }
        }
    }

    @MainActor
    private func renderCardImage() {
        let card = MogBoardShareCard(
            boardTitle:  board.title,
            scope:       scope,
            scoreLabel:  board.scoreLabel,
            entries:     board.entries
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        renderedImage = renderer.uiImage
    }

    private func handlePost() {
        guard !isPosting && !didPost else { return }
        isPosting = true
        onPost(renderedImage)
        isPosting = false
        withAnimation { didPost = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
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
