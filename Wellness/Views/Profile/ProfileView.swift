//
//  ProfileView.swift
//  Wellness
//

import SwiftUI
import SwiftData

// MARK: - ProfileView

struct ProfileView: View {
    // Profile being viewed
    let profileUserID:       String
    let profileUsername:     String
    let profileDisplayName:  String
    let profileAuraLevel:    Int
    let profileAuraPoints:   Int
    let profileImageData:    Data?

    /// Non-nil only when viewing your own profile (enables photo editing)
    var ownUserSettings: UserSettings? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @Query(sort: \SocialPost.repsCount, order: .reverse) private var allPosts: [SocialPost]
    @Query private var friends: [Friend]

    @State private var showingCamera = false
    @State private var newProfileImage: UIImage?
    @State private var selectedPost: SocialPost?

    private var isOwnProfile: Bool { ownUserSettings != nil }

    private var userPosts: [SocialPost] {
        allPosts.filter {
            $0.authorID == profileUserID ||
            $0.authorUsername.lowercased() == profileUsername.lowercased()
        }
    }

    private var isAlreadyFriend: Bool {
        friends.contains { $0.username.lowercased() == profileUsername.lowercased() }
    }

    private var displayName: String {
        profileDisplayName.isEmpty ? profileUsername : profileDisplayName
    }

    private var avatarImageData: Data? {
        if isOwnProfile {
            return newProfileImage?.jpegData(compressionQuality: 0.8) ?? ownUserSettings?.profileImageData
        }
        return profileImageData
    }

    private let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    postsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle(isOwnProfile ? "My Profile" : displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCamera, onDismiss: saveNewPhoto) {
            ImagePickerView(sourceType: .camera, selectedImage: $newProfileImage)
        }
        .sheet(item: $selectedPost) { post in
            if let settings = ownUserSettings {
                PostDetailView(post: post, userSettings: settings)
            }
        }
    }

    // MARK: - Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            Button {
                if isOwnProfile { showingCamera = true }
            } label: {
                avatarView(size: 90)
                    .overlay(alignment: .bottomTrailing) {
                        if isOwnProfile {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(purpl)
                                .clipShape(Circle())
                                .offset(x: 4, y: 4)
                        }
                    }
            }
            .buttonStyle(.plain)
            .disabled(!isOwnProfile)

            // Name + handle
            VStack(spacing: 4) {
                Text(displayName)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                if !profileUsername.isEmpty {
                    Text("@\(profileUsername)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
                }
            }

            // Aura badge
            if profileAuraPoints > 0 {
                HStack(spacing: 8) {
                    Text("⭐")
                    VStack(spacing: 2) {
                        Text("Lv \(profileAuraLevel)\(auraTitleString.isEmpty ? "" : " · \(auraTitleString)")")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(gold)
                        Text("\(profileAuraPoints) aura pts")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.40))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(cardBg)
                .cornerRadius(12)
            }

            // Add to Team (only on others' profiles)
            if !isOwnProfile {
                Button {
                    addFriend()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isAlreadyFriend ? "checkmark.circle.fill" : "person.badge.plus")
                        Text(isAlreadyFriend ? "On Your Team" : "Add to Team")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isAlreadyFriend ? Color.green.opacity(0.30) : purpl.opacity(0.80))
                    .cornerRadius(14)
                }
                .disabled(isAlreadyFriend)
            }
        }
        .padding(18)
        .background(cardBg)
        .cornerRadius(18)
    }

    private var auraTitleString: String {
        switch profileAuraLevel {
        case 0:       return ""
        case 1...9:   return "Initiate"
        case 10...24: return "Disciple"
        case 25...39: return "Ascender"
        case 40...59: return "Mog Apprentice"
        case 60...79: return "Aura Farmer"
        case 80...94: return "Elite Aesthetic"
        default:      return "Final Form"
        }
    }

    // MARK: - Posts

    private var postsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Posts")
                .font(.headline)
                .foregroundStyle(.white)

            if userPosts.isEmpty {
                Text("No posts yet.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.30))
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(userPosts) { post in
                    ProfilePostRow(post: post, userID: profileUserID)
                        .onTapGesture { selectedPost = post }
                }
            }
        }
    }

    // MARK: - Avatar helper

    @ViewBuilder
    func avatarView(size: CGFloat) -> some View {
        if let data = avatarImageData, let uiImg = UIImage(data: data) {
            Image(uiImage: uiImg)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(purpl.opacity(0.25))
                .frame(width: size, height: size)
                .overlay {
                    Text(String(displayName.prefix(1)).uppercased())
                        .font(.system(size: size * 0.40, weight: .bold, design: .rounded))
                        .foregroundStyle(purpl)
                }
        }
    }

    // MARK: - Actions

    private func saveNewPhoto() {
        guard let img = newProfileImage, let data = img.jpegData(compressionQuality: 0.75) else { return }
        ownUserSettings?.profileImageData = data
    }

    private func addFriend() {
        guard !isAlreadyFriend else { return }
        let friend = Friend(
            userID:      profileUserID,
            username:    profileUsername,
            displayName: profileDisplayName
        )
        modelContext.insert(friend)
    }
}

// MARK: - Compact post row for profile

private struct ProfilePostRow: View {
    @Bindable var post: SocialPost
    let userID: String

    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if post.isCustomPost {
                    Text(post.memeHeadline)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                } else {
                    Text(post.memeEmoji + "  " + post.memeHeadline.replacingOccurrences(of: "\n", with: " "))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("💪").font(.system(size: 13))
                    Text("\(post.repsCount)").font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.60))
                }
            }
            if !post.memeSub.isEmpty {
                Text(post.memeSub)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(2)
            }
            Text(post.postedAt, style: .date)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(12)
        .background(cardBg)
        .cornerRadius(14)
    }
}
