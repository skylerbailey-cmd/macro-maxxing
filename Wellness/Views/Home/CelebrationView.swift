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
    @State private var showingShare    = false
    @State private var showingPostEditor = false
    @State private var postedToFeed    = false
    @State private var renderedImage:  UIImage?
    
    // Random meme selected for this celebration
    private let meme = GymMeme.random()

    var body: some View {
        ZStack {
            // Dimmed backdrop (tap outside card does nothing — use X button)
            Color.black.opacity(bgOpacity * 0.72)
                .ignoresSafeArea()

            // Confetti
            ConfettiView()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Card
            VStack(spacing: 12) {
                // Streak badge
                if userSettings.macroStreak > 0 {
                    HStack(spacing: 6) {
                        Text("🔥")
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(userSettings.macroStreak)-day streak")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(Color(red: 1.00, green: 0.60, blue: 0.15))
                            Text("goals met \(userSettings.macroStreak) day\(userSettings.macroStreak == 1 ? "" : "s") in a row")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(red: 1.00, green: 0.45, blue: 0.10).opacity(0.15))
                    .cornerRadius(12)
                }

                // Macro met indicators
                macroRow
                    .padding(.top, 4)

                // Buttons row
                VStack(spacing: 10) {
                    // Post to Feed
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
                            : Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.35))
                        .cornerRadius(14)
                    }
                    .disabled(postedToFeed)

                    // Share image
                    Button {
                        showingShare = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Share")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.10))
                        .cornerRadius(14)
                    }
                }
                .padding(.top, 4)
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
                    .shadow(color: Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.50), radius: 40)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.55), lineWidth: 1.5)
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
            Task { await renderShareCard() }
        }
        .sheet(isPresented: $showingShare) {
            if let img = renderedImage {
                CelebrationShareOptionsSheet(image: img)
                    .presentationDetents([.medium])
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
    }

    // MARK: - Macro row

    private var macroRow: some View {
        let items: [(String, Color)] = [
            ("Cal",  Color(red: 1.00, green: 0.55, blue: 0.15)),
            ("Pro",  Color(red: 0.35, green: 0.75, blue: 1.00)),
            ("Carb", Color(red: 0.40, green: 0.90, blue: 0.72)),
            ("Fat",  Color(red: 1.00, green: 0.50, blue: 0.72)),
        ]
        return HStack(spacing: 14) {
            ForEach(items.indices, id: \.self) { i in
                let met = i < macroGoalsMet.count ? macroGoalsMet[i] : false
                VStack(spacing: 4) {
                    Circle()
                        .fill(met ? items[i].1 : items[i].1.opacity(0.18))
                        .frame(width: 32, height: 32)
                        .overlay {
                            if met {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .shadow(color: met ? items[i].1.opacity(0.6) : .clear, radius: 6)
                    Text(items[i].0)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
        }
    }

    // MARK: - Render & dismiss

    @MainActor
    private func renderShareCard() async {
        let card = CelebrationShareCard(
            meme: meme,
            macroGoalsMet: macroGoalsMet,
            userName: userName,
            streak: userSettings.macroStreak
        )
        let renderer   = ImageRenderer(content: card)
        renderer.scale = 3.0
        renderedImage  = renderer.uiImage
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

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)

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
            AdManager.shared.showRewarded(onReward: { [weak userSettings] in
                userSettings?.awardAura(points: 50)
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
            isPublic:            !userSettings.isPrivateAccount
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
                    postID:               fbPostID
                )
            } catch {
                print("[CelebrationView] Firebase sync failed: \(error.localizedDescription)")
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

// MARK: - Share options sheet

private struct CelebrationShareOptionsSheet: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var showingActivitySheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.05, blue: 0.12).ignoresSafeArea()

                VStack(spacing: 12) {
                    shareButton(
                        title: "Instagram Stories",
                        subtitle: "Share directly to your story",
                        icon: "camera.fill",
                        colors: [Color(red: 0.88, green: 0.19, blue: 0.42),
                                 Color(red: 0.98, green: 0.35, blue: 0.00)]
                    ) { shareToInstagram() }

                    shareButton(
                        title: "Share / Save / More",
                        subtitle: "Messages, AirDrop, save to Photos…",
                        icon: "square.and.arrow.up",
                        colors: [Color(red: 0.65, green: 0.45, blue: 1.00),
                                 Color(red: 0.40, green: 0.20, blue: 0.85)]
                    ) { showingActivitySheet = true }
                }
                .padding(.horizontal, 20)
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingActivitySheet) {
            ActivitySheet(items: [image])
        }
    }

    private func shareButton(title: String, subtitle: String,
                             icon: String, colors: [Color],
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: colors,
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.45))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.30))
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color(red: 0.13, green: 0.10, blue: 0.22))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    private func shareToInstagram() {
        guard let data = image.pngData(),
              let url  = URL(string: "instagram-stories://share?source_application=com.sbailey.Wellness")
        else { showingActivitySheet = true; return }

        let items: [String: Any] = [
            "com.instagram.sharedSticker.backgroundImage": data,
            "com.instagram.sharedSticker.backgroundTopColor":    "#080215",
            "com.instagram.sharedSticker.backgroundBottomColor": "#030108"
        ]
        UIPasteboard.general.setItems(
            [items],
            options: [.expirationDate: Date(timeIntervalSinceNow: 300)]
        )
        UIApplication.shared.open(url) { success in
            if !success { showingActivitySheet = true }
        }
    }
}

