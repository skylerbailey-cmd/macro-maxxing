//
//  SettingsView.swift
//  Wellness
//

import SwiftUI
import MapKit
import FirebaseAuth
import AppTrackingTransparency

// MARK: - FAQ item model

private struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer:   String
}

private let faqItems: [FAQItem] = [
    FAQItem(
        question: "House Rules",
        answer: """
        A few rules that keep the app honest.

        Streaks:
        A streak only continues if you hit ALL of your macro goals for that day — \
        calories, protein, carbs, and fat. Simply logging food does not count.

        To see if you're on track, open the Hub tab and check the macro rings under \
        your daily goal summary. All four need to be at or above 85% of their targets — \
        the streak updates immediately once all four goals are met.

        Fuel Log:
        Every food entry must be logged with a photo. The camera and photo library \
        buttons in the Fuel Log are the only way to add a meal — there is no \
        text-only entry. This keeps your log honest and your feed worth looking at.
        """
    ),
    FAQItem(
        question: "What is Aura XP?",
        answer: """
        Aura XP is the currency of your gains journey. Every rep in the gym and \
        every meal you track earns you Aura.

        Streaks — consecutive days hitting ALL macro goals (each milestone awarded once):
        • 3-day streak → +20 XP
        • 7-day streak → +60 XP
        • 14-day streak → +120 XP
        • 30-day streak → +200 XP
        • 60-day streak → +300 XP
        • 100-day streak → +1,000 XP

        Logging food alone does not count — you have to actually hit your goals.

        Posts, Comments & Reps (Social):
        • Post when you crush your macro goals → +50 XP
        • Rep a post or comment → +1 XP per rep
        • Comment on someone's post → +1 XP
        • Comment with a photo → +5 XP

        Leaderboard (Mog Board, resets every Sunday at 8 PM ET):
        Local top 10:
        • #1 → +75 XP  •  #2–3 → +50 XP  •  #4–10 → +25 XP
        Arena top 10:
        • #1 → +150 XP  •  #2–3 → +100 XP  •  #4–10 → +50 XP

        XP is awarded automatically at reset and added to your profile \
        the next time you open the app. Arena pays more — you're up against everyone.
        """
    ),
    FAQItem(
        question: "What are Aura Levels?",
        answer: """
        Aura Levels show where you stand on the looksmaxxing hierarchy. \
        Every 1,000 Aura XP = 1 level, up to a max of Level 100.

        Level titles:
        • Levels 1–5 — Initiate
        • Levels 6–10 — Rookie
        • Levels 11–15 — Grinder
        • Levels 16–20 — Disciple
        • Levels 21–25 — Ascender
        • Levels 26–35 — Mog Apprentice
        • Levels 36–45 — Aura Seeker
        • Levels 46–55 — Aura Farmer
        • Levels 56–65 — Aesthetic
        • Levels 66–75 — Elite Aesthetic
        • Levels 76–90 — Transcendent
        • Levels 91–100 — Final Form

        Your level and title appear under your name on the Home screen and \
        next to your name on every post you make. Stack those points and ascend.
        """
    ),
]

// MARK: - SettingsView

private enum ActivePicker: Identifiable {
    case currentWeight, goalWeight, height, proteinPerLb
    var id: Self { self }
}

struct SettingsView: View {
    @Bindable var userSettings: UserSettings
    @Environment(SessionManager.self) private var session
    @Environment(\.dismiss) private var dismiss
    @FocusState private var nameFocused: Bool

    // Local state — only writes to userSettings on commit, preventing re-renders on every input
    @State private var activeFAQ: FAQItem? = nil
    @State private var nameText:         String = ""
    @State private var usernameText:     String = ""
    @State private var currentWeightVal: Double = 160
    @State private var goalWeightVal:    Double = 160
    @State private var heightInchesVal:  Int    = 0
    @State private var proteinPerLbVal:  Double = 0.9
    @State private var activePicker: ActivePicker? = nil
    @State private var dobDate:          Date   = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var showCitySearch    = false
    @State private var showDeleteAccount = false
    @State private var showChangeEmail   = false
    @State private var isExportingData   = false
    @State private var exportFileURL: URL? = nil
    @State private var exportError: String? = nil
    @State private var showExportShare   = false

