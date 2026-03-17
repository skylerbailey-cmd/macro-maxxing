//
//  SettingsView.swift
//  Wellness
//

import SwiftUI
import MapKit
import FirebaseAuth

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
        question: "What are Aura Points?",
        answer: """
        Aura Points are the currency of your gains journey. Every rep in the gym and \
        every meal you track earns you Aura.

        Streaks — consecutive days hitting ALL macro goals (each milestone awarded once):
        • 3-day streak → +50 pts
        • 7-day streak → +150 pts
        • 14-day streak → +300 pts
        • 30-day streak → +500 pts
        • 60-day streak → +750 pts
        • 100-day streak → +1,000 pts

        Logging food alone does not count — you have to actually hit your goals.

        Posts, Comments & Reps (Social):
        • Post when you crush your macro goals → +50 pts
        • Rep a post or comment → +1 pt per rep
        • Comment on someone's post → +1 pt
        • Comment with a photo → +5 pts

        Leaderboard (Mog Board, resets every Monday):
        Local top 10:
        • #1 → +75 pts  •  #2–3 → +50 pts  •  #4–10 → +25 pts
        Arena top 10:
        • #1 → +150 pts  •  #2–3 → +100 pts  •  #4–10 → +50 pts

        Points are calculated Sunday at 11:59 PM EST and awarded the next time \
        you open the app. Arena pays more — you're up against everyone.
        """
    ),
    FAQItem(
        question: "What are Aura Levels?",
        answer: """
        Aura Levels show where you stand on the looksmaxxing hierarchy. \
        Every 1,000 Aura Points = 1 level, up to a max of Level 100.

        Level titles:
        • Level 0 — (no title yet)
        • Levels 1–9 — Initiate
        • Levels 10–24 — Disciple
        • Levels 25–39 — Ascender
        • Levels 40–59 — Mog Apprentice
        • Levels 60–79 — Aura Farmer
        • Levels 80–94 — Elite Aesthetic
        • Levels 95–100 — Final Form

        Your level and title appear under your name on the Home screen and \
        next to your name on every post you make. Stack those points and ascend.
        """
    ),
]

// MARK: - SettingsView

private enum ActivePicker: Identifiable {
    case currentWeight, goalWeight, proteinPerLb
    var id: Self { self }
}

struct SettingsView: View {
    @Bindable var userSettings: UserSettings
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @FocusState private var nameFocused: Bool

    // Local state — only writes to userSettings on commit, preventing re-renders on every input
    @State private var activeFAQ: FAQItem? = nil
    @State private var nameText:         String = ""
    @State private var usernameText:     String = ""
    @State private var currentWeightVal: Double = 160
    @State private var goalWeightVal:    Double = 160
    @State private var proteinPerLbVal:  Double = 0.9
    @State private var activePicker: ActivePicker? = nil
    @State private var showCitySearch    = false
    @State private var showDeleteAccount = false
    @State private var showChangeEmail   = false

    /// The Firebase UID that was active when this view appeared.
    /// commitAll() uses this — not userSettings.userID — so a late .onDisappear
    /// call can't accidentally write one user's local state into another user's
    /// Firestore document after an account switch.
    @State private var sessionUID: String = ""

    /// True once the user has edited any text field in this session.
    /// While false, incoming userSettings changes (from the async Firestore fetch)
    /// are allowed to refresh the local state vars.
    @State private var isDirty = false

