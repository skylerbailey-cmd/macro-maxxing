//
//  CelebrationView.swift
//  Wellness
//

import SwiftUI
import SwiftData
import CoreLocation

// MARK: - GymMeme (internal so ShareCardView can also use it)

struct GymMeme {
    let imageName: String   // asset catalog image
    let emoji:     String   // shown in social posts
    let headline:  String
    let sub:       String

    static func random() -> GymMeme { all.randomElement()! }

    static let all: [GymMeme] = [
        GymMeme(imageName: "meme_looksmaxx",  emoji: "🗿",  headline: "LOOKSMAXX MODE\nACTIVATED",    sub: "your gains are immaculate fr"),
        GymMeme(imageName: "meme_gigachad",   emoji: "💪",  headline: "GIGACHAD ENERGY\nUNLOCKED",    sub: "NPC energy has officially left the chat"),
        GymMeme(imageName: "meme_sigma",      emoji: "⚡",  headline: "SIGMA GRINDSET\nCOMPLETE",      sub: "the mewing is literally paying off rn"),
        GymMeme(imageName: "meme_roman",      emoji: "🏛️", headline: "ROMAN EMPEROR\nPHYSIQUE",      sub: "built different. always have been."),
        GymMeme(imageName: "meme_finalform",  emoji: "🔱",  headline: "ALL MACROS?\nEZ CLAP.",         sub: "you are simply not the same as them"),
        GymMeme(imageName: "meme_goat",       emoji: "🐐",  headline: "GOAT STATUS\nCONFIRMED",       sub: "your jawline could cut through steel rn"),
        GymMeme(imageName: "meme_bro",        emoji: "💀",  headline: "BRO ATE\n(LITERALLY)",         sub: "no cap this is your villain arc and you're winning"),
        GymMeme(imageName: "meme_optimal",    emoji: "🧬",  headline: "OPTIMAL SPECIMEN\nUNLOCKED",   sub: "peak performance protocol: complete"),
        GymMeme(imageName: "meme_king",       emoji: "👑",  headline: "MACRO KING\nHAS LOGGED",       sub: "the iron never lies. neither do your macros."),
        GymMeme(imageName: "meme_silverback", emoji: "🦍",  headline: "SILVERBACK\nNUTRITION",        sub: "respect. every gram accounted for."),
    ]
}

// MARK: - CelebrationView

/// All macro data needed to create a social post from the celebration screen.
struct CelebrationPostData: Equatable {
    let totalCalories: Double; let goalCalories: Double
    let totalProtein:  Double; let goalProtein:  Double
    let totalCarbs:    Double; let goalCarbs:    Double
    let totalFat:      Double; let goalFat:      Double
    let date: Date
    /// Formatted fasting window string, e.g. "9:00 AM – 5:00 PM · 8h window". Empty if disabled.
    let fastingWindowDisplay: String
}

struct CelebrationView: View {
    let macroGoalsMet: [Bool]
    let userName:      String
    let userSettings:  UserSettings
    let postData:      CelebrationPostData
    let onDismiss:     () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var cardScale:      CGFloat = 0.2
    @State private var cardOpacity:    Double  = 0
    @State private var bgOpacity:      Double  = 0
    @State private var streakScale:    CGFloat = 0.5
    @State private var showingPostEditor = false
    @State private var postedToFeed    = false

    private let meme = GymMeme.random()

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(bgOpacity * 0.72)
                .ignoresSafeArea()

