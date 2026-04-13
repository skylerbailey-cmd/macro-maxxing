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
    /// Called on the main actor after the Firestore post write completes.
    /// Use this to trigger a feed refresh so fuel log items are guaranteed to be in Firestore.
    var onPostCompleted: (() -> Void)? = nil
    @Environment(LocationManager.self) private var locationManager

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @Query(sort: \SocialPost.postedAt, order: .reverse) private var allSocialPosts: [SocialPost]

    @State private var titleText     = ""
    @State private var bodyText      = ""
    @State private var photos:       [PostPhoto] = []
    @State private var selectedLabel:      PostLabel? = nil
    @State private var mogBoardScope:      String     = "Arena"
    @State private var mogBoardType:       String     = "Weekly Aura"
    @State private var postScope:          String     = "arena"
    @FocusState private var focus: Field?

    // Fuel log pre-fill (loaded from Firestore)
    @State private var todayFoodEntries:  [FoodEntry] = []
    @State private var isLoadingFood      = false

    // Workout pre-fill
    @State private var todayWorkouts:    [WorkoutEntry] = []
    @State private var isLoadingWorkouts = false

    private let mogBoardScopes = ["Team", "Local", "Arena"]
    private let mogBoardTypes  = ["Weekly Aura"]

    private enum Field: Hashable { case title, body }

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)

    private var statusPrompt: String { dailyStatusPrompts[dailyIndex(for: dailyStatusPrompts)] }
    private var bodyPrompt:   String { dailyBodyPrompts[dailyIndex(for: dailyBodyPrompts)] }

    /// A post can be submitted if it has a title, body, photo, or a content-bearing label selected.
    private var hasPostableContent: Bool {
        let hasTitle = !titleText.trimmingCharacters(in: .whitespaces).isEmpty
        let hasBody  = !bodyText.trimmingCharacters(in: .whitespaces).isEmpty
        let hasPhoto = !photos.isEmpty
        let hasLabel = selectedLabel != nil
        return hasTitle || hasBody || hasPhoto || hasLabel
    }

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        // Label picker
                        labelPickerSection

                        // Audience scope
                        postScopePicker

                        // Fuel log preview (only when Fuel Log label is selected)
                        if selectedLabel == .fuelLog {
                            fuelLogPreview
                        }

                        // Workout preview (only when Workout label is selected)
                        if selectedLabel == .workout {
                            workoutPreview
                        }

                        // Goal post preview (only when Goal label is selected)
                        if selectedLabel == .goalPost {
                            goalPostPreview
                        }

                        // Mog Board sub-options
                        if selectedLabel == .mogBoard {
                            mogBoardOptions
                        }

                        // Photo preview (full-width, like the feed)
                        if !photos.isEmpty {
                            photoPreview
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

                        // Photos (buttons only — preview shown above)
                        MultiPhotoSection(photos: $photos, hideThumbnails: true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadTodayFoodEntries() }
            .onChange(of: selectedLabel) { old, label in
                // Clear auto-filled title/body when switching away from a label that pre-fills
                if old == .workout {
                    titleText = ""
                    bodyText  = ""
                }
                if label == .workout    { Task { await loadTodayWorkouts() } }
                if label == .fuelLog    { Task { await loadTodayFoodEntries() } }
                if label == .goalPost   { Task { await loadTodayFoodEntries() } }
                if let label { prefillForLabel(label) }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { Task { await submit() } }
                        .fontWeight(.bold)
                        .disabled(!hasPostableContent)
                }
            }
        }
    }

    // MARK: - Post scope picker

    private var postScopePicker: some View {
        HStack(spacing: 8) {
            Image(systemName: "eye")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
            Text("Visible to")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
            Picker("", selection: $postScope) {
                Text("Arena").tag("arena")
                Text("Local").tag("local")
                Text("Team").tag("team")
            }
            .pickerStyle(.menu)
            .tint(purpl)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
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
                if isLoadingFood {
                    ProgressView().tint(Color(red: 1.00, green: 0.55, blue: 0.15)).scaleEffect(0.8)
                } else {
                    Text("\(todayFoodEntries.count) items")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.40))
                }
            }

            if !isLoadingFood {
                if todayFoodEntries.isEmpty {
                    Text("No meals logged today yet. Log meals in the Fuel Log tab first.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.40))
                        .padding(.top, 2)
                } else {
                    ForEach(todayFoodEntries.prefix(5)) { entry in
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
                    if todayFoodEntries.count > 5 {
                        Text("+ \(todayFoodEntries.count - 5) more")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.35))
                    }

                    HStack(spacing: 5) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                        Text("Meal photos won't preview here but will appear in your post.")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.white.opacity(0.30))
                    .padding(.top, 2)
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

    // MARK: - Workout preview

    private let workoutGreen = Color(red: 0.30, green: 0.90, blue: 0.55)

    @ViewBuilder
    private var workoutPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(workoutGreen)
                Text("Today's workout will be attached")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                if isLoadingWorkouts {
                    ProgressView().tint(workoutGreen).scaleEffect(0.8)
                } else {
                    Text("\(todayWorkouts.count) workout\(todayWorkouts.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.40))
                }
            }

            if !isLoadingWorkouts {
                if todayWorkouts.isEmpty {
                    Text("No workouts logged today yet. Log a workout first.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.40))
                        .padding(.top, 2)
                } else {
                    ForEach(todayWorkouts) { entry in
                        HStack(spacing: 8) {
                            Image(systemName: entry.workoutType.icon)
                                .font(.system(size: 11))
                                .foregroundStyle(workoutGreen)
                                .frame(width: 16)
                            Text(entry.name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(1)
                            Text("· \(entry.formattedDuration) · \(entry.workoutType.shortLabel)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.40))
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            Text("\(entry.caloriesBurned) cal")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(workoutGreen)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(cardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(workoutGreen.opacity(0.30), lineWidth: 1)
        )
    }

    // MARK: - Goal totals helpers

    private var goalTotalCalories: Double { todayFoodEntries.reduce(0) { $0 + $1.calories } }
    private var goalTotalProtein:  Double { todayFoodEntries.reduce(0) { $0 + $1.protein  } }
    private var goalTotalCarbs:    Double { todayFoodEntries.reduce(0) { $0 + $1.carbs    } }
    private var goalTotalFat:      Double { todayFoodEntries.reduce(0) { $0 + $1.fat      } }

    private func ud(_ key: String, fallback: Double) -> Double {
        let ud = UserDefaults.standard
        return ud.object(forKey: key) != nil ? ud.double(forKey: key) : fallback
    }

    // MARK: - Goal post preview

    @ViewBuilder
    private var goalPostPreview: some View {
        let goalCal  = ud("goalCalories", fallback: 2000)
        let goalPro  = ud("goalProtein",  fallback: 150)
        let goalCarb = ud("goalCarbs",    fallback: 200)
        let goalFat  = ud("goalFat",      fallback: 65)
        let goalPurple = Color(red: 0.65, green: 0.45, blue: 1.00)

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "target")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(goalPurple)
                Text("Today's progress toward your goal")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                if isLoadingFood {
                    ProgressView().tint(goalPurple).scaleEffect(0.8)
                }
            }

            if !isLoadingFood {
                if goalCal <= 0 {
                    Text("No daily goals set. Set your goals in Profile → Settings to see progress here.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.40))
                        .padding(.top, 2)
                } else {
                    MacroDisciplineCard(
                        totalCalories: goalTotalCalories, goalCalories: goalCal,
                        totalProtein:  goalTotalProtein,  goalProtein:  goalPro,
                        totalCarbs:    goalTotalCarbs,    goalCarbs:    goalCarb,
                        totalFat:      goalTotalFat,      goalFat:      goalFat
                    )
                }
            }
        }
        .padding(12)
        .background(cardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(goalPurple.opacity(0.30), lineWidth: 1)
        )
    }

    // MARK: - Load food entries

    private func loadTodayFoodEntries() async {
        guard !userSettings.userID.isEmpty else { return }
        isLoadingFood = true
        let entries = (try? await FoodEntryService.shared.fetch(
            userID: userSettings.userID, date: Date())) ?? []
        todayFoodEntries = entries.sorted { $0.loggedAt < $1.loggedAt }
        isLoadingFood = false
    }

    // MARK: - Load workouts

    private func loadTodayWorkouts() async {
        isLoadingWorkouts = true
        todayWorkouts     = (try? await WorkoutService.shared.fetch(
            userID: userSettings.userID, date: Date())) ?? []
        isLoadingWorkouts = false

        guard !todayWorkouts.isEmpty else { return }

        // Pre-fill title and body only if they're still empty
        let realWorkouts = todayWorkouts.filter { $0.workoutType != .restDay }
        guard !realWorkouts.isEmpty else {
            if titleText.isEmpty { titleText = "Rest Day" }
            if bodyText.isEmpty  { bodyText  = "Taking it easy today. Recovery is part of the grind." }
            return
        }

        if titleText.isEmpty {
            titleText = realWorkouts.count == 1
                ? realWorkouts[0].name
                : "Today's Workouts"
        }

        if bodyText.isEmpty {
            if realWorkouts.count == 1 {
                let w = realWorkouts[0]
                bodyText = "\(w.formattedDuration) · \(w.caloriesBurned) cal burned · \(w.workoutType.rawValue)"
            } else {
                let lines = realWorkouts
                    .map { "• \($0.name): \($0.formattedDuration), \($0.caloriesBurned) cal" }
                    .joined(separator: "\n")
                let totalCal = realWorkouts.reduce(0) { $0 + $1.caloriesBurned }
                let totalMin = realWorkouts.reduce(0) { $0 + $1.durationMinutes }
                let totalTime = totalMin >= 60 ? "\(totalMin / 60)h \(totalMin % 60)m" : "\(totalMin)m"
                bodyText = "\(lines)\n\nTotal: \(totalTime) · \(totalCal) cal burned"
            }
        }
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

    /// Fetches the top-10 Weekly Aura snapshot from Firestore — same source as the
    /// board tab — so the post always matches what the leaderboard actually shows.
    private func computeMogBoardSnapshot() async -> [MogBoardSnapshotEntry] {
        let selfName        = userSettings.name.isEmpty ? userSettings.username : userSettings.name
        let currentWeekStart = UserSettings.currentWeekStart().timeIntervalSince1970

        let firestoreEntries = (try? await UserProfileService.shared.fetchWeeklyAuraBoard()) ?? []

        // Start with self (always included, uses live local value)
        var entries: [MogBoardSnapshotEntry] = [
            MogBoardSnapshotEntry(
                id:          userSettings.userID,
                displayName: selfName,
                username:    userSettings.username,
                score:       userSettings.weeklyAuraPoints
            )
        ]

        // Add everyone else from Firestore whose weekly window is current
        for e in firestoreEntries where e.userID != userSettings.userID {
            guard e.weeklyAuraWeekStartTimestamp >= currentWeekStart else { continue }
            let displayName = e.name.isEmpty ? e.username : e.name
            entries.append(MogBoardSnapshotEntry(
                id:          e.userID,
                displayName: displayName,
                username:    e.username,
                score:       e.weeklyAuraPoints
            ))
        }

        return Array(
            entries
                .sorted { $0.score != $1.score ? $0.score > $1.score : $0.displayName < $1.displayName }
                .prefix(10)
        )
    }

    private func labelColor(_ label: PostLabel) -> Color {
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

    // MARK: - Photo preview (feed-style)

    private var photoPreview: some View {
        VStack(spacing: 0) {
            ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: photo.image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipped()

                    // Delete button
                    Button {
                        photos.removeAll { $0.id == photo.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.6), radius: 3)
                            .padding(8)
                    }
                }
            }
        }
        .cornerRadius(12)
    }

    private func prefillForLabel(_ label: PostLabel) {
    }

    @MainActor
    private func submit() async {
        let t = titleText.trimmingCharacters(in: .whitespaces)
        guard hasPostableContent else { return }

        // 1. Save locally to SwiftData so the Aura Stream tab updates immediately
        let fbPostID = UUID().uuidString   // shared ID for SwiftData ↔ Firestore link
        let isGoalPost = selectedLabel == .goalPost
        let post = SocialPost(
            authorID:          userSettings.userID,
            authorUsername:    userSettings.username.isEmpty ? "me" : userSettings.username,
            authorDisplayName: userSettings.name,
            memeEmoji:         "",
            memeHeadline:      t,
            memeSub:           bodyText.trimmingCharacters(in: .whitespaces),
            macroDate:         Date(),
            totalCalories: isGoalPost ? goalTotalCalories : 0,
            goalCalories:  isGoalPost ? ud("goalCalories", fallback: 2000) : 0,
            totalProtein:  isGoalPost ? goalTotalProtein  : 0,
            goalProtein:   isGoalPost ? ud("goalProtein",  fallback: 150)  : 0,
            totalCarbs:    isGoalPost ? goalTotalCarbs     : 0,
            goalCarbs:     isGoalPost ? ud("goalCarbs",    fallback: 200)  : 0,
            totalFat:      isGoalPost ? goalTotalFat       : 0,
            goalFat:       isGoalPost ? ud("goalFat",      fallback: 65)   : 0
        )
        post.isCustomPost           = true
        post.postScope              = postScope
        post.authorAuraLevel        = userSettings.auraLevel
        post.authorAuraPoints       = userSettings.auraPoints
        post.authorAuraTitle        = userSettings.auraTitle
        post.authorLocation         = userSettings.postLocation(gpsCity: locationManager.city)
        post.authorLatitude         = locationManager.coordinate?.latitude  ?? 0
        post.authorLongitude        = locationManager.coordinate?.longitude ?? 0
        post.authorStreak           = userSettings.macroStreak
        post.isAuthorPrivate        = userSettings.isPrivateAccount
        post.authorProfileImageData = userSettings.profileImageData
        post.postLabel              = selectedLabel?.rawValue ?? ""
        if selectedLabel == .mogBoard {
            post.mogBoardScope = mogBoardScope
            post.mogBoardType  = mogBoardType
            let snapshotEntries = await computeMogBoardSnapshot()
            if let snapshotData = try? JSONEncoder().encode(snapshotEntries),
               let snapshotJSON = String(data: snapshotData, encoding: .utf8) {
                post.mogBoardSnapshot = snapshotJSON
            }
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
            for (i, entry) in todayFoodEntries.enumerated() {
                let fuelEntry = FuelLogEntry(
                    foodName:  entry.foodName,
                    calories:  entry.calories,
                    protein:   entry.protein,
                    carbs:     entry.carbs,
                    fat:       entry.fat,
                    loggedAt:  entry.loggedAt,
                    sortOrder: i,
                    imageData: entry.imageData,
                    photoURL:  entry.photoURL
                )
                post.fuelLogEntries.append(fuelEntry)
                modelContext.insert(fuelEntry)
            }
        }

        // Award aura for workout post — once per day only
        if selectedLabel == .workout, !userSettings.hasEarnedWorkoutPostAuraToday {
            if RemoteConfigService.shared.auraRewardAdRequired {
                let settings = userSettings
                AdManager.shared.showRewarded(onReward: {
                    Task { @MainActor in
                        settings.awardAura(points: 25)
                        settings.lastWorkoutPostDate = Date()
                    }
                })
            } else {
                userSettings.awardAura(points: 25)
                userSettings.lastWorkoutPostDate = Date()
            }
        }

        if selectedLabel == .workout {
            for (i, entry) in todayWorkouts.enumerated() {
                let workoutEntry = WorkoutLogEntry(
                    workoutName:     entry.name,
                    workoutType:     entry.workoutType.rawValue,
                    durationMinutes: entry.durationMinutes,
                    caloriesBurned:  entry.caloriesBurned,
                    loggedAt:        entry.loggedAt,
                    sortOrder:       i
                )
                post.workoutEntries.append(workoutEntry)
                modelContext.insert(workoutEntry)
            }
        }

        // 2. Mirror to Firebase in the background (non-blocking)
        let images       = photos.map { $0.image }
        let caption      = bodyText.trimmingCharacters(in: .whitespaces)
        let locationName    = userSettings.postLocation(gpsCity: locationManager.city)
        let latitude        = locationManager.coordinate?.latitude  ?? 0
        let longitude       = locationManager.coordinate?.longitude ?? 0
        let snapshotJSON    = selectedLabel == .mogBoard ? post.mogBoardSnapshot : ""
        let feedFuelLogItems: [FeedFuelLogItem] = selectedLabel == .fuelLog
            ? todayFoodEntries.enumerated().map { i, e in
                FeedFuelLogItem(foodName: e.foodName, calories: e.calories,
                                protein: e.protein, carbs: e.carbs, fat: e.fat,
                                photoURL: e.photoURL, sortOrder: i)
              }
            : []

        let feedWorkoutItems: [FeedWorkoutItem] = selectedLabel == .workout
            ? todayWorkouts.enumerated().map { i, e in
                FeedWorkoutItem(workoutName: e.name, workoutType: e.workoutType.rawValue,
                                durationMinutes: e.durationMinutes, caloriesBurned: e.caloriesBurned,
                                sortOrder: i)
              }
            : []

        let author = PostService.PostAuthor(
            userID:              userSettings.userID,
            username:            userSettings.username.isEmpty ? "me" : userSettings.username,
            whoName:             userSettings.name,
            userProfilePhotoURL: userSettings.profilePhotoURL,
            auraLevel:           userSettings.auraLevel,
            auraPoints:          userSettings.auraPoints,
            auraTitle:           userSettings.auraTitle,
            streak:              userSettings.macroStreak,
            memeType:            "",
            isPublic:            !userSettings.isPrivateAccount,
            isProSubscriber:     AISubscriptionStore.shared.isSubscribed
        )

        let postCompletedCallback = onPostCompleted
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
                    postLabel:        selectedLabel?.rawValue ?? "",
                    mogBoardScope:    selectedLabel == .mogBoard ? mogBoardScope : "",
                    mogBoardType:     selectedLabel == .mogBoard ? mogBoardType  : "",
                    mogBoardSnapshot: snapshotJSON,
                    calories:      isGoalPost ? Int(goalTotalCalories) : 0,
                    protein:       isGoalPost ? goalTotalProtein       : 0,
                    carbs:         isGoalPost ? goalTotalCarbs         : 0,
                    fat:           isGoalPost ? goalTotalFat           : 0,
                    goalCalories:  isGoalPost ? Int(ud("goalCalories", fallback: 2000)) : 0,
                    goalProtein:   isGoalPost ? ud("goalProtein", fallback: 150)        : 0,
                    goalCarbs:     isGoalPost ? ud("goalCarbs",   fallback: 200)        : 0,
                    goalFat:       isGoalPost ? ud("goalFat",     fallback: 65)         : 0,
                    fuelLogItems:  feedFuelLogItems,
                    workoutItems:  feedWorkoutItems,
                    postScope:     postScope,
                    postID:        fbPostID
                )
                // Notify the feed to refresh now that Firestore has the complete post data
                // (including fuelLogItems). This avoids a race where the feed refresh fires
                // before the write completes and shows the post without its fuel log.
                await MainActor.run { postCompletedCallback?() }
            } catch {
                AppLogger.log("[NewPostView] Firebase sync failed: \(error.localizedDescription)")
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