    // Username availability
    private enum UsernameState { case idle, checking, available, taken }
    @State private var usernameState: UsernameState = .idle
    @State private var usernameCheckTask: Task<Void, Never>? = nil

    /// Two-way binding that converts the hour/minute ints on UserSettings to a Date for DatePicker.
    private var mealReminderTimeBinding: Binding<Date> {
        Binding<Date>(
            get: {
                var comps = DateComponents()
                comps.hour   = userSettings.mealReminderHour
                comps.minute = userSettings.mealReminderMinute
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                userSettings.mealReminderHour   = comps.hour   ?? 12
                userSettings.mealReminderMinute = comps.minute ?? 0
            }
        )
    }

    var body: some View {
        Form {
            // MARK: Profile
            Section("Profile") {
                NavigationLink {
                    ProfileView(
                        profileUserID:      userSettings.userID,
                        profileUsername:    userSettings.username,
                        profileDisplayName: userSettings.name,
                        profileAuraLevel:   userSettings.auraLevel,
                        profileAuraPoints:  userSettings.auraPoints,
                        profileImageData:   userSettings.profileImageData,
                        profileLocation:    userSettings.location,
                        ownUserSettings:    userSettings
                    )
                } label: {
                    Label("View Profile", systemImage: "person.crop.circle")
                }
                HStack {
                    Text("Name")
                    Spacer()
                    TextField("Your name", text: $nameText)
                        .multilineTextAlignment(.trailing)
                        .focused($nameFocused)
                        .submitLabel(.next)
                        .onSubmit { nameFocused = false }
                }
                HStack {
                    Text("Username")
                    Spacer()
                    HStack(spacing: 6) {
                        HStack(spacing: 2) {
                            Text("@").foregroundStyle(.secondary)
                            TextField("handle", text: $usernameText)
                                .multilineTextAlignment(.trailing)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .focused($nameFocused)
                                .submitLabel(.done)
                                .onSubmit { Task { await saveProfile() }; nameFocused = false }
                                .onChange(of: usernameText) { _, newValue in
                                    let stripped = newValue.replacingOccurrences(of: " ", with: "")
                                    if stripped != newValue { usernameText = stripped }
                                    scheduleUsernameCheck(stripped)
                                }
                        }
                        // Availability indicator
                        switch usernameState {
                        case .checking:
                            ProgressView().scaleEffect(0.7)
                        case .available:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.system(size: 14))
                        case .taken:
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                                .font(.system(size: 14))
                        case .idle:
                            EmptyView()
                        }
                    }
                }
                if usernameState == .taken {
                    Text("Username already taken")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Button { showChangeEmail = true } label: {
                    HStack {
                        Label("Email", systemImage: "envelope.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(Auth.auth().currentUser?.email ?? "—")
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Toggle(isOn: $userSettings.isPrivateAccount) {
                    Label("Private Account", systemImage: "lock.fill")
                }
                DatePicker(
                    "Date of Birth",
                    selection: $dobDate,
                    in: ...(Calendar.current.date(byAdding: .year, value: -13, to: Date()) ?? Date()),
                    displayedComponents: .date
                )
            }

            // MARK: Location
            Section {
                Button { showCitySearch = true } label: {
                    HStack {
                        Label("Profile Location", systemImage: "mappin.circle.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(userSettings.location.isEmpty ? "Set city" : userSettings.location)
                            .foregroundStyle(userSettings.location.isEmpty ? .secondary : .primary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                Toggle(isOn: $userSettings.useGPSLocation) {
                    Label("Use GPS Location", systemImage: "location.fill")
                }
            } header: {
                Text("Location")
            } footer: {
                Text("Profile Location is shown on your profile and used as a fallback. GPS Location uses your real-time position for posts and the local leaderboard.")
            }

            // MARK: Socials
            Section("Socials") {
                HStack {
                    Label("Instagram", systemImage: "camera.fill")
                        .foregroundStyle(
                            LinearGradient(colors: [.orange, .pink, .purple],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                    Spacer()
                    HStack(spacing: 2) {
                        Text("@").foregroundStyle(.secondary)
                        TextField("username", text: $userSettings.instagramHandle)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .submitLabel(.done)
                    }
                }
                HStack {
                    Label("TikTok", systemImage: "music.note")
                    Spacer()
                    HStack(spacing: 2) {
                        Text("@").foregroundStyle(.secondary)
                        TextField("username", text: $userSettings.tiktokHandle)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .submitLabel(.done)
                    }
                }
            }

            // MARK: Body
            Section {
                pickerRow(label: "Current Weight", display: "\(Int(currentWeightVal)) lbs") {
                    activePicker = .currentWeight
                }
                pickerRow(label: "Goal Weight", display: "\(Int(goalWeightVal)) lbs") {
                    activePicker = .goalWeight
                }
                pickerRow(label: "Height", display: heightInchesVal > 0 ? Self.formatHeight(heightInchesVal) : "Not set") {
                    activePicker = .height
                }
                Picker("Gender", selection: $userSettings.gender) {
                    Text("Not set").tag("")
                    Text("Male").tag("male")
                    Text("Female").tag("female")
                }
            } header: {
                Text("Body")
            } footer: {
                Text("Gender is used to calculate your daily calorie goal more accurately. Goal weight is limited to 5 lbs from your current weight — aim for 1–2 lbs per week.")
            }

            // MARK: Nutrition
            Section {
                pickerRow(label: "Protein per lb", display: String(format: "%.2f g/lb", proteinPerLbVal)) {
                    activePicker = .proteinPerLb
                }
                Toggle(isOn: $userSettings.autoAdjustMacrosForWorkout) {
                    Label("Auto-adjust macros for workouts", systemImage: "figure.strengthtraining.traditional")
                }
                Toggle(isOn: $userSettings.excludeDairy) {
                    Label("Exclude dairy", systemImage: "cup.and.saucer.fill")
                }
                Toggle(isOn: $userSettings.excludeGluten) {
                    Label("Exclude gluten", systemImage: "leaf.fill")
                }
            } header: {
                Text("Nutrition")
            } footer: {
                Text("Grams of protein per pound of goal body weight. General fitness: 0.7–0.8 g/lb. Strength training: 0.8–1.0 g/lb.\n\nWhen auto-adjust is on, the \"Apply macro adjustments\" toggle in the workout log sheet will default to ON, automatically updating your daily macro targets based on the type of workout logged.\n\nDietary exclusions are used by the AI meal planner to avoid suggesting meals with dairy or gluten.")
            }

            // MARK: Blocked Users
            Section {
                NavigationLink {
                    BlockedUsersView(currentUserID: userSettings.userID)
                } label: {
                    Label("Blocked Users", systemImage: "hand.raised.fill")
                }
            }

            // MARK: FAQ
            Section("FAQ") {
                ForEach(faqItems) { item in
                    Button {
                        activeFAQ = item
                    } label: {
                        HStack {
                            Text(item.question)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // MARK: Aura
            Section {
                Toggle("Aura XP Popups", isOn: $userSettings.auraPopupsEnabled)
            } header: {
                Text("Aura")
            } footer: {
                Text(userSettings.auraPopupsEnabled
                     ? "A popup appears whenever you earn Aura XP, showing your level, total, and progress to the next level."
                     : "Aura XP is still earned silently — no popup will appear.")
            }

            // MARK: Intermittent Fasting
            Section {
                Toggle("Track Intermittent Fasting Window", isOn: $userSettings.fastingEnabled)
            } header: {
                Text("Intermittent Fasting")
            } footer: {
                Text(userSettings.fastingEnabled
                     ? "Your intermittent fasting window is shown on the Home screen. Tap Edit to adjust the start time and duration."
                     : "Enable to track your daily intermittent fasting window on the Home screen.")
            }

            // MARK: Meal Logging Reminder
            Section {
                Toggle("Daily Meal Reminder", isOn: $userSettings.mealReminderEnabled)

                if userSettings.mealReminderEnabled {
                    DatePicker(
                        "Reminder Time",
                        selection: mealReminderTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text(userSettings.mealReminderEnabled
                     ? "You'll get a daily reminder at the time above if you haven't hit your macro goals yet."
                     : "Enable to receive a daily push notification reminding you to log your meals.")
            }

            // MARK: Health Disclaimer
            Section {
                NavigationLink {
                    HealthDisclaimerSettingsView()
                } label: {
                    Label("Health Disclaimer", systemImage: "heart.text.clipboard")
                }
            }

            // MARK: Privacy & Data
            Section {
                Button {
                    if let url = URL(string: "https://macromaxxing.app/privacy-policy") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    if let url = URL(string: "https://www.macromaxxing.app/terms") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    ATTrackingManager.requestTrackingAuthorization { _ in }
                } label: {
                    HStack {
                        Label("Ad Tracking Permissions", systemImage: "eye.slash.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(attStatusText)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    guard !isExportingData else { return }
                    isExportingData = true
                    Task {
                        do {
                            let uid = Auth.auth().currentUser?.uid ?? ""
                            let url = try await DataExportService.shared.exportAllData(userID: uid)
                            exportFileURL = url
                            showExportShare = true
                        } catch {
                            exportError = error.localizedDescription
                        }
                        isExportingData = false
                    }
                } label: {
                    HStack {
                        Label("Export My Data", systemImage: "square.and.arrow.up")
                            .foregroundStyle(.primary)
                        Spacer()
                        if isExportingData {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Privacy & Data")
            } footer: {
                Text("We do not sell or share your personal information for advertising purposes. Ad tracking permissions control whether personalized ads are shown. You can export a copy of all your data at any time.")
            }

            // MARK: Account Actions
            Section {
                Button(role: .destructive) {
                    // Save to Firestore BEFORE revoking auth — otherwise Firestore
                    // security rules reject the write (request.auth is null after logout).
                    Task { await saveProfile(); session.logout() }
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                }

                Button(role: .destructive) {
                    showDeleteAccount = true
                } label: {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.minus")
                        Text("Delete Account")
                    }
                }
            }

        }
        .onAppear {
            applyProfile(name:          userSettings.name,
                         username:      userSettings.username,
                         currentWeight: userSettings.currentWeight,
                         goalWeight:    userSettings.goalWeight,
                         heightInches:  userSettings.heightInches,
                         proteinPerLb:  userSettings.proteinPerLb)
        }
        .onChange(of: currentWeightVal) { _, newWeight in
            // Clamp goal weight to stay within ±5 lbs of current weight
            let clamped = min(max(goalWeightVal, newWeight - 5), newWeight + 5)
            if clamped != goalWeightVal { goalWeightVal = clamped }
        }
        .onDisappear { Task { await saveProfile() } }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .sheet(item: $activeFAQ) { item in
            FAQDetailView(item: item)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showCitySearch) {
            CitySearchSheet(location: $userSettings.location)
        }
        .sheet(item: $activePicker) { picker in
            NumberPickerSheet(picker: picker,
                              currentWeight: $currentWeightVal,
                              goalWeight:    $goalWeightVal,
                              heightInches:  $heightInchesVal,
                              proteinPerLb:  $proteinPerLbVal)
            { Task { await saveProfile() } }
                .presentationDetents([.height(280)])
        }
        .sheet(isPresented: $showDeleteAccount) {
            DeleteAccountView()
                .environment(session)
                .environment(userSettings)
        }
        .sheet(isPresented: $showChangeEmail) {
            ChangeEmailView()
                .environment(session)
        }
        .sheet(isPresented: $showExportShare) {
            if let url = exportFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Export Failed", isPresented: .init(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
    }

    private var attStatusText: String {
        switch ATTrackingManager.trackingAuthorizationStatus {
        case .authorized:     return "Allowed"
        case .denied:         return "Denied"
        case .restricted:     return "Restricted"
        case .notDetermined:  return "Not Set"
        @unknown default:     return "Unknown"
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func pickerRow(label: String, display: String, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack {
                Text(label).foregroundStyle(.primary)
                Spacer()
                Text(display)
                    .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.0))
                    .monospacedDigit()
                    .fontWeight(.semibold)
            }
        }
        .buttonStyle(.plain)
    }

    static func formatHeight(_ inches: Int) -> String {
        guard inches > 0 else { return "Not set" }
        return "\(inches / 12)'\(inches % 12)\""
    }

    private static let dobFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private func applyProfile(name: String, username: String,
                               currentWeight: Double, goalWeight: Double,
                               heightInches: Int, proteinPerLb: Double) {
        nameText         = name
        usernameText     = username
        currentWeightVal = currentWeight > 0 ? currentWeight : 160
        goalWeightVal    = goalWeight    > 0 ? goalWeight    : 160
        heightInchesVal  = heightInches
        proteinPerLbVal  = proteinPerLb
        if !userSettings.dateOfBirth.isEmpty,
           let d = Self.dobFormatter.date(from: userSettings.dateOfBirth) {
            dobDate = d
        }
    }

    private func saveProfile() async {
        guard usernameState != .taken else { return }
        let trimmedUsername = usernameText.trimmingCharacters(in: .whitespaces).lowercased()
            .replacingOccurrences(of: "@", with: "")
        guard !trimmedUsername.isEmpty else { return }
        let trimmedName = nameText.trimmingCharacters(in: .whitespaces)

        let dobString = Self.dobFormatter.string(from: dobDate)
        userSettings.dateOfBirth = dobString

        userSettings.heightInches = heightInchesVal

        let fields: [String: Any] = [
            "username": trimmedUsername, "name": trimmedName,
            "location": userSettings.location,
            "auraPoints": userSettings.auraPoints,
            // streakDays is owned by the computeStreak Cloud Function — do NOT overwrite
            "instagramHandle": userSettings.instagramHandle,
            "tiktokHandle": userSettings.tiktokHandle,
            "isPrivateAccount": userSettings.isPrivateAccount,
            "currentWeight": currentWeightVal,
            "goalWeight": goalWeightVal,
            "heightInches": heightInchesVal,
            "proteinPerLb": proteinPerLbVal,
            "gender":       userSettings.gender,
            "fastingEnabled": userSettings.fastingEnabled,
            "auraPopupsEnabled": userSettings.auraPopupsEnabled,
            "excludeDairy":      userSettings.excludeDairy,
            "excludeGluten":     userSettings.excludeGluten,
            "dateOfBirth": dobString,
        ]
        try? await session.updateProfile(fields: fields)
    }

    private func scheduleUsernameCheck(_ raw: String) {
        let cleaned = raw.trimmingCharacters(in: .whitespaces).lowercased()
            .replacingOccurrences(of: "@", with: "")

        // If unchanged from what's already saved, no need to check
        if cleaned == userSettings.username {
            usernameState = .idle
            usernameCheckTask?.cancel()
            return
        }
        if cleaned.isEmpty {
            usernameState = .idle
            usernameCheckTask?.cancel()
            return
        }

        usernameCheckTask?.cancel()
        usernameState = .checking
        usernameCheckTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
            guard !Task.isCancelled else { return }
            let uid = Auth.auth().currentUser?.uid ?? ""
            let taken = await UserProfileService.shared.isUsernameTaken(
                cleaned, excludingUserID: uid)
            await MainActor.run {
                usernameState = taken ? .taken : .available
            }
        }
    }
}

// MARK: - Number Picker Sheet

private struct NumberPickerSheet: View {
    let picker: ActivePicker
    @Binding var currentWeight: Double
    @Binding var goalWeight:    Double
    @Binding var heightInches:  Int
    @Binding var proteinPerLb:  Double
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let weightValues  = Array(100...300).map { Double($0) }
    // 4'6" (54 in) through 7'0" (84 in)
    private let heightValues  = Array(54...84)
    private let proteinValues = stride(from: 0.70, through: 1.00, by: 0.05).map { Double(String(format: "%.2f", $0))! }

    /// Goal weight is capped to ±5 lbs from current weight.
    private var goalWeightValues: [Double] {
        let low  = max(100, Int(currentWeight) - 5)
        let high = min(300, Int(currentWeight) + 5)
        return Array(low...high).map { Double($0) }
    }

    var body: some View {
        NavigationStack {
            switch picker {
            case .currentWeight:
                wheelPicker(
                    title: "Current Weight",
                    values: weightValues,
                    selection: $currentWeight,
                    label: { "\(Int($0)) lbs" }
                )
            case .goalWeight:
                wheelPicker(
                    title: "Goal Weight",
                    values: goalWeightValues,
                    selection: $goalWeight,
                    label: { "\(Int($0)) lbs" }
                )
            case .height:
                intWheelPicker(
                    title: "Height",
                    values: heightValues,
                    selection: $heightInches,
                    label: { SettingsView.formatHeight($0) }
                )
            case .proteinPerLb:
                wheelPicker(
                    title: "Protein per lb",
                    values: proteinValues,
                    selection: $proteinPerLb,
                    label: { String(format: "%.2f g/lb", $0) }
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func wheelPicker(
        title: String,
        values: [Double],
        selection: Binding<Double>,
        label: @escaping (Double) -> String
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(values, id: \.self) { v in
                Text(label(v)).tag(v)
            }
        }
        .pickerStyle(.wheel)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { onDone(); dismiss() }.fontWeight(.semibold)
            }
        }
    }

    @ViewBuilder
    private func intWheelPicker(
        title: String,
        values: [Int],
        selection: Binding<Int>,
        label: @escaping (Int) -> String
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(values, id: \.self) { v in
                Text(label(v)).tag(v)
            }
        }
        .pickerStyle(.wheel)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Default to 5'9" (69 in) if not yet set
            if selection.wrappedValue == 0 { selection.wrappedValue = 69 }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { onDone(); dismiss() }.fontWeight(.semibold)
            }
        }
    }
}

// MARK: - FAQ Detail Sheet

private struct FAQDetailView: View {
    let item: FAQItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(item.answer)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }
            .preferredColorScheme(.dark)
            .navigationTitle(item.question)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - City Search

@Observable
private final class CityCompleter: NSObject, MKLocalSearchCompleterDelegate {
    var suggestions: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func search(_ text: String) {
        completer.queryFragment = text
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Keep only results that look like cities/regions (no leading digit = not a street address)
        suggestions = completer.results.filter { result in
            guard let first = result.title.first else { return false }
            return !first.isNumber
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError: Error) {
        suggestions = []
    }
}

private struct CitySearchSheet: View {
    @Binding var location: String
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var completer = CityCompleter()

    var body: some View {
        NavigationStack {
            List {
                ForEach(completer.suggestions, id: \.title) { suggestion in
                    Button {
                        location = [suggestion.title, suggestion.subtitle]
                            .filter { !$0.isEmpty }
                            .joined(separator: ", ")
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title)
                                .foregroundStyle(.primary)
                            if !suggestion.subtitle.isEmpty {
                                Text(suggestion.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search city or region")
            .onChange(of: query) { _, new in completer.search(new) }
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if !location.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear") { location = ""; dismiss() }
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        SettingsView(userSettings: UserSettings())
            .environment(SessionManager())
    }
}