            // Fire rising from bottom
            FireAnimationView()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Streak badge card
            VStack(spacing: 20) {
                // Fire emoji + streak count
                Text("🔥")
                    .font(.system(size: 64))
                    .scaleEffect(streakScale)

                VStack(spacing: 6) {
                    Text("\(userSettings.macroStreak)")
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.00, green: 0.80, blue: 0.20),
                                         Color(red: 1.00, green: 0.45, blue: 0.10)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    Text("DAY STREAK")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.70))
                }

                Text("goals met \(userSettings.macroStreak) day\(userSettings.macroStreak == 1 ? "" : "s") in a row")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))

                // Buttons
                VStack(spacing: 10) {
                    Button {
                        showingPostEditor = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: postedToFeed ? "checkmark.circle.fill" : "person.2.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text(postedToFeed ? "Posted!" : "Post for Points")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(postedToFeed
                            ? Color.green.opacity(0.30)
                            : ThemeStore.shared.accent.opacity(0.35))
                        .cornerRadius(14)
                    }
                    .disabled(postedToFeed)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.18, green: 0.08, blue: 0.36),
                                     Color(red: 0.08, green: 0.04, blue: 0.16)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.orange.opacity(0.40), radius: 40)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color(red: 1.00, green: 0.45, blue: 0.10).opacity(0.55), lineWidth: 1.5)
            )
            // X dismiss button
            .overlay(alignment: .topTrailing) {
                Button(action: animatedDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(14)
                }
            }
            .padding(.horizontal, 24)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.18)) { bgOpacity = 1 }
            withAnimation(.spring(duration: 0.55, bounce: 0.45).delay(0.06)) {
                cardScale   = 1.0
                cardOpacity = 1.0
            }
            withAnimation(.spring(duration: 0.7, bounce: 0.5).delay(0.2)) {
                streakScale = 1.0
            }
        }
        .sheet(isPresented: $showingPostEditor) {
            CelebrationPostEditorSheet(
                meme:         meme,
                postData:     postData,
                userSettings: userSettings
            ) {
                withAnimation { postedToFeed = true }
            }
        }
        .keyboardDoneToolbar()
    }

    private func animatedDismiss() {
        withAnimation(.easeIn(duration: 0.18)) {
            cardScale   = 0.85
            cardOpacity = 0
            bgOpacity   = 0
        }
        Task {
            try? await Task.sleep(for: .seconds(0.2))
            onDismiss()
        }
    }
}

// MARK: - Celebration post editor sheet

struct CelebrationPostEditorSheet: View {
    let meme:         GymMeme
    let postData:     CelebrationPostData
    let userSettings: UserSettings
    let onPosted:     () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @Environment(LocationManager.self) private var locationManager

    @State private var titleText:   String      = ""
    @State private var messageText: String      = ""
    @State private var photos:      [PostPhoto] = []
    @FocusState private var focus: Field?

    private enum Field: Hashable { case title, message }

    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var purpl: Color { ThemeStore.shared.accent }
    private var gold: Color { ThemeStore.shared.accent }

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Discipline summary card
                        disciplineCard

