//
//  OnboardingView.swift
//  Wellness
//
//  Multi-step onboarding shown to brand-new users immediately after sign-up.
//  Collects: name, profile photo, username (with uniqueness check), date of birth,
//            current weight, goal weight, and account privacy preference.
//  Email is already captured at sign-up and shown in Settings via Firebase Auth.
//

import SwiftUI
import UIKit
import FirebaseAuth

// MARK: - OnboardingView

struct OnboardingView: View {

    @Environment(SessionManager.self) private var session
    @Environment(UserSettings.self)   private var userSettings

    // Current page index (0-based)
    @State private var page = 0

    // Collected values
    @State private var name:            String   = ""
    @State private var profileImage:    UIImage? = nil
    @State private var username:        String   = ""
    @State private var dateOfBirth:     Date     = Calendar.current.date(
        byAdding: .year, value: -20, to: Date()) ?? Date()
    @State private var heightFeet:       Int      = 5
    @State private var heightInches:    Int      = 9
    @State private var gender:          String   = ""
    @State private var currentWeight:   Double   = 160
    @State private var goalWeight:      Double   = 160
    @State private var isPrivate:       Bool     = true

    // Photo picker state
    @State private var showingPhotoPicker  = false
    @State private var showingCamera       = false

    // Username check state
    @State private var usernameAvailable: Bool?   = nil
    @State private var checkingUsername           = false
    @State private var usernameCheckTask: Task<Void, Never>? = nil

    // Age verification state (iOS 26+ Declared Age Range API)
    @State private var ageVerified = false
    @State private var ageCheckInProgress = false
    @State private var ageCheckDeclined = false

    // Health disclaimer
    @State private var healthDisclaimerAgreed = false

    // Saving state
    @State private var isSaving = false
    @State private var saveError: String? = nil

    private let totalPages = 7
    private let purpl    = Color(red: 0.65, green: 0.45, blue: 1.00)
    // Matches TutorialOverlayView: pure black dim behind a floating purple-bordered card.
    private let backdrop = Color.black.opacity(0.85)
    private let cardBg   = Color(red: 0.10, green: 0.10, blue: 0.14)

