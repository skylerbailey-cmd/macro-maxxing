//
//  LeaderboardView.swift
//  Wellness
//

import SwiftUI
import SwiftData
import Combine
import CoreLocation

// MARK: - Data model

struct LeaderboardEntry: Identifiable, Hashable {
    let id:              String   // userID
    let displayName:     String
    let username:        String
    let profileImageData: Data?
    let profilePhotoURL: String
    let auraLevel:       Int
    let location:        String
    let latitude:        Double
    let longitude:       Double
    let score:           Int      // primary sort key
    let reps:            Int      // engagement board only
    let comments:        Int      // engagement board only
    let streak:          Int      // macro streak days
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
    @Environment(NotificationState.self) private var notificationState
    @Query(sort: \SocialPost.postedAt, order: .reverse) private var allPosts: [SocialPost]

    /// Firestore-loaded set of userIDs the current user follows.
    @State private var followingIDs:     Set<String>       = []

    @State private var selectedScope:    Scope            = .arena
    @State private var selectedProfile:  LeaderboardEntry? = nil
    @State private var showingTutorial   = false
    @State private var tutorialAnchors:  [String: Anchor<CGRect>] = [:]
    @State private var showingProfile    = false
    @State private var showPostPicker    = false
    @State private var showingNotifications = false
    @State private var previewBoard:       ShareableBoard?    = nil
    @State private var infoBoard:          Board?             = nil
    @State private var showingLastWeek:    Bool               = false
    @State private var lastWeekSnapshot:   UserProfileService.WeeklySnapshot? = nil
    @State private var lastWeekLoading:    Bool               = false
    @State private var firestoreAura:      [LeaderboardEntry] = []
    @State private var weeklyAuraLoading:  Bool               = false
    @State private var timeUntilReset:     TimeInterval       = 0
    @State private var countdownBlink:     Bool               = false
    @State private var showingWinnerPopup: Bool               = false
    @State private var boardUnlocked:      Bool               = false

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
                // Custom header (nav bar is hidden)
                HStack {
                    Text("Mog Board")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    HStack(spacing: 14) {
                        Button { showingTutorial = true } label: {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 20))
                                .foregroundStyle(.white.opacity(0.65))
                        }
                        .buttonStyle(.plain)
                        BellButton(showingNotifications: $showingNotifications, notificationState: notificationState)
                        Button { showingProfile = true } label: {
                            leaderboardProfileAvatarIcon
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

                scopePicker
                    .tutorialAnchor("board.scopePicker")
                ScrollView {
                    VStack(spacing: 24) {
                        if RemoteConfigService.shared.mogBoardAdRequired && !boardUnlocked {
                            // Rewarded ad gate
                            VStack(spacing: 16) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(purpl.opacity(0.50))
                                Text("Watch a short ad to view this week's board")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.65))
                                    .multilineTextAlignment(.center)
                                Button {
                                    AdManager.shared.showRewarded(onReward: {
                                        Task { @MainActor in boardUnlocked = true }
                                    })
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "play.fill")
                                        Text("Watch Ad")
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(gold, in: Capsule())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            if userSettings.isPrivateAccount && (selectedScope == .local || selectedScope == .arena) {
                                privateAccountBanner
                            }
                            resetCountdownBanner
                            boardSection(
                                title: "Weekly Aura",
                                icon: "bolt.fill",
                                subtitle: "Resets \(nextSundayString)",
                                entries: weeklyAuraDisplayed,
                                board: .weeklyAura,
                                isLoading: weeklyAuraLoading
                            )
                            .tutorialAnchor("board.rows")

                            Text("More boards coming soon")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.35))
                                .frame(maxWidth: .infinity)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .refreshable {
                    await loadFollowingIDs()
                    await loadWeeklyAuraBoard()
                }
            }
            if showingTutorial {
                TutorialOverlayView(steps: TutorialSteps.board, anchors: tutorialAnchors, onDismiss: {
                    withAnimation(.easeOut(duration: 0.25)) { showingTutorial = false }
                })
                .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                .zIndex(100)
            }
        }
        .onPreferenceChange(TutorialAnchorKey.self) { tutorialAnchors = $0 }
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
        .task {
            await loadFollowingIDs()
            await loadWeeklyAuraBoard()
        }
        .confirmationDialog("Post a Board", isPresented: $showPostPicker, titleVisibility: .visible) {
            Button("Weekly Aura") {
                previewBoard = ShareableBoard(title: "Weekly Aura", scoreLabel: "xp",
                                             entries: weeklyAuraDisplayed)
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
        .sheet(isPresented: $showingLastWeek) {
            LastWeekResultsSheet(
                snapshot: lastWeekSnapshot,
                isLoading: lastWeekLoading,
                currentUserID: userSettings.userID
            )
        }
        .sheet(isPresented: $showingWinnerPopup, onDismiss: {
            userSettings.pendingWeeklyWinnerRank = nil
            userSettings.pendingWeeklyWinnerXP   = 0
            userSettings.pendingLocalWinnerRank  = nil
            userSettings.pendingLocalWinnerXP    = 0
        }) {
            WeeklyWinnerPopup(
                arenaRank:    userSettings.pendingWeeklyWinnerRank,
                arenaXP:      userSettings.pendingWeeklyWinnerXP,
                localRank:    userSettings.pendingLocalWinnerRank,
                localXP:      userSettings.pendingLocalWinnerXP,
                boardEntries: weeklyAuraDisplayed
            )
        }
        .alert(infoBoardTitle, isPresented: Binding(
            get: { infoBoard != nil },
            set: { if !$0 { infoBoard = nil } }
        )) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text(infoBoardMessage)
        }
        .onAppear {
            userSettings.checkWeeklyReset()
            if selectedScope == .local { locationManager.requestLocationIfNeeded() }
            timeUntilReset = UserSettings.nextWeekReset().timeIntervalSinceNow
            // Show winner popup if either an arena or local win is pending
            if userSettings.pendingWeeklyWinnerRank != nil || userSettings.pendingLocalWinnerRank != nil {
                Task {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    showingWinnerPopup = true
                }
            }
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            let remaining = max(0, UserSettings.nextWeekReset().timeIntervalSinceNow)
            let oldSec = Int(timeUntilReset)
            timeUntilReset = remaining
            // Blink once per second, only when under 10 hours
            if remaining < 36000 && Int(remaining) != oldSec {
                countdownBlink = true
                withAnimation(.easeInOut(duration: 0.4)) { countdownBlink = false }
            }
        }
        .onChange(of: userSettings.pendingWeeklyWinnerRank) { _, rank in
            if rank != nil { showingWinnerPopup = true }
        }
        .onChange(of: userSettings.pendingLocalWinnerRank) { _, rank in
            if rank != nil { showingWinnerPopup = true }
        }
        .onChange(of: selectedScope) { _, scope in
            if scope == .local { locationManager.requestLocationIfNeeded() }
        }
        .onChange(of: selectedProfile) { old, new in
            // Refresh team following list when returning from a user profile
            if new == nil && old != nil { Task { await loadFollowingIDs() } }
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView(userSettings: userSettings, notificationState: notificationState)
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
                    ownUserSettings:    userSettings,
                    isDismissable:      true
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
                    profileLocation:    entry.location,
                    profileStreak:      entry.streak,
                    currentUserSettings: userSettings
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
        post.authorAuraTitle        = userSettings.auraTitle
        post.authorLocation         = userSettings.location
        post.authorLatitude         = locationManager.coordinate?.latitude  ?? 0
        post.authorLongitude        = locationManager.coordinate?.longitude ?? 0
        post.authorStreak           = userSettings.macroStreak
        post.isAuthorPrivate        = userSettings.isPrivateAccount
        post.authorProfileImageData = userSettings.profileImageData
        post.imageData              = image.jpegData(compressionQuality: 0.85)
        post.postLabel              = PostLabel.mogBoard.rawValue
        post.mogBoardScope          = selectedScope.rawValue
        post.mogBoardType           = board.title
        post.firebasePostID         = fbPostID
        // Embed a compact leaderboard snapshot so the feed card can show the live top-10
        let snapshotEntries = board.entries.prefix(10).map { e in
            MogBoardSnapshotEntry(id: e.id, displayName: e.displayName, username: e.username, score: e.score)
        }
        if let snapshotData = try? JSONEncoder().encode(Array(snapshotEntries)),
           let snapshotJSON = String(data: snapshotData, encoding: .utf8) {
            post.mogBoardSnapshot = snapshotJSON
        }
        modelContext.insert(post)

        // Mirror to Firebase
        let author = PostService.PostAuthor(
            userID:              userSettings.userID,
            username:            userSettings.username.isEmpty ? "me" : userSettings.username,
            whoName:             userSettings.name,
            userProfilePhotoURL: userSettings.profilePhotoURL,
            auraLevel:           userSettings.auraLevel,
            auraPoints:          userSettings.auraPoints,
            auraTitle:           userSettings.auraTitle,
            streak:              userSettings.macroStreak,
            memeType:            "",
            isPublic:            !userSettings.isPrivateAccount,
            isProSubscriber:     AISubscriptionStore.shared.isSubscribed
        )
        Task {
            do {
                try await PostService.shared.createCustomPost(
                    photos:           [image],
                    author:           author,
                    title:            title,
                    caption:          caption,
                    postLabel:        PostLabel.mogBoard.rawValue,
                    mogBoardScope:    post.mogBoardScope,
                    mogBoardType:     post.mogBoardType,
                    mogBoardSnapshot: post.mogBoardSnapshot,
                    postID:           fbPostID
                )
            } catch {
                AppLogger.log("[LeaderboardView] Firebase post failed: \(error.localizedDescription)")
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

    private var infoBoardTitle: String {
        switch infoBoard {
        case .weeklyAura: return "Weekly Aura Board"
        case nil:         return ""
        }
    }

    private var infoBoardMessage: String {
        switch infoBoard {
        case .weeklyAura:
            return "Ranks everyone by Aura XP earned during the current week. Post content, earn reps and comments, hit your macro goals, and keep your streak alive to climb.\n\nThe board resets every Sunday at 8 PM Eastern time. At reset, a snapshot of that week's final standings is saved and viewable via \"Last Week's Results\"."
        case nil:
            return ""
        }
    }

    @ViewBuilder
    private func boardSection(title: String, icon: String, subtitle: String,
                               entries: [LeaderboardEntry], board: Board,
                               isLoading: Bool = false) -> some View {
        let scoreLabel = "xp"
        let iconColor: Color = purpl

        VStack(alignment: .leading, spacing: 0) {
            // Card header
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(iconColor)
                    .frame(width: 30, height: 30)
                    .background(iconColor.opacity(0.15))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 5) {
                        Text(title)
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Button { infoBoard = board } label: {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.35))
                        }
                        .buttonStyle(.plain)
                    }
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                }
                Spacer()
                Button {
                    showingLastWeek = true
                    if lastWeekSnapshot == nil {
                        Task { await loadLastWeekSnapshot() }
                    }
                } label: {
                    Text("Last week")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(purpl)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(purpl.opacity(0.12), in: Capsule())
                        .overlay(Capsule().stroke(purpl.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(14)

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)

            let noLocation = selectedScope == .local && locationManager.coordinate == nil
            let localTooFew = selectedScope == .local && !noLocation && entries.count < 10

            if isLoading {
                ProgressView()
                    .tint(Color(red: 0.65, green: 0.45, blue: 1.00))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if entries.isEmpty || localTooFew {
                Group {
                    if selectedScope == .local && !noLocation {
                        localInviteBanner(full: true)
                    } else if selectedScope == .team {
                        teamInviteBanner(full: true)
                    } else {
                        VStack(spacing: 10) {
                            Text(noLocation
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
                }
                .padding(12)
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { rank, entry in
                        LeaderboardRow(rank: rank + 1, entry: entry, board: board,
                                       isCurrentUser: entry.isCurrentUser)
                            .onTapGesture { selectedProfile = entry }
                    }
                }
                .padding(12)

                if selectedScope == .team && entries.count < 5 {
                    teamInviteBanner(full: false)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                }
            }
        }
        .background(cardBg)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    /// Banner shown on the Team tab when fewer than 5 friends are competing.
    /// `full` = true when there are zero entries (replaces the section body).
    @ViewBuilder
    private func teamInviteBanner(full: Bool) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "person.2.badge.plus")
                    .font(.system(size: full ? 32 : 22))
                    .foregroundStyle(purpl)
                VStack(alignment: .leading, spacing: 4) {
                    Text(full ? "Nobody you follow yet" : "Your team is small")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(full
                         ? "Follow people to start competing as a team. Use the search button in the Aura Stream to find others."
                         : "You're following fewer than 5 people. Follow more to heat up the team board!")
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
                    Text("Not enough local competitors yet")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("You need more local competitors in your area to compete on the local board. Invite friends nearby to join!")
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
        let text = "Hey! 💪 I've been crushing my macro goals on Macromaxxing. Join me and compete on the local leaderboard! Download the app here: https://apps.apple.com/app/macro-maxxing"
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

    enum Board { case weeklyAura }

    private var scopePicker: some View {
        HStack(spacing: 0) {
            ForEach(Scope.allCases, id: \.self) { scope in
                Button { selectedScope = scope } label: {
                    Text(scope.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selectedScope == scope ? .black : .white.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(selectedScope == scope ? gold : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .animation(.spring(duration: 0.2), value: selectedScope)
            }
        }
        .padding(4)
        .background(Capsule().fill(cardBg))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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
        Array(scopeFiltered(firestoreAura).prefix(10))
    }


    private func loadWeeklyAuraBoard() async {
        weeklyAuraLoading = true
        defer { weeklyAuraLoading = false }

        guard let entries = try? await UserProfileService.shared.fetchWeeklyAuraBoard() else { return }

        let currentWeekStart = UserSettings.currentWeekStart().timeIntervalSince1970

        var result: [LeaderboardEntry] = entries.compactMap { e in
            // Filter out stale entries from a previous week
            guard e.weeklyAuraWeekStartTimestamp >= currentWeekStart else { return nil }
            let isCurrentUser = e.userID == userSettings.userID
            let auraLvl = isCurrentUser ? userSettings.auraLevel : UserSettings.auraLevel(for: e.auraPoints)
            let displayName = e.name.isEmpty ? e.username : e.name
            return LeaderboardEntry(
                id:               e.userID,
                displayName:      displayName,
                username:         e.username,
                profileImageData: isCurrentUser ? userSettings.profileImageData : nil,
                profilePhotoURL:  isCurrentUser ? userSettings.profilePhotoURL : e.profilePhotoURL,
                auraLevel:        auraLvl,
                location:         isCurrentUser ? userSettings.location : e.location,
                latitude:         isCurrentUser ? (locationManager.coordinate?.latitude  ?? 0) : 0,
                longitude:        isCurrentUser ? (locationManager.coordinate?.longitude ?? 0) : 0,
                score:            isCurrentUser ? userSettings.weeklyAuraPoints : e.weeklyAuraPoints,
                reps:             0,
                comments:         0,
                streak:           isCurrentUser ? userSettings.macroStreak : e.streakDays,
                isCurrentUser:    isCurrentUser,
                isPrivate:        isCurrentUser ? userSettings.isPrivateAccount : e.isPrivate
            )
        }

        // Seed current user so they always appear even with 0 pts
        if !result.contains(where: { $0.isCurrentUser }) {
            let selfName = userSettings.name.isEmpty ? userSettings.username : userSettings.name
            result.append(LeaderboardEntry(
                id:               userSettings.userID,
                displayName:      selfName,
                username:         userSettings.username,
                profileImageData: userSettings.profileImageData,
                profilePhotoURL:  userSettings.profilePhotoURL,
                auraLevel:        userSettings.auraLevel,
                location:         userSettings.location,
                latitude:         locationManager.coordinate?.latitude  ?? 0,
                longitude:        locationManager.coordinate?.longitude ?? 0,
                score:            userSettings.weeklyAuraPoints,
                reps:             0, comments: 0,
                streak:           userSettings.macroStreak,
                isCurrentUser:    true,
                isPrivate:        userSettings.isPrivateAccount
            ))
        }

        firestoreAura = result.sorted {
            $0.score != $1.score ? $0.score > $1.score : $0.displayName < $1.displayName
        }
    }

    private static let localRadiusMeters: Double = 160_934 // 100 miles

    private func scopeFiltered(_ entries: [LeaderboardEntry]) -> [LeaderboardEntry] {
        switch selectedScope {
        case .team:
            // Show the current user plus everyone they follow (matched by userID)
            return entries.filter { $0.isCurrentUser || followingIDs.contains($0.id) }
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

    // MARK: - Following IDs

    private func loadFollowingIDs() async {
        guard !userSettings.userID.isEmpty else { return }
        if let entries = try? await FollowService.shared.fetchFollowing(userID: userSettings.userID) {
            followingIDs = Set(entries.map { $0.userID })
        }
    }

    // MARK: - Helpers

    private func loadLastWeekSnapshot() async {
        lastWeekLoading = true
        defer { lastWeekLoading = false }
        lastWeekSnapshot = try? await UserProfileService.shared.fetchLastWeekSnapshot()
    }

    private var countdownText: String {
        let clamped = max(0, timeUntilReset)
        let total   = Int(clamped)
        let days    = total / 86400
        let hours   = (total % 86400) / 3600
        let mins    = (total % 3600) / 60
        let secs    = total % 60
        if total >= 36000 { // 10+ hours: days/hours/minutes only
            if days > 0 {
                return String(format: "%dd:%02dh:%02dm", days, hours, mins)
            } else {
                return String(format: "%02d:%02d", hours, mins)
            }
        } else { // under 10 hours: show seconds + tenths
            let tenths = Int((clamped - Double(total)) * 10)
            return String(format: "%d:%02d:%02d.%d", hours, mins, secs, tenths)
        }
    }

    private var countdownIsUrgent: Bool {
        timeUntilReset < 36000 // under 10 hours
    }

    private var resetCountdownBanner: some View {
        VStack(spacing: 6) {
            Text("NEXT RESET")
                .font(.system(size: 11, weight: .bold))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.40))
            Text(countdownText)
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundStyle(gold)
                .opacity(countdownIsUrgent ? (countdownBlink ? 1.0 : 0.5) : 1.0)
            Text("Sunday 8 PM ET")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.30))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(purpl.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private var nextSundayString: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: UserSettings.nextWeekReset())
    }
}

// MARK: - Last Week Results Sheet

private struct LastWeekResultsSheet: View {
    let snapshot:      UserProfileService.WeeklySnapshot?
    let isLoading:     Bool
    let currentUserID: String

    @Environment(\.dismiss) private var dismiss

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var weekLabel: String {
        guard let key = snapshot?.weekStartDate,
              let date = Self.dateFormatter.date(from: key) else { return "Last Week" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return "Week of \(f.string(from: date))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(purpl)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let snap = snapshot, !snap.entries.isEmpty {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(snap.entries) { entry in
                                rowView(entry: entry)
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 24)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 36))
                            .foregroundStyle(purpl.opacity(0.50))
                        Text("No results yet")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Last week's standings will appear here after the Sunday 8 PM ET reset.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.45))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(weekLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(purpl)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func rowView(entry: UserProfileService.WeeklySnapshotEntry) -> some View {
        let isMe = entry.id == currentUserID
        HStack(spacing: 12) {
            // Rank
            Text("#\(entry.rank)")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(entry.rank <= 3 ? gold : .white.opacity(0.40))
                .frame(width: 32, alignment: .trailing)

            // Avatar placeholder
            Circle()
                .fill(purpl.opacity(0.18))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String((entry.displayName.isEmpty ? entry.username : entry.displayName).prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(purpl)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName.isEmpty ? entry.username : entry.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isMe ? gold : .white)
                if !entry.location.isEmpty {
                    Text(entry.location)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }

            Spacer()

            Text("\(entry.auraPoints) xp")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(isMe ? gold : purpl)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isMe ? purpl.opacity(0.12) : cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isMe ? purpl.opacity(0.30) : Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

// MARK: - Weekly Winner Popup

private struct WeeklyWinnerPopup: View {
    let arenaRank:    Int?
    let arenaXP:      Int
    let localRank:    Int?
    let localXP:      Int
    let boardEntries: [LeaderboardEntry]

    @Environment(\.dismiss) private var dismiss

    private let pageBg = Color(red: 0.05, green: 0.03, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)

    private var totalXP: Int { arenaXP + localXP }

    private func rankEmoji(_ rank: Int) -> String {
        switch rank { case 1: return "🥇"; case 2: return "🥈"; case 3: return "🥉"; default: return "🏅" }
    }
    private func ordinal(_ rank: Int) -> String {
        switch rank { case 1: return "st"; case 2: return "nd"; case 3: return "rd"; default: return "th" }
    }

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Trophy icon + headline
                    VStack(spacing: 10) {
                        Text("🏆")
                            .font(.system(size: 64))
                            .padding(.top, 40)

                        Text("Congratulations!")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("You finished in the top 10 this week")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 20)

                    // Award rows
                    VStack(spacing: 10) {
                        if let rank = arenaRank, arenaXP > 0 {
                            awardRow(label: "Arena Board", detail: "\(rankEmoji(rank)) \(rank)\(ordinal(rank)) place", xp: arenaXP)
                        }
                        if let rank = localRank, localXP > 0 {
                            awardRow(label: "Local Board", detail: "\(rankEmoji(rank)) \(rank)\(ordinal(rank)) place", xp: localXP)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Total XP pill
                    if totalXP > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("+\(totalXP) Aura XP added to your profile")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(gold)
                        .clipShape(Capsule())
                        .padding(.top, 16)
                    }

                    // Arena board snapshot
                    if !boardEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Arena final standings")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.40))
                                .padding(.horizontal, 16)
                                .padding(.top, 28)
                                .padding(.bottom, 10)

                            VStack(spacing: 6) {
                                ForEach(Array(boardEntries.prefix(10).enumerated()), id: \.element.id) { idx, entry in
                                    HStack(spacing: 10) {
                                        Text(boardRankEmoji(idx + 1))
                                            .font(.system(size: 16))
                                            .frame(width: 28)
                                        Text(entry.displayName)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(entry.isCurrentUser ? gold : .white)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("\(entry.score) xp")
                                            .font(.system(size: 12, weight: .black, design: .rounded))
                                            .foregroundStyle(entry.isCurrentUser ? gold : purpl)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(entry.isCurrentUser ? purpl.opacity(0.12) : Color.white.opacity(0.04))
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    Button(action: { dismiss() }) {
                        Text("Awesome!")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(gold)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .padding(.top, 28)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func awardRow(label: String, detail: String, xp: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                Text(detail)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11, weight: .bold))
                Text("+\(xp) XP")
                    .font(.system(size: 13, weight: .black, design: .rounded))
            }
            .foregroundStyle(gold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(gold.opacity(0.12), in: Capsule())
        }
        .padding(14)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(gold.opacity(0.20), lineWidth: 1))
    }

    private func boardRankEmoji(_ rank: Int) -> String {
        switch rank { case 1: return "🥇"; case 2: return "🥈"; case 3: return "🥉"; default: return "#\(rank)" }
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
                    Text("MACROMAXXING")
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
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            dismiss()
        }
    }
}

// MARK: - Leaderboard row

private struct LeaderboardRow: View {
    let rank:          Int
    let entry:         LeaderboardEntry
    let board:         LeaderboardView.Board
    let isCurrentUser: Bool

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
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentUser
                      ? purpl.opacity(0.12)
                      : rank <= 3 ? rankColor.opacity(0.05) : Color(red: 0.10, green: 0.08, blue: 0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isCurrentUser ? purpl.opacity(0.30)
                            : rank <= 3 ? rankColor.opacity(0.22)
                            : Color.white.opacity(0.04),
                            lineWidth: 1
                        )
                )
        )
    }

    private var rankBadge: some View {
        ZStack {
            switch rank {
            case 1:
                Circle()
                    .fill(gold.opacity(0.20))
                    .frame(width: 34, height: 34)
                Text("👑")
                    .font(.system(size: 17))
            case 2:
                Circle()
                    .fill(silver.opacity(0.18))
                    .frame(width: 34, height: 34)
                Text("🥈")
                    .font(.system(size: 17))
            case 3:
                Circle()
                    .fill(bronze.opacity(0.18))
                    .frame(width: 34, height: 34)
                Text("🥉")
                    .font(.system(size: 17))
            default:
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 34, height: 34)
                Text("\(rank)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .frame(width: 34)
    }

    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarCircle(size: 44, data: entry.profileImageData, urlString: entry.profilePhotoURL, initial: entry.displayName)
            Text("⭐")
                .font(.system(size: 9))
                .padding(2)
                .background(Color.black.opacity(0.60))
                .clipShape(Circle())
                .offset(x: 2, y: 2)
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
                        .clipShape(Capsule())
                }
            }
            HStack(spacing: 4) {
                Text("@\(entry.username)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.32))
                Text("· Lv \(entry.auraLevel)")
                    .font(.caption2)
                    .foregroundStyle(Color(red: 1.0, green: 0.80, blue: 0.20).opacity(0.70))
            }
        }
    }

    private var scoreStack: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text("\(entry.score.formatted())")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(rankColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(rankColor.opacity(0.12))
                .clipShape(Capsule())
            Text("xp")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.28))
        }
    }

    private var rankColor: Color {
        if isCurrentUser { return purpl }
        switch rank {
        case 1: return Color(red: 1.00, green: 0.80, blue: 0.20)
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.82)
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.75)
        }
    }
}