                        // Status / title field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Status")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.50))
                            TextField("", text: $titleText, prompt:
                                Text("e.g. \"macros crushed. no cap. 🔥\"")
                                    .foregroundStyle(.white.opacity(0.28))
                            )
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(cardBg)
                            .cornerRadius(12)
                            .focused($focus, equals: .title)
                            .submitLabel(.next)
                            .onSubmit { focus = .message }
                            .onChange(of: titleText) { _, v in
                                if v.count > 80 { titleText = String(v.prefix(80)) }
                            }
                            HStack {
                                Spacer()
                                Text("\(titleText.count)/80")
                                    .font(.system(size: 11))
                                    .foregroundStyle(titleText.count >= 80 ? .red : titleText.count >= 64 ? Color.orange : .white.opacity(0.25))
                            }
                        }

                        // Message / body field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Message (optional)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.50))
                            ZStack(alignment: .topLeading) {
                                if messageText.isEmpty {
                                    Text("tell the feed how you locked in today fr.")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.28))
                                        .padding(14)
                                }
                                TextEditor(text: $messageText)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 100)
                                    .padding(10)
                                    .focused($focus, equals: .message)
                                    .onChange(of: messageText) { _, v in
                                        if v.count > 300 { messageText = String(v.prefix(300)) }
                                    }
                            }
                            .background(cardBg)
                            .cornerRadius(12)
                            HStack {
                                Spacer()
                                Text("\(messageText.count)/300")
                                    .font(.system(size: 11))
                                    .foregroundStyle(messageText.count >= 300 ? .red : messageText.count >= 240 ? Color.orange : .white.opacity(0.25))
                            }
                        }

                        // Photos
                        MultiPhotoSection(photos: $photos)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Post for Points")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        let t = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
                        submit(title: t.isEmpty ? "goals locked in 🎯" : t)
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(gold)
                }
            }
        }
    }

    // MARK: - Discipline Card

    private var disciplineProgress: Double {
        let pairs: [(Double, Double)] = [
            (postData.totalCalories, postData.goalCalories),
            (postData.totalProtein,  postData.goalProtein),
            (postData.totalCarbs,    postData.goalCarbs),
            (postData.totalFat,      postData.goalFat),
        ]
        let active = pairs.filter { $0.1 > 0 }
        guard !active.isEmpty else { return 0 }
        return active.reduce(0.0) { $0 + min($1.0 / $1.1, 1.0) } / Double(active.count)
    }

    private var disciplineCard: some View {
        let neon = Color(red: 0.35, green: 1.00, blue: 0.60)
        let pct  = Int(disciplineProgress * 100)

        return VStack(spacing: 10) {
            // Overall discipline bar
            HStack(spacing: 0) {
                Text("DISCIPLINE")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.40))
                Spacer()
                HStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08))
                                .frame(height: 5)
                            Capsule()
                                .fill(LinearGradient(
                                    colors: disciplineProgress >= 1.0
                                        ? [neon, Color(red: 0.20, green: 0.85, blue: 0.50)]
                                        : [purpl, Color(red: 0.35, green: 0.75, blue: 1.00)],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(width: max(4, geo.size.width * disciplineProgress), height: 5)
                        }
                    }
                    .frame(width: 80, height: 5)
                    Text("\(pct)%")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(disciplineProgress >= 1.0 ? neon : purpl)
                        .frame(width: 38, alignment: .trailing)
                }
            }

            Divider().background(purpl.opacity(0.15))

            // Per-macro rows
            let macros: [(String, Double, Double, String, Color)] = [
                ("Calories", postData.totalCalories, postData.goalCalories, "kcal",
                 Color.orange),
                ("Protein",  postData.totalProtein,  postData.goalProtein,  "g",
                 Color(red: 0.35, green: 0.75, blue: 1.00)),
                ("Carbs",    postData.totalCarbs,     postData.goalCarbs,    "g",
                 Color(red: 0.35, green: 1.00, blue: 0.80)),
                ("Fat",      postData.totalFat,       postData.goalFat,      "g",
                 Color(red: 1.00, green: 0.45, blue: 0.55)),
            ]
            ForEach(Array(macros.enumerated()), id: \.offset) { _, macro in
                let (label, total, goal, unit, color) = macro
                let ratio = goal > 0 ? min(total / goal, 1.0) : 0
                let macPct = goal > 0 ? Int((total / goal) * 100) : 0
                HStack(spacing: 8) {
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.70))
                        .frame(width: 60, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.07))
                                .frame(height: 6)
                            Capsule()
                                .fill(color.opacity(0.85))
                                .frame(width: max(4, geo.size.width * ratio), height: 6)
                        }
                    }
                    .frame(height: 6)
                    Text("\(macPct)%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                        .frame(width: 38, alignment: .trailing)
                    Text("\(Int(total)) / \(Int(goal)) \(unit)")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.28))
                        .frame(width: 80, alignment: .trailing)
                }
            }
        }
        .padding(14)
        .background(cardBg)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(purpl.opacity(0.20), lineWidth: 1)
        )
    }

    private func submit(title: String) {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let fbPostID = UUID().uuidString   // shared ID for SwiftData ↔ Firestore link
        let post = SocialPost(
            authorID:          userSettings.userID,
            authorUsername:    userSettings.username.isEmpty ? "me" : userSettings.username,
            authorDisplayName: userSettings.name,
            memeEmoji:         "",
            memeHeadline:      title,
            memeSub:           message,
            macroDate:         postData.date,
            totalCalories:     postData.totalCalories, goalCalories: postData.goalCalories,
            totalProtein:      postData.totalProtein,  goalProtein:  postData.goalProtein,
            totalCarbs:        postData.totalCarbs,    goalCarbs:    postData.goalCarbs,
            totalFat:          postData.totalFat,      goalFat:      postData.goalFat
        )
        post.authorAuraLevel        = userSettings.auraLevel
        post.authorAuraPoints       = userSettings.auraPoints
        post.authorAuraTitle        = userSettings.auraTitle
        post.authorLocation         = userSettings.postLocation(gpsCity: locationManager.city)
        post.authorLatitude         = locationManager.coordinate?.latitude  ?? 0
        post.authorLongitude        = locationManager.coordinate?.longitude ?? 0
        post.authorStreak           = userSettings.macroStreak
        post.isAuthorPrivate        = userSettings.isPrivateAccount
        post.authorProfileImageData = userSettings.profileImageData
        post.fastingWindowDisplay   = postData.fastingWindowDisplay
        post.postLabel              = PostLabel.goalPost.rawValue
        let datas = photos.map { $0.image.jpegData(compressionQuality: 0.8) }
        post.imageData  = datas.count > 0 ? datas[0] : nil
        post.imageData2 = datas.count > 1 ? datas[1] : nil
        post.imageData3 = datas.count > 2 ? datas[2] : nil
        post.imageData4     = datas.count > 3 ? datas[3] : nil
        post.firebasePostID = fbPostID
        modelContext.insert(post)
        if RemoteConfigService.shared.auraRewardAdRequired {
            let settings = userSettings
            AdManager.shared.showRewarded(onReward: {
                Task { @MainActor in settings.awardAura(points: 50) }
            })
        } else {
            userSettings.awardAura(points: 50)
        }

        // Mirror to Firebase in the background
        let images       = photos.map { $0.image }
        let locationName = userSettings.postLocation(gpsCity: locationManager.city)
        let latitude     = locationManager.coordinate?.latitude  ?? 0
        let longitude    = locationManager.coordinate?.longitude ?? 0
        let caption      = message
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
                    photos:               images,
                    author:               author,
                    title:                title,
                    caption:              caption,
                    locationName:         locationName,
                    latitude:             latitude,
                    longitude:            longitude,
                    fastingWindowDisplay: postData.fastingWindowDisplay,
                    postLabel:            PostLabel.goalPost.rawValue,
                    calories:             Int(postData.totalCalories),
                    protein:              postData.totalProtein,
                    carbs:                postData.totalCarbs,
                    fat:                  postData.totalFat,
                    goalCalories:         Int(postData.goalCalories),
                    goalProtein:          postData.goalProtein,
                    goalCarbs:            postData.goalCarbs,
                    goalFat:              postData.goalFat,
                    currentWeight:        userSettings.showWeightOnPosts ? userSettings.currentWeight : 0,
                    goalWeight:           userSettings.showWeightOnPosts ? userSettings.goalWeight    : 0,
                    postID:               fbPostID
                )
            } catch {
                AppLogger.log("[CelebrationView] Firebase sync failed: \(error.localizedDescription)")
            }
            await InAppNotificationService.shared.notifySubscribers(
                ofUserID:          userSettings.userID,
                posterUsername:    userSettings.username,
                posterDisplayName: userSettings.name,
                postID:            fbPostID,
                postTitle:         title,
                posterPhotoURL:    userSettings.profilePhotoURL
            )
        }

        onPosted()
        dismiss()
    }
}


