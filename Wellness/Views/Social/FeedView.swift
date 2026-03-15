//
//  FeedView.swift
//  Wellness
//
//  Firebase-backed global social feed.
//

import SwiftUI

// MARK: - Color palette

private extension Color {
    static let pageBg   = Color(red: 0.07, green: 0.05, blue: 0.12)
    static let cardBg   = Color(red: 0.13, green: 0.10, blue: 0.22)
    static let purpleHi = Color(red: 0.65, green: 0.45, blue: 1.00)
    static let calClr   = Color(red: 1.00, green: 0.55, blue: 0.15)
    static let proClr   = Color(red: 0.35, green: 0.75, blue: 1.00)
    static let carbClr  = Color(red: 0.40, green: 0.90, blue: 0.72)
    static let fatClr   = Color(red: 1.00, green: 0.50, blue: 0.72)
}

// MARK: - FeedView

struct FeedView: View {
    let userSettings: UserSettings

    @State private var viewModel = FeedViewModel()

    var body: some View {
        ZStack {
            Color.pageBg.ignoresSafeArea()

            Group {
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    skeletonFeed
                } else if viewModel.posts.isEmpty {
                    emptyState
                } else {
                    feedList
                }
            }

            // Error toast (bottom)
            if let err = viewModel.errorMessage {
                VStack {
                    Spacer()
                    errorToast(err)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationTitle("Aura Feed")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.posts.isEmpty { await viewModel.loadInitialFeed() }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage)
    }

    // MARK: - Feed list

    /// Extracted to a helper so the ForEach body stays simple enough for the Swift type-checker.
    private func postCard(for post: FeedPost) -> some View {
        let deleteAction: (() -> Void)? = post.userID == userSettings.userID
            ? { Task { await viewModel.deletePost(post) } }
            : nil
        return FeedPostCard(
            post:          post,
            currentUserID: userSettings.userID,
            onRep: { Task { await viewModel.toggleRep(postID: post.id, currentUserID: userSettings.userID) } },
            onDelete:      deleteAction
        )
    }

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.posts) { post in
                    postCard(for: post)
                        .onAppear {
                            Task { await viewModel.loadMoreIfNeeded(currentPost: post) }
                        }
                }

                // Pagination spinner
                if viewModel.isLoading && !viewModel.posts.isEmpty {
                    ProgressView()
                        .tint(Color.purpleHi)
                        .padding(.vertical, 20)
                }

                // End-of-feed message
                if !viewModel.hasMore && !viewModel.posts.isEmpty {
                    Text("You've seen it all 💪")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.25))
                        .padding(.vertical, 20)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 52))
                .foregroundStyle(.white.opacity(0.12))

            Text("No posts yet")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.35))

            Text("Be the first to share a meal.\nPost from the Fuel Log after scanning your food.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.22))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                Task { await viewModel.loadInitialFeed() }
            } label: {
                Text("Retry")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.purpleHi)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Skeleton

    private var skeletonFeed: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in SkeletonCard() }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Error toast

    private func errorToast(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(2)
            Spacer()
            Button { viewModel.errorMessage = nil } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.50))
            }
        }
        .padding(14)
        .background(Color(red: 0.18, green: 0.06, blue: 0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.red.opacity(0.30), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.40), radius: 10)
    }
}

// MARK: - Feed Post Card

struct FeedPostCard: View {
    let post:          FeedPost
    let currentUserID: String
    let onRep:         () -> Void
    var onDelete:      (() -> Void)? = nil

    @State private var showDeleteConfirm = false

