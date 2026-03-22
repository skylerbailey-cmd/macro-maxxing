//
//  ProfileView.swift
//  Wellness
//

import SwiftUI
import SwiftData

// MARK: - ProfileView

struct ProfileView: View {
    // Profile being viewed
    let profileUserID:       String
    let profileUsername:     String
    let profileDisplayName:  String
    let profileAuraLevel:    Int
    let profileAuraPoints:   Int
    let profileImageData:    Data?
    var profileLocation:     String = ""
    var profileBio:          String = ""
    var profileStreak:       Int    = 0

    /// Non-nil only when viewing your own profile (enables photo editing)
    var ownUserSettings: UserSettings? = nil

    /// Non-nil when viewing someone else's profile — provides the viewer's identity for follow actions
    var currentUserSettings: UserSettings? = nil

    /// Set true when ProfileView is presented as a sheet so an X dismiss button is shown.
    var isDismissable: Bool = false

    /// Whether the profile owner has a private account. When true and the viewer
    /// is not a follower, only the header is shown — posts and stats are hidden.
    var profileIsPrivate: Bool = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var editingBio          = false
    @State private var bioText:            String = ""
    @State private var balanceScore:          Int?   = nil
    @State private var yesterdayBalanceScore: Int?   = nil
    @State private var balancePercentile:     Int?   = nil
    @State private var ringProgress:          Double = 0
    @State private var showingBalanceInfo:    Bool   = false
    @State private var showingCamera       = false
    @State private var showingLibrary      = false
    @State private var showingPhotoSource  = false
    @State private var rawPickedImage:     UIImage? = nil
    @State private var showingCrop         = false
    @State private var newProfileImage:    UIImage?
    @State private var showingProfileShare = false
    @State private var showingSettings     = false

    // Firestore posts (primary source for profile grid)
    @State private var firestorePosts: [FeedPost] = []
    @State private var postsLoading   = false

    // Follow state
    @State private var followStateLoaded:     Bool   = false
    @State private var isFollowing:           Bool   = false
    @State private var followerCount:         Int    = 0
    @State private var followingCount:        Int    = 0
    @State private var friendCount:           Int    = 0
    @State private var followLoading:         Bool   = false
    @State private var viewerProfilePhotoURL: String = ""
    @State private var targetProfilePhotoURL: String = ""
    @State private var fetchedBio:            String = ""
    @State private var showingConnections:    Bool   = false

    // Subscription state
    @State private var isSubscribed:     Bool = false
    @State private var subscribeLoading: Bool = false

    // Tutorial
    @AppStorage("hasSeenProfileTutorial") private var hasSeenProfileTutorial = false
    @State private var showingTutorial  = false
    @State private var tutorialAnchors: [String: Anchor<CGRect>] = [:]
    @State private var tutorialScrollProxy: ScrollViewProxy? = nil

    private var isOwnProfile: Bool { ownUserSettings != nil }

    /// True once follow state is known AND the viewer isn't allowed to see content.
    private var isLocked: Bool {
        guard !isOwnProfile, profileIsPrivate, followStateLoaded else { return false }
        return !isFollowing
    }

    private var resolvedStreak: Int {
        if let own = ownUserSettings { return own.macroStreak }
        // For other users derive from the highest streak seen on their Firestore posts
        return firestorePosts.map { $0.streak }.max() ?? profileStreak
    }

    private var displayName: String {
        profileDisplayName.isEmpty ? profileUsername : profileDisplayName
    }

    private var resolvedAvatarImage: UIImage? {
        if isOwnProfile {
            if let img = newProfileImage { return img }
            if let data = ownUserSettings?.profileImageData { return UIImage(data: data) }
            return nil
        }
        if let data = profileImageData { return UIImage(data: data) }
        return nil
    }

    // MARK: - Palette
    private let pageBg  = Color(red: 0.04, green: 0.03, blue: 0.08)
    private let cardBg  = Color(red: 0.07, green: 0.06, blue: 0.11)
    private let purpl   = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold    = Color(red: 1.00, green: 0.80, blue: 0.20)
    private let neon    = Color(red: 0.35, green: 1.00, blue: 0.60)

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerBanner
                            .tutorialAnchor("profile.header")

