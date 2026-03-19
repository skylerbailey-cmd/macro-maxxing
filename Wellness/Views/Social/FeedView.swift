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
    var showStreak:    Bool          = true

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
                if !post.fuelLogItems.isEmpty {
                    fuelLogTable
                    if post.goalCalories > 0 {
                        MacroDisciplineCard(
                            totalCalories: Double(post.calories),  goalCalories: Double(post.goalCalories),
                            totalProtein:  post.protein,           goalProtein:  post.goalProtein,
                            totalCarbs:    post.carbs,             goalCarbs:    post.goalCarbs,
                            totalFat:      post.fat,               goalFat:      post.goalFat
                        )
                    }
                } else if !post.workoutItems.isEmpty {
                    workoutTable
                } else if !post.mogBoardSnapshot.isEmpty {
                    mogBoardSnapshotCard
                } else if post.goalCalories > 0 {
                    MacroDisciplineCard(
                        totalCalories: Double(post.calories),  goalCalories: Double(post.goalCalories),
                        totalProtein:  post.protein,           goalProtein:  post.goalProtein,
                        totalCarbs:    post.carbs,             goalCarbs:    post.goalCarbs,
                        totalFat:      post.fat,               goalFat:      post.goalFat
                    )
                } else {
                    macroRow
                }
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

                    if showStreak && post.streak > 0 {
                        Text("🔥 \(post.streak)d streak")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(red: 1.0, green: 0.60, blue: 0.20))
                    }

                    if let label = PostLabel(rawValue: post.postLabel) {
                        let labelColor = feedPostLabelColor(label)
                        HStack(spacing: 3) {
                            Image(systemName: label.icon)
                                .font(.system(size: 8, weight: .bold))
                            if label == .mogBoard, !post.mogBoardScope.isEmpty {
                                Text("\(post.mogBoardScope) Mog")
                                    .font(.system(size: 9, weight: .bold))
                            } else {
                                Text(label.rawValue)
                                    .font(.system(size: 9, weight: .bold))
                            }
                        }
                        .foregroundStyle(labelColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(labelColor.opacity(0.15), in: Capsule())
                        .overlay(Capsule().stroke(labelColor.opacity(0.35), lineWidth: 0.75))
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

    // MARK: Mog Board snapshot card

    private var mogBoardSnapshotEntries: [MogBoardSnapshotEntry] {
        guard !post.mogBoardSnapshot.isEmpty,
              let data = post.mogBoardSnapshot.data(using: .utf8),
              let entries = try? JSONDecoder().decode([MogBoardSnapshotEntry].self, from: data)
        else { return [] }
        return entries
    }

    @ViewBuilder
    private var mogBoardSnapshotCard: some View {
        let gold    = Color(red: 1.0, green: 0.80, blue: 0.20)
        let entries = mogBoardSnapshotEntries
        let scoreLabel: String = {
            switch post.mogBoardType {
            case "Streak":     return "days"
            case "Engagement": return "score"
            default:           return "pts"
            }
        }()

        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "list.number")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(gold)
                Text(post.mogBoardType.isEmpty ? "Board" : post.mogBoardType)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(gold)
                Spacer()
                Text(scoreLabel.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.30))
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 6)

            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)

            VStack(spacing: 0) {
                ForEach(Array(entries.prefix(5).enumerated()), id: \.element.id) { rank, entry in
                    HStack(spacing: 8) {
                        Text("#\(rank + 1)")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(rank == 0 ? gold : .white.opacity(0.30))
                            .frame(width: 26, alignment: .trailing)
                        Text(entry.displayName.isEmpty ? "@\(entry.username)" : entry.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                        Spacer()
                        Text("\(entry.score)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(rank == 0 ? gold : .white.opacity(0.55))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(rank == 0 ? gold.opacity(0.07) : Color.clear)
                }
            }
            .padding(.vertical, 4)
        }
        .background(Color(red: 0.10, green: 0.07, blue: 0.18))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(gold.opacity(0.20), lineWidth: 1))
    }

    // MARK: Workout table

    private let workoutGreen = Color(red: 0.30, green: 0.90, blue: 0.55)

    @ViewBuilder
    private var workoutTable: some View {
        let sorted   = post.workoutItems.sorted { $0.sortOrder < $1.sortOrder }
        let totalCal = sorted.reduce(0) { $0 + $1.caloriesBurned }
        let totalMin = sorted.reduce(0) { $0 + $1.durationMinutes }
        let totalTime = totalMin >= 60 ? "\(totalMin / 60)h \(totalMin % 60)m" : "\(totalMin)m"
        VStack(alignment: .leading, spacing: 0) {
            ForEach(sorted) { item in
                workoutRow(item: item, isLast: item.id == sorted.last?.id)
            }
            if sorted.count > 1 {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                HStack {
                    Spacer()
                    Text("Total: \(totalTime) · \(totalCal) cal burned")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(workoutGreen.opacity(0.80))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
        }
        .background(Color(red: 0.10, green: 0.07, blue: 0.18))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(workoutGreen.opacity(0.20), lineWidth: 1))
    }

    private func workoutRow(item: FeedWorkoutItem, isLast: Bool) -> some View {
        let icon      = WorkoutType(rawValue: item.workoutType)?.icon ?? "figure.mixed.cardio"
        let typeLabel = WorkoutType(rawValue: item.workoutType)?.shortLabel ?? item.workoutType
        return VStack(spacing: 0) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(workoutGreen.opacity(0.12))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundStyle(workoutGreen)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.workoutName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.90))
                        .lineLimit(1)
                    Text("\(item.formattedDuration) · \(typeLabel)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.40))
                }
                Spacer()
                Text("\(item.caloriesBurned) cal")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(workoutGreen)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            if !isLast {
                Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1).padding(.horizontal, 10)
            }
        }
    }

    // MARK: Fuel log table

    private var fuelLogTable: some View {
        let sorted = post.fuelLogItems.sorted { $0.sortOrder < $1.sortOrder }
        let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(sorted) { item in
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        if !item.photoURL.isEmpty, let url = URL(string: item.photoURL) {
                            CachedAsyncImage(
                                url: url,
                                content: { img in
                                    img.resizable().scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipped().cornerRadius(8)
                                },
                                placeholder: {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.07))
                                        .frame(width: 40, height: 40)
                                        .overlay {
                                            Image(systemName: "fork.knife")
                                                .font(.system(size: 14))
                                                .foregroundStyle(.white.opacity(0.30))
                                        }
                                }
                            )
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
                            Text(item.foodName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("\(Int(item.calories)) kcal · \(Int(item.protein))g P · \(Int(item.carbs))g C · \(Int(item.fat))g F")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    if item.id != sorted.last?.id {
                        Divider().background(Color.white.opacity(0.08))
                    }
                }
            }
            Divider().background(purpl.opacity(0.40)).padding(.top, 4)
            HStack {
                Text("Total")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(post.calories) kcal · \(Int(post.protein))g P · \(Int(post.carbs))g C · \(Int(post.fat))g F")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(purpl)
            }
            .padding(.top, 8)
        }
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

    private func feedPostLabelColor(_ label: PostLabel) -> Color {
        switch label {
        case .transformation: return Color(red: 0.35, green: 0.75, blue: 1.00)
        case .fuelLog:        return Color(red: 1.00, green: 0.55, blue: 0.15)
        case .mealInspo:      return Color(red: 1.00, green: 0.30, blue: 0.55)
        case .mogBoard:       return Color(red: 1.00, green: 0.80, blue: 0.20)
        case .advice:         return Color(red: 1.00, green: 0.90, blue: 0.20)
        case .workout:        return Color(red: 0.30, green: 0.90, blue: 0.55)
        case .goalPost:       return Color(red: 0.65, green: 0.45, blue: 1.00)
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

// MARK: - Macro Discipline Card (shared by feed + post detail)

struct MacroDisciplineCard: View {
    let totalCalories: Double; let goalCalories:  Double
    let totalProtein:  Double; let goalProtein:   Double
    let totalCarbs:    Double; let goalCarbs:     Double
    let totalFat:      Double; let goalFat:       Double

    private let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let neon   = Color(red: 0.35, green: 1.00, blue: 0.60)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)

    private var disciplineProgress: Double {
        let pairs = [(totalCalories, goalCalories), (totalProtein, goalProtein),
                     (totalCarbs, goalCarbs), (totalFat, goalFat)]
        let active = pairs.filter { $0.1 > 0 }
        guard !active.isEmpty else { return 0 }
        return active.reduce(0.0) { $0 + max(0, 1.0 - abs($1.0 / $1.1 - 1.0)) } / Double(active.count)
    }

    var body: some View {
        let pct    = Int((disciplineProgress * 100 / 5).rounded()) * 5
        let macros: [(String, Double, Double, String, Color)] = [
            ("Calories", totalCalories, goalCalories, "kcal", Color.calClr),
            ("Protein",  totalProtein,  goalProtein,  "g",    Color.proClr),
            ("Carbs",    totalCarbs,    goalCarbs,    "g",    Color.carbClr),
            ("Fat",      totalFat,      goalFat,      "g",    Color.fatClr),
        ]
        VStack(spacing: 10) {
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
                            Capsule().fill(Color.white.opacity(0.08)).frame(height: 5)
                            Capsule()
                                .fill(LinearGradient(
                                    colors: disciplineProgress >= 1.0
                                        ? [neon, Color(red: 0.20, green: 0.85, blue: 0.50)]
                                        : [purpl, Color(red: 0.35, green: 0.75, blue: 1.00)],
                                    startPoint: .leading, endPoint: .trailing))
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
            ForEach(Array(macros.enumerated()), id: \.offset) { _, macro in
                let (label, total, goal, unit, color) = macro
                let ratio  = goal > 0 ? min(total / goal, 1.0) : 0
                let macPct = goal > 0 ? Int((total / goal) * 100) : 0
                HStack(spacing: 8) {
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.70))
                        .frame(width: 60, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.07)).frame(height: 6)
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
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(purpl.opacity(0.20), lineWidth: 1))
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
