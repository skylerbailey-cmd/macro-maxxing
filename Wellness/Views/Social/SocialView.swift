//
//  SocialView.swift
//  Wellness
//

import SwiftUI
import SwiftData
import CoreLocation
import Contacts
import ContactsUI

// MARK: - Color palette

private extension Color {
    static let pageBg   = Color(red: 0.07, green: 0.05, blue: 0.12)
    static let cardBg   = Color(red: 0.13, green: 0.10, blue: 0.22)
    static let purpleHi = Color(red: 0.65, green: 0.45, blue: 1.00)
}

// MARK: - SocialView

struct SocialView: View {
    let userSettings: UserSettings

    @Environment(LocationManager.self) private var locationManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SocialPost.postedAt, order: .reverse) private var posts: [SocialPost]
    @Query(sort: \Friend.addedAt,      order: .reverse) private var friends: [Friend]

    @State private var showingAddFriend = false
    @State private var showingNewPost   = false
    @State private var selectedPost:    SocialPost?
    @State private var selectedFeed:    Feed        = .arena
    @State private var viewingProfile:  SocialPost? = nil
    @State private var showingSettings  = false
    @State private var showingOwnProfile = false

    enum Feed: String, CaseIterable {
        case team  = "Team"
        case local = "Local"
        case arena = "Arena"
    }

    private var teamPosts: [SocialPost] {
        let friendUsernames = Set(friends.map { $0.username.lowercased() })
        return posts.filter { post in
            post.authorID == userSettings.userID ||
            friendUsernames.contains(post.authorUsername.lowercased())
        }
    }

    private static let localRadiusMeters: Double = 160_934 // 100 miles

    private var localPosts: [SocialPost] {
        guard let coord = locationManager.coordinate else { return [] }
        let userLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)

        // Filter to visible posts within 100 miles (own posts always included)
        let nearby = posts.filter { post in
            guard isVisible(post) else { return false }
            if post.authorID == userSettings.userID { return true }
            guard post.authorLatitude != 0 || post.authorLongitude != 0 else { return false }
            return CLLocation(latitude: post.authorLatitude, longitude: post.authorLongitude)
                .distance(from: userLoc) <= Self.localRadiusMeters
        }

        // Deduplicate authors, keep 500 closest, then return all their posts
        var authorDist: [String: Double] = [:]
        for post in nearby {
            guard authorDist[post.authorID] == nil else { continue }
            if post.authorID == userSettings.userID {
                authorDist[post.authorID] = 0
            } else {
                authorDist[post.authorID] = CLLocation(latitude: post.authorLatitude, longitude: post.authorLongitude)
                    .distance(from: userLoc)
            }
        }
        let top500 = Set(authorDist.sorted { $0.value < $1.value }.prefix(500).map(\.key))
        return nearby.filter { top500.contains($0.authorID) }
    }

    private var arenaPosts: [SocialPost] {
        posts.filter { isVisible($0) }
    }

    private var displayedPosts: [SocialPost] {
        switch selectedFeed {
        case .team:  return ranked(teamPosts)
        case .local: return ranked(localPosts)
        case .arena: return ranked(arenaPosts)
        }
    }

    /// Returns true if a post should be visible in local/arena feeds.
    /// Private accounts (including your own) are hidden from local and arena entirely.
    private func isVisible(_ post: SocialPost) -> Bool {
        if post.authorID == userSettings.userID { return !userSettings.isPrivateAccount }
        return !post.isAuthorPrivate
    }

    /// Ranks posts by a blend of engagement and recency.
    /// Posts under 1 hour old get a decaying boost (up to +30) on top of their engagement score.
    /// Engagement: reps + comments × 2 (comments weighted higher — more effort than a rep).
    private func ranked(_ input: [SocialPost]) -> [SocialPost] {
        let now = Date()
        return input.sorted { a, b in
            feedScore(a, now: now) > feedScore(b, now: now)
        }
    }

    private func feedScore(_ post: SocialPost, now: Date) -> Double {
        let ageHours    = max(0, now.timeIntervalSince(post.postedAt) / 3600)
        let engagement  = Double(post.repsCount) + Double(post.comments.count) * 2.0
        // Large boost in the first hour, then a smaller tail that fades to zero at 24 hours
        let firstHourBoost = ageHours < 1  ? (1.0 - ageHours) * 20.0        : 0.0
        let dailyBoost     = ageHours < 24 ? (1.0 - ageHours / 24.0) * 10.0 : 0.0
        return engagement + firstHourBoost + dailyBoost
    }

    var body: some View {
        ZStack {
            Color.pageBg.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(Feed.allCases, id: \.self) { feed in
                        Button { selectedFeed = feed } label: {
                            Text(feed.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(selectedFeed == feed ? .black : .white.opacity(0.55))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule().fill(selectedFeed == feed ? Color.purpleHi : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(duration: 0.2), value: selectedFeed)
                    }
                }
                .padding(4)
                .background(Capsule().fill(Color.cardBg))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .onAppear {
                    if selectedFeed == .local { locationManager.requestLocationIfNeeded() }
                }
                .onChange(of: selectedFeed) { _, feed in
                    if feed == .local { locationManager.requestLocationIfNeeded() }
                }

                if userSettings.isPrivateAccount && (selectedFeed == .local || selectedFeed == .arena) {
                    privateAccountBanner
                }
                if displayedPosts.isEmpty {
                    emptyFeed
                } else {
                    List {
                        ForEach(displayedPosts) { post in
                            PostCard(post: post, userID: userSettings.userID,
                                     userSettings: userSettings,
                                     onAvatarTap: { viewingProfile = post })
                                .contentShape(Rectangle())
                                .onTapGesture { selectedPost = post }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    if post.authorID == userSettings.userID {
                                        Button(role: .destructive) {
                                            let fbID   = post.firebasePostID
                                            let userID = post.authorID
                                            modelContext.delete(post)
                                            if !fbID.isEmpty {
                                                Task {
                                                    do {
                                                        try await PostService.shared.deletePostByID(
                                                            postID: fbID,
                                                            userID: userID
                                                        )
                                                    } catch {
                                                        print("[SocialView] Firebase delete failed: \(error.localizedDescription)")
                                                    }
                                                }
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { showingAddFriend = true } label: {
                    Image(systemName: "person.badge.plus").foregroundStyle(Color.purpleHi)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 14) {
                    Button { showingNewPost = true } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(red: 1.00, green: 0.80, blue: 0.20))
                    }
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.purpleHi)
                    }
                    Button { showingOwnProfile = true } label: {
                        socialProfileAvatarIcon
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewPost) { NewPostView(userSettings: userSettings) }
        .sheet(isPresented: $showingAddFriend) { AddFriendView(userSettings: userSettings, friends: friends) }
        .sheet(isPresented: $showingSettings) {
            NavigationStack { SettingsView(userSettings: userSettings) }
        }
        .sheet(isPresented: $showingOwnProfile) {
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
        .sheet(item: $selectedPost) { post in PostDetailView(post: post, userSettings: userSettings) }
        .sheet(item: $viewingProfile) { post in
            NavigationStack {
                ProfileView(
                    profileUserID:      post.authorID,
                    profileUsername:    post.authorUsername,
                    profileDisplayName: post.authorDisplayName,
                    profileAuraLevel:   post.authorAuraLevel,
                    profileAuraPoints:  post.authorAuraPoints,
                    profileImageData:   post.authorProfileImageData,
                    profileLocation:    post.authorLocation,
                    profileStreak:      post.authorStreak,
                    ownUserSettings:    post.authorID == userSettings.userID ? userSettings : nil
                )
            }
            .presentationDetents([.large])
        }
    }

    private var socialProfileAvatarIcon: some View {
        Group {
            if let data = userSettings.profileImageData, let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg)
                    .resizable().scaledToFill()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.purpleHi, lineWidth: 1.5))
            } else {
                ZStack {
                    Circle().fill(Color.cardBg).frame(width: 30, height: 30)
                        .overlay(Circle().stroke(Color.purpleHi, lineWidth: 1.5))
                    Image(systemName: "person.fill").font(.system(size: 14)).foregroundStyle(Color.purpleHi)
                }
            }
        }
    }

    @ViewBuilder
    private var privateAccountBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color.purpleHi)
            VStack(alignment: .leading, spacing: 4) {
                Text("You're hidden from this feed")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Private accounts don't appear in Local or Arena. Switch to a public profile in Settings to join the conversation.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.50))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.purpleHi.opacity(0.30), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var emptyFeed: some View {
        let noLocation = selectedFeed == .local && locationManager.coordinate == nil
        let icon = selectedFeed == .team ? "person.2.fill"
            : selectedFeed == .local ? "location.circle.fill"
            : "bolt.circle.fill"
        let headline = selectedFeed == .team ? "Team is quiet"
            : noLocation ? "Location needed"
            : selectedFeed == .local ? "No local posts yet"
            : "Arena is empty"
        let body = selectedFeed == .team
            ? "Add friends with the + button above — their posts will appear here."
            : noLocation
            ? "Enable location in Settings so we can show posts from people near you."
            : selectedFeed == .local ? "No one in your area has posted yet. Be the first."
            : "Hit your macro goals and post from the celebration screen, or tap ✏️ to drop a post."

        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.purpleHi.opacity(0.10))
                    .frame(width: 88, height: 88)
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Color.purpleHi.opacity(0.45))
            }
            VStack(spacing: 6) {
                Text(headline)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.32))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 32)
            }
            if noLocation {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.purpleHi)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Post card