                        if isLocked {
                            lockedProfileView
                        } else {
                            socialStatsBar
                                .tutorialAnchor("profile.stats")
                                .padding(.top, 24)
                            socialLinks
                            if !isOwnProfile { addToTeamButton }
                            if !isOwnProfile && isFollowing { subscribeButton }
                            postsGrid
                                .padding(.top, 8)
                        }
                    }
                    .padding(.bottom, 40)
                }
                .onAppear { tutorialScrollProxy = scrollProxy }
            }

            if showingTutorial {
                TutorialOverlayView(
                    steps:   TutorialSteps.profile,
                    anchors: tutorialAnchors,
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.25)) { showingTutorial = false }
                        hasSeenProfileTutorial = true
                    },
                    onStepChange: { anchorID in
                        guard let proxy = tutorialScrollProxy else { return }
                        if anchorID == "profile.balanceScore" {
                            withAnimation { proxy.scrollTo("balanceScoreAnchor", anchor: .center) }
                        } else if anchorID == "profile.header" {
                            withAnimation { proxy.scrollTo("balanceScoreAnchor", anchor: .bottom) }
                        } else if anchorID == "profile.stats" {
                            withAnimation { proxy.scrollTo("balanceScoreAnchor", anchor: .top) }
                        }
                    }
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                .zIndex(100)
            }
        }
        .onPreferenceChange(TutorialAnchorKey.self) { tutorialAnchors = $0 }
        .preferredColorScheme(.dark)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isDismissable {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.70))
                    }
                }
            }
            if isOwnProfile {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
                        Button { showingTutorial = true } label: {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 20))
                                .foregroundStyle(.white.opacity(0.65))
                        }
                        Button { showingProfileShare = true } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(gold)
                        }
                        Button { showingSettings = true } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(purpl)
                        }
                    }
                }
            }
        }
        .task { await loadFollowState() }
        .task { await loadPosts() }
        .task { await loadBalanceScore() }
        .task {
            // Show the profile tutorial once, only on the user's own profile
            if isOwnProfile && !hasSeenProfileTutorial {
                try? await Task.sleep(for: .seconds(1.0))
                showingTutorial = true
            }
        }
        .sheet(isPresented: $showingBalanceInfo) { balanceInfoSheet }
        .sheet(isPresented: $showingConnections) {
            ConnectionsSheet(
                userID:              profileUserID,
                currentUserSettings: currentUserSettings ?? ownUserSettings
            )
        }
        .sheet(isPresented: $showingSettings) {
            if let settings = ownUserSettings {
                NavigationStack { SettingsView(userSettings: settings) }
            }
        }
        .confirmationDialog("Change Profile Photo", isPresented: $showingPhotoSource, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") { showingCamera = true }
            }
            Button("Choose from Library") { showingLibrary = true }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showingCamera, onDismiss: { if rawPickedImage != nil { showingCrop = true } }) {
            ImagePickerView(sourceType: .camera, selectedImage: $rawPickedImage)
        }
        .sheet(isPresented: $showingLibrary, onDismiss: { if rawPickedImage != nil { showingCrop = true } }) {
            ImagePickerView(sourceType: .photoLibrary, selectedImage: $rawPickedImage)
        }
        .fullScreenCover(isPresented: $showingCrop) {
            if let img = rawPickedImage {
                CropCircleView(sourceImage: img) { cropped in
                    newProfileImage = cropped
                    rawPickedImage  = nil
                    showingCrop     = false
                    saveNewPhoto()
                } onCancel: {
                    rawPickedImage = nil
                    showingCrop    = false
                }
            }
        }
        .sheet(isPresented: $showingProfileShare) {
            ProfileShareView(
                displayName:     profileDisplayName.isEmpty ? profileUsername : profileDisplayName,
                username:        profileUsername,
                auraLevel:       profileAuraLevel,
                auraPoints:      profileAuraPoints,
                auraTitleString: auraTitleString,
                profileImage:    resolvedAvatarImage,
                balanceScore:    balanceScore
            )
        }
    }

    // MARK: - Header Banner

    private var headerBanner: some View {
        ZStack(alignment: .bottom) {
            // Flat banner background
            Color(red: 0.06, green: 0.05, blue: 0.10)
                .frame(height: 200)

            // Decorative glow orb
            Ellipse()
                .fill(purpl.opacity(0.18))
                .frame(width: 260, height: 120)
                .blur(radius: 40)
                .offset(y: -30)

            VStack(spacing: 12) {
                // Avatar
                Button {
                    if isOwnProfile { showingPhotoSource = true }
                } label: {
                    ZStack {
                        // Outer glow ring (gradient)
                        Circle()
                            .fill(
                                AngularGradient(
                                    colors: [gold, purpl, neon, gold],
                                    center: .center
                                )
                            )
                            .frame(width: 114, height: 114)
                            .blur(radius: 3)

                        avatarView(size: 104)

                        if isOwnProfile {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.black)
                                        .padding(6)
                                        .background(gold)
                                        .clipShape(Circle())
                                        .offset(x: 4, y: 4)
                                }
                            }
                            .frame(width: 104, height: 104)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(!isOwnProfile)
                .padding(.top, 24)

                // Name + handle
                VStack(spacing: 3) {
                    Text(displayName)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 6) {
                        if !profileUsername.isEmpty {
                            Text("@\(profileUsername)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        if !profileLocation.isEmpty {
                            Text("·")
                                .foregroundStyle(.white.opacity(0.25))
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 9))
                                .foregroundStyle(purpl.opacity(0.70))
                            Text(profileLocation)
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.40))
                        }
                    }
                }

                // Bio
                bioSection

                // Balance Score
                if isOwnProfile {
                    balanceScoreBubble
                        .id("balanceScoreAnchor")
                        .tutorialAnchor("profile.balanceScore")
                        .padding(.top, 8)
                }

                // Level + title (no pill, just plain text)
                if !auraTitleString.isEmpty {
                    HStack(spacing: 5) {
                        Text("LVL \(max(1, profileAuraLevel))")
                            .font(.system(size: 11, weight: .black))
                            .tracking(1)
                            .foregroundStyle(purpl)
                        Text("·")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(gold.opacity(0.50))
                        Text(auraTitleString.uppercased())
                            .font(.system(size: 11, weight: .black))
                            .tracking(2)
                            .foregroundStyle(gold)
                    }
                    .padding(.top, 6)
                }
            }
            .padding(.bottom, 20)
        }
    }

    @ViewBuilder
    private var balanceScoreBubble: some View {
        let scoreColor: Color = {
            guard let s = balanceScore else { return .white }
            return s >= 75 ? neon : s >= 50 ? gold : Color(red: 1.0, green: 0.35, blue: 0.35)
        }()
        let scoreLabel: String = {
            guard let s = balanceScore else { return "BALANCE" }
            return s >= 75 ? "DIALED IN" : s >= 50 ? "ON TRACK" : "BUILDING"
        }()

        Button { showingBalanceInfo = true } label: {
            VStack(spacing: 0) {
                // Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.07), lineWidth: 7)
                        .frame(width: 96, height: 96)
                    if let score = balanceScore {
                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(scoreColor.opacity(0.25),
                                    style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .frame(width: 96, height: 96)
                            .rotationEffect(.degrees(-90))
                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(scoreColor,
                                    style: StrokeStyle(lineWidth: 7, lineCap: .round))
                            .frame(width: 96, height: 96)
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 1) {
                            Text("\(score)")
                                .font(.system(size: 30, weight: .black, design: .rounded))
                                .foregroundStyle(scoreColor)
                            Text("/ 100")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(scoreColor.opacity(0.50))
                        }
                    } else {
                        Text("—")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.18))
                    }
                }

                // Score range label + info icon
                HStack(spacing: 4) {
                    Text(scoreLabel)
                        .font(.system(size: 10, weight: .black))
                        .tracking(2)
                        .foregroundStyle(balanceScore != nil ? scoreColor.opacity(0.85) : .white.opacity(0.40))
                    Image(systemName: "info.circle")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(purpl.opacity(0.60))
                }
                .padding(.top, 14)

                // Percentile + day-over-day delta
                HStack(spacing: 6) {
                    if let pct = balancePercentile {
                        Text("Top \(pct)%")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.white.opacity(0.55))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.07), in: Capsule())
                    }
                    if let today = balanceScore, let yest = yesterdayBalanceScore, yest > 0 {
                        let delta = Double(today - yest) / Double(yest) * 100
                        let isUp  = delta >= 0
                        let red   = Color(red: 1.0, green: 0.35, blue: 0.35)
                        HStack(spacing: 2) {
                            Image(systemName: isUp ? "arrow.up" : "arrow.down")
                                .font(.system(size: 8, weight: .black))
                            Text("\(abs(Int(delta.rounded())))%")
                                .font(.system(size: 9, weight: .black))
                        }
                        .foregroundStyle(isUp ? neon : red)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background((isUp ? neon : red).opacity(0.12), in: Capsule())
                    }
                }
                .padding(.top, 6)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var bioSection: some View {
        let currentBio = ownUserSettings?.bio ?? (fetchedBio.isEmpty ? profileBio : fetchedBio)
        if editingBio {
            VStack(spacing: 8) {
                TextField("Add a bio…", text: $bioText, axis: .vertical)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .lineLimit(3...5)
                    .padding(10)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(purpl.opacity(0.35), lineWidth: 1))
                    .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    Button("Cancel") {
                        bioText    = currentBio
                        editingBio = false
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.50))

                    Button("Save") {
                        let trimmed = bioText.trimmingCharacters(in: .whitespacesAndNewlines)
                        ownUserSettings?.bio = trimmed
                        editingBio = false
                        if let settings = ownUserSettings {
                            Task { try? await UserProfileService.shared.updateProfile(userID: settings.userID, fields: ["bio": trimmed]) }
                        }
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(purpl)
                }
            }
            .padding(.bottom, 4)
        } else {
            HStack(alignment: .top, spacing: 6) {
                if !currentBio.isEmpty {
                    Text(currentBio)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                } else if isOwnProfile {
                    Text("Add a bio")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.25))
                }

                if isOwnProfile {
                    Button {
                        bioText    = currentBio
                        editingBio = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(purpl.opacity(0.70))
                            .padding(5)
                            .background(purpl.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Social Stats Bar

    private var socialStatsBar: some View {
        HStack(spacing: 0) {
            statCell(value: resolvedStreak > 0 ? "🔥 \(resolvedStreak)" : "—", label: "STREAK")
            statDivider
            statCell(value: "⚡️ \(auraPointsFormatted)", label: "AURA XP")
            statDivider
            Button { showingConnections = true } label: {
                VStack(spacing: 5) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    Text("CONNECTIONS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.35))
                        .tracking(1.5)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.35))
                .tracking(1.5)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(purpl.opacity(0.20))
            .frame(width: 1, height: 32)
    }

    private var auraPointsFormatted: String {
        if profileAuraPoints >= 1000 {
            return String(format: "%.1fk", Double(profileAuraPoints) / 1000)
        }
        return "\(profileAuraPoints)"
    }

    // MARK: - Aura Level Card

    @ViewBuilder
    private var auraLevelCard: some View {
        if profileAuraPoints > 0 || profileAuraLevel > 0 {
            let pts        = profileAuraPoints
            let level      = UserSettings.auraLevel(for: pts)
            let levelStart = level <= 1 ? 0 : UserSettings.auraThreshold(level)
            let levelEnd   = UserSettings.auraThreshold(level + 1)
            let inLevel    = pts - levelStart
            let forLevel   = max(1, levelEnd - levelStart)
            let progress   = level >= 100 ? 1.0 : Double(inLevel) / Double(forLevel)
            let pctText    = level >= 100 ? "MAX" : "\(Int(progress * 100))%"
            let title      = auraTitle(for: max(1, level))

            VStack(spacing: 10) {
                HStack(spacing: 0) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(gold)
                        Text("Level \(max(1, level))")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        if !title.isEmpty {
                            Text("·")
                                .foregroundStyle(.white.opacity(0.20))
                            Text(title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(gold.opacity(0.80))
                        }
                    }
                    Spacer()
                    Text(pctText)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(gold)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 8)
                        Capsule()
                            .fill(purpl)
                            .frame(width: max(8, geo.size.width * progress), height: 8)
                            .animation(.easeOut(duration: 0.6), value: progress)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(inLevel) / \(forLevel) pts")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.30))
                    Spacer()
                    if level < 100 {
                        Text("\(forLevel - inLevel) pts to Level \(level + 1)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.30))
                    } else {
                        Text("Maximum level reached")
                            .font(.caption2)
                            .foregroundStyle(gold.opacity(0.60))
                    }
                }
            }
            .padding(16)
            .background(cardBg)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.top, 0)
        }
    }



    private var balanceInfoSheet: some View {
        let pageBg2  = Color(red: 0.07, green: 0.05, blue: 0.12)
        let cardBg2  = Color(red: 0.13, green: 0.10, blue: 0.22)
        return NavigationStack {
            ZStack {
                pageBg2.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // Score display
                        HStack {
                            Spacer()
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.07), lineWidth: 8)
                                        .frame(width: 110, height: 110)
                                    if let score = balanceScore {
                                        let color: Color = score >= 75 ? neon : score >= 50 ? gold : Color(red: 1.0, green: 0.35, blue: 0.35)
                                        Circle()
                                            .trim(from: 0, to: ringProgress)
                                            .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                            .frame(width: 110, height: 110)
                                            .rotationEffect(.degrees(-90))
                                        VStack(spacing: 2) {
                                            Text("\(score)")
                                                .font(.system(size: 36, weight: .black, design: .rounded))
                                                .foregroundStyle(color)
                                            Text("/ 100")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(color.opacity(0.50))
                                        }
                                    } else {
                                        Text("Not enough data")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(.white.opacity(0.30))
                                            .multilineTextAlignment(.center)
                                            .frame(width: 80)
                                    }
                                }
                                Text("Your Balance Score")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                            Spacer()
                        }
                        .padding(.top, 8)

                        // What it means
                        infoSection(
                            icon: "scale.3d",
                            iconColor: purpl,
                            title: "What is Balance Score?",
                            body: "Balance Score measures how consistently your eating habits align with your personal macro goals. It combines two signals: how precisely you hit your daily macro targets and how well each individual meal's nutrient ratio matches your ideal breakdown."
                        )

                        infoSection(
                            icon: "chart.bar.fill",
                            iconColor: gold,
                            title: "14-Day Discipline",
                            body: "Each day, your actual calories, protein, carbs, and fat are compared to your goals. A score of 100% means you hit every target exactly — going over or under equally reduces the score. Your discipline average across the last 14 days makes up half of your Balance Score."
                        )

                        infoSection(
                            icon: "fork.knife",
                            iconColor: neon,
                            title: "7-Day Meal Quality",
                            body: "Each logged meal (300+ calories) earns a score based on how closely its protein, carb, and fat ratio matches your goal ratios. The average of all qualifying meals over the last 7 days makes up the other half of your Balance Score."
                        )

                        // Grade key
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Score Ranges")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(.white.opacity(0.55))
                                .tracking(1)

                            gradeRow(range: "75 – 100", label: "Dialed In", color: neon,
                                     description: "Your discipline and meal quality are consistently excellent.")
                            gradeRow(range: "50 – 74",  label: "On Track",  color: gold,
                                     description: "Good habits with room to sharpen your consistency.")
                            gradeRow(range: "0 – 49",   label: "Building",  color: Color(red: 1.0, green: 0.35, blue: 0.35),
                                     description: "Keep logging — your score updates as your data builds.")
                        }
                        .padding(16)
                        .background(cardBg2)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(purpl.opacity(0.15), lineWidth: 1))
                        infoSection(
                            icon: "arrow.up.arrow.down",
                            iconColor: purpl,
                            title: "Daily Change Indicator",
                            body: "The percentage shown below your score compares today's Balance Score to yesterday's. A green arrow up means your score improved — you hit your targets more precisely today. A red arrow down means you were less consistent than yesterday. It resets daily so every day is a fresh opportunity to improve."
                        )
                    }
                    .padding(20)
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Balance Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showingBalanceInfo = false }
                        .foregroundStyle(purpl)
                }
            }
        }
    }

    private func infoSection(icon: String, iconColor: Color, title: String, body: String) -> some View {
        let cardBg2 = Color(red: 0.13, green: 0.10, blue: 0.22)
        return HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                Text(body)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.60))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(cardBg2)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(iconColor.opacity(0.15), lineWidth: 1))
    }

    private func gradeRow(range: String, label: String, color: Color, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(range)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .frame(width: 60, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(color)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.45))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Social Links

    @ViewBuilder
    private var socialLinks: some View {
        if isOwnProfile {
            let ig = ownUserSettings?.instagramHandle.trimmingCharacters(in: .whitespaces) ?? ""
            let tt = ownUserSettings?.tiktokHandle.trimmingCharacters(in: .whitespaces) ?? ""
            if !ig.isEmpty || !tt.isEmpty {
                HStack(spacing: 10) {
                    if !ig.isEmpty {
                        Button {
                            let appURL = URL(string: "instagram://user?username=\(ig)")!
                            let webURL = URL(string: "https://instagram.com/\(ig)")!
                            if UIApplication.shared.canOpenURL(appURL) {
                                UIApplication.shared.open(appURL)
                            } else {
                                UIApplication.shared.open(webURL)
                            }
                        } label: {
                            socialBadge(
                                icon: "camera.fill", label: "@\(ig)",
                                gradient: [Color(red: 1.0, green: 0.55, blue: 0.0),
                                           Color(red: 0.95, green: 0.2, blue: 0.55),
                                           Color(red: 0.55, green: 0.15, blue: 0.9)]
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    if !tt.isEmpty {
                        Button {
                            let appURL = URL(string: "tiktok://user?username=\(tt)")!
                            let webURL = URL(string: "https://www.tiktok.com/@\(tt)")!
                            if UIApplication.shared.canOpenURL(appURL) {
                                UIApplication.shared.open(appURL)
                            } else {
                                UIApplication.shared.open(webURL)
                            }
                        } label: {
                            socialBadge(
                                icon: "music.note", label: "@\(tt)",
                                gradient: [Color(red: 0.1, green: 0.1, blue: 0.1),
                                           Color(red: 0.28, green: 0.28, blue: 0.28)]
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 20)
            }
        }
    }

    // MARK: - Follow / Unfollow Button

    private var addToTeamButton: some View {
        Button {
            Task { await toggleFollow() }
        } label: {
            HStack(spacing: 8) {
                if followLoading {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Image(systemName: isFollowing ? "checkmark.seal.fill" : "person.badge.plus")
                        .font(.system(size: 14, weight: .bold))
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.system(size: 15, weight: .black))
                }
            }
            .foregroundStyle(isFollowing ? neon : .black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Group {
                    if isFollowing {
                        AnyView(neon.opacity(0.15))
                    } else {
                        AnyView(
                            LinearGradient(
                                colors: [gold, Color(red: 1.0, green: 0.60, blue: 0.10)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isFollowing ? neon.opacity(0.40) : Color.clear, lineWidth: 1)
            )
            .cornerRadius(14)
        }
        .disabled(followLoading)
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }

    // MARK: - Posts Grid

    // MARK: - Locked Profile View

    private var lockedProfileView: some View {
        VStack(spacing: 20) {
            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.top, 24)

            Image(systemName: "lock.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(purpl.opacity(0.70))
                .padding(.top, 16)

            VStack(spacing: 8) {
                Text("This account is private")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Follow \(displayName) to see their posts, stats, and progress.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.50))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            addToTeamButton
                .padding(.top, 4)
        }
        .padding(.bottom, 40)
    }

    private var postsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1)
                .padding(.horizontal, 16)
            HStack {
                Text("POSTS")
                    .font(.system(size: 11, weight: .black))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.35))
                Spacer()
                Text("\(firestorePosts.count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(purpl.opacity(0.60))
            }
            .padding(.horizontal, 16)
            .padding(.top, 32)

            if postsLoading {
                ProgressView()
                    .tint(purpl)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if firestorePosts.isEmpty {
                VStack(spacing: 8) {
                    Text("💀")
                        .font(.system(size: 36))
                    Text("No posts yet.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.25))
                    Text("Post your first W to the feed.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.15))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(firestorePosts) { post in
                        let currentUserID = ownUserSettings?.userID ?? currentUserSettings?.userID ?? ""
                        FeedPostCard(
                            post:          post,
                            currentUserID: currentUserID,
                            onRep: { Task { await repPost(post) } },
                            onDelete: post.userID == currentUserID
                                ? { Task { await deletePost(post) } }
                                : nil,
                            showStreak: false
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func auraTitle(for level: Int) -> String {
        switch level {
        case 1...5:   return "Initiate"
        case 6...10:  return "Rookie"
        case 11...15: return "Grinder"
        case 16...20: return "Disciple"
        case 21...25: return "Ascender"
        case 26...35: return "Mog Apprentice"
        case 36...45: return "Aura Seeker"
        case 46...55: return "Aura Farmer"
        case 56...65: return "Aesthetic"
        case 66...75: return "Elite Aesthetic"
        case 76...90: return "Transcendent"
        case 91...:   return "Final Form"
        default:      return ""
        }
    }

    private var auraTitleString: String {
        let level = max(profileAuraLevel, UserSettings.auraLevel(for: profileAuraPoints))
        return auraTitle(for: level)
    }

    private var rankEmoji: String {
        let level = max(profileAuraLevel, UserSettings.auraLevel(for: profileAuraPoints))
        switch level {
        case 1...10:  return "🔥"
        case 11...25: return "⚡️"
        case 26...45: return "💪"
        case 46...65: return "👑"
        case 66...90: return "🐐"
        default:      return "🗿"
        }
    }

    @ViewBuilder
    func avatarView(size: CGFloat) -> some View {
        if let uiImg = resolvedAvatarImage {
            Image(uiImage: uiImg)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            let urlString = isOwnProfile
                ? (ownUserSettings?.profilePhotoURL ?? "")
                : targetProfilePhotoURL
            if !urlString.isEmpty, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    default:
                        avatarPlaceholder(size: size)
                    }
                }
            } else {
                avatarPlaceholder(size: size)
            }
        }
    }

    private func avatarPlaceholder(size: CGFloat) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [purpl.opacity(0.40), Color(red: 0.30, green: 0.10, blue: 0.60)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Text(String(displayName.prefix(1)).uppercased())
                    .font(.system(size: size * 0.40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
    }

    @ViewBuilder
    private func socialBadge(icon: String, label: String, gradient: [Color]) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.white.opacity(0.80))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(cardBg)
        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
        .clipShape(Capsule())
    }

    // MARK: - Actions

    private func saveNewPhoto() {
        guard let img = newProfileImage, let data = img.jpegData(compressionQuality: 0.75) else { return }
        ownUserSettings?.profileImageData = data
        // Upload to Firebase Storage and update the Firestore profile URL
        if let settings = ownUserSettings {
            Task {
                if let url = try? await UserProfileService.shared.updateProfilePhoto(userID: settings.userID, image: img) {
                    settings.profilePhotoURL = url
                }
            }
        }
    }

    private func loadBalanceScore() async {
        guard isOwnProfile, let settings = ownUserSettings, !settings.userID.isEmpty else { return }

        let calendar = Calendar.current
        let today    = Date()
        guard let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: today),
              let sevenDaysAgo    = calendar.date(byAdding: .day, value:  -7, to: today) else { return }

        // 1. Discipline: average of daily discipline scores over the last 14 days
        let history = (try? await MacroHistoryService.shared.fetchMacroHistory(
            userID: settings.userID, from: fourteenDaysAgo, to: today)) ?? []
        guard !Task.isCancelled else { return }

        let disciplineAvg: Double? = history.isEmpty ? nil : {
            let scores = history.map { day -> Double in
                let pairs: [(Double, Double)] = [
                    (Double(day.totalCalories), Double(day.goalCalories)),
                    (day.totalProtein,          day.goalProtein),
                    (day.totalCarbs,            day.goalCarbs),
                    (day.totalFat,              day.goalFat),
                ]
                let active = pairs.filter { $0.1 > 0 }
                guard !active.isEmpty else { return 0 }
                let sum = active.reduce(0.0) { $0 + max(0, 1.0 - abs($1.0 / $1.1 - 1.0)) }
                return sum / Double(active.count)
            }
            return scores.reduce(0, +) / Double(scores.count) * 100
        }()

        // 2. Meal score: average over all qualifying entries in the last 7 days
        let userID = settings.userID
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate { $0.loggedAt >= sevenDaysAgo && $0.userID == userID }
        )
        let entries = (try? modelContext.fetch(descriptor)) ?? []

        let ud = UserDefaults.standard
        func g(_ key: String, fallback: Double) -> Double {
            ud.object(forKey: key) != nil ? ud.double(forKey: key) : fallback
        }
        let pCal  = g("goalProtein", fallback: 150) * 4
        let cCal  = g("goalCarbs",   fallback: 200) * 4
        let fCal  = g("goalFat",     fallback:  65) * 9
        let total = pCal + cCal + fCal
        let goalP = total > 0 ? pCal / total : 0.26
        let goalC = total > 0 ? cCal / total : 0.49
        let goalF = total > 0 ? fCal / total : 0.25

        let qualifying = entries.filter { $0.calories >= 300 }
        let mealAvg: Double? = qualifying.isEmpty ? nil : {
            let scores = qualifying.map { e -> Double in
                let c = e.calories
                let dev = abs((e.protein * 4) / c - goalP)
                        + abs((e.carbs   * 4) / c - goalC)
                        + abs((e.fat     * 9) / c - goalF)
                return max(0, min(100, (1.0 - dev / 2.0) * 100))
            }
            return scores.reduce(0, +) / Double(scores.count)
        }()

        let computed: Int?
        switch (disciplineAvg, mealAvg) {
        case (let d?, let m?): computed = Int(((d + m) / 2).rounded())
        case (let d?, nil):    computed = Int(d.rounded())
        case (nil, let m?):    computed = Int(m.rounded())
        case (nil, nil):       computed = nil
        }
        guard !Task.isCancelled else { return }
        balanceScore = computed
        if let target = computed {
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 1.2)) {
                    ringProgress = Double(target) / 100
                }
            }
        }

        guard !Task.isCancelled else { return }
        let uid = settings.userID
        if let score = computed {
            try? await BalanceScoreService.shared.saveScore(score, userID: uid)
        }
        guard !Task.isCancelled else { return }
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        async let yest = BalanceScoreService.shared.fetchScore(for: yesterday, userID: uid)
        async let pct  = BalanceScoreService.shared.fetchTopPercent(score: computed ?? 0)
        let y = await yest
        let p = await pct
        guard !Task.isCancelled else { return }
        yesterdayBalanceScore = y
        balancePercentile     = computed != nil ? p : nil
    }

    private func repPost(_ post: FeedPost) async {
        guard let postID = post.postID, !postID.isEmpty else { return }
        let currentUserID = ownUserSettings?.userID ?? currentUserSettings?.userID ?? ""
        guard !currentUserID.isEmpty else { return }
        try? await PostService.shared.toggleRep(postID: postID, currentUserID: currentUserID)
        // Refresh list to reflect updated rep count
        await loadPosts()
    }

    private func deletePost(_ post: FeedPost) async {
        try? await PostService.shared.deletePost(post)
        firestorePosts.removeAll { $0.postID == post.postID }
    }

    private func loadPosts() async {
        guard !profileUserID.isEmpty else {
            postsLoading = false
            return
        }
        postsLoading = true
        do {
            let posts = try await PostService.shared.fetchUserPosts(userID: profileUserID)
            guard !Task.isCancelled else { return }
            firestorePosts = posts
        } catch {
            guard !Task.isCancelled else { return }
            firestorePosts = []
        }
        postsLoading = false
    }

    private func loadFollowState() async {
        // Compute counts from actual follow collections rather than cached Firestore counters,
        // which can drift over time.
        async let followersOfProfile  = FollowService.shared.fetchFollowers(userID: profileUserID)
        async let followingByProfile  = FollowService.shared.fetchFollowing(userID: profileUserID)

        let followers  = (try? await followersOfProfile)  ?? []
        let following  = (try? await followingByProfile)  ?? []
        let followerIDs  = Set(followers.map { $0.userID })
        let followingIDs = Set(following.map { $0.userID })

        followerCount  = followerIDs.count
        followingCount = followingIDs.count
        friendCount    = followingIDs.intersection(followerIDs).count

        if isOwnProfile {
            // Still fetch profile for photo URL updates
            if let uid = ownUserSettings?.userID, !uid.isEmpty,
               let profile = try? await UserProfileService.shared.fetchProfile(userID: uid) {
                targetProfilePhotoURL = profile.profilePhotoURL
            }
            followStateLoaded = true
            return
        }
        let viewer = currentUserSettings ?? ownUserSettings
        guard let viewerID = viewer?.userID, !viewerID.isEmpty else {
            followStateLoaded = true
            return
        }

        async let followingCheck = FollowService.shared.isFollowing(currentUserID: viewerID, targetUserID: profileUserID)
        async let targetProfile  = UserProfileService.shared.fetchProfile(userID: profileUserID)
        async let viewerProfile  = UserProfileService.shared.fetchProfile(userID: viewerID)

        if let viewerIsFollowing = try? await followingCheck { isFollowing = viewerIsFollowing }
        guard !Task.isCancelled else { return }
        if let profile = try? await targetProfile {
            targetProfilePhotoURL = profile.profilePhotoURL
            fetchedBio            = profile.bio
        }
        guard !Task.isCancelled else { return }
        if let vp = try? await viewerProfile { viewerProfilePhotoURL = vp.profilePhotoURL }
        guard !Task.isCancelled else { return }
        if let subscribed = try? await SubscriptionService.shared.isSubscribed(
            subscriberID: viewerID, targetUserID: profileUserID) {
            isSubscribed = subscribed
        }
        followStateLoaded = true
    }

    private func toggleFollow() async {
        let viewer = currentUserSettings ?? ownUserSettings
        guard let viewerSettings = viewer, !viewerSettings.userID.isEmpty else { return }

        followLoading = true
        defer { followLoading = false }

        do {
            if isFollowing {
                try await FollowService.shared.unfollowUser(
                    currentUserID: viewerSettings.userID,
                    targetUserID:  profileUserID
                )
                isFollowing   = false
                followerCount = max(0, followerCount - 1)
            } else {
                try await FollowService.shared.followUser(
                    currentUserID:          viewerSettings.userID,
                    currentUsername:        viewerSettings.username,
                    currentDisplayName:     viewerSettings.name.isEmpty ? nil : viewerSettings.name,
                    currentProfilePhotoURL: viewerProfilePhotoURL,
                    targetUserID:           profileUserID,
                    targetUsername:         profileUsername,
                    targetDisplayName:      profileDisplayName.isEmpty ? nil : profileDisplayName,
                    targetProfilePhotoURL:  targetProfilePhotoURL
                )
                isFollowing   = true
                followerCount += 1
                await InAppNotificationService.shared.sendFollow(
                    to:               profileUserID,
                    actorID:          viewerSettings.userID,
                    actorUsername:    viewerSettings.username,
                    actorDisplayName: viewerSettings.name
                )
            }
        } catch {
            print("[ProfileView] toggleFollow error: \(error)")
        }
    }

    private var subscribeButton: some View {
        Button {
            Task { await toggleSubscribe() }
        } label: {
            HStack(spacing: 8) {
                if subscribeLoading {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Image(systemName: isSubscribed ? "bell.fill" : "bell")
                        .font(.system(size: 14, weight: .bold))
                    Text(isSubscribed ? "Subscribed" : "Get Notified")
                        .font(.system(size: 15, weight: .black))
                }
            }
            .foregroundStyle(isSubscribed ? gold : .white.opacity(0.70))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSubscribed ? gold.opacity(0.15) : Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSubscribed ? gold.opacity(0.40) : Color.white.opacity(0.15), lineWidth: 1)
            )
            .cornerRadius(14)
        }
        .disabled(subscribeLoading)
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    private func toggleSubscribe() async {
        let viewer = currentUserSettings ?? ownUserSettings
        guard let viewerSettings = viewer, !viewerSettings.userID.isEmpty else { return }
        subscribeLoading = true
        defer { subscribeLoading = false }
        do {
            if isSubscribed {
                try await SubscriptionService.shared.unsubscribe(
                    subscriberID: viewerSettings.userID,
                    targetUserID: profileUserID
                )
                isSubscribed = false
            } else {
                try await SubscriptionService.shared.subscribe(
                    subscriberID:          viewerSettings.userID,
                    subscriberUsername:    viewerSettings.username,
                    subscriberDisplayName: viewerSettings.name,
                    targetUserID:          profileUserID
                )
                isSubscribed = true
            }
        } catch {
            print("[ProfileView] toggleSubscribe error: \(error)")
        }
    }
}
