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
    @State private var selectedFeed: Feed = .team
    @State private var viewingProfile: SocialPost? = nil

    enum Feed: String, CaseIterable {
        case team  = "The Team"
        case local = "Local"
        case arena = "The Arena"
    }

    private var teamPosts: [SocialPost] {
        let friendUsernames = Set(friends.map { $0.username.lowercased() })
        return posts.filter { post in
            post.authorID == userSettings.userID ||
            friendUsernames.contains(post.authorUsername.lowercased())
        }
    }

    private var localPosts: [SocialPost] {
        let myCity = cityKey(userSettings.location)
        guard !myCity.isEmpty else { return [] }
        return posts.filter { post in
            post.authorID == userSettings.userID ||
            (cityKey(post.authorLocation) == myCity && isVisible(post))
        }
    }

    /// Normalizes a location string to just the city name for loose matching.
    /// "Austin, Texas, United States" and "Austin, TX" both become "austin".
    private func cityKey(_ location: String) -> String {
        (location.split(separator: ",", maxSplits: 1).first ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private var arenaPosts: [SocialPost] {
        posts.filter { $0.authorID == userSettings.userID || isVisible($0) }
    }

    private var displayedPosts: [SocialPost] {
        switch selectedFeed {
        case .team:  return ranked(teamPosts)
        case .local: return ranked(localPosts)
        case .arena: return ranked(arenaPosts)
        }
    }

    /// Returns true if a post from another user should be visible to the current user.
    /// Private-account posts are hidden unless the author is already on the current user's team.
    private func isVisible(_ post: SocialPost) -> Bool {
        guard post.isAuthorPrivate else { return true }
        let friendUsernames = Set(friends.map { $0.username.lowercased() })
        return friendUsernames.contains(post.authorUsername.lowercased())
    }

    /// Ranks posts by a blend of engagement and recency.
    /// Posts under 1 hour old get a decaying boost (up to +30) on top of their engagement score.
    /// Engagement: reps + comments × 2 (comments weighted higher — more effort than a rep).
    private func ranked(_ input: [SocialPost]) -> [SocialPost] {
        let now = Date()
        return input.sorted { a, b in
            feedScore(a, now: now) > feedScore(b, now: now)
        }
    }

    private func feedScore(_ post: SocialPost, now: Date) -> Double {
        let ageHours    = max(0, now.timeIntervalSince(post.postedAt) / 3600)
        let engagement  = Double(post.repsCount) + Double(post.comments.count) * 2.0
        // Large boost in the first hour, then a smaller tail that fades to zero at 24 hours
        let firstHourBoost = ageHours < 1  ? (1.0 - ageHours) * 20.0        : 0.0
        let dailyBoost     = ageHours < 24 ? (1.0 - ageHours / 24.0) * 10.0 : 0.0
        return engagement + firstHourBoost + dailyBoost
    }

    var body: some View {
        ZStack {
            Color.pageBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Picker("Feed", selection: $selectedFeed) {
                    ForEach(Feed.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if displayedPosts.isEmpty {
                    emptyFeed
                } else {
                    List {
                        ForEach(displayedPosts) { post in
                            PostCard(post: post, userID: userSettings.userID,
                                     userSettings: userSettings,
                                     onAvatarTap: { viewingProfile = post })
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
                                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Aura Stream")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { showingNewPost = true } label: {
                    Image(systemName: "square.and.pencil").foregroundStyle(Color.purpleHi)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAddFriend = true } label: {
                    Image(systemName: "person.badge.plus").foregroundStyle(Color.purpleHi)
                }
            }
        }
        .sheet(isPresented: $showingNewPost) { NewPostView(userSettings: userSettings) }
        .sheet(isPresented: $showingAddFriend) { AddFriendView(userSettings: userSettings, friends: friends) }
        .sheet(item: $selectedPost) { post in PostDetailView(post: post, userSettings: userSettings) }
        .sheet(item: $viewingProfile) { post in
            NavigationStack {
                ProfileView(
                    profileUserID:      post.authorID,
                    profileUsername:    post.authorUsername,
                    profileDisplayName: post.authorDisplayName,
                    profileAuraLevel:   post.authorAuraLevel,
                    profileAuraPoints:  post.authorAuraPoints,
                    profileImageData:   post.authorProfileImageData,
                    profileLocation:    post.authorLocation,
                    ownUserSettings:    post.authorID == userSettings.userID ? userSettings : nil
                )
            }
            .presentationDetents([.large])
        }
    }

    @ViewBuilder
    private var emptyFeed: some View {
        let noLocation = selectedFeed == .local && userSettings.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        VStack(spacing: 14) {
            Image(systemName: selectedFeed == .team
                  ? "person.2" : selectedFeed == .local
                  ? "mappin.circle" : "figure.strengthtraining.traditional")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.15))
            Text(selectedFeed == .team ? "The Team is quiet"
                 : noLocation ? "No location set"
                 : selectedFeed == .local ? "No local posts yet"
                 : "The Arena is empty")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.35))
            Text(selectedFeed == .team
                 ? "Add friends from the + button above, then their posts will appear here."
                 : noLocation
                 ? "Go to Settings → Account to set your city. Local shows posts from people in your area."
                 : selectedFeed == .local ? "No one in your area has posted yet. Be the first."
                 : "Hit all your macro goals and post from the celebration screen, or tap ✏️ to drop a post.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.22))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Post card

// Reusable avatar circle used by PostCard and PostDetailView
func avatarCircle(size: CGFloat, data: Data?, initial: String) -> some View {
    Group {
        if let d = data, let img = UIImage(data: d) {
            Image(uiImage: img)
                .resizable().scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.25))
                .frame(width: size, height: size)
                .overlay {
                    Text(String(initial.prefix(1)).uppercased())
                        .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.0))
                }
        }
    }
}

