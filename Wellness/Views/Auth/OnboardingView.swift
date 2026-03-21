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

    // Saving state
    @State private var isSaving = false
    @State private var saveError: String? = nil

    private let totalPages = 6
    private let purpl  = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                progressDots
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                // Page content
                TabView(selection: $page) {
                    namePage.tag(0)
                    profilePicPage.tag(1)
                    usernamePage.tag(2)
                    dobPage.tag(3)
                    weightPage.tag(4)
                    privacyPage.tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)

                // Navigation buttons
                navButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Pre-fill from whatever was collected at sign-up
            name     = userSettings.name
            username = userSettings.username
        }
    }

    // MARK: Progress Dots

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { i in
                Capsule()
                    .fill(i <= page ? purpl : Color.white.opacity(0.15))
                    .frame(width: i == page ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: page)
            }
        }
    }

    // MARK: Nav Buttons

    private var navButtons: some View {
        HStack(spacing: 16) {
            if page > 0 {
                Button("Back") {
                    withAnimation { page -= 1 }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.50))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            }

            Button(action: advance) {
                ZStack {
                    if isSaving {
                        ProgressView().tint(.black)
                    } else {
                        Text(page == totalPages - 1 ? "Let's Go!" : "Continue")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    canAdvance
                        ? LinearGradient(colors: [purpl, Color(red: 0.85, green: 0.55, blue: 1.0)],
                                         startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.12)],
                                         startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            }
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
        case 5: return true
        default: return true
        }
    }

    private func advance() {
        if page < totalPages - 1 {
            withAnimation { page += 1 }
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
            subtitle: "Used to personalize your experience. Not shown publicly."
        ) {
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

    private var dobRange: ClosedRange<Date> {
        let oldest = Calendar.current.date(byAdding: .year, value: -100, to: Date()) ?? Date()
        let youngest = Calendar.current.date(byAdding: .year, value: -13, to: Date()) ?? Date()
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
                heightPicker
                weightSlider(label: "Current Weight", value: $currentWeight)
                goalWeightSlider
                Text("Goal weight is limited to 5 lbs from your current weight. Sustainable progress means small, steady steps — aim for 1–2 lbs per week, then update your goal as you hit it.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.40))
                    .padding(.horizontal, 4)
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
            let taken = await UserProfileService.shared.isUsernameTaken(
                trimmed, excludingUserID: userSettings.userID)
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

        // Calculate macros using Mifflin-St Jeor (gender-neutral avg) + moderate activity
        let totalInches = heightFeet * 12 + heightInches
        let weightKg  = goalWeight * 0.453592
        let heightCm  = Double(totalInches) * 2.54
        let age       = Double(Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 20)
        let bmr       = 10.0 * weightKg + 6.25 * heightCm - 5.0 * age - 78.0
        let cals      = bmr * 1.55
        let protein   = goalWeight * 0.9
        let fat       = (cals * 0.25) / 9.0
        let carbs     = (cals - protein * 4.0 - fat * 9.0) / 4.0

        do {
            // Upload profile photo first if one was selected
            if let image = profileImage {
                try await session.updateProfilePhoto(image: image)
            }

            try await session.updateProfile(fields: [
                "name":             name.trimmingCharacters(in: .whitespacesAndNewlines),
                "username":         username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                "dateOfBirth":      dobString,
                "heightInches":     totalInches,
                "currentWeight":    currentWeight,
                "goalWeight":       goalWeight,
                "isPrivateAccount": isPrivate
            ])

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

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 12) {
                    Text(emoji)
                        .font(.system(size: 64))

                    Text(title)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                }

                content()
            }
            .padding(.horizontal, 28)
            .padding(.top, 32)
            .padding(.bottom, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}
