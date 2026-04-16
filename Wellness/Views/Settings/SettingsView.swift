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
    @State private var theme = ThemeStore.shared
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

    // Subscription
    @State private var aiSubscription = AISubscriptionStore.shared
    @State private var showingAIPaywall = false
    @State private var subscriptionStatusMessage: String? = nil

    // Help & FAQ list sheet (collapses the 3 FAQ rows into one entry point)
    @State private var showingFAQList = false

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
        ScrollView {
            VStack(spacing: 14) {
                SettingsHeroCard(userSettings:      userSettings,
                                 nameText:          nameText,
                                 usernameText:      usernameText,
                                 aiSubscription:    aiSubscription,
                                 theme:             theme,
                                 showingAIPaywall:  $showingAIPaywall)
                youCard
                bodyNutritionCard
                notificationsCard
                socialsCard
                appearanceCard
                SettingsSubscriptionCard(aiSubscription:            aiSubscription,
                                         theme:                     theme,
                                         showingAIPaywall:          $showingAIPaywall,
                                         subscriptionStatusMessage: $subscriptionStatusMessage)
                helpSupportCard
                privacyDataCard
                SettingsDangerZoneCard(userSettings:      userSettings,
                                       session:           session,
                                       showDeleteAccount: $showDeleteAccount,
                                       onSave:            { await saveProfile() })

                Text("Macro Maxxing")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.25))
                    .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 40)
        }
        .background(Color.pageBg.ignoresSafeArea())
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
        .navigationTitle("Settings")
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
        .sheet(isPresented: $showingFAQList) {
            FAQListSheet(items: faqItems)
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
        .sheet(isPresented: $showingAIPaywall) {
            AISubscriptionPaywallView(
                onSubscribed: {
                    showingAIPaywall = false
                    subscriptionStatusMessage = "Subscription active — AI features unlocked."
                },
                onDismiss: { showingAIPaywall = false }
            )
        }
        .alert("Export Failed", isPresented: .init(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
        .task {
            await aiSubscription.loadProduct()
            await aiSubscription.refreshEntitlement()
        }
        .keyboardDoneToolbar()
    }

    // MARK: - Branded Cards

    // MARK: You (identity)
    /// Custom-rendered card (doesn't go through `settingCard`) so we can put
    /// a "View My Profile" button on the right side of the card header.
    private var youCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                iconBadge("person.fill", color: theme.accent)
                Text("You")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
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
                    HStack(spacing: 4) {
                        Text("View My Profile")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(theme.accent.opacity(0.14), in: Capsule())
                    .overlay(Capsule().stroke(theme.accent.opacity(0.35), lineWidth: 0.75))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            textFieldRow(label: "Name", placeholder: "Your name", text: $nameText, isUsername: false)
            divider
            usernameRow
            if usernameState == .taken {
                Text("Username already taken")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 6)
            }
            divider
            tapRow(title: "Email",
                   icon: "envelope.fill",
                   detail: Auth.auth().currentUser?.email ?? "—",
                   chevron: true) { showChangeEmail = true }
            divider
            toggleRow(label: "Private Account",
                      icon: "lock.fill",
                      isOn: $userSettings.isPrivateAccount)
            divider
            dobRow
            divider
            tapRow(title: "Profile Location",
                   icon: "mappin.circle.fill",
                   detail: userSettings.location.isEmpty ? "Set city" : userSettings.location,
                   chevron: true) { showCitySearch = true }
            divider
            toggleRow(label: "Use GPS on posts",
                      icon: "location.fill",
                      isOn: $userSettings.useGPSLocation)

            Text("Profile location shows on your profile as a fallback. GPS uses your real-time position for posts and the local leaderboard.")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.40))
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBg, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    private var usernameRow: some View {
        HStack(spacing: 10) {
            iconBadge("at", color: theme.accent)
            Text("Username")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            HStack(spacing: 6) {
                HStack(spacing: 1) {
                    Text("@").foregroundStyle(.white.opacity(0.45))
                    TextField("handle", text: $usernameText)
                        .multilineTextAlignment(.trailing)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                        .foregroundStyle(theme.accent)
                        .onSubmit { Task { await saveProfile() } }
                        .onChange(of: usernameText) { _, newValue in
                            let stripped = newValue.replacingOccurrences(of: " ", with: "")
                            if stripped != newValue { usernameText = stripped }
                            scheduleUsernameCheck(stripped)
                        }
                }
                switch usernameState {
                case .checking:  ProgressView().scaleEffect(0.65)
                case .available: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.system(size: 14))
                case .taken:     Image(systemName: "xmark.circle.fill").foregroundStyle(.red).font(.system(size: 14))
                case .idle:      EmptyView()
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var dobRow: some View {
        HStack(spacing: 10) {
            iconBadge("calendar", color: theme.accent)
            Text("Date of Birth")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            DatePicker("",
                       selection: $dobDate,
                       in: ...(Calendar.current.date(byAdding: .year, value: -13, to: Date()) ?? Date()),
                       displayedComponents: .date)
                .labelsHidden()
                .tint(theme.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: Body & Nutrition
    private var bodyNutritionCard: some View {
        settingCard(title: "Body & Nutrition", icon: "dumbbell.fill", iconColor: .orange) {
            brandedPickerRow(label: "Current Weight",
                             icon: "scalemass.fill",
                             display: "\(Int(currentWeightVal)) lbs") { activePicker = .currentWeight }
            divider
            brandedPickerRow(label: "Goal Weight",
                             icon: "target",
                             display: "\(Int(goalWeightVal)) lbs") { activePicker = .goalWeight }
            divider
            brandedPickerRow(label: "Height",
                             icon: "ruler.fill",
                             display: heightInchesVal > 0 ? Self.formatHeight(heightInchesVal) : "Not set") { activePicker = .height }
            divider
            sexRow
            divider
            brandedPickerRow(label: "Protein per lb",
                             icon: "fork.knife",
                             display: String(format: "%.2f g/lb", proteinPerLbVal)) { activePicker = .proteinPerLb }
            divider
            toggleRow(label: "Auto-adjust macros for workouts",
                      icon: "figure.strengthtraining.traditional",
                      isOn: $userSettings.autoAdjustMacrosForWorkout)
            divider
            toggleRow(label: "Exclude dairy",
                      icon: "cup.and.saucer.fill",
                      isOn: $userSettings.excludeDairy)
            divider
            toggleRow(label: "Exclude gluten",
                      icon: "leaf.fill",
                      isOn: $userSettings.excludeGluten)
            divider
            toggleRow(label: "Track intermittent fasting",
                      icon: "moon.stars.fill",
                      isOn: $userSettings.fastingEnabled)
        } footer: {
            "Goal weight is capped at ±5 lbs of your current weight — aim for 1–2 lbs per week. Protein per lb: general fitness 0.7–0.8, strength training 0.8–1.0. Dietary exclusions are applied by the AI meal planner and the photo macro scanner."
        }
    }

    private var sexRow: some View {
        HStack(spacing: 10) {
            iconBadge("person.2.fill", color: .orange)
            Text("Sex")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            Picker("Sex", selection: $userSettings.gender) {
                Text("Not set").tag("")
                Text("Male").tag("male")
                Text("Female").tag("female")
            }
            .pickerStyle(.menu)
            .tint(theme.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: Notifications
    private var notificationsCard: some View {
        settingCard(title: "Notifications", icon: "bell.fill", iconColor: Color(red: 1.00, green: 0.55, blue: 0.55)) {
            toggleRow(label: "Daily Meal Reminder",
                      icon: "fork.knife",
                      isOn: $userSettings.mealReminderEnabled)
            if userSettings.mealReminderEnabled {
                divider
                HStack(spacing: 10) {
                    iconBadge("clock.fill", color: theme.accent)
                    Text("Reminder Time")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    DatePicker("", selection: mealReminderTimeBinding, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(theme.accent)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
            }
            if userSettings.fastingEnabled {
                divider
                toggleRow(label: "Fasting Window Reminder",
                          icon: "hourglass",
                          isOn: $userSettings.fastingWindowNotificationEnabled)
            }
            divider
            toggleRow(label: "Aura XP Popups",
                      icon: "sparkles",
                      isOn: $userSettings.auraPopupsEnabled)
        } footer: { notificationsFooterText }
    }

    // MARK: Socials
    private var socialsCard: some View {
        settingCard(title: "Socials", icon: "link", iconColor: .pink) {
            socialRow(label: "Instagram",
                      icon: "camera.fill",
                      gradient: [.orange, .pink, .purple],
                      text: $userSettings.instagramHandle)
            divider
            socialRow(label: "TikTok",
                      icon: "music.note",
                      gradient: [.white, Color(red: 0.30, green: 0.90, blue: 0.80)],
                      text: $userSettings.tiktokHandle)
        }
    }

    private func socialRow(label: String, icon: String, gradient: [Color], text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(LinearGradient(colors: gradient.map { $0.opacity(0.15) },
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 26, height: 26)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
                    )
            }
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            HStack(spacing: 1) {
                Text("@").foregroundStyle(.white.opacity(0.45))
                TextField("username", text: text)
                    .multilineTextAlignment(.trailing)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .foregroundStyle(theme.accent)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: Appearance
    private var appearanceCard: some View {
        settingCard(title: "Appearance", icon: "paintpalette.fill", iconColor: theme.accent) {
            NavigationLink {
                AccentColorPickerView()
            } label: {
                HStack(spacing: 10) {
                    iconBadge("paintbrush.pointed.fill", color: theme.accent)
                    Text("Accent Color")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Circle().fill(theme.accent).frame(width: 18, height: 18)
                        .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
                    Text(theme.selectedAccent.displayName)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.55))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.30))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Help & Support
    private var helpSupportCard: some View {
        settingCard(title: "Help & Support", icon: "lifepreserver", iconColor: theme.accent) {
            tapRow(title: "Help & FAQs",
                   icon: "questionmark.circle.fill",
                   detail: nil,
                   chevron: true) { showingFAQList = true }
            divider
            NavigationLink {
                HealthDisclaimerSettingsView()
            } label: {
                HStack(spacing: 10) {
                    iconBadge("heart.text.clipboard", color: theme.accent)
                    Text("Health Disclaimer")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.30))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)
            divider
            if let mailURL = URL(string: "mailto:support@grnd-lab.com?subject=Macro%20Maxxing%20Feedback") {
                Link(destination: mailURL) {
                    HStack(spacing: 10) {
                        iconBadge("envelope.fill", color: theme.accent)
                        Text("Contact Us")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("support@grnd-lab.com")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.45))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.30))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                }
            }
        }
    }

    // MARK: Privacy & Data
    private var privacyDataCard: some View {
        settingCard(title: "Privacy & Data", icon: "hand.raised.fill", iconColor: Color(red: 0.35, green: 0.75, blue: 1.00)) {
            tapRow(title: "Privacy Policy",
                   icon: "shield.lefthalf.filled",
                   detail: nil,
                   chevron: false,
                   trailing: "arrow.up.right") {
                if let url = URL(string: "https://macromaxxing.app/privacy-policy") {
                    UIApplication.shared.open(url)
                }
            }
            divider
            tapRow(title: "Terms of Service",
                   icon: "doc.text.fill",
                   detail: nil,
                   chevron: false,
                   trailing: "arrow.up.right") {
                if let url = URL(string: "https://www.macromaxxing.app/terms") {
                    UIApplication.shared.open(url)
                }
            }
            divider
            tapRow(title: "Ad Tracking",
                   icon: "eye.slash.fill",
                   detail: attStatusText,
                   chevron: true) {
                ATTrackingManager.requestTrackingAuthorization { _ in }
            }
            divider
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
                HStack(spacing: 10) {
                    iconBadge("square.and.arrow.up", color: Color(red: 0.35, green: 0.75, blue: 1.00))
                    Text("Export My Data")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    if isExportingData {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.30))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)
        } footer: {
            "We don't sell your personal information. Ad tracking controls personalized ads. Export a full copy of your data any time."
        }
    }

    // MARK: - Card Shell + Shared Row Builders

    @ViewBuilder
    private func settingCard<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content,
        footer: (() -> String)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                iconBadge(icon, color: iconColor)
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            content()

            if let footer, let text = Optional(footer()) {
                Text(text)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.40))
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
            } else {
                Spacer().frame(height: 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBg, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    /// Small colored-tile icon used at the start of every row and card header.
    private func iconBadge(_ name: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(color.opacity(0.16))
                .frame(width: 26, height: 26)
            Image(systemName: name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .frame(height: 1)
            .padding(.leading, 50)
    }

    private func toggleRow(label: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            iconBadge(icon, color: theme.accent)
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(theme.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func tapRow(title: String,
                        icon: String,
                        detail: String?,
                        chevron: Bool,
                        trailing: String? = nil,
                        action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                iconBadge(icon, color: theme.accent)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                if let detail {
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                if chevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.30))
                } else if let trailing {
                    Image(systemName: trailing)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
    }

    private func textFieldRow(label: String, placeholder: String, text: Binding<String>, isUsername: Bool) -> some View {
        HStack(spacing: 10) {
            iconBadge("person.fill", color: theme.accent)
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            TextField(placeholder, text: text)
                .multilineTextAlignment(.trailing)
                .focused($nameFocused)
                .submitLabel(.next)
                .foregroundStyle(theme.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private func brandedPickerRow(label: String, icon: String, display: String, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                iconBadge(icon, color: .orange)
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text(display)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.accent)
                    .monospacedDigit()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.30))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
    }

    private var notificationsFooterText: String {
        var lines: [String] = []
        lines.append(userSettings.mealReminderEnabled
                     ? "You'll get a daily reminder at the time above if you haven't hit your macro goals yet."
                     : "Enable the daily meal reminder to get a push notification reminding you to log your meals.")
        if userSettings.fastingEnabled {
            lines.append(userSettings.fastingWindowNotificationEnabled
                         ? "You'll get a notification 90 minutes before your eating window closes so you can fit in a final meal."
                         : "The 90-minute fasting window reminder is off.")
        }
        return lines.joined(separator: "\n\n")
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
                    .foregroundStyle(ThemeStore.shared.accent)
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

// MARK: - Settings Card Components
//
// Extracted from `SettingsView.body` so each card has its own identity in the
// SwiftUI view graph. A single monolithic `body` returning deeply-nested
// `some View` expressions across 10 card computed properties was producing
// enough type-tree depth to overflow the main thread's stack during
// AttributeGraph construction (EXC_BAD_ACCESS code=2). Splitting them into
// their own `View` structs flattens the outer `body` return type and scopes
// re-renders to the card whose input actually changed.

private struct SettingsIconBadge: View {
    let name:  String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(color.opacity(0.16))
                .frame(width: 26, height: 26)
            Image(systemName: name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
        }
    }
}

private struct SettingsRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .frame(height: 1)
            .padding(.leading, 50)
    }
}

/// Shared tap-row used by the extracted cards. Kept separate from
/// `SettingsView.tapRow(...)` so the old callers don't have to change.
private struct SettingsTapRow: View {
    let title:    String
    let icon:     String
    let accent:   Color
    let detail:   String?
    let chevron:  Bool
    var trailing: String? = nil
    let action:   () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                SettingsIconBadge(name: icon, color: accent)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                if let detail {
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                if chevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.30))
                } else if let trailing {
                    Image(systemName: trailing)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
    }
}

// MARK: Hero Card

/// Avatar + name + @handle + subscription chip at the top of Settings.
private struct SettingsHeroCard: View {
    let userSettings:     UserSettings
    let nameText:         String
    let usernameText:     String
    let aiSubscription:   AISubscriptionStore
    let theme:            ThemeStore
    @Binding var showingAIPaywall: Bool

    var body: some View {
        HStack(spacing: 14) {
            heroAvatar
            VStack(alignment: .leading, spacing: 2) {
                Text(nameText.isEmpty ? userSettings.name : nameText)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(usernameText.isEmpty
                     ? (userSettings.username.isEmpty ? "—" : "@\(userSettings.username)")
                     : "@\(usernameText)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
                subscriptionChip
                    .padding(.top, 5)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.cardBg, Color.cardBgDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(RoundedRectangle(cornerRadius: 18)
            .stroke(theme.accent.opacity(0.22), lineWidth: 1))
    }

    @ViewBuilder
    private var heroAvatar: some View {
        if let data = userSettings.profileImageData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable().scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(Circle().stroke(theme.accent, lineWidth: 2))
        } else {
            ZStack {
                Circle().fill(Color.cardBgDeep)
                    .frame(width: 60, height: 60)
                    .overlay(Circle().stroke(theme.accent, lineWidth: 2))
                Image(systemName: "person.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(theme.accent)
            }
        }
    }

    private var subscriptionChip: some View {
        Button {
            if aiSubscription.isSubscribed {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            } else {
                showingAIPaywall = true
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: aiSubscription.isSubscribed ? "checkmark.seal.fill" : "sparkles")
                    .font(.system(size: 10, weight: .bold))
                Text(subscriptionChipLabel)
                    .font(.system(size: 11, weight: .black, design: .rounded))
            }
            .foregroundStyle(aiSubscription.isSubscribed ? Color(red: 0.30, green: 0.90, blue: 0.55) : theme.accent)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                (aiSubscription.isSubscribed
                    ? Color(red: 0.30, green: 0.90, blue: 0.55)
                    : theme.accent).opacity(0.14),
                in: Capsule()
            )
            .overlay(Capsule().stroke(
                (aiSubscription.isSubscribed
                    ? Color(red: 0.30, green: 0.90, blue: 0.55)
                    : theme.accent).opacity(0.35),
                lineWidth: 0.75
            ))
        }
        .buttonStyle(.plain)
    }

    private var subscriptionChipLabel: String {
        if aiSubscription.isSubscribed { return "PRO" }
        if aiSubscription.isEligibleForIntroOffer { return "TRY FREE" }
        return "UNLOCK AI"
    }
}

// MARK: Subscription Card

private struct SettingsSubscriptionCard: View {
    let aiSubscription: AISubscriptionStore
    let theme:          ThemeStore
    @Binding var showingAIPaywall:          Bool
    @Binding var subscriptionStatusMessage: String?

    var body: some View {
        let isPro = aiSubscription.isSubscribed
        let brand = isPro
            ? Color(red: 0.30, green: 0.90, blue: 0.55)
            : theme.accent

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                SettingsIconBadge(name: isPro ? "checkmark.seal.fill" : "sparkles", color: brand)
                VStack(alignment: .leading, spacing: 1) {
                    Text(isPro ? "AI Features Active" : "Unlock AI Features")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(subscriptionSubtitle)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
            }

            if isPro {
                if let expires = aiSubscription.expirationDate {
                    SettingsTapRow(title:   "Renews",
                                   icon:    "calendar",
                                   accent:  theme.accent,
                                   detail:  formattedDate(expires),
                                   chevron: false) { }
                }
                SettingsTapRow(title:    "Manage Subscription",
                               icon:     "creditcard.fill",
                               accent:   theme.accent,
                               detail:   nil,
                               chevron:  false,
                               trailing: "arrow.up.right") {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }
            } else {
                Button { showingAIPaywall = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text(aiSubscription.isEligibleForIntroOffer
                             ? "Try AI Free for 7 Days"
                             : "Unlock AI Features")
                        Spacer()
                        Text(aiSubscription.isEligibleForIntroOffer
                             ? "Free trial"
                             : aiSubscription.priceString + "/mo")
                            .opacity(0.85)
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.premiumGold, in: RoundedRectangle(cornerRadius: 12))
                    .shimmering(cornerRadius: 12)
                }
                .buttonStyle(.plain)
            }

            Button {
                Task {
                    let ok = await aiSubscription.restore()
                    subscriptionStatusMessage = ok
                        ? "Subscription restored."
                        : (aiSubscription.errorMessage ?? "No active subscription found.")
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Restore Purchases")
                    Spacer()
                    if aiSubscription.isRestoring { ProgressView().scaleEffect(0.7) }
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .disabled(aiSubscription.isRestoring)

            if let msg = subscriptionStatusMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.horizontal, 14)
                    .padding(.bottom, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBg, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(brand.opacity(isPro ? 0.40 : 0.55), lineWidth: 1))
    }

    private var subscriptionSubtitle: String {
        if aiSubscription.isSubscribed { return "AI Meal Planner, Nutrition Coach, and photo logging" }
        return "One subscription unlocks every AI feature in the app"
    }

    private func formattedDate(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: d)
    }
}

// MARK: Danger Zone Card

private struct SettingsDangerZoneCard: View {
    let userSettings:      UserSettings
    let session:           SessionManager
    @Binding var showDeleteAccount: Bool
    let onSave:            () async -> Void

    var body: some View {
        let danger = Color(red: 1.00, green: 0.45, blue: 0.45)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(danger.opacity(0.75))
                Text("DANGER ZONE")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(danger.opacity(0.75))
                    .tracking(1.0)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 6)

            NavigationLink {
                BlockedUsersView(currentUserID: userSettings.userID)
            } label: {
                HStack(spacing: 10) {
                    SettingsIconBadge(name: "hand.raised.fill", color: .white.opacity(0.55))
                    Text("Blocked Users")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.30))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)

            SettingsRowDivider()

            Button {
                Task { await onSave(); session.logout() }
            } label: {
                HStack(spacing: 10) {
                    SettingsIconBadge(name: "rectangle.portrait.and.arrow.right", color: danger)
                    Text("Sign Out")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(danger)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)

            SettingsRowDivider()

            Button {
                showDeleteAccount = true
            } label: {
                HStack(spacing: 10) {
                    SettingsIconBadge(name: "person.crop.circle.badge.minus", color: danger)
                    Text("Delete Account")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(danger)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBg, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(danger.opacity(0.30), lineWidth: 1))
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

// MARK: - FAQ List Sheet

/// Shown when the user taps "Help & FAQs" in Settings. Lists the available
/// FAQ topics; tapping one pushes its detail inside the same NavigationStack.
private struct FAQListSheet: View {
    let items: [FAQItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        FAQDetailInlineView(item: item)
                    } label: {
                        HStack {
                            Text(item.question)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.pageBg)
            .preferredColorScheme(.dark)
            .navigationTitle("Help & FAQs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

/// Same content as `FAQDetailView` but designed for NavigationStack push
/// (no sheet chrome). Exists because the original `FAQDetailView` wraps
/// itself in its own NavigationStack + Done button which would double up.
private struct FAQDetailInlineView: View {
    let item: FAQItem

    var body: some View {
        ScrollView {
            Text(item.answer)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
        }
        .background(Color.pageBg)
        .navigationTitle(item.question)
        .navigationBarTitleDisplayMode(.inline)
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
