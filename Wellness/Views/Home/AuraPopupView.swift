//
//  AuraPopupView.swift
//  Wellness
//

import SwiftUI
import SwiftData

struct AuraPopupView: View {
    let award:       UserSettings.AuraAward
    let auraLevel:   Int
    let auraTitle:   String
    let totalPoints: Int
    let userSettings: UserSettings
    let onDismiss:   () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var scale:      CGFloat = 0.3
    @State private var opacity:    Double  = 0
    @State private var bgOpacity:  Double  = 0
    @State private var postedToFeed = false

    var body: some View {
        ZStack {
            Color.black.opacity(bgOpacity * 0.60)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Text("⭐")
                    .font(.system(size: 60))

                Text("+\(award.points) Aura")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.85, blue: 0.2),
                                     Color(red: 1.0, green: 0.55, blue: 0.15)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )

                Text(award.reason)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                // Current standing
                VStack(spacing: 4) {
                    Text("Level \(auraLevel)\(auraTitle.isEmpty ? "" : " · \(auraTitle)")")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.0))
                    Text("\(totalPoints) total aura pts")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.40))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 16)
                .background(Color(red: 0.13, green: 0.10, blue: 0.22))
                .cornerRadius(10)

                // Hype message
                Text(award.message)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                // Post to Feed button
                Button {
                    postToFeed()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: postedToFeed ? "checkmark.circle.fill" : "person.2.fill")
                        Text(postedToFeed ? "Posted!" : "Post to Feed")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        postedToFeed
                            ? Color.green.opacity(0.30)
                            : Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.35)
                    )
                    .cornerRadius(14)
                }
                .disabled(postedToFeed)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.16, green: 0.10, blue: 0.28),
                                 Color(red: 0.07, green: 0.04, blue: 0.14)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .shadow(color: Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.35), radius: 30)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.40), lineWidth: 1.5)
            )
            .padding(.horizontal, 28)
            .overlay(alignment: .topTrailing) {
                Button(action: animatedDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white.opacity(0.50))
                        .padding(14)
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.15)) { bgOpacity = 1 }
            withAnimation(.spring(duration: 0.50, bounce: 0.40).delay(0.05)) {
                scale = 1.0; opacity = 1.0
            }
        }
    }

    private func postToFeed() {
        guard !postedToFeed else { return }
        let post = SocialPost(
            authorID:          userSettings.userID,
            authorUsername:    userSettings.username.isEmpty ? "me" : userSettings.username,
            authorDisplayName: userSettings.name,
            memeEmoji:         "⭐",
            memeHeadline:      award.reason,
            memeSub:           "\(award.message) +\(award.points) aura pts",
            macroDate:         Date(),
            totalCalories: 0, goalCalories: 0,
            totalProtein:  0, goalProtein:  0,
            totalCarbs:    0, goalCarbs:    0,
            totalFat:      0, goalFat:      0
        )
        post.isCustomPost    = false
        post.authorAuraLevel = userSettings.auraLevel
        modelContext.insert(post)
        withAnimation { postedToFeed = true }
    }

    private func animatedDismiss() {
        withAnimation(.easeIn(duration: 0.15)) {
            scale = 0.85; opacity = 0; bgOpacity = 0
        }
        Task {
            try? await Task.sleep(for: .seconds(0.2))
            onDismiss()
        }
    }
}
