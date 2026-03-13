//
//  NewPostView.swift
//  Wellness
//

import SwiftUI
import SwiftData

// MARK: - Daily rotating prompts (cycles by day of year)

private let dailyStatusPrompts: [String] = [
    "Day \(Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1) of the grind 🔥",
    "Locked in today 💪",
    "Another day, another W",
    "Sigma mode: activated",
    "Built different today fr",
    "No days off. no cap.",
    "Mewing + macros = results",
    "Aura check ✅",
    "Roman emperor energy today",
    "The grind never stops",
    "Discipline > motivation",
    "Glow up in progress 📈",
    "Looksmaxxing arc continues",
    "Ate clean. hit the gym. mogged everyone.",
    "Peak performance unlocked",
    "Today's gains hit different",
    "Full send. no excuses.",
    "Protein up. fat down. aura skyrocketing.",
    "Another day I didn't skip",
    "Consistency is the cheat code",
    "The body keeps the score fr",
    "W day incoming",
    "Main character energy 🎬",
    "Physique arc loading…",
    "Macros tracked. mission complete.",
    "Gains secured 🔒",
    "Nourished and built 💀",
    "Today I chose discipline",
    "One step closer to final form",
    "No cap this hit different",
]

private let dailyBodyPrompts: [String] = [
    "Drop your check-in. macros, lifts, mindset — all of it.",
    "How'd you eat today? what got tracked, what got crushed?",
    "Tell the feed what you moved and what you fueled with.",
    "Give the boys a progress report. numbers, vibes, all that.",
    "What did you lock in on today? log it for the record.",
    "Protein count? gym session? mental fortitude? spill.",
    "Rate your day 1–10 and explain yourself to the feed.",
    "What meal hit the hardest today? what lift went crazy?",
    "Mogs achieved today? enemies of the grind defeated?",
    "Break it down — what did you eat, lift, and conquer?",
    "Post your W. the feed needs to know.",
    "Flex on the feed or confess to the feed. either way log it.",
    "What habits got locked in today? tell the timeline.",
    "Daily debrief: what went right, what do you build on?",
    "How's the looksmaxxing arc progressing? update us.",
    "Physique update. no filter. just results.",
    "What's the body saying today? fuel report incoming.",
    "Gym PR? meal PR? life PR? drop it here.",
    "Accountability check. what did you actually do today?",
    "Caloric performance + gym performance = today's aura.",
    "Show the feed your discipline today. they need to see it.",
    "Real ones log every day. what's today's entry?",
    "The algorithm rewards consistency. so does your physique.",
    "Paint the picture. what did the grind look like today?",
    "Progress > perfection. what moved the needle today?",
    "Sigma daily log: submit your report to the feed.",
    "This is your sign to log it before you forget.",
    "What got tracked today goes on the record forever.",
    "Grind recap: go.",
    "One day you'll look back at this. make it count.",
]

private func dailyIndex(for prompts: [String]) -> Int {
    let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    return (day - 1) % prompts.count
}

struct NewPostView: View {
    let userSettings: UserSettings

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var titleText = ""
    @State private var bodyText  = ""
    @State private var photos: [PostPhoto] = []
    @FocusState private var focus: Field?

    private enum Field: Hashable { case title, body }

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)

    private var statusPrompt: String { dailyStatusPrompts[dailyIndex(for: dailyStatusPrompts)] }
    private var bodyPrompt:   String { dailyBodyPrompts[dailyIndex(for: dailyBodyPrompts)] }

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        // Status
                        TextField(statusPrompt, text: $titleText)
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(cardBg)
                            .cornerRadius(12)
                            .focused($focus, equals: .title)
                            .submitLabel(.next)
                            .onSubmit { focus = .body }

                        // Body
                        ZStack(alignment: .topLeading) {
                            if bodyText.isEmpty {
                                Text(bodyPrompt)
                                    .foregroundStyle(.white.opacity(0.30))
                                    .padding(18)
                            }
                            TextEditor(text: $bodyText)
                                .foregroundStyle(.white)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 130)
                                .padding(10)
                                .focused($focus, equals: .body)
                        }
                        .background(cardBg)
                        .cornerRadius(12)

                        // Photos
                        MultiPhotoSection(photos: $photos)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { submit() }
                        .fontWeight(.bold)
                        .disabled(titleText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func submit() {
        let t = titleText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let post = SocialPost(
            authorID:          userSettings.userID,
            authorUsername:    userSettings.username.isEmpty ? "me" : userSettings.username,
            authorDisplayName: userSettings.name,
            memeEmoji:         "",
            memeHeadline:      t,
            memeSub:           bodyText.trimmingCharacters(in: .whitespaces),
            macroDate:         Date(),
            totalCalories: 0, goalCalories: 0,
            totalProtein:  0, goalProtein:  0,
            totalCarbs:    0, goalCarbs:    0,
            totalFat:      0, goalFat:      0
        )
        post.isCustomPost           = true
        post.authorAuraLevel        = userSettings.auraLevel
        post.authorAuraPoints       = userSettings.auraPoints
        post.authorLocation         = userSettings.location
        post.authorStreak           = userSettings.macroStreak
        post.isAuthorPrivate        = userSettings.isPrivateAccount
        post.authorProfileImageData = userSettings.profileImageData
        let datas = photos.map { $0.image.jpegData(compressionQuality: 0.8) }
        post.imageData  = datas.count > 0 ? datas[0] : nil
        post.imageData2 = datas.count > 1 ? datas[1] : nil
        post.imageData3 = datas.count > 2 ? datas[2] : nil
        post.imageData4 = datas.count > 3 ? datas[3] : nil
        modelContext.insert(post)
        dismiss()
    }
}