// Reusable avatar circle used by PostCard and PostDetailView
func avatarCircle(size: CGFloat, data: Data?, initial: String) -> some View {
    Group {
        if let d = data, let img = UIImage(data: d) {
            Image(uiImage: img)
                .resizable().scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.25))
                .frame(width: size, height: size)
                .overlay {
                    Text(String(initial.prefix(1)).uppercased())
                        .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.0))
                }
        }
    }
}

struct PostCard: View {
    @Bindable var post: SocialPost
    let userID: String
    let userSettings: UserSettings
    var onAvatarTap: (() -> Void)? = nil

    @State private var showingImageViewer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            authorHeader

            if !post.fuelLogEntries.isEmpty {
                fuelLogBody
            } else if post.isCustomPost {
                customBody
            } else {
                achievementBody
            }

            // Reps + comments (right-aligned)
            HStack(spacing: 8) {
                Spacer()
                // 💪 Rep button
                Button {
                    let isNewRep = !post.hasRepped(userID: userID)
                    post.toggleRep(userID: userID)
                    if isNewRep {
                        userSettings.awardAura(points: 1, silent: true)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text("💪")
                            .font(.system(size: 12))
                        Text(post.repsCount > 0 ? "\(post.repsCount)" : "Rep")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(
                                post.hasRepped(userID: userID)
                                    ? Color(red: 1.0, green: 0.75, blue: 0.2)
                                    : .white.opacity(0.70)
                            )
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        post.hasRepped(userID: userID)
                            ? Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.14)
                            : Color.white.opacity(0.06)
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(
                            post.hasRepped(userID: userID)
                                ? Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.35)
                                : Color.clear,
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)

                HStack(spacing: 5) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 11))
                    Text("\(post.comments.count)")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(.white.opacity(0.35))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.05))
                .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(Color.cardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .sheet(isPresented: $showingImageViewer) {
            PostImageViewerSheet(imageDatas: post.allImageDatas)
        }
    }

    private var authorHeader: some View {
        HStack(spacing: 10) {
            // Tappable avatar
            Button(action: { onAvatarTap?() }) {
                avatarCircle(size: 38, data: post.authorProfileImageData,
                             initial: post.authorDisplayName)
            }
            .buttonStyle(.plain)
            .disabled(onAvatarTap == nil)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(post.authorDisplayName.isEmpty ? post.authorUsername : post.authorDisplayName)
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    if post.authorAuraPoints > 0 {
                        HStack(spacing: 3) {
                            Text("⭐")
                                .font(.system(size: 9))
                            Text("Lv \(post.authorAuraLevel)")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(Color(red: 1.0, green: 0.80, blue: 0.20))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color(red: 1.0, green: 0.80, blue: 0.20).opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
                Text("@\(post.authorUsername)  ·  \(post.postedAt, format: .dateTime.month(.abbreviated).day().hour().minute())")
                    .font(.caption2).foregroundStyle(.white.opacity(0.35))
            }
            Spacer()
            if !post.isCustomPost {
                Text(post.memeEmoji)
                    .font(post.memeEmoji.count > 2 ? .subheadline.weight(.bold) : .title2)
                    .foregroundStyle(
                        post.memeEmoji.hasPrefix("⭐")
                            ? Color(red: 1.0, green: 0.80, blue: 0.20)
                            : .white
                    )
            }
        }
    }

    // Custom post: image + title + body
    @ViewBuilder
    private var customBody: some View {
        if !post.allImageDatas.isEmpty {
            imageThumbnailStrip
        }
        Text(post.memeHeadline)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
        if !post.memeSub.isEmpty {
            Text(post.memeSub)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .lineLimit(3)
        }
    }

    // Achievement post: optional photo + meme + macro summary
    @ViewBuilder
    private var achievementBody: some View {
        if !post.allImageDatas.isEmpty {
            imageThumbnailStrip
        }
        Text(post.memeHeadline.replacingOccurrences(of: "\n", with: " "))
            .font(.system(size: 15, weight: .black, design: .rounded))
            .foregroundStyle(.white)
        Text(post.memeSub)
            .font(.caption).foregroundStyle(.white.opacity(0.50))

        if post.goalCalories > 0 {
            macroSummaryRow
        }

        if !post.fastingWindowDisplay.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.00))
                Text(post.fastingWindowDisplay)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.60))
            }
            .padding(.top, 2)
        }
    }

    /// Fixed-height thumbnail strip shown in the feed card. Tap opens full-screen viewer.
    @ViewBuilder
    private var imageThumbnailStrip: some View {
        let datas = post.allImageDatas
        let images = datas.compactMap { UIImage(data: $0) }
        if !images.isEmpty {
            Button(action: { showingImageViewer = true }) {
                ZStack(alignment: .bottomTrailing) {
                    if images.count == 1 {
                        Image(uiImage: images[0])
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .clipped()
                            .cornerRadius(10)
                    } else {
                        PostImagesView(imageDatas: datas)
                    }

                    // Expand hint badge
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                        .padding(6)
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var macroSummaryRow: some View {
        let items: [(String, Double, Double, Color)] = [
            ("Cal",  post.totalCalories, post.goalCalories, Color(red: 1.00, green: 0.55, blue: 0.15)),
            ("Pro",  post.totalProtein,  post.goalProtein,  Color(red: 0.35, green: 0.75, blue: 1.00)),
            ("Carb", post.totalCarbs,    post.goalCarbs,    Color(red: 0.40, green: 0.90, blue: 0.72)),
            ("Fat",  post.totalFat,      post.goalFat,      Color(red: 1.00, green: 0.50, blue: 0.72)),
        ]
        HStack(spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                let (label, actual, goal, color) = item
                let met: Bool = label == "Cal"
                    ? actual >= goal * 0.85 && actual <= goal * 1.15
                    : actual >= goal * 0.85
                HStack(spacing: 3) {
                    if met {
                        Image(systemName: "checkmark")
                            .font(.system(size: 7, weight: .black))
                    }
                    Text(label)
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(met ? color : .white.opacity(0.32))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(met ? color.opacity(0.14) : Color.white.opacity(0.05))
                .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    private func fuelBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // Fuel log post: visual meal table matching the preview
    @ViewBuilder
    private var fuelLogBody: some View {
        let sorted = post.fuelLogEntries.sorted { $0.sortOrder < $1.sortOrder }
        let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
        let totalCal = sorted.reduce(0.0) { $0 + $1.calories }
        let totalPro = sorted.reduce(0.0) { $0 + $1.protein  }
        let totalCarb = sorted.reduce(0.0) { $0 + $1.carbs   }
        let totalFat = sorted.reduce(0.0) { $0 + $1.fat      }

        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Today's Fuel Log 🔥")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, 10)

            // Optional user message
            if !post.memeSub.isEmpty {
                Text(post.memeSub)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.bottom, 10)
            }

            // Entries
            ForEach(sorted) { entry in
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        if let data = entry.imageData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipped()
                                .cornerRadius(8)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.07))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white.opacity(0.30))
                                }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.foodName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            HStack(spacing: 4) {
                                fuelBadge("\(Int(entry.calories)) kcal", color: Color(red: 1.00, green: 0.55, blue: 0.15))
                                fuelBadge("\(Int(entry.protein))g P",    color: Color(red: 0.35, green: 0.75, blue: 1.00))
                                fuelBadge("\(Int(entry.carbs))g C",      color: Color(red: 0.40, green: 0.90, blue: 0.72))
                                fuelBadge("\(Int(entry.fat))g F",        color: Color(red: 1.00, green: 0.50, blue: 0.72))
                            }
                        }
                        Spacer()
                        Text(entry.loggedAt, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.25))
                    }
                    .padding(.vertical, 8)

                    if entry.id != sorted.last?.id {
                        Divider().background(Color.white.opacity(0.08))
                    }
                }
            }

            // Totals row
            Divider()
                .background(purpl.opacity(0.40))
                .padding(.top, 4)

            HStack {
                Text("Total")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 4) {
                    fuelBadge("\(Int(totalCal)) kcal", color: Color(red: 1.00, green: 0.55, blue: 0.15))
                    fuelBadge("\(Int(totalPro))g P",   color: Color(red: 0.35, green: 0.75, blue: 1.00))
                    fuelBadge("\(Int(totalCarb))g C",  color: Color(red: 0.40, green: 0.90, blue: 0.72))
                    fuelBadge("\(Int(totalFat))g F",   color: Color(red: 1.00, green: 0.50, blue: 0.72))
                }
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Full-screen image viewer

