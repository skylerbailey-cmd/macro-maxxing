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
    /// Called just before dismiss with the selected post scope ("arena", "local", "team")
    /// so the parent can switch to the matching feed tab.
    var onPostScope: ((String) -> Void)? = nil

    // MARK: - Meal Inspo pre-population (set when opened from food confirmation)

    /// Pre-select a label on appearance.
    var preSelectedLabel: PostLabel? = nil
    /// Pre-attached photo (e.g. the meal photo from AI scan).
    var prePopulatedPhoto: UIImage? = nil
    /// Meal macro data for Meal Inspo posts.
    var prePopulatedCalories: Int    = 0
    var prePopulatedProtein:  Double = 0
    var prePopulatedCarbs:    Double = 0
    var prePopulatedFat:      Double = 0
    /// Meal score (0–100) computed at food confirmation time.
    var prePopulatedMealScore: Int   = 0
    /// Food name from the AI scan.
    var prePopulatedFoodName: String = ""

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
    @State private var photoLayout:        String     = "carousel"
    @FocusState private var focus: Field?

    // @mention autocomplete
    @State private var followingList:  [FollowEntry] = []
    @State private var mentionQuery:   String        = ""

    // Fuel log pre-fill (loaded from Firestore)
    @State private var todayFoodEntries:  [FoodEntry] = []
    @State private var isLoadingFood      = false

    // Workout pre-fill
    @State private var todayWorkouts:    [WorkoutEntry] = []
    @State private var isLoadingWorkouts = false

    private let mogBoardScopes = ["Team", "Local", "Arena"]
    private let mogBoardTypes  = ["Weekly Aura"]

    private enum Field: Hashable { case title, body }

    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var purpl: Color { ThemeStore.shared.accent }
    private var gold: Color { ThemeStore.shared.accent }

    private var statusPrompt: String { "Title" }
    private var bodyPrompt:   String { "What's on your mind?" }

    /// A post can be submitted if it has any content: title, body, photos, or a label.
    private var hasPostableContent: Bool {
        selectedLabel != nil
        || !titleText.trimmingCharacters(in: .whitespaces).isEmpty
        || !bodyText.trimmingCharacters(in: .whitespaces).isEmpty
        || !photos.isEmpty
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

                        // Meal Inspo preview (when pre-populated from food confirmation)
                        if selectedLabel == .mealInspo, prePopulatedMealScore > 0 {
                            mealInspoPreview
                        }

                        // Mog Board sub-options
                        if selectedLabel == .mogBoard {
                            mogBoardOptions
                        }

                        // Photo preview (full-width, like the feed)
                        if !photos.isEmpty {
                            photoPreview
                        }

                        // Photo layout picker (only for multi-photo posts)
                        if photos.count > 1 {
                            photoLayoutPicker
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
                                        mentionQuery = Self.activeMentionQuery(in: v)
                                    }
                            }
                            .background(cardBg)
                            .cornerRadius(12)
                            Text("\(bodyText.count)/300")
                                .font(.system(size: 11))
                                .foregroundStyle(bodyText.count >= 300 ? .red : bodyText.count >= 240 ? Color.orange : .white.opacity(0.25))
                        }

                        // @mention suggestions (max 3 from following list)
                        if !mentionSuggestions.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(mentionSuggestions) { entry in
                                    Button {
                                        insertMention(entry.username)
                                    } label: {
                                        HStack(spacing: 10) {
                                            if !entry.profilePhotoURL.isEmpty,
                                               let url = URL(string: entry.profilePhotoURL) {
                                                CachedAsyncImage(
                                                    url: url,
                                                    content: { img in
                                                        img.resizable().scaledToFill()
                                                            .frame(width: 28, height: 28)
                                                            .clipShape(Circle())
                                                    },
                                                    placeholder: {
                                                        mentionInitialCircle(entry.displayName ?? entry.username)
                                                    }
                                                )
                                            } else {
                                                mentionInitialCircle(entry.displayName ?? entry.username)
                                            }
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(entry.displayName ?? entry.username)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundStyle(.white)
                                                    .lineLimit(1)
                                                Text("@\(entry.username)")
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(.white.opacity(0.45))
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.plain)
                                    if entry.id != mentionSuggestions.last?.id {
                                        Divider().background(Color.white.opacity(0.08))
                                            .padding(.horizontal, 14)
                                    }
                                }
                            }
                            .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
                        }

                        // Photos (buttons only — preview shown above)
                        MultiPhotoSection(photos: $photos, hideThumbnails: true)

                        // Post button
                        Button {
                            Task { await submit() }
                        } label: {
                            Text("Post")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(purpl, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .disabled(!hasPostableContent)
                        .opacity(hasPostableContent ? 1 : 0.4)
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
            .task {
                followingList = (try? await FollowService.shared.fetchFollowing(
                    userID: userSettings.userID)) ?? []
            }
            .onAppear {
                // Pre-populate from meal inspo flow
                if let label = preSelectedLabel {
                    selectedLabel = label
                    prefillForLabel(label)
                }
                if let img = prePopulatedPhoto {
                    photos = [PostPhoto(image: img)]
                }
                if prePopulatedMealScore > 0, !prePopulatedFoodName.isEmpty {
                    if titleText.isEmpty { titleText = prePopulatedFoodName }
                }
            }
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
        .keyboardDoneToolbar()
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

    // MARK: - Photo layout picker

    private var photoLayoutPicker: some View {
        HStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
            Text("Photo Layout")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))

            Spacer()

            HStack(spacing: 0) {
                photoLayoutOption(value: "carousel", icon: "rectangle.stack", label: "Carousel")
                photoLayoutOption(value: "grid",     icon: "square.grid.2x2", label: "Side by Side")
            }
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 9))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
    }

    private func photoLayoutOption(value: String, icon: String, label: String) -> some View {
        let selected = photoLayout == value
        return Button {
            withAnimation(.spring(duration: 0.2)) { photoLayout = value }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(selected ? .white : .white.opacity(0.40))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(selected ? purpl : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
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

                    let sortedLabels = PostLabel.allCases.sorted { a, _ in a == selectedLabel }
                    ForEach(sortedLabels, id: \.self) { label in
                        let isSelected = selectedLabel == label
                        let color = label.color
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

    /// Today's macro totals for the Goal post.
    /// Prefers the HomeViewModel cache written to UserDefaults (includes pending entries)
    /// and falls back to the Firestore-fetched todayFoodEntries.
    private var goalTotalCalories: Double { cachedOrFetchedTotal("cachedDailyCalories") { $0.calories } }
    private var goalTotalProtein:  Double { cachedOrFetchedTotal("cachedDailyProtein")  { $0.protein  } }
    private var goalTotalCarbs:    Double { cachedOrFetchedTotal("cachedDailyCarbs")    { $0.carbs    } }
    private var goalTotalFat:      Double { cachedOrFetchedTotal("cachedDailyFat")      { $0.fat      } }

    private func cachedOrFetchedTotal(_ key: String, extract: (FoodEntry) -> Double) -> Double {
        let ud = UserDefaults.standard
        let cachedDay = ud.double(forKey: "cachedDailyDate")
        let today = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        // Use cached value if it's for today (within the same calendar day)
        if cachedDay == today, ud.object(forKey: key) != nil {
            return ud.double(forKey: key)
        }
        return todayFoodEntries.reduce(0) { $0 + extract($1) }
    }

    private func ud(_ key: String, fallback: Double) -> Double {
        let ud = UserDefaults.standard
        return ud.object(forKey: key) != nil ? ud.double(forKey: key) : fallback
    }

    // MARK: - Meal Inspo preview

    @ViewBuilder
    private var mealInspoPreview: some View {
        let score = prePopulatedMealScore
        let sColor: Color = score >= 75 ? Color(red: 0.25, green: 0.85, blue: 0.50)
                          : score >= 50 ? Color(red: 1.00, green: 0.75, blue: 0.20)
                          :               Color(red: 1.00, green: 0.35, blue: 0.35)
        let mealColor = PostLabel.mealInspo.color

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "fork.knife")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(mealColor)
                Text("Meal Inspo Preview")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
            }

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(sColor.opacity(0.35), lineWidth: 2.5)
                        .frame(width: 46, height: 46)
                    Text("\(score)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(sColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(prePopulatedFoodName.isEmpty ? "Meal" : prePopulatedFoodName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        miniMacroPill("\(prePopulatedCalories) kcal", color: .orange)
                        miniMacroPill("\(Int(prePopulatedProtein))g P", color: Color(red: 0.35, green: 0.75, blue: 1.00))
                        miniMacroPill("\(Int(prePopulatedCarbs))g C", color: Color(red: 0.40, green: 0.90, blue: 0.72))
                        miniMacroPill("\(Int(prePopulatedFat))g F", color: Color(red: 1.00, green: 0.50, blue: 0.72))
                    }
                }
                Spacer()
            }
        }
        .padding(12)
        .background(cardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(mealColor.opacity(0.30), lineWidth: 1)
        )
    }

    private func miniMacroPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.13))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Goal post preview

    @ViewBuilder
    private var goalPostPreview: some View {
        let goalCal  = ud("goalCalories", fallback: 2000)
        let goalPro  = ud("goalProtein",  fallback: 150)
        let goalCarb = ud("goalCarbs",    fallback: 200)
        let goalFat  = ud("goalFat",      fallback: 65)
        let goalPurple = ThemeStore.shared.accent

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
                    Text("No daily goals set. Set your goals in the Hub tab to see progress here.")
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
                    if goalTotalCalories == 0 {
                        Text("Log meals in the Fuel tab to see today's progress.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.35))
                    }
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

    // MARK: - Photo preview (feed-style)

    @State private var markupPhotoIndex: Int? = nil

    private var photoPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { idx, photo in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: photo.image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 90)
                            .clipped()
                            .cornerRadius(10)

                        // Delete button
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                photos.removeAll { $0.id == photo.id }
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.5), radius: 2)
                                .padding(4)
                        }

                        // Edit / markup button (bottom-right)
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button { markupPhotoIndex = idx } label: {
                                    Image(systemName: "pencil.tip.crop.circle")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.6), radius: 2)
                                        .padding(5)
                                        .background(.ultraThinMaterial, in: Circle())
                                }
                            }
                        }
                        .frame(width: 90, height: 90)
                    }
                }
            }
        }
        .fullScreenCover(item: Binding(
            get: { markupPhotoIndex.map { MarkupIndex(index: $0) } },
            set: { markupPhotoIndex = $0?.index }
        )) { item in
            if photos.indices.contains(item.index) {
                PhotoMarkupView(
                    image: photos[item.index].image,
                    onSave: { edited in
                        photos[item.index] = PostPhoto(image: edited)
                        markupPhotoIndex = nil
                    },
                    onCancel: { markupPhotoIndex = nil }
                )
            }
        }
    }

    /// Wrapper so an Int can drive `.fullScreenCover(item:)`.
    private struct MarkupIndex: Identifiable {
        let index: Int
        var id: Int { index }
    }

    private func prefillForLabel(_ label: PostLabel) {
    }

    @MainActor
    private func submit() async {
        let t = titleText.trimmingCharacters(in: .whitespaces)
        guard hasPostableContent else { return }

        // 1. Save locally to SwiftData so the Aura Stream tab updates immediately
        let fbPostID = UUID().uuidString   // shared ID for SwiftData ↔ Firestore link
        let isGoalPost   = selectedLabel == .goalPost
        let isMealInspo  = selectedLabel == .mealInspo && prePopulatedMealScore > 0
        let showWeight = userSettings.showWeightOnPosts
            && (selectedLabel == .goalPost || selectedLabel == .fuelLog || selectedLabel == .workout)
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
                    calories:      isGoalPost ? Int(goalTotalCalories)
                                 : isMealInspo ? prePopulatedCalories : 0,
                    protein:       isGoalPost ? goalTotalProtein
                                 : isMealInspo ? prePopulatedProtein  : 0,
                    carbs:         isGoalPost ? goalTotalCarbs
                                 : isMealInspo ? prePopulatedCarbs    : 0,
                    fat:           isGoalPost ? goalTotalFat
                                 : isMealInspo ? prePopulatedFat      : 0,
                    goalCalories:  isGoalPost || isMealInspo ? Int(ud("goalCalories", fallback: 2000)) : 0,
                    goalProtein:   isGoalPost || isMealInspo ? ud("goalProtein", fallback: 150)        : 0,
                    goalCarbs:     isGoalPost || isMealInspo ? ud("goalCarbs",   fallback: 200)        : 0,
                    goalFat:       isGoalPost || isMealInspo ? ud("goalFat",     fallback: 65)         : 0,
                    currentWeight: showWeight ? userSettings.currentWeight              : 0,
                    goalWeight:    showWeight ? userSettings.goalWeight                 : 0,
                    fuelLogItems:  feedFuelLogItems,
                    workoutItems:  feedWorkoutItems,
                    mealScore:     isMealInspo ? prePopulatedMealScore : 0,
                    photoLayout:   photos.count > 1 ? photoLayout : "carousel",
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

        // Send mention notifications for @usernames in title or body
        let allText = t + " " + bodyText
        let mentionedUsernames = Self.parseMentions(from: allText)
        if !mentionedUsernames.isEmpty {
            let uid   = userSettings.userID
            let uname = userSettings.username
            let dname = userSettings.name
            let photo = userSettings.profilePhotoURL
            Task {
                for username in mentionedUsernames {
                    guard let targetID = await UserProfileService.shared.fetchUserID(forUsername: username),
                          targetID != uid else { continue }
                    await InAppNotificationService.shared.sendMention(
                        to:               targetID,
                        postID:           fbPostID,
                        postHeadline:     t,
                        actorID:          uid,
                        actorUsername:    uname,
                        actorDisplayName: dname,
                        actorPhotoURL:    photo
                    )
                }
            }
        }

        onPostScope?(postScope)
        dismiss()
    }

    // MARK: - @Mention helpers

    private var mentionSuggestions: [FollowEntry] {
        let q = mentionQuery.lowercased()
        guard !q.isEmpty else { return [] }
        return followingList
            .filter { $0.username.lowercased().hasPrefix(q) }
            .prefix(3)
            .map { $0 }
    }

    private static func activeMentionQuery(in text: String) -> String {
        guard let atIdx = text.lastIndex(of: "@") else { return "" }
        let after = text[text.index(after: atIdx)...]
        if after.contains(" ") || after.contains("\n") { return "" }
        return String(after)
    }

    private static func parseMentions(from text: String) -> [String] {
        let pattern = #"@([A-Za-z0-9_.]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        let usernames = matches.compactMap { match -> String? in
            guard let r = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[r]).lowercased()
        }
        return Array(Set(usernames))
    }

    private func insertMention(_ username: String) {
        guard let atIdx = bodyText.lastIndex(of: "@") else { return }
        bodyText = String(bodyText[..<atIdx]) + "@\(username) "
        mentionQuery = ""
    }

    private func mentionInitialCircle(_ name: String) -> some View {
        Circle()
            .fill(purpl.opacity(0.22))
            .frame(width: 28, height: 28)
            .overlay {
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(purpl)
            }
    }
}
