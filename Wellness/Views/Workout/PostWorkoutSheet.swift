//
//  PostWorkoutSheet.swift
//  Wellness
//

import SwiftUI
import SwiftData
internal import _LocationEssentials

struct PostWorkoutSheet: View {

    let userSettings:    UserSettings
    let workoutName:     String
    let workoutType:     WorkoutType
    let durationMinutes: Int
    let caloriesBurned:  Int
    /// Optional gym tagged at log time. Surfaces in the post's workout
    /// item (visible in feed rows) and in the preview card here.
    var gym:             WorkoutLocation? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @Environment(LocationManager.self) private var locationManager

    @State private var captionText    = ""
    @State private var photo: UIImage? = nil
    @State private var showingCamera  = false
    @State private var showingLibrary = false
    @State private var isPosting      = false

    // MARK: - Colors

    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var accent: Color { ThemeStore.shared.accent }

    private var workoutHeadline: String { workoutName }
    private var workoutStats: String { "\(durationMinutes) min · \(caloriesBurned) kcal · \(workoutType.rawValue)" }

    /// Aura points the user will earn for sharing this workout (once per day).
    private static let workoutPostAuraReward = 25
    private var auraRewardAvailable: Bool { !userSettings.hasEarnedWorkoutPostAuraToday }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        promptHeader
                        auraRewardBanner
                        previewCard
                        photoSection
                        captionSection
                        HStack(spacing: 14) {
                            skipButton
                            postButton
                        }
                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Share Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePickerView(sourceType: .camera, selectedImage: $photo)
        }
        .sheet(isPresented: $showingLibrary) {
            ImagePickerView(sourceType: .photoLibrary, selectedImage: $photo)
        }
        .keyboardDoneToolbar()
    }

    // MARK: - Prompt Header

    private var promptHeader: some View {
        VStack(spacing: 6) {
            Text("Want to share your workout? 🔥")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Let the feed know you put in work.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Aura Reward Banner

    /// Gold palette for the aura reward — fixed hue (not the user's accent) so
    /// the "+25 Aura" badge always reads as a reward regardless of theme.
    private static let auraGold      = Color(red: 1.00, green: 0.82, blue: 0.25)
    private static let auraGoldDeep  = Color(red: 0.95, green: 0.65, blue: 0.10)

    private var auraRewardBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Self.auraGold)

            VStack(alignment: .leading, spacing: 2) {
                if auraRewardAvailable {
                    shimmeringText("Earn +\(Self.workoutPostAuraReward) Aura",
                                   font: .system(size: 14, weight: .black, design: .rounded))
                    Text("Post this workout to claim your points.")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.55))
                } else {
                    Text("Aura Claimed Today")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Workout-post Aura resets tomorrow.")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }

            Spacer(minLength: 8)

            if auraRewardAvailable {
                shimmeringText("+\(Self.workoutPostAuraReward)",
                               font: .system(size: 15, weight: .black, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Self.auraGold.opacity(0.15), in: Capsule())
                    .overlay(Capsule().stroke(Self.auraGold.opacity(0.55), lineWidth: 0.75))
            } else {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Self.auraGold.opacity(0.6))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Self.auraGold.opacity(0.40), lineWidth: 1))
    }

    /// Text with a diagonal shimmer highlight that sweeps left→right, producing
    /// a subtle gold gleam. The base color is gold; the highlight is a near-white
    /// gold-white that slides across the glyphs on a repeat loop.
    @ViewBuilder
    private func shimmeringText(_ string: String, font: Font) -> some View {
        Text(string)
            .font(font)
            .foregroundStyle(Self.auraGold)
            .modifier(AuraShimmerModifier(color: Self.auraGold))
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PREVIEW")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.white.opacity(0.25))
                Spacer()
                // Workout badge (top-right, matching PostCard overlay)
                HStack(spacing: 4) {
                    Image(systemName: PostLabel.workout.icon)
                        .font(.system(size: 9, weight: .bold))
                    Text(PostLabel.workout.rawValue)
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(accent.opacity(0.15), in: Capsule())
                .overlay(Capsule().stroke(accent.opacity(0.35), lineWidth: 0.75))
            }

            Text(workoutHeadline)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                statBadge(icon: "timer",             value: "\(durationMinutes) min",      color: ThemeStore.shared.accent)
                statBadge(icon: "flame.fill",         value: "\(caloriesBurned) kcal",      color: Color(red: 1.00, green: 0.55, blue: 0.15))
                statBadge(icon: workoutType.icon,     value: workoutType.shortLabel,        color: accent)
            }

            if let gym, gym.isValid {
                HStack(spacing: 5) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(accent)
                    Text(gym.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.80))
                        .lineLimit(1)
                }
            }

            if let img = photo {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipped()
                    .cornerRadius(10)
            }

            let trimmed = captionText.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                Text(trimmed)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(3)
            }
        }
        .padding(14)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    private func statBadge(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10))
            Text(value).font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add a Photo (optional)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))

            if let img = photo {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .clipped()
                        .cornerRadius(12)
                    Button { photo = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                            .shadow(radius: 3)
                    }
                    .padding(6)
                }
            } else {
                HStack(spacing: 12) {
                    photoPickerButton(icon: "camera.fill",  label: "Camera") { showingCamera  = true }
                    photoPickerButton(icon: "photo.fill",   label: "Photos") { showingLibrary = true }
                }
            }
        }
    }

    private func photoPickerButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 14))
                Text(label).font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white.opacity(0.75))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Caption

    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Caption (optional)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
            TextField("Tell the feed about your workout…", text: $captionText, axis: .vertical)
                .lineLimit(3...5)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .padding(12)
                .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.20), lineWidth: 1))
        }
    }

    // MARK: - Buttons

    private var skipButton: some View {
        Button { dismiss() } label: {
            Text("Skip")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.65))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var postButton: some View {
        Button { Task { await submitPost() } } label: {
            HStack(spacing: 8) {
                if isPosting { ProgressView().tint(.black) }
                else { Image(systemName: "paperplane.fill") }
                Text(isPosting ? "Posting…" : "Post")
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(accent, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(isPosting)
    }

    // MARK: - Submit

    @MainActor
    private func submitPost() async {
        isPosting = true

        let fbPostID  = UUID().uuidString
        let caption   = captionText.trimmingCharacters(in: .whitespaces)
        let locName   = userSettings.postLocation(gpsCity: locationManager.city)
        let lat       = locationManager.coordinate?.latitude  ?? 0
        let lon       = locationManager.coordinate?.longitude ?? 0
        let workoutItem = FeedWorkoutItem(
            workoutName:     workoutName,
            workoutType:     workoutType.rawValue,
            durationMinutes: durationMinutes,
            caloriesBurned:  caloriesBurned,
            sortOrder:       0,
            gymName:         gym?.name      ?? "",
            gymAddress:      gym?.address   ?? "",
            gymLatitude:     gym?.latitude  ?? 0,
            gymLongitude:    gym?.longitude ?? 0
        )

        let post = SocialPost(
            authorID:          userSettings.userID,
            authorUsername:    userSettings.username.isEmpty ? "me" : userSettings.username,
            authorDisplayName: userSettings.name,
            memeEmoji:         "",
            memeHeadline:      workoutHeadline,
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
        post.authorLocation         = locName
        post.authorLatitude         = lat
        post.authorLongitude        = lon
        post.authorStreak           = userSettings.macroStreak
        post.isAuthorPrivate        = userSettings.isPrivateAccount
        post.authorProfileImageData = userSettings.profileImageData
        post.postLabel              = PostLabel.workout.rawValue
        post.firebasePostID         = fbPostID
        if let img = photo {
            post.imageData = img.jpegData(compressionQuality: 0.8)
        }
        modelContext.insert(post)

        let images = photo.map { [$0] } ?? []
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

        do {
            try await PostService.shared.createCustomPost(
                photos:       images,
                author:       author,
                title:        workoutHeadline,
                caption:      caption,
                locationName: locName,
                latitude:     lat,
                longitude:    lon,
                postLabel:    PostLabel.workout.rawValue,
                workoutItems: [workoutItem],
                postID:       fbPostID
            )
        } catch {
            AppLogger.log("[PostWorkoutSheet] Firebase sync failed: \(error.localizedDescription)")
        }

        // Award aura for sharing the workout — once per day only.
        if !userSettings.hasEarnedWorkoutPostAuraToday {
            let reward = Self.workoutPostAuraReward
            if RemoteConfigService.shared.auraRewardAdRequired {
                let settings = userSettings
                AdManager.shared.showRewarded(onReward: {
                    Task { @MainActor in
                        settings.awardAura(points: reward)
                        settings.lastWorkoutPostDate = Date()
                    }
                })
            } else {
                userSettings.awardAura(points: reward)
                userSettings.lastWorkoutPostDate = Date()
            }
        }

        Task {
            await InAppNotificationService.shared.notifySubscribers(
                ofUserID:          userSettings.userID,
                posterUsername:    userSettings.username,
                posterDisplayName: userSettings.name,
                postID:            fbPostID,
                postTitle:         workoutHeadline,
                posterPhotoURL:    userSettings.profilePhotoURL
            )
        }

        isPosting = false
        dismiss()
    }
}

// MARK: - Aura Shimmer

/// Overlays a diagonal, semi-transparent white "gleam" that travels across
/// the masked text, repeating forever. Using `.mask(content)` confines the
/// gleam to the glyphs so the surrounding card stays untouched.
private struct AuraShimmerModifier: ViewModifier {
    let color: Color

    @State private var phase: CGFloat = -1.0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    let w = geo.size.width
                    let gleamWidth = max(w * 0.55, 80)
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.00), location: 0.0),
                            .init(color: .white.opacity(0.85), location: 0.5),
                            .init(color: .white.opacity(0.00), location: 1.0),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: gleamWidth)
                    .blendMode(.plusLighter)
                    // Move from just off-screen left to just off-screen right.
                    .offset(x: phase * (w + gleamWidth) - gleamWidth / 2)
                    .allowsHitTesting(false)
                }
                .mask(content)
            )
            .onAppear {
                // Kick off the sweep and repeat forever. A short delay keeps
                // the first frame clean (otherwise the shimmer flashes at t=0).
                withAnimation(
                    .linear(duration: 2.4)
                        .repeatForever(autoreverses: false)
                        .delay(0.2)
                ) {
                    phase = 1.0
                }
            }
    }
}
