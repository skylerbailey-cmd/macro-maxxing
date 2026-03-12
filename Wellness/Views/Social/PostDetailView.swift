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

    @State private var commentText = ""
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
                            macroBreakdown
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
                Circle()
                    .fill(purpl.opacity(0.25))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Text(String(post.authorDisplayName.prefix(1)).uppercased())
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(purpl)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorDisplayName.isEmpty ? post.authorUsername : post.authorDisplayName)
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    Text("@\(post.authorUsername)  ·  \(post.macroDate, style: .date)")
                        .font(.caption2).foregroundStyle(.white.opacity(0.35))
                }
                Spacer()
            }

            // Meme
            Text(post.memeEmoji).font(.system(size: 56))
            Text(post.memeHeadline)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(post.memeSub)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(cardBg)
        .cornerRadius(16)
    }

    // MARK: Macro breakdown (food log summary for this user on that day)

    private var macroBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Macros that day")
                    .font(.headline).foregroundStyle(.white)
                Spacer()
                Text(post.macroDate, style: .date)
                    .font(.caption).foregroundStyle(.white.opacity(0.35))
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                macroCell("Calories", value: post.totalCalories, goal: post.goalCalories,
                          color: Color(red: 1.00, green: 0.55, blue: 0.15), unit: "kcal")
                macroCell("Protein",  value: post.totalProtein,  goal: post.goalProtein,
                          color: Color(red: 0.35, green: 0.75, blue: 1.00), unit: "g")
                macroCell("Carbs",    value: post.totalCarbs,    goal: post.goalCarbs,
                          color: Color(red: 0.40, green: 0.90, blue: 0.72), unit: "g")
                macroCell("Fat",      value: post.totalFat,      goal: post.goalFat,
                          color: Color(red: 1.00, green: 0.50, blue: 0.72), unit: "g")
            }
        }
        .padding(14)
        .background(cardBg)
        .cornerRadius(16)
    }

    private func macroCell(_ label: String, value: Double, goal: Double,
                            color: Color, unit: String) -> some View {
        let pct = goal > 0 ? min(value / goal, 1.0) : 0
        return VStack(spacing: 4) {
            ZStack {
                Circle().trim(from: 0, to: 0.75)
                    .stroke(color.opacity(0.15),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(135))
                Circle().trim(from: 0, to: pct * 0.75)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(135))
                Text("\(Int(value))\(unit == "kcal" ? "" : unit)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 60, height: 60)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.55))
            Text("/ \(Int(goal))\(unit)").font(.system(size: 9)).foregroundStyle(.white.opacity(0.30))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(red: 0.10, green: 0.07, blue: 0.18))
        .cornerRadius(12)
    }

    // MARK: Comments

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Comments (\(post.comments.count))")
                .font(.headline).foregroundStyle(.white)

            if post.comments.isEmpty {
                Text("No comments yet. Be the first!")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.30))
                    .padding(.vertical, 8)
            } else {
                ForEach(post.comments.sorted(by: { $0.postedAt < $1.postedAt })) { comment in
                    commentRow(comment)
                }
            }
        }
        .padding(14)
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
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(comment.authorDisplayName.isEmpty ? comment.authorUsername : comment.authorDisplayName)
                        .font(.caption.weight(.semibold)).foregroundStyle(.white)
                    Text(comment.postedAt, style: .relative)
                        .font(.caption2).foregroundStyle(.white.opacity(0.30))
                }
                Text(comment.text)
                    .font(.subheadline).foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
        }
    }

    // MARK: Comment input bar

    private var commentBar: some View {
        HStack(spacing: 10) {
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
                    .foregroundStyle(commentText.isEmpty ? .white.opacity(0.25) : purpl)
            }
            .disabled(commentText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(red: 0.07, green: 0.05, blue: 0.12))
    }

    private func submitComment() {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let comment = SocialComment(
            authorID:          userSettings.userID,
            authorUsername:    userSettings.username.isEmpty ? "me" : userSettings.username,
            authorDisplayName: userSettings.name,
            text:              text,
            post:              post
        )
        post.comments.append(comment)
        modelContext.insert(comment)
        commentText   = ""
        commentFocused = false
    }
}
