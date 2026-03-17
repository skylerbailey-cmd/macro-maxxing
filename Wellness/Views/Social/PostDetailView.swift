//
//  PostDetailView.swift
//  Wellness
//

import SwiftUI
import SwiftData

// MARK: - PostDetailView

struct PostDetailView: View {
    @Bindable var post: SocialPost
    let userSettings: UserSettings

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var commentText     = ""
    @State private var commentImage:   UIImage? = nil
    @State private var showCommentCamera = false
    @State private var showingProfile  = false
    @FocusState private var commentFocused: Bool

    private let purpl   = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let pageBg  = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg  = Color(red: 0.13, green: 0.10, blue: 0.22)

    private var isOwnPost: Bool { post.authorID == userSettings.userID }

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 16) {
                            postCard
                            if post.goalCalories > 0 && post.fuelLogEntries.isEmpty {
                                macroBreakdown
                            }
                            commentsSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }

                    // Comment input
                    commentBar
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCommentCamera) {
                ImagePickerView(sourceType: .camera, selectedImage: $commentImage)
            }
            .sheet(isPresented: $showingProfile) {
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
                        ownUserSettings:    post.authorID == userSettings.userID ? userSettings : nil,
                        currentUserSettings: post.authorID == userSettings.userID ? nil : userSettings,
                        isDismissable:      true
                    )
                }
                .presentationDetents([.large])
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                if isOwnPost {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(role: .destructive) {
                            modelContext.delete(post)
                            dismiss()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red.opacity(0.75))
                        }
                    }
                }
            }
        }
    }

    // MARK: Post card

    private var postCard: some View {
        VStack(spacing: 10) {
            // Author
            HStack(spacing: 10) {
                Button { showingProfile = true } label: {
                    avatarCircle(size: 42, data: post.authorProfileImageData,
                                 initial: post.authorDisplayName)
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(post.authorDisplayName.isEmpty ? post.authorUsername : post.authorDisplayName)
                            .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        if post.authorAuraPoints > 0 {
                            Text("⭐ Lv \(post.authorAuraLevel) · \(post.authorAuraPoints) pts")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 1.0, green: 0.80, blue: 0.20))
                        }
                    }
                    Text("@\(post.authorUsername)  ·  \(post.macroDate, style: .date)")
                        .font(.caption2).foregroundStyle(.white.opacity(0.35))
                }
                Spacer()
            }

            // Content
            if !post.fuelLogEntries.isEmpty {
                fuelLogContent
            } else if post.isCustomPost {
                if !post.allImageDatas.isEmpty {
                    PostImagesView(imageDatas: post.allImageDatas)
                }
                Text(post.memeHeadline)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white).multilineTextAlignment(.center)
                if !post.memeSub.isEmpty {
                    Text(post.memeSub)
                        .font(.subheadline).foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }
            } else {
                if !post.allImageDatas.isEmpty {
                    PostImagesView(imageDatas: post.allImageDatas)
                }
                Text(post.memeEmoji).font(.system(size: 56))
                Text(post.memeHeadline)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white).multilineTextAlignment(.center)
                Text(post.memeSub)
                    .font(.subheadline).foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(cardBg)
        .cornerRadius(16)
    }

    // MARK: Macro breakdown (celebration posts only)

    private var macroBreakdown: some View {
        let items: [(String, Double, Double, Color)] = [
            ("Calories", post.totalCalories, post.goalCalories, Color(red: 1.00, green: 0.55, blue: 0.15)),
            ("Protein",  post.totalProtein,  post.goalProtein,  Color(red: 0.35, green: 0.75, blue: 1.00)),
            ("Carbs",    post.totalCarbs,    post.goalCarbs,    Color(red: 0.40, green: 0.90, blue: 0.72)),
            ("Fat",      post.totalFat,      post.goalFat,      Color(red: 1.00, green: 0.50, blue: 0.72)),
        ]
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Macros")
                    .font(.headline).foregroundStyle(.white)
                Spacer()
                Text(post.macroDate, style: .date)
                    .font(.caption).foregroundStyle(.white.opacity(0.35))
            }
            HStack(spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    let (label, actual, goal, color) = item
                    let met: Bool = label == "Calories"
                        ? actual >= goal * 0.85 && actual <= goal * 1.15
                        : actual >= goal * 0.85
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(met ? color.opacity(0.20) : Color.white.opacity(0.06))
                                .frame(width: 48, height: 48)
                            if met {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(color)
                            } else {
                                Text("\(Int(actual))g")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.50))
                            }
                        }
                        .shadow(color: met ? color.opacity(0.40) : .clear, radius: 6)
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.45))
                        Text("/ \(Int(goal))\(label == "Calories" ? " kcal" : "g")")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.28))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(14)
        .background(Color(red: 0.13, green: 0.10, blue: 0.22))
        .cornerRadius(16)
    }

    // MARK: Fuel log content (inline inside postCard)

    @ViewBuilder
    private var fuelLogContent: some View {
        let sorted    = post.fuelLogEntries.sorted { $0.sortOrder < $1.sortOrder }
        let purpl     = Color(red: 0.65, green: 0.45, blue: 1.00)
        let totalCal  = sorted.reduce(0.0) { $0 + $1.calories }
        let totalPro  = sorted.reduce(0.0) { $0 + $1.protein  }
        let totalCarb = sorted.reduce(0.0) { $0 + $1.carbs    }
        let totalFat  = sorted.reduce(0.0) { $0 + $1.fat      }

        VStack(alignment: .leading, spacing: 0) {
            Text("Today's Fuel Log 🔥")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, 10)

            if !post.memeSub.isEmpty {
                Text(post.memeSub)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.bottom, 12)
            }

            ForEach(sorted) { entry in
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        if let data = entry.imageData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipped()
                                .cornerRadius(10)
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.07))
                                .frame(width: 48, height: 48)
                                .overlay {
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white.opacity(0.30))
                                }
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.foodName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("\(Int(entry.calories)) kcal · \(Int(entry.protein))g P · \(Int(entry.carbs))g C · \(Int(entry.fat))g F")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        Spacer()
                        Text(entry.loggedAt, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.25))
                    }
                    .padding(.vertical, 10)

                    if entry.id != sorted.last?.id {
                        Divider().background(Color.white.opacity(0.08))
                    }
                }
            }

            Divider()
                .background(purpl.opacity(0.40))
                .padding(.top, 4)

            HStack {
                Text("Total")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(totalCal)) kcal · \(Int(totalPro))g P · \(Int(totalCarb))g C · \(Int(totalFat))g F")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(purpl)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Comments

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Comments (\(post.comments.count))")
                .font(.headline).foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.top, 14)

            if post.comments.isEmpty {
                Text("No comments yet. Be the first!")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.30))
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
            } else {
                // List inside card for swipe-to-delete
                // Sort by most reps first, then by date for ties
                let sorted = post.comments.sorted {
                    $0.repsCount != $1.repsCount ? $0.repsCount > $1.repsCount : $0.postedAt < $1.postedAt
                }
                List {
                    ForEach(sorted) { comment in
                        commentRow(comment)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    post.comments.removeAll { $0.id == comment.id }
                                    modelContext.delete(comment)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 14, bottom: 4, trailing: 14))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(height: sorted.reduce(0) { $0 + ($1.imageData != nil ? 175 : 70) })
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBg)
        .cornerRadius(16)
    }

    private func commentRow(_ comment: SocialComment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(purpl.opacity(0.2))
                .frame(width: 30, height: 30)
                .overlay {
                    Text(String(comment.authorDisplayName.prefix(1)).uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(purpl)
                }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(comment.authorDisplayName.isEmpty ? comment.authorUsername : comment.authorDisplayName)
                        .font(.caption.weight(.semibold)).foregroundStyle(.white)
                    Text(comment.postedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(.caption2).foregroundStyle(.white.opacity(0.30))
                }
                Text(comment.text)
                    .font(.subheadline).foregroundStyle(.white.opacity(0.85))
                if let data = comment.imageData, let uiImg = UIImage(data: data) {
                    Image(uiImage: uiImg)
                        .resizable().scaledToFill()
                        .frame(maxWidth: .infinity).frame(height: 120)
                        .clipped().cornerRadius(10)
                        .padding(.top, 4)
                }

                // 💪 Rep button on comment
                Button {
                    let isNewRep = !comment.hasRepped(userID: userSettings.userID)
                    comment.toggleRep(userID: userSettings.userID)
                    if isNewRep {
                        userSettings.awardAura(points: 1, silent: true)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("💪")
                            .font(.system(size: 12))
                        Text("\(comment.repsCount) Reps")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(
                                comment.hasRepped(userID: userSettings.userID)
                                    ? Color(red: 1.0, green: 0.75, blue: 0.2)
                                    : .white.opacity(0.35)
                            )
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: Comment input bar

    private var commentBar: some View {
        VStack(spacing: 0) {
            // Image preview strip (shown when a photo is attached)
            if let img = commentImage {
                HStack(spacing: 8) {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipped().cornerRadius(8)
                    Text("Photo attached")
                        .font(.caption).foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    Button { commentImage = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.50))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(red: 0.07, green: 0.05, blue: 0.12))
            }

            HStack(spacing: 10) {
                // Camera button
                Button {
                    showCommentCamera = true
                } label: {
                    Image(systemName: commentImage != nil ? "camera.fill" : "camera")
                        .font(.system(size: 20))
                        .foregroundStyle(commentImage != nil ? purpl : .white.opacity(0.40))
                }
                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                TextField("Add a comment…", text: $commentText)
                    .padding(10)
                    .background(Color(red: 0.13, green: 0.10, blue: 0.22))
                    .cornerRadius(20)
                    .foregroundStyle(.white)
                    .focused($commentFocused)
                    .submitLabel(.send)
                    .onSubmit { submitComment() }

                Button(action: submitComment) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle((commentText.isEmpty && commentImage == nil) ? .white.opacity(0.25) : purpl)
                }
                .disabled(commentText.isEmpty && commentImage == nil)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(red: 0.07, green: 0.05, blue: 0.12))
        }
    }

    private func submitComment() {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || commentImage != nil else { return }
        let imgData = commentImage?.jpegData(compressionQuality: 0.8)
        let comment = SocialComment(
            authorID:          userSettings.userID,
            authorUsername:    userSettings.username.isEmpty ? "me" : userSettings.username,
            authorDisplayName: userSettings.name,
            text:              text.isEmpty ? "📸" : text,
            imageData:         imgData,
            post:              post
        )
        post.comments.append(comment)
        modelContext.insert(comment)
        commentText    = ""
        commentImage   = nil
        commentFocused = false
        let hasPhoto = imgData != nil
        userSettings.awardAura(points: hasPhoto ? 5 : 1, silent: true)
        if post.authorID != userSettings.userID {
            Task {
                await InAppNotificationService.shared.sendComment(
                    to:               post.authorID,
                    postID:           post.firebasePostID,
                    postHeadline:     post.memeHeadline,
                    actorID:          userSettings.userID,
                    actorUsername:    userSettings.username,
                    actorDisplayName: userSettings.name
                )
            }
        }
    }
}