// MARK: - Fire Overlay (self-contained trigger → show → auto-dismiss)
//
// A standalone view that watches a trigger counter. Each time `trigger`
// increments it shows the fire for 5 seconds then hides. Because it manages
// its own @State internally, it re-renders independently of the parent's
// view-builder chain — solving the issue where let-captured views don't
// re-evaluate on state changes.

struct FireOverlayView: View {
    let trigger: Int

    @State private var isVisible = false
    @State private var lastHandledTrigger = 0

    var body: some View {
        ZStack {
            if isVisible {
                FireAnimationView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isVisible)
        .onChange(of: trigger) { _, newValue in
            guard newValue != lastHandledTrigger, newValue > 0 else { return }
            lastHandledTrigger = newValue
            isVisible = true
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                isVisible = false
            }
        }
    }
}

// MARK: - Fire Animation
//
// Realistic multi-layered fire. On appear the flames burst upward from the
// center, then settle into an organic, chaotic flicker. Each flame tongue
// has its own random seed so they never move in sync.

struct FireAnimationView: View {

    @State private var startTime: Date = .now
    @State private var tongues: [FlameTongue] = []
    @State private var sparks:  [Spark]       = []
    @State private var embers:  [Ember]       = []

    // MARK: - Data

    /// Each tongue carries its own random seeds so no two move alike.
    private struct FlameTongue {
        let xFrac: Double
        let widthFrac: Double
        let maxHeightFrac: Double
        let s1: Double; let s2: Double; let s3: Double
        let s4: Double; let s5: Double
        let layer: Int
    }