struct PostImageViewerSheet: View {
    let imageDatas: [Data]

    @Environment(\.dismiss) private var dismiss

    private var images: [UIImage] { imageDatas.compactMap { UIImage(data: $0) } }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if images.isEmpty {
                Text("No images").foregroundStyle(.white.opacity(0.40))
            } else if images.count == 1 {
                Image(uiImage: images[0])
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView {
                    ForEach(Array(images.enumerated()), id: \.offset) { _, img in
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.80))
                            .shadow(radius: 4)
                    }
                    .padding(20)
                }
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Add Friend sheet

struct AddFriendView: View {
    let userSettings: UserSettings
    let friends: [Friend]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var usernameInput  = ""
    @State private var showContacts   = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pageBg.ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Add by Username")
                            .font(.headline).foregroundStyle(.white)
                        HStack(spacing: 10) {
                            TextField("@username", text: $usernameInput)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            Button("Add") { addByUsername() }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.purpleHi)
                        }
                        if let err = errorMessage {
                            Text(err).font(.caption).foregroundStyle(.red)
                        }
                    }
                    .padding(16).background(Color.cardBg).cornerRadius(14)

                    Button { showContacts = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "person.crop.circle")
                            Text("Add from Contacts").font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.cardBg).foregroundStyle(.white).cornerRadius(14)
                    }

                    if !friends.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Friends (\(friends.count))")
                                .font(.headline).foregroundStyle(.white)
                            ForEach(friends) { friend in
                                HStack {
                                    Circle().fill(Color.purpleHi.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                        .overlay {
                                            Text(String(friend.displayName.prefix(1)).uppercased())
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(Color.purpleHi)
                                        }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(friend.displayName).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                                        Text("@\(friend.username)").font(.caption2).foregroundStyle(.white.opacity(0.40))
                                    }
                                    Spacer()
                                    Button(role: .destructive) { modelContext.delete(friend) } label: {
                                        Image(systemName: "person.badge.minus").foregroundStyle(.red.opacity(0.65))
                                    }
                                }
                                .padding(10).background(Color.cardBg).cornerRadius(12)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.top, 16)
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Friends").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .sheet(isPresented: $showContacts) {
            ContactPickerView { name in
                addFriend(username: name.lowercased().replacingOccurrences(of: " ", with: ""),
                          displayName: name)
            }
        }
    }

    private func addByUsername() {
        let handle = usernameInput.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased().replacingOccurrences(of: "@", with: "")
        guard !handle.isEmpty else { errorMessage = "Enter a username."; return }
        if handle == userSettings.username { errorMessage = "That's you!"; return }
        if friends.contains(where: { $0.username == handle }) { errorMessage = "Already added."; return }
        addFriend(username: handle, displayName: handle)
        usernameInput = ""; errorMessage = nil
    }

    private func addFriend(username: String, displayName: String) {
        modelContext.insert(Friend(username: username, displayName: displayName))
    }
}

// MARK: - Contacts picker

private struct ContactPickerView: UIViewControllerRepresentable {
    let onSelect: (String) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onSelect: onSelect) }
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let p = CNContactPickerViewController(); p.delegate = context.coordinator; return p
    }
    func updateUIViewController(_: CNContactPickerViewController, context: Context) {}
    class Coordinator: NSObject, CNContactPickerDelegate {
        let onSelect: (String) -> Void
        init(onSelect: @escaping (String) -> Void) { self.onSelect = onSelect }
        func contactPicker(_: CNContactPickerViewController, didSelect c: CNContact) {
            let name = [c.givenName, c.familyName].filter { !$0.isEmpty }.joined(separator: " ")
            onSelect(name.isEmpty ? "Friend" : name)
        }
    }
}
