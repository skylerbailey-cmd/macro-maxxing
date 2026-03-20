//
//  FeedPostDetailView.swift
//  Wellness
//
//  Firestore-backed post detail screen with comments.
//

import SwiftUI
import FirebaseFirestore

// MARK: - FeedComment

struct FeedComment: Identifiable, Codable {
    @DocumentID var commentID: String?
    var authorID:          String
    var authorUsername:    String
    var authorDisplayName: String
    var authorPhotoURL:    String = ""
    var text:              String
    @ServerTimestamp var createdAt: Timestamp?

    var id: String { commentID ?? UUID().uuidString }
}

// MARK: - FeedPostDetailView

struct FeedPostDetailView: View {

    let post:                FeedPost
    let currentUserSettings: UserSettings?
    var focusComment:        Bool = false

    @Environment(\.dismiss) private var dismiss

    @State private var comments:           [FeedComment] = []
    @State private var isLoadingComments:  Bool          = true
    @State private var commentText:        String        = ""
    @State private var isSubmitting:       Bool          = false
    @State private var showingAuthorProfile = false
    @FocusState private var commentFocused: Bool

    private let pageBg  = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg  = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let purpl   = Color(red: 0.65, green: 0.45, blue: 1.00)
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
        .task {
            await loadComments()
            if focusComment {
                try? await Task.sleep(nanoseconds: 400_000_000)
                commentFocused = true
            }
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
                Text(post.whoName.isEmpty ? post.username : post.whoName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
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
            // Food photo
            if !post.foodPhotoURL.isEmpty {
                CachedAsyncImage(
                    url: URL(string: post.foodPhotoURL),
                    content: { img in
                        img.resizable().scaledToFit().frame(maxWidth: .infinity)
                    },
                    placeholder: {
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(maxWidth: .infinity).frame(height: 220)
                            .overlay { ProgressView().tint(.white.opacity(0.30)) }
                    }
                )
                .cornerRadius(12)
            }

            // Title
            if !post.title.isEmpty {
                let parts = post.title.split(separator: ":", maxSplits: 1).map(String.init)
                let name  = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : post.title
                Text(name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }

            // Caption
            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }

            // Fuel log table
            if !post.fuelLogItems.isEmpty {
                fuelLogTable
            } else if !post.workoutItems.isEmpty {
                workoutTable
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
            Divider().background(purpl.opacity(0.40)).padding(.top, 4)
            HStack {
                Text("Total").font(.subheadline.weight(.bold)).foregroundStyle(.white)
                Spacer()
                Text("\(post.calories) kcal · \(Int(post.protein))g P · \(Int(post.carbs))g C · \(Int(post.fat))g F")
                    .font(.caption.weight(.semibold)).foregroundStyle(purpl)
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

    private let workoutGreen = Color(red: 0.30, green: 0.90, blue: 0.55)

    @ViewBuilder
    private var workoutTable: some View {
        let sorted   = post.workoutItems.sorted { $0.sortOrder < $1.sortOrder }
        let totalCal = sorted.reduce(0) { $0 + $1.caloriesBurned }
        let totalMin = sorted.reduce(0) { $0 + $1.durationMinutes }
        let totalTime = totalMin >= 60 ? "\(totalMin / 60)h \(totalMin % 60)m" : "\(totalMin)m"

        VStack(alignment: .leading, spacing: 0) {
            ForEach(sorted) { item in
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
                    Text("\(item.caloriesBurned) cal").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(workoutGreen)
                }
                .padding(.vertical, 8)
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
        .background(Color(red: 0.10, green: 0.07, blue: 0.18))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(workoutGreen.opacity(0.20), lineWidth: 1))
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
        HStack(alignment: .top, spacing: 10) {
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
                Text(comment.text)
                    .font(.subheadline).foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    // MARK: - Comment bar

    private var commentBar: some View {
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

    // MARK: - Data

    private func loadComments() async {
        guard let ref = commentsRef else { isLoadingComments = false; return }
        do {
            let snapshot = try await ref.order(by: "createdAt", descending: false).getDocuments()
            comments = snapshot.documents.compactMap { try? $0.data(as: FeedComment.self) }
        } catch {
            print("[FeedPostDetailView] Failed to load comments: \(error)")
        }
        isLoadingComments = false
    }

    private func submitComment() async {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let ref = commentsRef, let settings = currentUserSettings else { return }
        isSubmitting = true
        let comment = FeedComment(
            authorID:          settings.userID,
            authorUsername:    settings.username,
            authorDisplayName: settings.name,
            authorPhotoURL:    settings.profilePhotoURL,
            text:              text
        )
        do {
            _ = try ref.addDocument(from: comment)
            commentText    = ""
            commentFocused = false
            await loadComments()
        } catch {
            print("[FeedPostDetailView] Failed to submit comment: \(error)")
        }
        isSubmitting = false
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