    /// Bright white/yellow sparks that shoot up quickly and fade.
    private struct Spark: Identifiable {
        let id = UUID()
        let x: CGFloat
        let speed: Double
        let size: CGFloat
        let delay: Double
        let sway: Double
        let swayFreq: Double
        let brightness: Double
    }

    /// Glowing orange/red ember chunks that drift upward slowly, tumble, and cool down.
    private struct Ember: Identifiable {
        let id = UUID()
        let x: CGFloat          // 0-1 start position
        let speed: Double       // slower than sparks
        let size: CGFloat       // bigger than sparks
        let delay: Double
        let sway: Double
        let swayFreq: Double
        let rotSpeed: Double    // tumble rotation speed
        let colorIndex: Int     // 0 = orange, 1 = red-orange, 2 = dark red
    }

    // Palette
    private static let white      = Color(red: 1.00, green: 0.97, blue: 0.85)
    private static let yellow     = Color(red: 1.00, green: 0.85, blue: 0.12)
    private static let orange     = Color(red: 1.00, green: 0.52, blue: 0.05)
    private static let deepOrange = Color(red: 1.00, green: 0.28, blue: 0.04)
    private static let red        = Color(red: 0.88, green: 0.14, blue: 0.03)
    private static let darkRed    = Color(red: 0.50, green: 0.07, blue: 0.02)

    private static func layerColors(_ layer: Int) -> (base: Color, tip: Color) {
        switch layer {
        case 0: return (darkRed,    .clear)
        case 1: return (red,        darkRed.opacity(0))
        case 2: return (deepOrange, red.opacity(0))
        case 3: return (orange,     deepOrange.opacity(0))
        default: return (yellow,    orange.opacity(0))
        }
    }

    private static func layerOpacity(_ layer: Int) -> Double {
        [0.55, 0.65, 0.70, 0.75, 0.65][min(layer, 4)]
    }

    // Screen dimensions used as a guaranteed fallback so the fire always
    // renders at full size even if the SwiftUI layout offers something smaller.
    private static let screenW = UIScreen.main.bounds.width
    private static let screenH = UIScreen.main.bounds.height

