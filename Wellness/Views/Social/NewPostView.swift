//
//  NewPostView.swift
//  Wellness
//

import SwiftUI
import SwiftData
import CoreLocation

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
    @Environment(LocationManager.self) private var locationManager

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @Query(sort: \FoodEntry.loggedAt) private var allFoodEntries: [FoodEntry]

    @State private var titleText     = ""
    @State private var bodyText      = ""
    @State private var photos:       [PostPhoto] = []
    @State private var selectedLabel:      PostLabel? = nil
    @State private var mogBoardScope:      String     = "Arena"
    @State private var mogBoardType:       String     = "Weekly Aura"
    @FocusState private var focus: Field?

    private let mogBoardScopes = ["Team", "Local", "Arena"]
    private let mogBoardTypes  = ["Weekly Aura", "Engagement", "Streak"]

    private enum Field: Hashable { case title, body }

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)

    private var statusPrompt: String { dailyStatusPrompts[dailyIndex(for: dailyStatusPrompts)] }
    private var bodyPrompt:   String { dailyBodyPrompts[dailyIndex(for: dailyBodyPrompts)] }

    private var todayFuelEntries: [FoodEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return allFoodEntries
            .filter { Calendar.current.startOfDay(for: $0.loggedAt) == today }
            .sorted { $0.loggedAt < $1.loggedAt }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        // Label picker
                        labelPickerSection

                        // Fuel log preview (only when Fuel Log label is selected)
                        if selectedLabel == .fuelLog {
                            fuelLogPreview
                        }

                        // Mog Board sub-options
                        if selectedLabel == .mogBoard {
                            mogBoardOptions
                        }

                        // Status
                        VStack(alignment: .trailing, spacing: 4) {
                            TextField(statusPrompt, text: $titleText)
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                                .padding(14)
                                .background(cardBg)
                                .cornerRadius(12)
                                .focused($focus, equals: .title)
                                .submitLabel(.next)
                                .onSubmit { focus = .body }
                                .onChange(of: titleText) { _, v in
                                    if v.count > 80 { titleText = String(v.prefix(80)) }
                                }
                            Text("\(titleText.count)/80")
                                .font(.system(size: 11))
                                .foregroundStyle(titleText.count >= 80 ? .red : titleText.count >= 64 ? Color.orange : .white.opacity(0.25))
                        }

                        // Body
                        VStack(alignment: .trailing, spacing: 4) {
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
                                    .onChange(of: bodyText) { _, v in
                                        if v.count > 300 { bodyText = String(v.prefix(300)) }
                                    }
                            }
                            .background(cardBg)
                            .cornerRadius(12)
                            Text("\(bodyText.count)/300")
                                .font(.system(size: 11))
                                .foregroundStyle(bodyText.count >= 300 ? .red : bodyText.count >= 240 ? Color.orange : .white.opacity(0.25))
                        }

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

    // MARK: - Label picker

    private var labelPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Label (optional)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.50))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // "None" chip
                    Button {
                        withAnimation(.spring(duration: 0.2)) { selectedLabel = nil }
                    } label: {
                        Text("None")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(selectedLabel == nil ? .black : .white.opacity(0.55))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(selectedLabel == nil
                                    ? Color.white
                                    : Color.white.opacity(0.07))
                            )
                    }
                    .buttonStyle(.plain)

                    ForEach(PostLabel.allCases, id: \.self) { label in
                        let isSelected = selectedLabel == label
                        let color = labelColor(label)
                        Button {
                            withAnimation(.spring(duration: 0.2)) {
                                selectedLabel = isSelected ? nil : label
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: label.icon)
                                    .font(.system(size: 11, weight: .semibold))
                                Text(label.rawValue)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(isSelected ? .black : color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(isSelected ? color : color.opacity(0.12)))
                            .overlay(Capsule().stroke(color.opacity(isSelected ? 0 : 0.35), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    // MARK: - Fuel log preview

    @ViewBuilder
    private var fuelLogPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(red: 1.00, green: 0.55, blue: 0.15))
                Text("Today's fuel log will be attached")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(todayFuelEntries.count) items")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.40))
            }

            if todayFuelEntries.isEmpty {
                Text("No meals logged today yet. Log meals in the Fuel Log tab first.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.40))
                    .padding(.top, 2)
            } else {
                ForEach(todayFuelEntries.prefix(5)) { entry in
                    HStack(spacing: 8) {
                        if let data = entry.imageData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable().scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipped().cornerRadius(6)
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.07))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.30))
                                }
                        }
                        Text(entry.foodName)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.80))
                        Spacer()
                        Text("\(Int(entry.calories)) kcal")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(red: 1.00, green: 0.55, blue: 0.15))
                    }
                }
                if todayFuelEntries.count > 5 {
                    Text("+ \(todayFuelEntries.count - 5) more")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
        .padding(12)
        .background(cardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 1.00, green: 0.55, blue: 0.15).opacity(0.30), lineWidth: 1)
        )
    }

    // MARK: - Mog Board options

    private var mogBoardOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(gold)
                Text("Mog Board Options")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // Feed scope
            VStack(alignment: .leading, spacing: 6) {
                Text("Feed")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.50))
                HStack(spacing: 8) {
                    ForEach(mogBoardScopes, id: \.self) { scope in
                        let isSelected = mogBoardScope == scope
                        Button {
                            withAnimation(.spring(duration: 0.2)) { mogBoardScope = scope }
                        } label: {
                            Text(scope)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(isSelected ? .black : .white.opacity(0.65))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(isSelected ? gold : Color.white.opacity(0.08)))
                                .overlay(Capsule().stroke(gold.opacity(isSelected ? 0 : 0.25), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Board type
            VStack(alignment: .leading, spacing: 6) {
                Text("Board")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.50))
                HStack(spacing: 8) {
                    ForEach(mogBoardTypes, id: \.self) { type in
                        let isSelected = mogBoardType == type
                        Button {
                            withAnimation(.spring(duration: 0.2)) { mogBoardType = type }
                        } label: {
                            Text(type)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(isSelected ? .black : .white.opacity(0.65))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(isSelected ? gold : Color.white.opacity(0.08)))
                                .overlay(Capsule().stroke(gold.opacity(isSelected ? 0 : 0.25), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
        .background(cardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(gold.opacity(0.30), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func labelColor(_ label: PostLabel) -> Color {
        switch label {
        case .transformation: return Color(red: 0.35, green: 0.75, blue: 1.00)
        case .fuelLog:        return Color(red: 1.00, green: 0.55, blue: 0.15)
        case .mealInspo:      return Color(red: 1.00, green: 0.30, blue: 0.55)
        case .mogBoard:       return Color(red: 1.00, green: 0.80, blue: 0.20)
        case .advice:         return Color(red: 1.00, green: 0.90, blue: 0.20)
        case .workout:        return Color(red: 0.30, green: 0.90, blue: 0.55)
        }
    }

    private func submit() {
        let t = titleText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }

        // 1. Save locally to SwiftData so the Aura Stream tab updates immediately
        let fbPostID = UUID().uuidString   // shared ID for SwiftData ↔ Firestore link
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
        post.authorAuraTitle        = userSettings.auraTitle
        post.authorLocation         = locationManager.city.isEmpty ? userSettings.location : locationManager.city
        post.authorLatitude         = locationManager.coordinate?.latitude  ?? 0
        post.authorLongitude        = locationManager.coordinate?.longitude ?? 0
        post.authorStreak           = userSettings.macroStreak
        post.isAuthorPrivate        = userSettings.isPrivateAccount
        post.authorProfileImageData = userSettings.profileImageData
        post.postLabel              = selectedLabel?.rawValue ?? ""
        if selectedLabel == .mogBoard {
            post.mogBoardScope = mogBoardScope
            post.mogBoardType  = mogBoardType
        }
        let datas = photos.map { $0.image.jpegData(compressionQuality: 0.8) }
        post.imageData  = datas.count > 0 ? datas[0] : nil
        post.imageData2 = datas.count > 1 ? datas[1] : nil
        post.imageData3 = datas.count > 2 ? datas[2] : nil
        post.imageData4      = datas.count > 3 ? datas[3] : nil
        post.firebasePostID  = fbPostID
        modelContext.insert(post)

        // Attach today's fuel log entries when label is Fuel Log
        if selectedLabel == .fuelLog {
            for (i, entry) in todayFuelEntries.enumerated() {
                let fuelEntry = FuelLogEntry(
                    foodName:  entry.foodName,
                    calories:  entry.calories,
                    protein:   entry.protein,
                    carbs:     entry.carbs,
                    fat:       entry.fat,
                    loggedAt:  entry.loggedAt,
                    sortOrder: i,
                    imageData: entry.imageData
                )
                post.fuelLogEntries.append(fuelEntry)
                modelContext.insert(fuelEntry)
            }
        }

        // 2. Mirror to Firebase in the background (non-blocking)
        let images       = photos.map { $0.image }
        let caption      = bodyText.trimmingCharacters(in: .whitespaces)
        let locationName = locationManager.city.isEmpty ? userSettings.location : locationManager.city
        let latitude     = locationManager.coordinate?.latitude  ?? 0
        let longitude    = locationManager.coordinate?.longitude ?? 0

        let author = PostService.PostAuthor(
            userID:              userSettings.userID,
            username:            userSettings.username.isEmpty ? "me" : userSettings.username,
            whoName:             userSettings.name,
            userProfilePhotoURL: "",
            auraLevel:           userSettings.auraLevel,
            auraPoints:          userSettings.auraPoints,
            auraTitle:           userSettings.auraTitle,
            streak:              userSettings.macroStreak,
            memeType:            "",
            isPublic:            !userSettings.isPrivateAccount
        )

        Task {
            do {
                try await PostService.shared.createCustomPost(
                    photos:       images,
                    author:       author,
                    title:        t,
                    caption:      caption,
                    locationName: locationName,
                    latitude:     latitude,
                    longitude:    longitude,
                    postLabel:     selectedLabel?.rawValue ?? "",
                    mogBoardScope: selectedLabel == .mogBoard ? mogBoardScope : "",
                    mogBoardType:  selectedLabel == .mogBoard ? mogBoardType  : "",
                    postID:        fbPostID
                )
            } catch {
                print("[NewPostView] Firebase sync failed: \(error.localizedDescription)")
            }
            await InAppNotificationService.shared.notifySubscribers(
                ofUserID:          userSettings.userID,
                posterUsername:    userSettings.username,
                posterDisplayName: userSettings.name,
                postID:            fbPostID,
                postTitle:         t,
                posterPhotoURL:    userSettings.profilePhotoURL
            )
        }

        dismiss()
    }
}