// MARK: - Celebration share card (1080 × 1920 @ 3×)

private struct CelebrationShareCard: View {
    let meme:          GymMeme
    let macroGoalsMet: [Bool]
    let userName:      String
    var streak:        Int = 0

    private let purpl = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold  = Color(red: 1.00, green: 0.80, blue: 0.20)

    private let macroItems: [(String, Color)] = [
        ("Calories", Color(red: 1.00, green: 0.55, blue: 0.15)),
        ("Protein",  Color(red: 0.35, green: 0.75, blue: 1.00)),
        ("Carbs",    Color(red: 0.40, green: 0.90, blue: 0.72)),
        ("Fat",      Color(red: 1.00, green: 0.50, blue: 0.72)),
    ]

    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(RadialGradient(
                    colors: [Color(red: 0.18, green: 0.08, blue: 0.32),
                             Color(red: 0.04, green: 0.02, blue: 0.10)],
                    center: .init(x: 0.5, y: 0.35),
                    startRadius: 0, endRadius: 380
                ))

            // Sparkle dots
            ForEach(0..<8, id: \.self) { i in
                let pos: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                    (0.08,0.08,0.55,4),(0.88,0.12,0.40,3),(0.18,0.88,0.50,5),
                    (0.92,0.78,0.35,4),(0.50,0.04,0.65,3),(0.12,0.52,0.40,2),
                    (0.78,0.42,0.50,4),(0.40,0.94,0.40,3)
                ]
                Circle().fill(gold.opacity(pos[i].2))
                    .frame(width: pos[i].3, height: pos[i].3)
                    .position(x: pos[i].0 * 360, y: pos[i].1 * 640)
                    .blur(radius: 1)
            }

            VStack(spacing: 0) {
                // App branding
                HStack(spacing: 7) {
                    ZStack {
                        Circle().stroke(purpl, lineWidth: 2).frame(width: 26, height: 26)
                        Image(systemName: "fork.knife")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(purpl)
                    }
                    Text("Macro Maxxing")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.top, 44)

                Spacer()

                Spacer()

                // Macro circles
                HStack(spacing: 20) {
                    ForEach(macroItems.indices, id: \.self) { i in
                        let met = i < macroGoalsMet.count ? macroGoalsMet[i] : false
                        VStack(spacing: 6) {
                            Circle()
                                .fill(met ? macroItems[i].1 : macroItems[i].1.opacity(0.15))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    if met {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .shadow(color: met ? macroItems[i].1.opacity(0.6) : .clear, radius: 8)
                            Text(macroItems[i].0)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                }
                .padding(.bottom, 8)

                Text("all macros crushed 🔥")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(gold.opacity(0.80))

                if streak > 0 {
                    Text("🔥 \(streak)-day streak")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 1.00, green: 0.60, blue: 0.15))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color(red: 1.00, green: 0.45, blue: 0.10).opacity(0.20))
                        .cornerRadius(8)
                }

                Spacer()

                // Footer
                HStack {
                    Text("macro maxxing")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(purpl.opacity(0.65))
                    Spacer()
                    Text("log the mog.")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.22))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 32)
            }
        }
        .frame(width: 360, height: 640)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Confetti

private struct ConfettiView: View {
    private struct Piece {
        let xFraction: CGFloat
        let color:     Color
        let size:      CGFloat
        let speed:     Double
        let sway:      Double
        let swayFreq:  Double
        let delay:     Double
    }

    @State private var pieces:    [Piece] = []
    @State private var startTime: Date    = .now

    private static let palette: [Color] = [
        .orange,
        Color(red: 0.65, green: 0.45, blue: 1.00),
        Color(red: 0.35, green: 0.75, blue: 1.00),
        Color(red: 0.40, green: 0.90, blue: 0.72),
        Color(red: 1.00, green: 0.50, blue: 0.72),
        .yellow, .white,
        Color(red: 1.00, green: 0.75, blue: 0.20),
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let elapsed = timeline.date.timeIntervalSince(startTime)
                for p in pieces {
                    let t     = max(0, elapsed - p.delay)
                    let yFrac = t * p.speed
                    guard yFrac < 1.4 else { continue }
                    let x      = p.xFraction * size.width + sin(t * p.swayFreq * .pi) * p.sway
                    let y      = yFrac * size.height
                    let fadeIn = min(1.0, t / 0.2)
                    let fadeOut = yFrac > 0.75 ? max(0, 1 - (yFrac - 0.75) / 0.6) : 1.0
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x - p.size/2, y: y - p.size/2,
                                               width: p.size, height: p.size)),
                        with: .color(p.color.opacity(fadeIn * fadeOut * 0.88))
                    )
                }
            }
        }
        .onAppear {
            startTime = .now
            pieces = (0..<50).map { i in
                Piece(
                    xFraction: CGFloat.random(in: 0...1),
                    color:     Self.palette[i % Self.palette.count],
                    size:      CGFloat.random(in: 5...13),
                    speed:     Double.random(in: 0.22...0.50),
                    sway:      Double.random(in: 12...45),
                    swayFreq:  Double.random(in: 1.2...3.5),
                    delay:     Double.random(in: 0...1.8)
                )
            }
        }
    }
}