    // Username availability
    private enum UsernameState { case idle, checking, available, taken }
    @State private var usernameState: UsernameState = .idle
    @State private var usernameCheckTask: Task<Void, Never>? = nil

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
                        .onChange(of: nameText) { _, _ in isDirty = true }
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
                                .onSubmit { Task { await commitAll() }; nameFocused = false }
                                .onChange(of: usernameText) { _, newValue in
                                    isDirty = true
                                    scheduleUsernameCheck(newValue)
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

                Button { showCitySearch = true } label: {
                    HStack {
                        Label("Location", systemImage: "mappin.circle.fill")
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
                Toggle(isOn: $userSettings.isPrivateAccount) {
                    Label("Private Account", systemImage: "lock.fill")
                }
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
            Section("Body") {
                pickerRow(label: "Current Weight", display: "\(Int(currentWeightVal)) lbs") {
                    activePicker = .currentWeight
                }
                pickerRow(label: "Goal Weight", display: "\(Int(goalWeightVal)) lbs") {
                    activePicker = .goalWeight
                }
            }

            // MARK: Nutrition
            Section {
                pickerRow(label: "Protein per lb", display: String(format: "%.2f g/lb", proteinPerLbVal)) {
                    activePicker = .proteinPerLb
                }
            } header: {
                Text("Nutrition")
            } footer: {
                Text("Grams of protein per pound of goal body weight. General fitness: 0.7–0.8 g/lb. Strength training: 0.8–1.0 g/lb.")
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
                Toggle("Aura Points Popups", isOn: $userSettings.auraPopupsEnabled)
            } header: {
                Text("Aura")
            } footer: {
                Text(userSettings.auraPopupsEnabled
                     ? "A popup appears whenever you earn Aura Points, showing your level, total, and progress to the next level."
                     : "Aura Points are still earned silently — no popup will appear.")
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

            // MARK: Account Actions
            Section {
                Button(role: .destructive) {
                    // Save to Firestore BEFORE revoking auth — otherwise Firestore
                    // security rules reject the write (request.auth is null after logout).
                    Task { await commitAll(); auth.logout() }
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
            isDirty    = false
            sessionUID = userSettings.userID
            // Seed fields from whatever userSettings already holds (may be empty
            // if the Firestore fetch hasn't finished yet — loadProfile() below
            // will overwrite with the real values once the fetch completes).
            applyProfile(name:          userSettings.name,
                         username:      userSettings.username,
                         currentWeight: userSettings.currentWeight,
                         goalWeight:    userSettings.goalWeight,
                         proteinPerLb:  userSettings.proteinPerLb)
            Task { await loadProfile() }
        }
        .onDisappear { Task { await commitAll() } }
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
                              proteinPerLb:  $proteinPerLbVal)
            { Task { await commitAll() } }
                .presentationDetents([.height(280)])
        }
        .sheet(isPresented: $showDeleteAccount) {
            DeleteAccountView()
                .environment(auth)
                .environment(userSettings)
        }
        .sheet(isPresented: $showChangeEmail) {
            ChangeEmailView()
                .environment(auth)
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

    /// Fetches the profile directly from Firestore and populates all local fields.
    /// Called on every onAppear so Settings always shows fresh data regardless of
    /// whether syncUserSettings has already completed.
    private func loadProfile() async {
        let uid = userSettings.userID
        guard !uid.isEmpty else { return }
        guard let profile = try? await UserProfileService.shared.fetchProfile(userID: uid) else { return }
        guard !isDirty else { return }   // user started typing while fetch was in flight

        // Push fetched values into userSettings so the rest of the app stays in sync
        userSettings.name              = profile.name
        userSettings.username          = profile.username
        userSettings.location          = profile.location
        userSettings.auraPoints        = profile.auraPoints
        userSettings.macroStreak       = profile.streakDays
        userSettings.instagramHandle   = profile.instagramHandle
        userSettings.tiktokHandle      = profile.tiktokHandle
        userSettings.isPrivateAccount  = profile.isPrivateAccount
        userSettings.currentWeight     = profile.currentWeight
        userSettings.goalWeight        = profile.goalWeight
        userSettings.proteinPerLb      = profile.proteinPerLb
        userSettings.fastingEnabled    = profile.fastingEnabled
        userSettings.auraPopupsEnabled = profile.auraPopupsEnabled

        // Populate the local text/number fields shown in this view
        applyProfile(name:          profile.name,
                     username:      profile.username,
                     currentWeight: profile.currentWeight,
                     goalWeight:    profile.goalWeight,
                     proteinPerLb:  profile.proteinPerLb)
    }

    private func applyProfile(name: String, username: String,
                               currentWeight: Double, goalWeight: Double,
                               proteinPerLb: Double) {
        nameText         = name
        usernameText     = username
        currentWeightVal = currentWeight > 0 ? currentWeight : 160
        goalWeightVal    = goalWeight    > 0 ? goalWeight    : 160
        proteinPerLbVal  = proteinPerLb
    }

    private func commitAll() async {
        // Block save if the username is confirmed taken
        guard usernameState != .taken else { return }

        // Don't write to Firestore if username is still empty — that means the
        // Firestore profile fetch (syncUserSettings) hasn't completed yet and the
        // local state was never populated. Writing now would overwrite real Firestore
        // data with blank values.
        let trimmedUsernameEarlyCheck = usernameText
            .trimmingCharacters(in: .whitespaces)
            .lowercased()
            .replacingOccurrences(of: "@", with: "")
        guard !trimmedUsernameEarlyCheck.isEmpty else { return }

        // Use the UID captured at onAppear time (sessionUID), not userSettings.userID.
        // If .onDisappear fires late — after an account switch has already changed
        // userSettings.userID to a different user — the snapshot below would carry
        // the old session's local text into the new user's Firestore document.
        // Guarding against Auth.currentUser ensures we only write when the session
        // user is still the one currently authenticated.
        let uid = sessionUID
        guard !uid.isEmpty, uid == Auth.auth().currentUser?.uid else { return }

        let trimmedName = nameText.trimmingCharacters(in: .whitespaces)
        let trimmedUsername = usernameText
            .trimmingCharacters(in: .whitespaces)
            .lowercased()
            .replacingOccurrences(of: "@", with: "")
        userSettings.name          = trimmedName
        userSettings.username      = trimmedUsername
        userSettings.currentWeight = currentWeightVal
        userSettings.goalWeight    = goalWeightVal
        userSettings.proteinPerLb  = proteinPerLbVal

        let fields: [String: Any] = [
            "username":          trimmedUsername,
            "name":              trimmedName,
            "location":          userSettings.location,
            "auraPoints":        userSettings.auraPoints,
            "streakDays":        userSettings.macroStreak,
            "instagramHandle":   userSettings.instagramHandle,
            "tiktokHandle":      userSettings.tiktokHandle,
            "isPrivateAccount":  userSettings.isPrivateAccount,
            "currentWeight":     currentWeightVal,
            "goalWeight":        goalWeightVal,
            "proteinPerLb":      proteinPerLbVal,
            "fastingEnabled":    userSettings.fastingEnabled,
            "auraPopupsEnabled": userSettings.auraPopupsEnabled,
        ]
        // Await the write so callers (e.g. Sign Out button) can ensure it
        // completes while the user is still authenticated.
        try? await UserProfileService.shared.updateProfile(userID: uid, fields: fields)
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
            let taken = await UserProfileService.shared.isUsernameTaken(
                cleaned, excludingUserID: userSettings.userID)
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
    @Binding var proteinPerLb:  Double
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let weightValues  = Array(100...300).map { Double($0) }
    private let proteinValues = stride(from: 0.70, through: 1.00, by: 0.05).map { Double(String(format: "%.2f", $0))! }

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
                    values: weightValues,
                    selection: $goalWeight,
                    label: { "\(Int($0)) lbs" }
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

#Preview {
    NavigationStack {
        SettingsView(userSettings: UserSettings())
            .environment(AuthViewModel())
    }
}