    private let cardBg   = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let purpleHi = Color(red: 0.65, green: 0.45, blue: 1.00)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            authorHeader
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 12)

            foodPhoto

            VStack(alignment: .leading, spacing: 10) {
                titleRow
                if !post.caption.isEmpty {
                    captionView(post.caption)
                }
                macroRow
                actionRow
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 14)
        }
        .background(cardBg)
        .cornerRadius(16)
        .confirmationDialog("Delete this post?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Post", role: .destructive) { onDelete?() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes the post and all its photos. This cannot be undone.")
        }
    }

    // MARK: Author header

    private var authorHeader: some View {
        HStack(spacing: 10) {
            // Avatar
            CachedAsyncImage(
                url: URL(string: post.userProfilePhotoURL),
                content: { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())
                },
                placeholder: { initialCircle(size: 38, name: post.whoName) }
            )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(post.whoName.isEmpty ? post.username : post.whoName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    if post.auraPoints > 0 {
                        Text("⭐ Lv \(post.auraLevel)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 1.0, green: 0.80, blue: 0.20))
                    }

                    if post.streak > 0 {
                        Text("🔥 \(post.streak)")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(red: 1.0, green: 0.60, blue: 0.20))
                    }
                }

                HStack(spacing: 4) {
                    Text("@\(post.username)")
                    Text("·")
                    Text(timeAgo(from: post.createdAtDate ?? Date()))
                    if !post.locationName.isEmpty {
                        Text("·")
                        Image(systemName: "location.fill")
                            .font(.system(size: 8))
                        Text(post.locationName)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.35))
            }

            Spacer()

            // Delete button (own posts only)
            if onDelete != nil {
                Button { showDeleteConfirm = true } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.30))
                        .padding(6)
                }
            }
        }
    }

    // MARK: Food photo

    @ViewBuilder
    private var foodPhoto: some View {
        if !post.foodPhotoURL.isEmpty {
            CachedAsyncImage(
                url: URL(string: post.foodPhotoURL),
                content: { image in
                    image.resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                },
                placeholder: { photoPlaceholder(loading: true) }
            )
        }
    }

    private func photoPlaceholder(loading: Bool) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .overlay {
                if loading {
                    ProgressView().tint(.white.opacity(0.30))
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.15))
                }
            }
    }

    // MARK: Title + meal type badge

    private var titleRow: some View {
        HStack(spacing: 8) {
            // Extract food name from "MealType: FoodName" title
            let parts  = post.title.split(separator: ":", maxSplits: 1).map(String.init)
            let meal   = parts.count > 1 ? parts[0].trimmingCharacters(in: .whitespaces) : ""
            let name   = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : post.title

            Text(name)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            if !meal.isEmpty {
                Text(meal)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(purpleHi)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(purpleHi.opacity(0.12))
                    .cornerRadius(6)
            }
        }
    }

    // MARK: Caption

    private func captionView(_ caption: String) -> some View {
        Text(caption)
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.70))
            .lineLimit(3)
    }

    // MARK: Macro row

    private var macroRow: some View {
        HStack(spacing: 6) {
            macroBadge(value: "\(post.calories)",     unit: "kcal", color: Color.calClr)
            macroBadge(value: "\(Int(post.protein))", unit: "P",    color: Color.proClr)
            macroBadge(value: "\(Int(post.carbs))",   unit: "C",    color: Color.carbClr)
            macroBadge(value: "\(Int(post.fat))",     unit: "F",    color: Color.fatClr)

            Spacer()

            // Goal progress ring (when goal is set)
            if post.goalCalories > 0 {
                goalRing
            }
        }
    }

    private func macroBadge(value: String, unit: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(unit)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color.opacity(0.65))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color.opacity(0.10))
        .cornerRadius(8)
    }

    private var goalRing: some View {
        let pct = min(Double(post.calories) / Double(max(post.goalCalories, 1)), 1.0)
        let met = pct >= 0.85 && pct <= 1.15
        return ZStack {
            Circle()
                .stroke(.white.opacity(0.08), lineWidth: 3)
                .frame(width: 26, height: 26)
            Circle()
                .trim(from: 0, to: pct)
                .stroke(met ? Color.calClr : Color.calClr.opacity(0.50), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 26, height: 26)
                .rotationEffect(.degrees(-90))
            if met {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.calClr)
            }
        }
    }

    // MARK: Action row (reps + comments)

    private var actionRow: some View {
        HStack(spacing: 16) {
            Spacer()

            // 💪 Rep button
            Button(action: onRep) {
                HStack(spacing: 5) {
                    Text("💪")
                        .font(.system(size: 15))
                    Text("\(post.reps)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(
                            post.hasRepped(userID: currentUserID)
                                ? Color(red: 1.0, green: 0.75, blue: 0.2)
                                : .white.opacity(0.35)
                        )
                    Text("Reps")
                        .font(.caption)
                        .foregroundStyle(
                            post.hasRepped(userID: currentUserID)
                                ? Color(red: 1.0, green: 0.75, blue: 0.2)
                                : .white.opacity(0.35)
                        )
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(post.hasRepped(userID: currentUserID) ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: post.hasRepped(userID: currentUserID))

            // 💬 Comment count
            HStack(spacing: 4) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 13))
                Text("\(post.commentsCount)")
                    .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.30))
        }
    }

    // MARK: Helpers

    private func initialCircle(size: CGFloat, name: String) -> some View {
        Circle()
            .fill(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.22))
            .frame(width: size, height: size)
            .overlay {
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.0))
            }
    }

    private func timeAgo(from date: Date) -> String {
        let s = Int(Date().timeIntervalSince(date))
        switch s {
        case ..<60:       return "just now"
        case 60..<3600:   return "\(s / 60)m"
        case 3600..<86400: return "\(s / 3600)h"
        case 86400..<604800: return "\(s / 86400)d"
        default:          return "\(s / 604800)w"
        }
    }
}

// MARK: - Skeleton card

private struct SkeletonCard: View {
    @State private var opacity: Double = 0.4

    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Author row
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 5) {
                    Capsule().fill(Color.white.opacity(0.12)).frame(width: 120, height: 10)
                    Capsule().fill(Color.white.opacity(0.08)).frame(width: 80,  height: 8)
                }
                Spacer()
            }
            .padding(14)

            // Photo placeholder
            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(maxWidth: .infinity)
                .frame(height: 220)

            // Text rows
            VStack(alignment: .leading, spacing: 8) {
                Capsule().fill(Color.white.opacity(0.10)).frame(width: 160, height: 11)
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 60, height: 26)
                    }
                }
                HStack {
                    Spacer()
                    Capsule().fill(Color.white.opacity(0.08)).frame(width: 80, height: 9)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(cardBg)
        .cornerRadius(16)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                opacity = 0.85
            }
        }
    }
}