    var body: some View {
        GeometryReader { geo in
            fireCanvas(geoSize: geo.size)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { generateFlames() }
    }

    private func fireCanvas(geoSize: CGSize) -> some View {
        // Use the largest available size — GeometryReader, screen, or Canvas.
        let useW = max(geoSize.width,  Self.screenW)
        let useH = max(geoSize.height, Self.screenH)

        return TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSince(startTime)
                let w = max(size.width,  useW)
                let h = max(size.height, useH)
                guard w > 0, h > 0 else { return }
                let fireZone = h * 0.82

                // Initial burst: fire shoots up fast from center in first 0.6s
                // then settles to full spread by ~1.2s
                let burstT = min(t / 1.2, 1.0)
                let burstEase = burstT * burstT * (3.0 - 2.0 * burstT) // smoothstep
                // During burst, flames concentrate toward center
                let spreadFactor = 0.15 + 0.85 * burstEase
                // During burst, height ramps up fast then overshoots slightly
                let burstHeight: Double
                if t < 0.5 {
                    burstHeight = min(1.3, t / 0.5 * 1.3) // shoot up to 130%
                } else if t < 1.0 {
                    burstHeight = 1.3 - 0.3 * ((t - 0.5) / 0.5) // settle to 100%
                } else {
                    burstHeight = 1.0
                }

                // Sort tongues by layer so back layers draw first
                let sorted = tongues.sorted { $0.layer < $1.layer }

                for tongue in sorted {
                    // Pseudo-random noise from layered sines at incommensurate frequencies
                    let n1 = sin(t * 2.3  * tongue.s1 + tongue.s2 * 10.0)
                    let n2 = sin(t * 3.7  * tongue.s2 + tongue.s3 * 7.0)
                    let n3 = sin(t * 5.1  * tongue.s3 + tongue.s1 * 4.0)
                    let n4 = sin(t * 1.9  * tongue.s4 + tongue.s5 * 13.0)
                    let n5 = sin(t * 7.3  * tongue.s5 + tongue.s4 * 3.0)

                    // Height flicker: combine multiple noise channels
                    let flickerRaw = n1 * 0.3 + n2 * 0.25 + n3 * 0.2 + n4 * 0.15 + n5 * 0.1
                    let flicker = 0.60 + 0.40 * flickerRaw // range ~0.2 to 1.0
                    let tongueH = fireZone * tongue.maxHeightFrac * flicker * burstHeight

                    // Horizontal sway: also multi-frequency noise
                    let swayRaw = n2 * 0.4 + n3 * 0.3 + n5 * 0.3
                    let maxSway = tongue.widthFrac * w * 0.35
                    let sway = swayRaw * maxSway

                    // During burst, pull x toward center
                    let centerX = w * 0.5
                    let naturalX = CGFloat(tongue.xFrac) * w
                    let cx = naturalX + (centerX - naturalX) * CGFloat(1.0 - spreadFactor) + CGFloat(sway)

                    let tongueW = CGFloat(tongue.widthFrac) * w
                    let cy = h - tongueH / 2

                    // Draw the tongue as a pointed path (not an ellipse) for more flame-like shape
                    let colors = Self.layerColors(tongue.layer)
                    let alpha  = Self.layerOpacity(tongue.layer)

                    let tipY = cy - tongueH / 2
                    let halfW = tongueW / 2

                    // Build left and right edge points with noise-driven bulges.
                    // More segments = more organic, wavy edges.
                    let segments = 6
                    var leftPts:  [CGPoint] = []
                    var rightPts: [CGPoint] = []

                    for seg in 0...segments {
                        let frac = Double(seg) / Double(segments) // 0 = base, 1 = tip

                        // Taper: wide at base, narrow at tip
                        let taper = CGFloat(1.0 - pow(frac, 1.4))

                        // Per-segment noise from combining seeds at different phases
                        let segSeed = Double(seg) * 1.7
                        let noiseL = sin(t * 2.8 * tongue.s1 + segSeed + tongue.s3 * 5.0) * 0.4
                                   + sin(t * 4.3 * tongue.s4 + segSeed * 2.3) * 0.3
                                   + sin(t * 6.1 * tongue.s2 + segSeed * 0.7) * 0.2
                        let noiseR = sin(t * 3.1 * tongue.s2 + segSeed + tongue.s5 * 6.0) * 0.4
                                   + sin(t * 4.9 * tongue.s5 + segSeed * 1.9) * 0.3
                                   + sin(t * 5.7 * tongue.s3 + segSeed * 1.1) * 0.2

                        // Bulge amount scales with taper (bigger bulges in the middle of the flame)
                        let bulgeScale = halfW * 0.35 * taper
                        let y = h - CGFloat(frac) * tongueH

                        leftPts.append(CGPoint(
                            x: cx - halfW * taper + CGFloat(noiseL) * bulgeScale,
                            y: y
                        ))
                        rightPts.append(CGPoint(
                            x: cx + halfW * taper + CGFloat(noiseR) * bulgeScale,
                            y: y
                        ))
                    }

                    // The tip point — slightly offset by noise so it dances
                    let tipX = cx + CGFloat(n3 * 3 + n5 * 2)

                    // Build path: up the left side, across the tip, down the right side
                    var path = Path()
                    path.move(to: CGPoint(x: cx - halfW, y: h)) // base left

                    // Left edge: use quadratic curves between consecutive points
                    for i in 1..<leftPts.count {
                        let prev = leftPts[i - 1]
                        let curr = leftPts[i]
                        let cpX = (prev.x + curr.x) / 2 + CGFloat(sin(t * 3.0 * tongue.s4 + Double(i) * 2.1)) * halfW * 0.12
                        let cpY = (prev.y + curr.y) / 2
                        path.addQuadCurve(to: curr, control: CGPoint(x: cpX, y: cpY))
                    }

                    // Rounded tip
                    path.addQuadCurve(
                        to: rightPts.last ?? CGPoint(x: tipX, y: tipY),
                        control: CGPoint(x: tipX, y: tipY - tongueH * 0.04)
                    )

                    // Right edge: back down (reversed)
                    for i in stride(from: rightPts.count - 2, through: 0, by: -1) {
                        let prev = rightPts[i + 1]
                        let curr = rightPts[i]
                        let cpX = (prev.x + curr.x) / 2 + CGFloat(sin(t * 2.7 * tongue.s5 + Double(i) * 1.8)) * halfW * 0.12
                        let cpY = (prev.y + curr.y) / 2
                        path.addQuadCurve(to: curr, control: CGPoint(x: cpX, y: cpY))
                    }

                    path.closeSubpath()

                    ctx.fill(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [colors.tip, colors.base.opacity(alpha)]),
                            startPoint: CGPoint(x: cx, y: tipY),
                            endPoint:   CGPoint(x: cx, y: h)
                        )
                    )
                }

