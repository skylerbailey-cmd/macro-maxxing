//
//  SocialView.swift
//  Wellness
//

import SwiftUI
import SwiftData
import Contacts
import ContactsUI

// MARK: - Color palette

private extension Color {
    static let pageBg   = Color(red: 0.07, green: 0.05, blue: 0.12)
    static let cardBg   = Color(red: 0.13, green: 0.10, blue: 0.22)
    static let purpleHi = Color(red: 0.65, green: 0.45, blue: 1.00)
}

// MARK: - SocialView

struct SocialView: View {
    let userSettings: UserSettings

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SocialPost.postedAt, order: .reverse) private var posts: [SocialPost]
    @Query(sort: \Friend.addedAt,      order: .reverse) private var friends: [Friend]

    @State private var showingAddFriend = false
    @State private var showingNewPost   = false
    @State private var selectedPost: SocialPost?

    var body: some View {
        ZStack {
            Color.pageBg.ignoresSafeArea()

            if posts.isEmpty {
                emptyFeed
            } else {
                List {
                    ForEach(posts) { post in
                        PostCard(post: post, userID: userSettings.userID)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedPost = post }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    modelContext.delete(post)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(
                                EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16)
                            )
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Social")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { showingNewPost = true } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(Color.purpleHi)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAddFriend = true } label: {
                    Image(systemName: "person.badge.plus")
                        .foregroundStyle(Color.purpleHi)
                }
            }
        }
        .sheet(isPresented: $showingNewPost) {
            NewPostView(userSettings: userSettings)
        }
        .sheet(isPresented: $showingAddFriend) {
            AddFriendView(userSettings: userSettings, friends: friends)
        }
        .sheet(item: $selectedPost) { post in
            PostDetailView(post: post, userSettings: userSettings)
        }
    }

    private var emptyFeed: some View {
        VStack(spacing: 14) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.15))
            Text("No posts yet")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.35))
            Text("Hit all your macro goals and post from the celebration screen,\nor tap ✏️ to write your own post.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.22))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Post card

struct PostCard: View {
    @Bindable var post: SocialPost
    let userID: String

    private let colCal  = Color(red: 1.00, green: 0.55, blue: 0.15)
    private let colPro  = Color(red: 0.35, green: 0.75, blue: 1.00)
    private let colCarb = Color(red: 0.40, green: 0.90, blue: 0.72)
    private let colFat  = Color(red: 1.00, green: 0.50, blue: 0.72)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            authorHeader

            if post.isCustomPost {
                customBody
            } else {
                achievementBody
            }

            // Reps + comments
            HStack(spacing: 16) {
                // 💪 Rep button
                Button {
                    post.toggleRep(userID: userID)
                } label: {
                    HStack(spacing: 5) {
                        Text("💪")
                            .font(.system(size: 14))
                        Text("\(post.repsCount)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(
                                post.hasRepped(userID: userID)
                                    ? Color(red: 1.0, green: 0.75, blue: 0.2)
                                    : .white.opacity(0.35)
                            )
                        Text("Reps")
                            .font(.caption)
                            .foregroundStyle(
                                post.hasRepped(userID: userID)
                                    ? Color(red: 1.0, green: 0.75, blue: 0.2)
                                    : .white.opacity(0.35)
                            )
                    }
                }
                .buttonStyle(.plain)

                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 12))
                    Text("\(post.comments.count)")
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.35))

                Spacer()
            }
        }
        .padding(14)
        .background(Color.cardBg)
        .cornerRadius(16)
    }

    private var authorHeader: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.purpleHi.opacity(0.25))
                .frame(width: 38, height: 38)
                .overlay {
                    Text(String(post.authorDisplayName.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.purpleHi)
                }
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
                Text("@\(post.authorUsername)  ·  \(post.postedAt, style: .relative)")
                    .font(.caption2).foregroundStyle(.white.opacity(0.35))
            }
            Spacer()
            if !post.isCustomPost { Text(post.memeEmoji).font(.title2) }
        }
    }

    // Custom post: image + title + body
    @ViewBuilder
    private var customBody: some View {
        if let data = post.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .clipped()
                .cornerRadius(10)
        }
        Text(post.memeHeadline)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
        if !post.memeSub.isEmpty {
            Text(post.memeSub)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .lineLimit(3)
        }
    }

    // Achievement post: meme + macro rings
    @ViewBuilder
    private var achievementBody: some View {
        Text(post.memeHeadline.replacingOccurrences(of: "\n", with: " "))
            .font(.system(size: 15, weight: .black, design: .rounded))
            .foregroundStyle(.white)
        Text(post.memeSub)
            .font(.caption).foregroundStyle(.white.opacity(0.50))
        HStack(spacing: 10) {
            ForEach(Array(zip(
                [colCal, colPro, colCarb, colFat],
                [post.totalCalories / max(post.goalCalories, 1),
                 post.totalProtein  / max(post.goalProtein,  1),
                 post.totalCarbs    / max(post.goalCarbs,    1),
                 post.totalFat      / max(post.goalFat,      1)]
            ).enumerated()), id: \.offset) { _, pair in
                let (color, pct) = pair
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 28, height: 28)
                    Circle()
                        .trim(from: 0, to: min(pct, 1))
                        .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 28, height: 28)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Add Friend sheet

struct AddFriendView: View {
    let userSettings: UserSettings
    let friends: [Friend]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var usernameInput  = ""
    @State private var showContacts   = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pageBg.ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Add by Username")
                            .font(.headline).foregroundStyle(.white)
                        HStack(spacing: 10) {
                            TextField("@username", text: $usernameInput)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            Button("Add") { addByUsername() }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.purpleHi)
                        }
                        if let err = errorMessage {
                            Text(err).font(.caption).foregroundStyle(.red)
                        }
                    }
                    .padding(16).background(Color.cardBg).cornerRadius(14)

                    Button { showContacts = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "person.crop.circle")
                            Text("Add from Contacts").font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.cardBg).foregroundStyle(.white).cornerRadius(14)
                    }

                    if !friends.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Friends (\(friends.count))")
                                .font(.headline).foregroundStyle(.white)
                            ForEach(friends) { friend in
                                HStack {
                                    Circle().fill(Color.purpleHi.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                        .overlay {
                                            Text(String(friend.displayName.prefix(1)).uppercased())
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(Color.purpleHi)
                                        }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(friend.displayName).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                                        Text("@\(friend.username)").font(.caption2).foregroundStyle(.white.opacity(0.40))
                                    }
                                    Spacer()
                                    Button(role: .destructive) { modelContext.delete(friend) } label: {
                                        Image(systemName: "person.badge.minus").foregroundStyle(.red.opacity(0.65))
                                    }
                                }
                                .padding(10).background(Color.cardBg).cornerRadius(12)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.top, 16)
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Friends").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .sheet(isPresented: $showContacts) {
            ContactPickerView { name in
                addFriend(username: name.lowercased().replacingOccurrences(of: " ", with: ""),
                          displayName: name)
            }
        }
    }

    private func addByUsername() {
        let handle = usernameInput.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased().replacingOccurrences(of: "@", with: "")
        guard !handle.isEmpty else { errorMessage = "Enter a username."; return }
        if handle == userSettings.username { errorMessage = "That's you!"; return }
        if friends.contains(where: { $0.username == handle }) { errorMessage = "Already added."; return }
        addFriend(username: handle, displayName: handle)
        usernameInput = ""; errorMessage = nil
    }

    private func addFriend(username: String, displayName: String) {
        modelContext.insert(Friend(username: username, displayName: displayName))
    }
}

// MARK: - Contacts picker

private struct ContactPickerView: UIViewControllerRepresentable {
    let onSelect: (String) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onSelect: onSelect) }
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let p = CNContactPickerViewController(); p.delegate = context.coordinator; return p
    }
    func updateUIViewController(_: CNContactPickerViewController, context: Context) {}
    class Coordinator: NSObject, CNContactPickerDelegate {
        let onSelect: (String) -> Void
        init(onSelect: @escaping (String) -> Void) { self.onSelect = onSelect }
        func contactPicker(_: CNContactPickerViewController, didSelect c: CNContact) {
            let name = [c.givenName, c.familyName].filter { !$0.isEmpty }.joined(separator: " ")
            onSelect(name.isEmpty ? "Friend" : name)
        }
    }
}
