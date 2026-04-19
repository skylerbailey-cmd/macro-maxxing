//
//  FeedPostDetailView.swift
//  Wellness
//
//  Firestore-backed post detail screen with comments.
//

import SwiftUI
import FirebaseFirestore

// MARK: - FeedComment

struct FeedComment: Identifiable, Codable, Hashable {
    var commentID: String?
    var authorID:          String
    var authorUsername:    String
    var authorDisplayName: String
    var authorPhotoURL:    String = ""
    var text:              String
    var createdAt: Timestamp?

    var id: String { commentID ?? "\(authorID)-\(text.prefix(20))-\(createdAt?.seconds ?? 0)" }

    static func == (lhs: FeedComment, rhs: FeedComment) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - FeedPostDetailView

struct FeedPostDetailView: View {

    let post:                FeedPost
    let currentUserSettings: UserSettings?
    var focusComment:        Bool = false
    var onCommentCountChanged: ((Int) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var comments:           [FeedComment] = []
    @State private var isLoadingComments:  Bool          = true
    @State private var commentText:        String        = ""
    @State private var isSubmitting:       Bool          = false
    @State private var showingAuthorProfile = false
    @State private var isFollowingAuthor    = false
    @State private var showBlockConfirm     = false
    @State private var showReportUserConfirm = false
    @State private var showReportPostConfirm = false
    @State private var followErrorMessage:  String? = nil
    @State private var expandedWorkoutID:   String? = nil
    @State private var showingShareSheet          = false
    @State private var commentPendingDelete:      FeedComment? = nil
    @State private var commentPendingBlock:       FeedComment? = nil
    @State private var commentPendingReport:      FeedComment? = nil
    @State private var commentPendingReportUser:  FeedComment? = nil
    @State private var followedCommentAuthors:    Set<String>  = []
    @State private var followingList:            [FollowEntry] = []
    @State private var mentionQuery:             String        = ""
    @State private var currentPhotoPage: Int = 0
    @FocusState private var commentFocused: Bool

    private let pageBg  = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg  = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var purpl: Color { ThemeStore.shared.accent }
    private let calClr  = Color(red: 1.00, green: 0.55, blue: 0.15)
    private let proClr  = Color(red: 0.35, green: 0.75, blue: 1.00)
    private let carbClr = Color(red: 0.40, green: 0.90, blue: 0.72)
    private let fatClr  = Color(red: 1.00, green: 0.50, blue: 0.72)

    private var commentsRef: CollectionReference? {
        guard let postID = post.postID else { return nil }
        return Firestore.firestore()
            .collection("posts").document(postID).collection("comments")
    }

    // MARK: - Body

    var body: some View {
        // The modifier chain below was exceeding the Swift type-checker's
        // budget (8 stacked .alert calls + 2 sheets + toolbar + nav modifiers).
        // Split into `postLevelContent` (base + toolbar + post-author alerts)
        // and apply the comment-level alerts + sheets here so each computed
        // property has its own isolated inference context.
        postLevelContent
        .alert(
            "Delete comment?",
            isPresented: Binding(
                get: { commentPendingDelete != nil },
                set: { if !$0 { commentPendingDelete = nil } }
            ),
            presenting: commentPendingDelete
        ) { comment in
            Button("Delete", role: .destructive) {
                Task { await deleteComment(comment) }
            }
            Button("Cancel", role: .cancel) { commentPendingDelete = nil }
        } message: { _ in
            Text("This can't be undone.")
        }
        .alert(
            "Report this comment?",
            isPresented: Binding(
                get: { commentPendingReport != nil },
                set: { if !$0 { commentPendingReport = nil } }
            ),
            presenting: commentPendingReport
        ) { comment in
            Button("Report", role: .destructive) {
                Task {
                    guard let uid = currentUserSettings?.userID,
                          let postID = post.postID,
                          let commentID = comment.commentID else { return }
                    try? await BlockService.shared.reportComment(
                        postID: postID, commentID: commentID,
                        commentAuthorID: comment.authorID, reporterID: uid)
                }
            }
            Button("Cancel", role: .cancel) { commentPendingReport = nil }
        } message: { _ in
            Text("This comment will be flagged for review.")
        }
        .alert(
            Text(commentPendingReportUser.map { "Report @\($0.authorUsername)?" } ?? "Report user?"),
            isPresented: Binding(
                get: { commentPendingReportUser != nil },
                set: { if !$0 { commentPendingReportUser = nil } }
            ),
            presenting: commentPendingReportUser
        ) { comment in
            Button("Report", role: .destructive) {
                Task {
                    guard let uid = currentUserSettings?.userID else { return }
                    try? await BlockService.shared.reportUser(
                        reporterID: uid, reportedUserID: comment.authorID)
                }
            }
            Button("Cancel", role: .cancel) { commentPendingReportUser = nil }
        } message: { _ in
            Text("This user will be flagged for review.")
        }
        .alert(
            Text(commentPendingBlock.map { "Block @\($0.authorUsername)?" } ?? "Block user?"),
            isPresented: Binding(
                get: { commentPendingBlock != nil },
                set: { if !$0 { commentPendingBlock = nil } }
            ),
            presenting: commentPendingBlock
        ) { comment in
            Button("Block", role: .destructive) {
                Task {
                    guard let uid = currentUserSettings?.userID else { return }
                    try? await BlockService.shared.blockUser(
                        currentUserID: uid, targetUserID: comment.authorID,
                        targetUsername: comment.authorUsername,
                        targetDisplayName: comment.authorDisplayName,
                        targetProfilePhotoURL: comment.authorPhotoURL)
                    // Hide this user's comments immediately
                    comments.removeAll { $0.authorID == comment.authorID }
                }
            }
            Button("Cancel", role: .cancel) { commentPendingBlock = nil }
        } message: { _ in
            Text("They won't be able to see your posts and you won't see theirs.")
        }
        .task {
            // Load follow state for the menu
            if let uid = currentUserSettings?.userID, uid != post.userID {
                isFollowingAuthor = (try? await FollowService.shared.isFollowing(
                    currentUserID: uid, targetUserID: post.userID)) ?? false
            }
            // Load following list for @mention suggestions
            if let uid = currentUserSettings?.userID {
                followingList = (try? await FollowService.shared.fetchFollowing(userID: uid)) ?? []
            }
            await loadComments()
            guard !Task.isCancelled else { return }
            if focusComment {
                try? await Task.sleep(nanoseconds: 400_000_000)
                guard !Task.isCancelled else { return }
                commentFocused = true
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            PostShareView(post: post)
        }
        .sheet(isPresented: $showingAuthorProfile) {
            NavigationStack {
                ProfileView(
                    profileUserID:       post.userID,
                    profileUsername:     post.username,
                    profileDisplayName:  post.whoName,
                    profileAuraLevel:    post.auraLevel,
                    profileAuraPoints:   post.auraPoints,
                    profileImageData:    nil,
                    currentUserSettings: currentUserSettings,
                    isDismissable:       true,
                    profileIsPrivate:    !post.isPublic
                )
            }
            .presentationDetents([.large])
        }
        .keyboardDoneToolbar()
    }

    // MARK: - Post-level content (first half of modifier chain)

    /// Base content + toolbar + the 4 post-author alerts. Kept as its own
    /// computed property so the Swift type-checker can infer it independently
    /// from the 4 comment-level alerts + sheets applied in `body`.
    private var postLevelContent: some View {
        ZStack(alignment: .bottom) {
            pageBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    authorHeader
                    postContent
                    commentsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }

            commentBar
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.70))
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if post.userID == currentUserSettings?.userID {
                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("Share Post", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button {
                            Task { await toggleFollow() }
                        } label: {
                            Label(
                                isFollowingAuthor ? "Unfollow @\(post.username)" : "Follow @\(post.username)",
                                systemImage: isFollowingAuthor ? "person.badge.minus" : "person.badge.plus"
                            )
                        }
                        Divider()
                        Button(role: .destructive) { showReportPostConfirm = true } label: {
                            Label("Report Post", systemImage: "flag")
                        }
                        Button(role: .destructive) { showReportUserConfirm = true } label: {
                            Label("Report @\(post.username)", systemImage: "exclamationmark.bubble")
                        }
                        Button(role: .destructive) { showBlockConfirm = true } label: {
                            Label("Block @\(post.username)", systemImage: "hand.raised")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.70))
                }
            }
        }
        .alert("Block @\(post.username)?", isPresented: $showBlockConfirm) {
            Button("Block", role: .destructive) {
                Task {
                    guard let uid = currentUserSettings?.userID else { return }
                    try? await BlockService.shared.blockUser(
                        currentUserID: uid, targetUserID: post.userID,
                        targetUsername: post.username, targetDisplayName: post.whoName,
                        targetProfilePhotoURL: post.userProfilePhotoURL)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("They won't be able to see your posts and you won't see theirs.")
        }
        .alert("Report @\(post.username)?", isPresented: $showReportUserConfirm) {
            Button("Report", role: .destructive) {
                Task {
                    guard let uid = currentUserSettings?.userID else { return }
                    try? await BlockService.shared.reportUser(reporterID: uid, reportedUserID: post.userID)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This user will be flagged for review.")
        }
        .alert("Report this post?", isPresented: $showReportPostConfirm) {
            Button("Report", role: .destructive) {
                Task {
                    guard let uid = currentUserSettings?.userID else { return }
                    try? await BlockService.shared.reportPost(postID: post.id, reporterID: uid)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This post will be flagged for review.")
        }
        .alert(
            "Follow failed",
            isPresented: Binding(
                get: { followErrorMessage != nil },
                set: { if !$0 { followErrorMessage = nil } }
            ),
            presenting: followErrorMessage
        ) { _ in
            Button("OK", role: .cancel) { followErrorMessage = nil }
        } message: { msg in
            Text(msg)
        }
    }

    // MARK: - Author header

    private var authorHeader: some View {
        HStack(spacing: 10) {
            Button { showingAuthorProfile = true } label: {
                CachedAsyncImage(
                    url: URL(string: post.userProfilePhotoURL),
                    content: { img in
                        img.resizable().scaledToFill()
                            .frame(width: 42, height: 42)
                            .clipShape(Circle())
                    },
                    placeholder: { initialCircle(size: 42, name: post.whoName) }
                )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(post.whoName.isEmpty ? post.username : post.whoName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    if post.isProSubscriber {
                        Text("PRO")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 1.00, green: 0.80, blue: 0.20),
                                             Color(red: 1.00, green: 0.65, blue: 0.10)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                    }
                }
                Text("@\(post.username) · \(timeAgo(from: post.createdAtDate ?? Date()))")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))
            }
            Spacer()
        }
        .padding(14)
        .background(cardBg)
        .cornerRadius(16)
    }

    // MARK: - Post content

    @ViewBuilder
    private var postContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title + caption above photo
            if !post.title.isEmpty {
                let parts = post.title.split(separator: ":", maxSplits: 1).map(String.init)
                let name  = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : post.title
                Text(name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }
            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }

            // Food photos (carousel for multi-photo)
            let urls = post.allPhotoURLs
            if !urls.isEmpty {
                VStack(spacing: 0) {
                    TabView(selection: $currentPhotoPage) {
                        ForEach(Array(urls.enumerated()), id: \.offset) { idx, urlString in
                            CachedAsyncImage(
                                url: URL(string: urlString),
                                content: { img in
                                    img.resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 350)
                                        .clipped()
                                },
                                placeholder: {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.05))
                                        .frame(maxWidth: .infinity).frame(height: 350)
                                        .overlay { ProgressView().tint(.white.opacity(0.30)) }
                                }
                            )
                            .tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 350)
                    .cornerRadius(12)

                    if urls.count > 1 {
                        HStack(spacing: 6) {
                            ForEach(0..<urls.count, id: \.self) { idx in
                                Circle()
                                    .fill(idx == currentPhotoPage ? ThemeStore.shared.accent : Color.white.opacity(0.25))
                                    .frame(width: 7, height: 7)
                                    .scaleEffect(idx == currentPhotoPage ? 1.15 : 1.0)
                                    .animation(.spring(duration: 0.2), value: currentPhotoPage)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }

            // Fuel log table
            if !post.fuelLogItems.isEmpty {
                fuelLogTable
            } else if !post.workoutItems.isEmpty {
                workoutTable
            } else if post.postLabel == PostLabel.mealInspo.rawValue, post.mealScore > 0 {
                MealInspoCard(
                    mealScore:   post.mealScore,
                    calories:    post.calories,
                    protein:     post.protein,
                    carbs:       post.carbs,
                    fat:         post.fat,
                    goalProtein: post.goalProtein,
                    goalCarbs:   post.goalCarbs,
                    goalFat:     post.goalFat
                )
            } else if post.previousWeight > 0 {
                WeighInProgressCard(
                    previousWeight: post.previousWeight,
                    currentWeight:  post.currentWeight,
                    goalWeight:     post.goalWeight
                )
            } else if post.goalCalories > 0 {
                MacroDisciplineCard(
                    totalCalories: Double(post.calories),  goalCalories: Double(post.goalCalories),
                    totalProtein:  post.protein,           goalProtein:  post.goalProtein,
                    totalCarbs:    post.carbs,             goalCarbs:    post.goalCarbs,
                    totalFat:      post.fat,               goalFat:      post.goalFat
                )
            } else if post.calories > 0 {
                macroRow
            }
            if post.previousWeight == 0, post.currentWeight > 0, post.goalWeight > 0 {
                GoalWeightBadge(currentWeight: post.currentWeight, goalWeight: post.goalWeight)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBg)
        .cornerRadius(16)
    }

    // MARK: - Fuel log table

    private var fuelLogTable: some View {
        let sorted = post.fuelLogItems.sorted { $0.sortOrder < $1.sortOrder }
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(sorted) { item in
                HStack(spacing: 10) {
                    if !item.photoURL.isEmpty, let url = URL(string: item.photoURL) {
                        CachedAsyncImage(
                            url: url,
                            content: { img in img.resizable().scaledToFill().frame(width: 40, height: 40).clipped().cornerRadius(8) },
                            placeholder: { foodIcon }
                        )
                    } else {
                        foodIcon
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.foodName)
                            .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        Text("\(Int(item.calories)) kcal · \(Int(item.protein))g P · \(Int(item.carbs))g C · \(Int(item.fat))g F")
                            .font(.caption).foregroundStyle(.white.opacity(0.45))
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                if item.id != sorted.last?.id {
                    Divider().background(Color.white.opacity(0.08))
                }
            }
            Divider().background(post.themeColor.opacity(0.40)).padding(.top, 4)
            HStack(spacing: 6) {
                Text("Total").font(.subheadline.weight(.bold)).foregroundStyle(.white)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(post.calories) kcal").foregroundStyle(Color.calClr)
                    Text("·").foregroundStyle(.white.opacity(0.30))
                    Text("\(Int(post.protein))g P").foregroundStyle(Color.proClr)
                    Text("·").foregroundStyle(.white.opacity(0.30))
                    Text("\(Int(post.carbs))g C").foregroundStyle(Color.carbClr)
                    Text("·").foregroundStyle(.white.opacity(0.30))
                    Text("\(Int(post.fat))g F").foregroundStyle(Color.fatClr)
                }
                .font(.caption.weight(.semibold))
            }
            .padding(.top, 8)
        }
    }

    private var foodIcon: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.07))
            .frame(width: 40, height: 40)
            .overlay { Image(systemName: "fork.knife").font(.system(size: 14)).foregroundStyle(.white.opacity(0.30)) }
    }

    // MARK: - Workout table

    // Uses the post's label color when one was picked in the composer,
    // otherwise the app accent. Keeps workout chrome consistent with the
    // label chip at the top of the card.
    private var workoutGreen: Color { post.themeColor }

    @ViewBuilder
    private var workoutTable: some View {
        let sorted   = post.workoutItems.sorted { $0.sortOrder < $1.sortOrder }
        let totalCal = sorted.reduce(0) { $0 + $1.caloriesBurned }
        let totalMin = sorted.reduce(0) { $0 + $1.durationMinutes }
        let totalTime = totalMin >= 60 ? "\(totalMin / 60)h \(totalMin % 60)m" : "\(totalMin)m"

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(sorted) { item in
                let isExpanded   = expandedWorkoutID == item.id
                let hasExercises = !item.exercises.isEmpty
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(workoutGreen.opacity(0.12))
                            .frame(width: 40, height: 40)
                            .overlay { Image(systemName: WorkoutType(rawValue: item.workoutType)?.icon ?? "figure.mixed.cardio").font(.system(size: 16)).foregroundStyle(workoutGreen) }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.workoutName).font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.90))
                            Text("\(item.formattedDuration)").font(.caption).foregroundStyle(.white.opacity(0.40))
                        }
                        Spacer()
                        HStack(spacing: 6) {
                            Text("\(item.caloriesBurned) cal").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(workoutGreen)
                            if hasExercises {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(workoutGreen.opacity(0.70))
                                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                                    .animation(.spring(duration: 0.3), value: isExpanded)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard hasExercises else { return }
                        withAnimation(.spring(duration: 0.35)) {
                            expandedWorkoutID = isExpanded ? nil : item.id
                        }
                    }

                    if isExpanded && hasExercises {
                        detailExerciseList(item.exercises)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                if item.id != sorted.last?.id {
                    Divider().background(Color.white.opacity(0.05))
                }
            }
            if sorted.count > 1 {
                Divider().background(Color.white.opacity(0.06))
                HStack {
                    Spacer()
                    Text("Total: \(totalTime) · \(totalCal) cal burned")
                        .font(.caption.weight(.semibold)).foregroundStyle(workoutGreen.opacity(0.80))
                }
                .padding(.top, 6)
            }
        }
        .padding(12)
        .background(Color.cardBg)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(workoutGreen.opacity(0.20), lineWidth: 1))
    }

    private func detailExerciseList(_ exercises: [Exercise]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider().background(workoutGreen.opacity(0.15))
            VStack(alignment: .leading, spacing: 8) {
                ForEach(exercises) { exercise in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(workoutGreen.opacity(0.25))
                            .frame(width: 6, height: 6)
                            .padding(.top, 5)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                            Text(detailSetsLabel(exercise))
                                .font(.system(size: 11))
                                .foregroundStyle(workoutGreen.opacity(0.70))
                        }
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 10)
        }
    }

    private func detailSetsLabel(_ exercise: Exercise) -> String {
        let setCount = exercise.sets.count
        guard setCount > 0 else { return "" }
        if exercise.hasUniformSets, let first = exercise.sets.first {
            let weightStr = first.weight.map { w in
                w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w)) lb" : "\(w) lb"
            } ?? "bodyweight"
            return "\(setCount) × \(first.reps) reps · \(weightStr)"
        } else {
            return exercise.sets.enumerated().map { i, s in
                let w = s.weight.map { w in
                    w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w)) lb" : "\(w) lb"
                } ?? "BW"
                return "Set \(i + 1): \(s.reps) × \(w)"
            }.joined(separator: "  ·  ")
        }
    }

    // MARK: - Macro row

    private var macroRow: some View {
        HStack(spacing: 6) {
            macroBadge(value: "\(post.calories)",     unit: "kcal", color: calClr)
            macroBadge(value: "\(Int(post.protein))", unit: "P",    color: proClr)
            macroBadge(value: "\(Int(post.carbs))",   unit: "C",    color: carbClr)
            macroBadge(value: "\(Int(post.fat))",     unit: "F",    color: fatClr)
        }
    }

    private func macroBadge(value: String, unit: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(value).font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(color)
            Text(unit).font(.system(size: 10, weight: .semibold)).foregroundStyle(color.opacity(0.65))
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(color.opacity(0.10)).cornerRadius(8)
    }

    // MARK: - Comments section

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Comments (\(comments.count))")
                .font(.headline).foregroundStyle(.white)
                .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 10)

            if isLoadingComments {
                ProgressView().tint(purpl)
                    .frame(maxWidth: .infinity).padding(.vertical, 20)
            } else if comments.isEmpty {
                Text("No comments yet. Be the first!")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.30))
                    .padding(.horizontal, 14).padding(.bottom, 14)
            } else {
                VStack(spacing: 0) {
                    ForEach(comments) { comment in
                        commentRow(comment)
                        if comment.id != comments.last?.id {
                            Divider().background(Color.white.opacity(0.08))
                                .padding(.horizontal, 14)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBg)
        .cornerRadius(16)
    }

    private func commentRow(_ comment: FeedComment) -> some View {
        let myID      = currentUserSettings?.userID ?? ""
        let isOwn     = comment.authorID == myID
        let isPostOwner = myID == post.userID
        let isFollowing = followedCommentAuthors.contains(comment.authorID)

        return HStack(alignment: .top, spacing: 10) {
            CachedAsyncImage(
                url: URL(string: comment.authorPhotoURL),
                content: { img in img.resizable().scaledToFill().frame(width: 30, height: 30).clipShape(Circle()) },
                placeholder: { initialCircle(size: 30, name: comment.authorDisplayName) }
            )
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(comment.authorDisplayName.isEmpty ? comment.authorUsername : comment.authorDisplayName)
                        .font(.caption.weight(.semibold)).foregroundStyle(.white)
                    if let date = comment.createdAt?.dateValue() {
                        Text(timeAgo(from: date))
                            .font(.caption2).foregroundStyle(.white.opacity(0.30))
                    }
                }
                highlightedMentions(comment.text)
                    .font(.subheadline)
            }
            Spacer()

            Menu {
                if isOwn {
                    Button(role: .destructive) {
                        commentPendingDelete = comment
                    } label: {
                        Label("Delete Comment", systemImage: "trash")
                    }
                } else {
                    Button {
                        Task { await toggleFollowCommentAuthor(comment) }
                    } label: {
                        Label(
                            isFollowing ? "Unfollow @\(comment.authorUsername)" : "Follow @\(comment.authorUsername)",
                            systemImage: isFollowing ? "person.badge.minus" : "person.badge.plus"
                        )
                    }
                    Divider()
                    Button(role: .destructive) {
                        commentPendingReport = comment
                    } label: {
                        Label("Report Comment", systemImage: "flag")
                    }
                    Button(role: .destructive) {
                        commentPendingReportUser = comment
                    } label: {
                        Label("Report @\(comment.authorUsername)", systemImage: "exclamationmark.bubble")
                    }
                    Button(role: .destructive) {
                        commentPendingBlock = comment
                    } label: {
                        Label("Block @\(comment.authorUsername)", systemImage: "hand.raised")
                    }
                    if isPostOwner {
                        Divider()
                        Button(role: .destructive) {
                            commentPendingDelete = comment
                        } label: {
                            Label("Delete Comment", systemImage: "trash")
                        }
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.vertical, 2).padding(.horizontal, 4)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .accessibilityLabel("Comment options")
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    // MARK: - Comment bar

    /// Filtered suggestions based on the current @mention query.
    private var mentionSuggestions: [FollowEntry] {
        let q = mentionQuery.lowercased()
        guard !q.isEmpty else { return [] }
        return followingList
            .filter { $0.username.lowercased().hasPrefix(q) }
            .prefix(3)
            .map { $0 }
    }

    /// Extracts the partial username the cursor is currently typing after an
    /// `@` character. Returns "" if the cursor isn't inside an @mention.
    private static func activeMentionQuery(in text: String) -> String {
        // Walk backwards from the end to find the last `@`
        guard let atIdx = text.lastIndex(of: "@") else { return "" }
        let after = text[text.index(after: atIdx)...]
        // If there's a space after the @, the mention is already closed
        if after.contains(" ") { return "" }
        return String(after)
    }

    private var commentBar: some View {
        VStack(spacing: 0) {
            // @mention suggestions — float above the input bar
            if !mentionSuggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(mentionSuggestions) { entry in
                        Button {
                            insertMention(entry.username)
                        } label: {
                            HStack(spacing: 10) {
                                if !entry.profilePhotoURL.isEmpty, let url = URL(string: entry.profilePhotoURL) {
                                    CachedAsyncImage(
                                        url: url,
                                        content: { img in
                                            img.resizable().scaledToFill()
                                                .frame(width: 28, height: 28).clipShape(Circle())
                                        },
                                        placeholder: { initialCircle(size: 28, name: entry.displayName ?? entry.username) }
                                    )
                                } else {
                                    initialCircle(size: 28, name: entry.displayName ?? entry.username)
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(entry.displayName ?? entry.username)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Text("@\(entry.username)")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.white.opacity(0.45))
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        if entry.id != mentionSuggestions.last?.id {
                            Divider().background(Color.white.opacity(0.08))
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(cardBg)
            }

            HStack(spacing: 10) {
                // Own avatar
                if let settings = currentUserSettings {
                    if let data = settings.profileImageData, let uiImg = UIImage(data: data) {
                        Image(uiImage: uiImg)
                            .resizable().scaledToFill()
                            .frame(width: 30, height: 30).clipShape(Circle())
                    } else {
                        initialCircle(size: 30, name: settings.name)
                    }
                }

                TextField("Add a comment…", text: $commentText)
                    .padding(10)
                    .background(cardBg)
                    .cornerRadius(20)
                    .foregroundStyle(.white)
                    .focused($commentFocused)
                    .submitLabel(.send)
                    .onSubmit { Task { await submitComment() } }
                    .onChange(of: commentText) { _, newValue in
                        mentionQuery = Self.activeMentionQuery(in: newValue)
                    }

                Button { Task { await submitComment() } } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(commentText.isEmpty ? .white.opacity(0.25) : purpl)
                }
                .disabled(commentText.isEmpty || isSubmitting || currentUserSettings == nil)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(.ultraThinMaterial.opacity(0.8))
            .background(pageBg)
        }
    }

    /// Replaces the partial @query with the full username and adds a trailing space.
    private func insertMention(_ username: String) {
        guard let atIdx = commentText.lastIndex(of: "@") else { return }
        commentText = String(commentText[..<atIdx]) + "@\(username) "
        mentionQuery = ""
    }

    // MARK: - Follow toggle

    private func toggleFollow() async {
        guard let settings = currentUserSettings else { return }
        let wasFollowing = isFollowingAuthor
        do {
            if wasFollowing {
                try await FollowService.shared.unfollowUser(
                    currentUserID: settings.userID, targetUserID: post.userID)
                isFollowingAuthor = false
            } else {
                try await FollowService.shared.followUser(
                    currentUserID:          settings.userID,
                    currentUsername:        settings.username,
                    currentDisplayName:     settings.name,
                    currentProfilePhotoURL: settings.profilePhotoURL,
                    targetUserID:           post.userID,
                    targetUsername:         post.username,
                    targetDisplayName:      post.whoName,
                    targetProfilePhotoURL:  post.userProfilePhotoURL)
                isFollowingAuthor = true
            }
        } catch {
            AppLogger.log("[FeedPostDetailView] toggleFollow error: \(error)")
            followErrorMessage = wasFollowing
                ? "Couldn't unfollow @\(post.username). \(error.localizedDescription)"
                : "Couldn't follow @\(post.username). \(error.localizedDescription)"
        }
    }

    // MARK: - Data

    private func loadComments() async {
        guard let ref = commentsRef else { isLoadingComments = false; return }
        do {
            let snapshot = try await ref.order(by: "createdAt", descending: false).getDocuments()
            guard !Task.isCancelled else { return }
            comments = snapshot.documents.compactMap { doc in
                guard var comment = try? doc.data(as: FeedComment.self) else { return nil }
                comment.commentID = doc.documentID
                return comment
            }
            // Self-heal: if the cached commentsCount on the post doc has drifted
            // from the actual number of comment documents, write the true count
            // back. This fixes older posts whose comments were added before the
            // count was being maintained.
            if let postID = post.postID, comments.count != post.commentsCount {
                try? await PostService.shared.setCommentCount(postID: postID, count: comments.count)
            }
            await refreshFollowedCommentAuthors()
        } catch {
            guard !Task.isCancelled else { return }
            AppLogger.log("[FeedPostDetailView] Failed to load comments: \(error)")
        }
        isLoadingComments = false
    }

    /// Looks up follow state for each unique comment author so the per-comment
    /// menu can show Follow vs. Unfollow correctly.
    private func refreshFollowedCommentAuthors() async {
        guard let uid = currentUserSettings?.userID else { return }
        let authorIDs = Set(comments.map(\.authorID)).subtracting([uid])
        var followed = Set<String>()
        await withTaskGroup(of: (String, Bool).self) { group in
            for authorID in authorIDs {
                group.addTask {
                    let isFollowing = (try? await FollowService.shared.isFollowing(
                        currentUserID: uid, targetUserID: authorID)) ?? false
                    return (authorID, isFollowing)
                }
            }
            for await (authorID, isFollowing) in group where isFollowing {
                followed.insert(authorID)
            }
        }
        guard !Task.isCancelled else { return }
        followedCommentAuthors = followed
    }

    private func toggleFollowCommentAuthor(_ comment: FeedComment) async {
        guard let settings = currentUserSettings else { return }
        let wasFollowing = followedCommentAuthors.contains(comment.authorID)
        do {
            if wasFollowing {
                try await FollowService.shared.unfollowUser(
                    currentUserID: settings.userID, targetUserID: comment.authorID)
                followedCommentAuthors.remove(comment.authorID)
            } else {
                try await FollowService.shared.followUser(
                    currentUserID:          settings.userID,
                    currentUsername:        settings.username,
                    currentDisplayName:     settings.name,
                    currentProfilePhotoURL: settings.profilePhotoURL,
                    targetUserID:           comment.authorID,
                    targetUsername:         comment.authorUsername,
                    targetDisplayName:      comment.authorDisplayName,
                    targetProfilePhotoURL:  comment.authorPhotoURL)
                followedCommentAuthors.insert(comment.authorID)
            }
        } catch {
            AppLogger.log("[FeedPostDetailView] toggleFollowCommentAuthor error: \(error)")
            followErrorMessage = wasFollowing
                ? "Couldn't unfollow @\(comment.authorUsername). \(error.localizedDescription)"
                : "Couldn't follow @\(comment.authorUsername). \(error.localizedDescription)"
        }
    }

    private func deleteComment(_ comment: FeedComment) async {
        guard let ref = commentsRef,
              let commentID = comment.commentID,
              let uid = currentUserSettings?.userID
        else { return }

        // Permitted if the viewer authored the comment, or owns the post.
        guard comment.authorID == uid || post.userID == uid else { return }

        // Optimistic local removal
        let previous = comments
        comments.removeAll { $0.id == comment.id }

        do {
            try await ref.document(commentID).delete()
            if let postID = post.postID {
                try? await PostService.shared.decrementCommentCount(postID: postID)
            }
            onCommentCountChanged?(-1)
        } catch {
            AppLogger.log("[FeedPostDetailView] Failed to delete comment: \(error)")
            comments = previous
        }
    }

    private func submitComment() async {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let ref = commentsRef, let settings = currentUserSettings else { return }
        isSubmitting = true
        var comment = FeedComment(
            authorID:          settings.userID,
            authorUsername:    settings.username,
            authorDisplayName: settings.name,
            authorPhotoURL:    settings.profilePhotoURL,
            text:              text
        )
        comment.createdAt = Timestamp(date: Date())

        // Optimistically show the comment immediately
        let previousComments = comments
        comments.append(comment)
        onCommentCountChanged?(1)
        commentText    = ""
        commentFocused = false
        isSubmitting   = false

        do {
            var data = try Firestore.Encoder().encode(comment)
            data["createdAt"] = FieldValue.serverTimestamp()
            _ = try await ref.addDocument(data: data)
            if let postID = post.postID {
                try? await PostService.shared.incrementCommentCount(postID: postID)
            }

            // Send mention notifications for any @username in the comment
            let mentionedUsernames = Self.parseMentions(from: text)
            if !mentionedUsernames.isEmpty {
                Task {
                    for username in mentionedUsernames {
                        guard let targetID = await UserProfileService.shared.fetchUserID(forUsername: username),
                              targetID != settings.userID else { continue }
                        await InAppNotificationService.shared.sendMention(
                            to:               targetID,
                            postID:           post.postID ?? "",
                            postHeadline:     post.title,
                            actorID:          settings.userID,
                            actorUsername:    settings.username,
                            actorDisplayName: settings.name,
                            actorPhotoURL:    settings.profilePhotoURL
                        )
                    }
                }
            }
        } catch {
            guard !Task.isCancelled else { return }
            // Revert optimistic insert on failure
            comments = previousComments
            onCommentCountChanged?(-1)
            AppLogger.log("[FeedPostDetailView] Failed to submit comment: \(error)")
        }
    }

    /// Extracts unique @usernames from comment text. Handles handles with
    /// letters, digits, underscores, and dots (common social-media chars).
    private static func parseMentions(from text: String) -> [String] {
        let pattern = #"@([A-Za-z0-9_.]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        let usernames = matches.compactMap { match -> String? in
            guard let r = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[r]).lowercased()
        }
        return Array(Set(usernames))
    }

    /// Renders comment text with @mentions highlighted in the accent color.
    private func highlightedMentions(_ text: String) -> Text {
        let pattern = #"@[A-Za-z0-9_.]+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return Text(text).foregroundColor(.white.opacity(0.85))
        }
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, range: fullRange)

        var result = Text("")
        var cursor = text.startIndex
        for match in matches {
            guard let range = Range(match.range, in: text) else { continue }
            // Text before the mention
            if cursor < range.lowerBound {
                result = result + Text(text[cursor..<range.lowerBound])
                    .foregroundColor(.white.opacity(0.85))
            }
            // The @mention itself
            result = result + Text(text[range])
                .foregroundColor(purpl)
                .bold()
            cursor = range.upperBound
        }
        // Remaining text after last mention
        if cursor < text.endIndex {
            result = result + Text(text[cursor...])
                .foregroundColor(.white.opacity(0.85))
        }
        return result
    }

    // MARK: - Helpers

    private func initialCircle(size: CGFloat, name: String) -> some View {
        Circle()
            .fill(purpl.opacity(0.22))
            .frame(width: size, height: size)
            .overlay {
                Text(String((name.isEmpty ? "?" : name).prefix(1)).uppercased())
                    .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                    .foregroundStyle(purpl)
            }
    }

    private func timeAgo(from date: Date) -> String {
        let s = Int(Date().timeIntervalSince(date))
        switch s {
        case ..<60:          return "just now"
        case 60..<3600:      return "\(s / 60)m"
        case 3600..<86400:   return "\(s / 3600)h"
        case 86400..<604800: return "\(s / 86400)d"
        default:             return "\(s / 604800)w"
        }
    }
}