struct PostCard: View {
    @Bindable var post: SocialPost
    let userID: String
    let userSettings: UserSettings
    var onAvatarTap: (() -> Void)? = nil


    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            authorHeader

            if !post.fuelLogEntries.isEmpty {
                fuelLogBody
            } else if post.isCustomPost {
                customBody
            } else {
                achievementBody
            }

            // Reps + comments (right-aligned)
            HStack(spacing: 16) {
                Spacer()
                // 💪 Rep button
                Button {
                    let isNewRep = !post.hasRepped(userID: userID)
                    post.toggleRep(userID: userID)
                    if isNewRep {
                        userSettings.awardAura(points: 1, silent: true)
                    }
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
            }
        }
        .padding(14)
        .background(Color.cardBg)
        .cornerRadius(16)
    }

    private var authorHeader: some View {
        HStack(spacing: 10) {
            // Tappable avatar
            Button(action: { onAvatarTap?() }) {
                avatarCircle(size: 38, data: post.authorProfileImageData,
                             initial: post.authorDisplayName)
            }
            .buttonStyle(.plain)
            .disabled(onAvatarTap == nil)
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
                Text("@\(post.authorUsername)  ·  \(post.postedAt, format: .dateTime.month(.abbreviated).day().hour().minute())")
                    .font(.caption2).foregroundStyle(.white.opacity(0.35))
            }
            Spacer()
            if !post.isCustomPost {
                Text(post.memeEmoji)
                    .font(post.memeEmoji.count > 2 ? .subheadline.weight(.bold) : .title2)
                    .foregroundStyle(
                        post.memeEmoji.hasPrefix("⭐")
                            ? Color(red: 1.0, green: 0.80, blue: 0.20)
                            : .white
                    )
            }
        }
    }

    // Custom post: image + title + body
    @ViewBuilder
    private var customBody: some View {
        if !post.allImageDatas.isEmpty {
            PostImagesView(imageDatas: post.allImageDatas)
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

    // Achievement post: optional photo + meme + macro summary
    @ViewBuilder
    private var achievementBody: some View {
        if !post.allImageDatas.isEmpty {
            PostImagesView(imageDatas: post.allImageDatas)
        }
        Text(post.memeHeadline.replacingOccurrences(of: "\n", with: " "))
            .font(.system(size: 15, weight: .black, design: .rounded))
            .foregroundStyle(.white)
        Text(post.memeSub)
            .font(.caption).foregroundStyle(.white.opacity(0.50))

        if post.goalCalories > 0 {
            macroSummaryRow
        }
    }

    @ViewBuilder
    private var macroSummaryRow: some View {
        let items: [(String, Double, Double, Color)] = [
            ("Cal",  post.totalCalories, post.goalCalories, Color(red: 1.00, green: 0.55, blue: 0.15)),
            ("Pro",  post.totalProtein,  post.goalProtein,  Color(red: 0.35, green: 0.75, blue: 1.00)),
            ("Carb", post.totalCarbs,    post.goalCarbs,    Color(red: 0.40, green: 0.90, blue: 0.72)),
            ("Fat",  post.totalFat,      post.goalFat,      Color(red: 1.00, green: 0.50, blue: 0.72)),
        ]
        HStack(spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                let (label, actual, goal, color) = item
                let met: Bool = label == "Cal"
                    ? actual >= goal * 0.85 && actual <= goal * 1.15
                    : actual >= goal * 0.85
                VStack(spacing: 3) {
                    ZStack {
                        Circle()
                            .fill(met ? color.opacity(0.20) : Color.white.opacity(0.06))
                            .frame(width: 30, height: 30)
                        if met {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(color)
                        } else {
                            Text("\(Int((actual / max(goal, 1)) * 100))%")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white.opacity(0.40))
                        }
                    }
                    Text(label)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.40))
                }
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    // Fuel log post: visual meal table matching the preview
    @ViewBuilder
    private var fuelLogBody: some View {
        let sorted = post.fuelLogEntries.sorted { $0.sortOrder < $1.sortOrder }
        let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
        let totalCal = sorted.reduce(0.0) { $0 + $1.calories }
        let totalPro = sorted.reduce(0.0) { $0 + $1.protein  }
        let totalCarb = sorted.reduce(0.0) { $0 + $1.carbs   }
        let totalFat = sorted.reduce(0.0) { $0 + $1.fat      }

        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Today's Fuel Log 🔥")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, 10)

            // Optional user message
            if !post.memeSub.isEmpty {
                Text(post.memeSub)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.bottom, 10)
            }

            // Entries
            ForEach(sorted) { entry in
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        if let data = entry.imageData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipped()
                                .cornerRadius(8)
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
                    .padding(.vertical, 8)

                    if entry.id != sorted.last?.id {
                        Divider().background(Color.white.opacity(0.08))
                    }
                }
            }

            // Totals row
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