                // White-hot base glow
                let baseH = h * 0.06
                ctx.fill(
                    Path(CGRect(x: 0, y: h - baseH, width: w, height: baseH)),
                    with: .linearGradient(
                        Gradient(colors: [Self.white.opacity(0.85 * min(1, t / 0.3)),
                                          Self.yellow.opacity(0.5 * min(1, t / 0.3)),
                                          .clear]),
                        startPoint: CGPoint(x: w / 2, y: h),
                        endPoint:   CGPoint(x: w / 2, y: h - baseH)
                    )
                )

                // ── Embers: glowing chunks that drift up slowly and tumble ──
                let emberColors: [Color] = [Self.orange, Self.deepOrange, Self.red]
                for ember in embers {
                    let et = max(0, t - ember.delay)
                    let rise = et * ember.speed
                    guard rise < 1.5 else { continue }

                    let ex = ember.x * w + CGFloat(sin(et * ember.swayFreq * .pi) * ember.sway)
                    let ey = h - CGFloat(rise) * fireZone * 0.95

                    let fadeIn  = min(1.0, et / 0.3)
                    // Embers glow bright at first, then cool down and fade
                    let cooldown = max(0, 1.0 - rise * 0.7)
                    let fadeOut  = rise > 0.8 ? max(0, 1.0 - (rise - 0.8) / 0.5) : 1.0
                    let alpha    = fadeIn * fadeOut * cooldown * 0.9

                    let s = ember.size * CGFloat(max(0.3, 1.0 - rise * 0.5))
                    let rotation = et * ember.rotSpeed

                    // Draw a small rotated rectangle (chunk shape)
                    var transform = CGAffineTransform.identity
                    transform = transform.translatedBy(x: ex, y: ey)
                    transform = transform.rotated(by: CGFloat(rotation))
                    let rect = CGRect(x: -s / 2, y: -s / 3, width: s, height: s * 0.65)
                    var path = Path(roundedRect: rect, cornerRadius: s * 0.15)
                    path = path.applying(transform)

                    let color = emberColors[ember.colorIndex % emberColors.count]

                    // Outer glow
                    let glowRect = CGRect(x: -s, y: -s * 0.7, width: s * 2, height: s * 1.4)
                    var glowPath = Path(ellipseIn: glowRect)
                    glowPath = glowPath.applying(transform)
                    ctx.fill(glowPath, with: .color(color.opacity(alpha * 0.25)))

                    // Core
                    ctx.fill(path, with: .color(color.opacity(alpha)))

                    // Hot center highlight
                    if cooldown > 0.5 {
                        let dotSize = s * 0.35
                        let dotRect = CGRect(x: -dotSize / 2, y: -dotSize / 2, width: dotSize, height: dotSize)
                        var dotPath = Path(ellipseIn: dotRect)
                        dotPath = dotPath.applying(transform)
                        ctx.fill(dotPath, with: .color(Self.yellow.opacity(alpha * (cooldown - 0.5) * 1.5)))
                    }
                }