    var body: some View {
        ZStack {
            // Dark backdrop — same visual language as TutorialOverlayView.
            backdrop.ignoresSafeArea()

            // Decorative purple glow behind the card so the screen doesn't
            // feel empty with a pure-black backdrop.
            RadialGradient(
                colors: [purpl.opacity(0.22), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 340
            )
            .ignoresSafeArea()

            // A single floating card that swaps its inner content as the
            // user advances. Mirrors TutorialOverlayView.card precisely:
            // header (progress + counter), title/body, then nav buttons.
            VStack(alignment: .leading, spacing: 18) {
                cardHeader

                ScrollView {
                    pageContent
                        .id(page)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal:   .opacity.combined(with: .move(edge: .leading))
                        ))
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
                // Let the card grow with content but cap at 62% of screen
                // so it stays the same approximate size as the tutorial card
                // and leaves room for the keyboard on short devices.
                .frame(maxHeight: 440)

                navButtons
            }
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(purpl.opacity(0.30), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.50), radius: 24, y: 8)
            }
            .padding(.horizontal, 16)
        }
        .animation(.easeInOut(duration: 0.3), value: page)
        .onAppear {
            // Pre-fill from whatever was collected at sign-up
            name     = userSettings.name
            username = userSettings.username
            // If sign-up already collected name + username, skip to the profile photo page
            if !name.isEmpty && username.count >= 4 {
                page = 1
            }
        }
    }

    // MARK: Page switcher

    @ViewBuilder
    private var pageContent: some View {
        switch page {
        case 0: namePage
        case 1: profilePicPage
        case 2: usernamePage
        case 3: dobPage
        case 4: weightPage
        case 5: healthDisclaimerPage
        case 6: privacyPage
        default: EmptyView()
        }
    }

    // MARK: Card Header (progress capsules + step counter)
    // Matches TutorialOverlayView's progress row: tiny capsules that grow
    // for the active step, with "N / M" counter on the right.

    private var cardHeader: some View {
        HStack(spacing: 0) {
            HStack(spacing: 5) {
                ForEach(0..<totalPages, id: \.self) { i in
                    Capsule()
                        .fill(i == page
                              ? purpl
                              : Color.white.opacity(0.20))
                        .frame(width: i == page ? 18 : 6, height: 6)
                        .animation(.spring(duration: 0.3), value: page)
                }
            }
            Spacer()
            Text("\(page + 1) / \(totalPages)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.40))
        }
    }

    // MARK: Nav Buttons
    // Matches TutorialOverlayView's footer: subtle Back pill on the left,
    // bold solid-purple Next/Let's Go pill on the right.

    private var navButtons: some View {
        HStack(spacing: 10) {
            if page > 0 {
                Button { withAnimation { page -= 1 } } label: {
                    Text("Back")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(Color.white.opacity(0.10),
                                    in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Button(action: advance) {
                ZStack {
                    if isSaving {
                        ProgressView().tint(.black)
                    } else {
                        Text(page == totalPages - 1 ? "Let's Go!" : "Next")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 9)
                .background(
                    canAdvance ? purpl : Color.white.opacity(0.18),
                    in: RoundedRectangle(cornerRadius: 10)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canAdvance || isSaving)
        }
    }

    // MARK: Can Advance Logic

    private var canAdvance: Bool {
        switch page {
        case 0: return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 1: return true   // photo is optional
        case 2: return (usernameAvailable == true) && username.count >= 4
        case 3: return true   // DOB always valid
        case 4: return currentWeight > 0 && goalWeight > 0
        case 5: return healthDisclaimerAgreed
        case 6: return true
        default: return true
        }
    }

    private func advance() {
        // Baseline step: require a sex selection before proceeding, since it
        // feeds the Mifflin–St Jeor BMR calculation used to set macro goals.
        if page == 4 && gender.isEmpty {
            saveError = "Please select a sex. We use this to calculate your daily calorie and macro goals (the Mifflin–St Jeor formula adjusts BMR by biological sex)."
            return
        }
        if page < totalPages - 1 {
            var next = page + 1
            // Skip username page if already set from sign-up
            if next == 2 && username.count >= 4 {
                next = 3
            }
            withAnimation { page = next }
        } else {
            Task { await finishOnboarding() }
        }
    }

    // MARK: - Pages

    // Page 0: Name
    private var namePage: some View {
        OnboardingPageShell(
            emoji: "👋",
            title: "What should we call you?",
            subtitle: "This is your display name — you can change it anytime in Settings."
        ) {
            VStack(spacing: 0) {
                TextField("Display name", text: $name)
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                    .autocorrectionDisabled()
            }
        }
    }

    // Page 1: Profile Picture
    private var profilePicPage: some View {
        OnboardingPageShell(
            emoji: "📸",
            title: "Add a profile photo",
            subtitle: "Put a face to the name. You can always change it later."
        ) {
            VStack(spacing: 24) {
                // Avatar preview
                ZStack {
                    if let img = profileImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 130, height: 130)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(purpl.opacity(0.15))
                            .frame(width: 130, height: 130)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 54))
                                    .foregroundStyle(purpl.opacity(0.40))
                            }
                    }

                    // Edit badge
                    Circle()
                        .fill(purpl)
                        .frame(width: 34, height: 34)
                        .overlay {
                            Image(systemName: profileImage == nil ? "plus" : "pencil")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .offset(x: 44, y: 44)
                }
                .frame(width: 130, height: 130)
                .onTapGesture { showingPhotoPicker = true }

                // Source buttons
                VStack(spacing: 10) {
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            showingCamera = true
                        } label: {
                            Label("Take a Photo", systemImage: "camera.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }

                    if profileImage != nil {
                        Button {
                            profileImage = nil
                        } label: {
                            Text("Remove photo")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.40))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            ImagePickerView(sourceType: .photoLibrary, selectedImage: $profileImage)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePickerView(sourceType: .camera, selectedImage: $profileImage)
        }
    }

    // Page 2: Username
    private var usernamePage: some View {
        OnboardingPageShell(
            emoji: "🪪",
            title: "Choose your username",
            subtitle: "Minimum 4 characters, letters and numbers only. You can't change this later."
        ) {
            VStack(spacing: 10) {
                HStack {
                    Text("@")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(purpl)
                    TextField("username", text: $username)
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: username) { _, newVal in
                            let stripped = newVal.replacingOccurrences(of: " ", with: "")
                            if stripped != newVal { username = stripped }
                            scheduleUsernameCheck(stripped)
                        }
                    if checkingUsername {
                        ProgressView().tint(purpl).scaleEffect(0.8)
                    } else if let available = usernameAvailable {
                        Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(available ? .green : .red)
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))

                if let available = usernameAvailable, !checkingUsername {
                    Text(available ? "Username is available!" : "That username is already taken.")
                        .font(.caption)
                        .foregroundStyle(available ? .green : .red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
            }
        }
    }

    // Page 3: Date of Birth
    private var dobPage: some View {
        OnboardingPageShell(
            emoji: "🎂",
            title: "When's your birthday?",
            subtitle: "You must be at least 18 years old to use Macro Maxxing. Not shown publicly."
        ) {
            VStack(spacing: 16) {
                // On iOS 26+, try Apple's Declared Age Range API first
                if AgeVerificationService.isAvailable && !ageVerified && !ageCheckDeclined {
                    Button {
                        Task { await requestAppleAgeVerification() }
                    } label: {
                        HStack(spacing: 10) {
                            if ageCheckInProgress {
                                ProgressView().tint(.black)
                            } else {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Verify Age with Apple")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(ageCheckInProgress)
                    .buttonStyle(.plain)

                    Text("or enter your date of birth below")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.40))
                }

                if ageVerified {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Age verified by Apple")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 8)
                }

                DatePicker(
                    "",
                    selection: $dateOfBirth,
                    in: dobRange,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func requestAppleAgeVerification() async {
        ageCheckInProgress = true
        let result = await AgeVerificationService.verifyAge()
        ageCheckInProgress = false

        switch result {
        case .verified:
            ageVerified = true
        case .underage:
            saveError = "You must be at least 18 years old to use Macro Maxxing."
        case .declined:
            ageCheckDeclined = true
        case .unavailable:
            ageCheckDeclined = true
        }
    }

    private var dobRange: ClosedRange<Date> {
        let oldest = Calendar.current.date(byAdding: .year, value: -100, to: Date()) ?? Date()
        let youngest = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
        return oldest...youngest
    }

    // Page 4: Weights
    private var weightPage: some View {
        OnboardingPageShell(
            emoji: "⚖️",
            title: "Set your baseline",
            subtitle: "We'll use these to calculate your daily macro goals."
        ) {
            VStack(spacing: 20) {
                genderPicker
                heightPicker
                weightSlider(label: "Current Weight", value: $currentWeight)
                goalWeightSlider
                Text("Goal weight is limited to 5 lbs from your current weight. Sustainable progress means small, steady steps — aim for 1–2 lbs per week, then update your goal as you hit it.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.40))
                    .padding(.horizontal, 4)
                if page == 4, let error = saveError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
        }
    }

    private var goalWeightSlider: some View {
        let low  = max(80, currentWeight - 5)
        let high = min(400, currentWeight + 5)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Goal Weight")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.65))
                Spacer()
                Text("\(Int(goalWeight)) lbs")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            Slider(value: $goalWeight, in: low...high, step: 1)
                .tint(purpl)
        }
        .padding(16)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
        .onChange(of: currentWeight) { _, newWeight in
            let clamped = min(max(goalWeight, newWeight - 5), newWeight + 5)
            if clamped != goalWeight { goalWeight = clamped }
        }
    }

    private var genderPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sex")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.65))
            HStack(spacing: 12) {
                genderButton(label: "Male", value: "male")
                genderButton(label: "Female", value: "female")
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
    }

    private func genderButton(label: String, value: String) -> some View {
        Button {
            gender = value
            // Clear the "please select a sex" error once the user picks one.
            if saveError != nil { saveError = nil }
        } label: {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(gender == value ? .black : .white.opacity(0.55))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(gender == value ? purpl : Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var heightPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Height")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.65))
                Spacer()
                Text("\(heightFeet)'\(heightInches)\"")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Picker("Feet", selection: $heightFeet) {
                        ForEach(3...7, id: \.self) { ft in
                            Text("\(ft) ft").tag(ft)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 90, height: 100)
                    .clipped()

                    Picker("Inches", selection: $heightInches) {
                        ForEach(0...11, id: \.self) { inch in
                            Text("\(inch) in").tag(inch)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 90, height: 100)
                    .clipped()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
    }

    private func weightSlider(label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.65))
                Spacer()
                Text("\(Int(value.wrappedValue)) lbs")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            Slider(value: value, in: 80...400, step: 1)
                .tint(purpl)
        }
        .padding(16)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
    }

    // Page 5: Privacy
    // Page 5: Health Disclaimer
    private var healthDisclaimerPage: some View {
        OnboardingPageShell(
            emoji: "⚕️",
            title: "Health Disclaimer",
            subtitle: "Please read and acknowledge before continuing."
        ) {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    disclaimerRow(
                        icon: "heart.text.clipboard",
                        text: "This app is for fitness tracking only and does not provide medical advice."
                    )
                    disclaimerRow(
                        icon: "sparkles",
                        text: "AI-estimated nutritional values are approximations and may not be fully accurate."
                    )
                    disclaimerRow(
                        icon: "stethoscope",
                        text: "Consult a healthcare professional before making significant changes to your diet or exercise routine."
                    )
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )

                Button {
                    healthDisclaimerAgreed.toggle()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: healthDisclaimerAgreed ? "checkmark.square.fill" : "square")
                            .font(.system(size: 22))
                            .foregroundStyle(healthDisclaimerAgreed ? purpl : .white.opacity(0.35))
                        Text("I understand and acknowledge this disclaimer")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(healthDisclaimerAgreed ? 0.09 : 0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(healthDisclaimerAgreed ? purpl.opacity(0.50) : Color.clear, lineWidth: 1.5)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func disclaimerRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(purpl)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // Page 6: Privacy
    private var privacyPage: some View {
        OnboardingPageShell(
            emoji: "🔒",
            title: "Who can see your profile?",
            subtitle: "You can always change this later in Settings."
        ) {
            VStack(spacing: 12) {
                privacyOption(
                    icon: "lock.fill",
                    title: "Private",
                    desc: "Only approved followers can see your profile and posts.",
                    selected: isPrivate
                ) { isPrivate = true }

                privacyOption(
                    icon: "globe",
                    title: "Public",
                    desc: "Anyone can view your profile, follow you, and see your posts. Go public to compete on the Arena and Local leaderboards and earn bonus Aura XP each week.",
                    selected: !isPrivate
                ) { isPrivate = false }

                if let error = saveError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
        }
    }

    private func privacyOption(icon: String, title: String, desc: String,
                               selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(purpl.opacity(selected ? 0.25 : 0.08))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(selected ? purpl : .white.opacity(0.35))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.50))
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(purpl)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(selected ? 0.09 : 0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(selected ? purpl.opacity(0.50) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Username Check

    private func scheduleUsernameCheck(_ raw: String) {
        usernameAvailable = nil
        usernameCheckTask?.cancel()
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 4 else { return }
        usernameCheckTask = Task {
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s debounce
            guard !Task.isCancelled else { return }
            checkingUsername = true
            let uid = userSettings.userID.isEmpty
                ? (Auth.auth().currentUser?.uid ?? "")
                : userSettings.userID
            let taken = await UserProfileService.shared.isUsernameTaken(
                trimmed, excludingUserID: uid)
            guard !Task.isCancelled else { return }
            checkingUsername = false
            usernameAvailable = !taken
        }
    }

    // MARK: - Finish

    private func finishOnboarding() async {
        isSaving = true
        saveError = nil

        let dobFormatter = DateFormatter()
        dobFormatter.dateFormat = "yyyy-MM-dd"
        let dobString = dobFormatter.string(from: dateOfBirth)

        // Calculate macros using Mifflin-St Jeor + sedentary baseline (1.2)
        // Auto-adjust for workouts handles extra calories on active days.
        let totalInches = heightFeet * 12 + heightInches
        let weightKg  = goalWeight * 0.453592
        let heightCm  = Double(totalInches) * 2.54
        let age       = Double(Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 20)
        let genderOffset: Double = gender == "male" ? 5.0 : gender == "female" ? -161.0 : -78.0
        let bmr       = 10.0 * weightKg + 6.25 * heightCm - 5.0 * age + genderOffset
        let cals      = bmr * 1.2
        let protein   = goalWeight * 0.9
        let fat       = (cals * 0.25) / 9.0
        let carbs     = (cals - protein * 4.0 - fat * 9.0) / 4.0

        // Route sensitive fields (DOB, weights, height, gender) to the
        // `users/{uid}/private/profile` subcollection. Post-migration these
        // no longer live in the public doc, and `fetchProfile` reads the
        // private doc last and overrides anything in the public doc with
        // whatever it finds there. Writing these through the public-doc
        // path would leave the private doc at its createProfile defaults
        // (dateOfBirth: "", heightInches: 0), which in turn trips the
        // onboarding gate in `SessionManager.fetchAndApplyProfile` the
        // next time the app returns to the foreground — including the
        // brief scenePhase flicker iOS fires when the user takes a
        // screenshot during the post-onboarding tutorial.
        let uid = userSettings.userID.isEmpty
            ? (Auth.auth().currentUser?.uid ?? "")
            : userSettings.userID
        let privateFields: [String: Any] = [
            "dateOfBirth":   dobString,
            "heightInches":  totalInches,
            "gender":        gender,
            "currentWeight": currentWeight,
            "goalWeight":    goalWeight,
        ]
        let publicFields: [String: Any] = [
            "name":             name.trimmingCharacters(in: .whitespacesAndNewlines),
            "username":         username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            "isPrivateAccount": isPrivate,
        ]

        do {
            // Write the private subcollection FIRST. Both `updateProfilePhoto`
            // and `updateProfile` call `fetchAndApplyProfile` internally, and
            // that call trips the onboarding gate in `SessionManager` if the
            // private doc still holds empty `dateOfBirth` / `heightInches`.
            // Getting the private doc right up front also keeps `populate`
            // from briefly overwriting UserSettings with stale empty values.
            try await UserProfileService.shared.updatePrivateProfile(
                userID: uid, fields: privateFields)

            // Upload profile photo if one was selected
            if let image = profileImage {
                try await session.updateProfilePhoto(image: image)
            }

            try await session.updateProfile(fields: publicFields)

            // Update local macro goals to match the goal weight
            UserDefaults.standard.set(max(cals,    1200), forKey: "goalCalories")
            UserDefaults.standard.set(max(protein,    50), forKey: "goalProtein")
            UserDefaults.standard.set(max(carbs,      50), forKey: "goalCarbs")
            UserDefaults.standard.set(max(fat,        20), forKey: "goalFat")

            session.needsOnboarding = false
        } catch {
            saveError = "Couldn't save your profile. Please try again."
            isSaving = false
        }
    }
}

// MARK: - Shared Page Shell

private struct OnboardingPageShell<Content: View>: View {

    let emoji:    String
    let title:    String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    // Matches TutorialOverlayView.card's title/body typography:
    // • title: 19pt .black .rounded white
    // • body : 14pt white.opacity(0.82) with a little line-spacing
    // The emoji is kept but shrunk and left-aligned so it reads as a small
    // section accent rather than a giant hero image.
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(emoji)
                        .font(.system(size: 24))
                    Text(title)
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
