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

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @Environment(LocationManager.self) private var locationManager

    @State private var captionText    = ""
    @State private var photo: UIImage? = nil
    @State private var showingCamera  = false
    @State private var showingLibrary = false
    @State private var isPosting      = false

    // MARK: - Colors

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let accent = Color(red: 0.30, green: 0.90, blue: 0.55)

    private var workoutHeadline: String { "\(workoutName) 💪" }
    private var workoutStats: String { "\(durationMinutes) min · \(caloriesBurned) kcal · \(workoutType.rawValue)" }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        promptHeader
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
                statBadge(icon: "timer",             value: "\(durationMinutes) min",      color: Color(red: 0.65, green: 0.45, blue: 1.00))
                statBadge(icon: "flame.fill",         value: "\(caloriesBurned) kcal",      color: Color(red: 1.00, green: 0.55, blue: 0.15))
                statBadge(icon: workoutType.icon,     value: workoutType.shortLabel,        color: accent)
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
        let sub       = caption.isEmpty ? workoutStats : "\(workoutStats)\n\(caption)"
        let locName   = locationManager.city.isEmpty ? userSettings.location : locationManager.city
        let lat       = locationManager.coordinate?.latitude  ?? 0
        let lon       = locationManager.coordinate?.longitude ?? 0

        let post = SocialPost(
            authorID:          userSettings.userID,
            authorUsername:    userSettings.username.isEmpty ? "me" : userSettings.username,
            authorDisplayName: userSettings.name,
            memeEmoji:         "",
            memeHeadline:      workoutHeadline,
            memeSub:           sub,
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
            isPublic:            !userSettings.isPrivateAccount
        )

        do {
            try await PostService.shared.createCustomPost(
                photos:        images,
                author:        author,
                title:         workoutHeadline,
                caption:       sub,
                locationName:  locName,
                latitude:      lat,
                longitude:     lon,
                postLabel:     PostLabel.workout.rawValue,
                mogBoardScope: "",
                mogBoardType:  "",
                postID:        fbPostID
            )
        } catch {
            print("[PostWorkoutSheet] Firebase sync failed: \(error.localizedDescription)")
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
