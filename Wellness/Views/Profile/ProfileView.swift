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
    var profileLocation:     String = ""

    /// Non-nil only when viewing your own profile (enables photo editing)
    var ownUserSettings: UserSettings? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @Query(sort: \SocialPost.repsCount, order: .reverse) private var allPosts: [SocialPost]
    @Query private var friends: [Friend]

    @State private var showingCamera = false
    @State private var newProfileImage: UIImage?
    @State private var selectedPost: SocialPost?
    @State private var showingProfileShare = false

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

    /// Resolved UIImage for the avatar — uses UIImage directly to avoid JPEG round-trips.
    private var resolvedAvatarImage: UIImage? {
        if isOwnProfile {
            if let img = newProfileImage { return img }
            if let data = ownUserSettings?.profileImageData { return UIImage(data: data) }
            return nil
        }
        if let data = profileImageData { return UIImage(data: data) }
        return nil
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
        .toolbar {
            if isOwnProfile {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingProfileShare = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera, onDismiss: saveNewPhoto) {
            ImagePickerView(sourceType: .camera, selectedImage: $newProfileImage)
        }
        .sheet(isPresented: $showingProfileShare) {
            ProfileShareView(
                displayName:     profileDisplayName.isEmpty ? profileUsername : profileDisplayName,
                username:        profileUsername,
                auraLevel:       profileAuraLevel,
                auraPoints:      profileAuraPoints,
                auraTitleString: auraTitleString,
                profileImage:    resolvedAvatarImage
            )
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

            // Name + handle + location
            VStack(spacing: 4) {
                Text(displayName)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                if !profileUsername.isEmpty {
                    Text("@\(profileUsername)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
                }
                if !profileLocation.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(purpl.opacity(0.60))
                        Text(profileLocation)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.50))
                    }
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

            // Social links (own profile only, shown when set)
            if isOwnProfile {
                let ig = ownUserSettings?.instagramHandle.trimmingCharacters(in: .whitespaces) ?? ""
                let tt = ownUserSettings?.tiktokHandle.trimmingCharacters(in: .whitespaces) ?? ""
                if !ig.isEmpty || !tt.isEmpty {
                    HStack(spacing: 12) {
                        if !ig.isEmpty {
                            Button {
                                let appURL  = URL(string: "instagram://user?username=\(ig)")!
                                let webURL  = URL(string: "https://instagram.com/\(ig)")!
                                if UIApplication.shared.canOpenURL(appURL) {
                                    UIApplication.shared.open(appURL)
                                } else {
                                    UIApplication.shared.open(webURL)
                                }
                            } label: {
                                socialBadge(
                                    icon: "camera.fill",
                                    label: "@\(ig)",
                                    gradient: [Color(red: 1.0, green: 0.55, blue: 0.0),
                                               Color(red: 0.95, green: 0.2, blue: 0.55),
                                               Color(red: 0.55, green: 0.15, blue: 0.9)]
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        if !tt.isEmpty {
                            Button {
                                let appURL  = URL(string: "tiktok://user?username=\(tt)")!
                                let webURL  = URL(string: "https://www.tiktok.com/@\(tt)")!
                                if UIApplication.shared.canOpenURL(appURL) {
                                    UIApplication.shared.open(appURL)
                                } else {
                                    UIApplication.shared.open(webURL)
                                }
                            } label: {
                                socialBadge(
                                    icon: "music.note",
                                    label: "@\(tt)",
                                    gradient: [Color(red: 0.1, green: 0.1, blue: 0.1),
                                               Color(red: 0.25, green: 0.25, blue: 0.25)]
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
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

    // MARK: - Social badge helper

    @ViewBuilder
    private func socialBadge(icon: String, label: String, gradient: [Color]) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(20)
    }

    // MARK: - Avatar helper

    @ViewBuilder
    func avatarView(size: CGFloat) -> some View {
        if let uiImg = resolvedAvatarImage {
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
            // Post images (up to 4)
            if !post.allImageDatas.isEmpty {
                PostImagesView(imageDatas: post.allImageDatas)
            }

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