                // ── Sparks: bright hot points that shoot up fast ──
                for spark in sparks {
                    let st = max(0, t - spark.delay)
                    let rise = st * spark.speed
                    guard rise < 1.4 else { continue }

                    let sx = spark.x * w + CGFloat(sin(st * spark.swayFreq * .pi) * spark.sway)
                    let sy = h - CGFloat(rise) * fireZone * 1.15

                    let fadeIn  = min(1.0, st / 0.1)
                    let fadeOut = rise > 0.4 ? max(0, 1.0 - (rise - 0.4) / 0.6) : 1.0
                    let alpha = fadeIn * fadeOut * spark.brightness * 0.9

                    let s = spark.size * CGFloat(max(0.05, 1.0 - rise * 0.9))

                    // Outer glow
                    let glowS = s * 3.0
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: sx - glowS/2, y: sy - glowS/2, width: glowS, height: glowS)),
                        with: .color(Self.orange.opacity(alpha * 0.2))
                    )

                    // Bright core
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: sx - s/2, y: sy - s/2, width: s, height: s * 1.4)),
                        with: .color(Self.white.opacity(alpha * 0.9))
                    )
                    // Yellow ring
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: sx - s, y: sy - s * 0.7, width: s * 2, height: s * 1.8)),
                        with: .color(Self.yellow.opacity(alpha * 0.35))
                    )
                }
            }
        }
        .frame(width: useW, height: useH)
    }

    // MARK: - Generate

    private func generateFlames() {
        startTime = .now

        // Build tongues across 5 layers with randomized properties
        var allTongues: [FlameTongue] = []
        let layerConfigs: [(count: Int, widthRange: ClosedRange<Double>, heightRange: ClosedRange<Double>)] = [
            (6,  0.35...0.60, 0.80...1.00),  // layer 0: wide, tall background — tallest reach 3/4+
            (8,  0.22...0.40, 0.65...0.92),  // layer 1: red outer
            (10, 0.14...0.28, 0.50...0.80),  // layer 2: deep orange
            (10, 0.10...0.20, 0.35...0.65),  // layer 3: bright orange
            (7,  0.08...0.16, 0.22...0.45),  // layer 4: yellow core
        ]
        for (layer, config) in layerConfigs.enumerated() {
            for _ in 0..<config.count {
                allTongues.append(FlameTongue(
                    xFrac:         Double.random(in: -0.05...1.05),
                    widthFrac:     Double.random(in: config.widthRange),
                    maxHeightFrac: Double.random(in: config.heightRange),
                    s1: Double.random(in: 0.5...2.0),
                    s2: Double.random(in: 0.5...2.0),
                    s3: Double.random(in: 0.5...2.0),
                    s4: Double.random(in: 0.5...2.0),
                    s5: Double.random(in: 0.5...2.0),
                    layer: layer
                ))
            }
        }
        tongues = allTongues

        // Bright white-hot sparks that shoot up fast
        sparks = (0..<70).map { _ in
            Spark(
                x:          CGFloat.random(in: 0.05...0.95),
                speed:      Double.random(in: 0.15...0.45),
                size:       CGFloat.random(in: 2...8),
                delay:      Double.random(in: 0.0...4.0),
                sway:       Double.random(in: 8...30),
                swayFreq:   Double.random(in: 1.5...5.0),
                brightness: Double.random(in: 0.6...1.0)
            )
        }

        // Glowing ember chunks that drift up slowly and tumble
        embers = (0..<40).map { _ in
            Ember(
                x:          CGFloat.random(in: 0.05...0.95),
                speed:      Double.random(in: 0.06...0.18),
                size:       CGFloat.random(in: 5...16),
                delay:      Double.random(in: 0.2...3.5),
                sway:       Double.random(in: 10...35),
                swayFreq:   Double.random(in: 0.8...2.5),
                rotSpeed:   Double.random(in: 1.5...6.0) * (Bool.random() ? 1 : -1),
                colorIndex: Int.random(in: 0...2)
            )
        }
    }
}
