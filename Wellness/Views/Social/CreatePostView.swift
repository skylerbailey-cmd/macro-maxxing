//
//  CreatePostView.swift
//  Wellness
//
//  Sheet for sharing a food photo + AI-scanned macros to the Firebase social feed.
//

import SwiftUI
import CoreLocation

struct CreatePostView: View {

    // MARK: - Inputs (from AI scan / caller)

    let initialPhoto:  UIImage?
    let foodName:      String
    let calories:      Int
    let protein:       Double
    let carbs:         Double
    let fat:           Double
    let goalCalories:  Int
    let goalProtein:   Double
    let goalCarbs:     Double
    let goalFat:       Double
    let userSettings:  UserSettings

    // MARK: - Environment

    @Environment(LocationManager.self) private var locationManager
    @Environment(\.dismiss)            private var dismiss

    // MARK: - State

    @State private var photo:            UIImage?
    @State private var pickerImage:      UIImage? = nil
    @State private var caption:          String   = ""
    @State private var selectedMealType: PostService.MealType
    @State private var isPosting:        Bool     = false
    @State private var errorMessage:     String?  = nil
    @State private var showCamera:       Bool     = false
    @State private var showLibrary:      Bool     = false
    @State private var showCrop:         Bool     = false
    @FocusState private var captionFocused: Bool

    // MARK: - Design tokens (matches rest of app)

    private let pageBg   = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg   = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let purpleHi = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let calColor  = Color(red: 1.00, green: 0.55, blue: 0.15)
    private let proColor  = Color(red: 0.35, green: 0.75, blue: 1.00)
    private let carbColor = Color(red: 0.40, green: 0.90, blue: 0.72)
    private let fatColor  = Color(red: 1.00, green: 0.50, blue: 0.72)

    // MARK: - Init

    init(
        initialPhoto:  UIImage?  = nil,
        foodName:      String,
        calories:      Int,
        protein:       Double,
        carbs:         Double,
        fat:           Double,
        goalCalories:  Int    = 0,
        goalProtein:   Double = 0,
        goalCarbs:     Double = 0,
        goalFat:       Double = 0,
        userSettings:  UserSettings
    ) {
        self.initialPhoto = initialPhoto
        self.foodName     = foodName
        self.calories     = calories
        self.protein      = protein
        self.carbs        = carbs
        self.fat          = fat
        self.goalCalories = goalCalories
        self.goalProtein  = goalProtein
        self.goalCarbs    = goalCarbs
        self.goalFat      = goalFat
        self.userSettings = userSettings

        _photo = State(wrappedValue: initialPhoto)

        // Auto-detect a sensible meal type from the current hour
        let hour = Calendar.current.component(.hour, from: Date())
        let defaultType: PostService.MealType
        switch hour {
        case 5...10:  defaultType = .breakfast
        case 11...14: defaultType = .lunch
        case 15...17: defaultType = .snack
        case 18...22: defaultType = .dinner
        default:      defaultType = .snack
        }
        _selectedMealType = State(wrappedValue: defaultType)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        photoSection
                        macroCard
                        captionField
                        mealTypePicker
                        if let err = errorMessage { errorBanner(err) }
                        postButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 48)
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Share to Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isPosting)
                }
            }
            .onChange(of: pickerImage) { _, img in
                guard let img else { return }
                photo      = img
                pickerImage = nil
            }
            .sheet(isPresented: $showCamera) {
                ImagePickerView(sourceType: .camera,       selectedImage: $pickerImage)
            }
            .sheet(isPresented: $showLibrary) {
                ImagePickerView(sourceType: .photoLibrary, selectedImage: $pickerImage)
            }
            .fullScreenCover(isPresented: $showCrop) {
                if let img = photo {
                    CropImageView(
                        image: img,
                        onCrop: { cropped in
                            photo    = cropped
                            showCrop = false
                        },
                        onCancel: { showCrop = false }
                    )
                }
            }
        }
    }

    // MARK: - Photo Section

    @ViewBuilder
    private var photoSection: some View {
        ZStack(alignment: .bottomTrailing) {
            // Preview or placeholder
            if let img = photo {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .clipped()
                    .cornerRadius(16)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBg)
                    .frame(height: 240)
                    .overlay {
                        VStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(.white.opacity(0.20))
                            Text("Tap to add a photo")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.35))
                        }
                    }
                    .onTapGesture { showLibrary = true }
            }

            HStack(spacing: 8) {
                // Camera / library picker button
                Menu {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera.fill")
                        }
                    }
                    Button {
                        showLibrary = true
                    } label: {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(photo == nil ? "Add Photo" : "Change")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }

                // Crop button (only when a photo is set)
                if photo != nil {
                    Button { showCrop = true } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "crop")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Crop")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
            .padding(10)
        }
    }

    // MARK: - Macro Card

    private var macroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(foodName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("AI-scanned macros")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.40))
                }
                Spacer()
                if userSettings.auraPoints > 0 {
                    Text("⭐ Lv \(userSettings.auraLevel)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.80, blue: 0.20))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 1.0, green: 0.80, blue: 0.20).opacity(0.12))
                        .cornerRadius(8)
                }
            }

            HStack(spacing: 8) {
                macroPill(label: "Cal",  value: "\(calories)",     unit: "kcal", color: calColor)
                macroPill(label: "Pro",  value: "\(Int(protein))", unit: "g",    color: proColor)
                macroPill(label: "Carb", value: "\(Int(carbs))",   unit: "g",    color: carbColor)
                macroPill(label: "Fat",  value: "\(Int(fat))",     unit: "g",    color: fatColor)
            }

            // Goal progress bar (only shown when goals are set)
            if goalCalories > 0 {
                goalProgressRow
            }
        }
        .padding(14)
        .background(cardBg)
        .cornerRadius(16)
    }

    private func macroPill(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(unit)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(color.opacity(0.60))
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.40))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.10))
        .cornerRadius(12)
    }

    @ViewBuilder
    private var goalProgressRow: some View {
        let pct = min(Double(calories) / Double(max(goalCalories, 1)), 1.0)
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("Calorie goal")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.40))
                Spacer()
                Text("\(Int(pct * 100))%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(pct >= 0.85 ? calColor : .white.opacity(0.40))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(calColor.opacity(0.80))
                        .frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 5)
        }
    }

    // MARK: - Caption Field

    private var captionField: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ZStack(alignment: .topLeading) {
                if caption.isEmpty {
                    Text("Add a caption… (optional)")
                        .foregroundStyle(.white.opacity(0.28))
                        .padding(.top, 18)
                        .padding(.leading, 16)
                }
                TextEditor(text: $caption)
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80, maxHeight: 130)
                    .padding(10)
                    .focused($captionFocused)
                    .onChange(of: caption) { _, v in
                        if v.count > 300 { caption = String(v.prefix(300)) }
                    }
            }
            .background(cardBg)
            .cornerRadius(16)
            .onTapGesture { captionFocused = true }
            Text("\(caption.count)/300")
                .font(.system(size: 11))
                .foregroundStyle(caption.count >= 300 ? .red : caption.count >= 240 ? Color.orange : .white.opacity(0.25))
        }
    }

    // MARK: - Meal Type Picker

    private var mealTypePicker: some View {
        HStack {
            Label("Meal Type", systemImage: "fork.knife")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.70))
            Spacer()
            Menu {
                ForEach(PostService.MealType.allCases, id: \.self) { type in
                    Button(type.rawValue) { selectedMealType = type }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(selectedMealType.rawValue)
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11))
                }
                .foregroundStyle(purpleHi)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(purpleHi.opacity(0.12))
                .cornerRadius(10)
            }
        }
        .padding(14)
        .background(cardBg)
        .cornerRadius(16)
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
            Spacer()
            Button { withAnimation { errorMessage = nil } } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.50))
            }
        }
        .padding(14)
        .background(Color.red.opacity(0.15))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.red.opacity(0.30), lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Post Button

    private var postButton: some View {
        Button(action: submitPost) {
            ZStack {
                if isPosting {
                    HStack(spacing: 10) {
                        ProgressView().tint(.white)
                        Text("Uploading…")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                        Text("Post to Feed")
                            .font(.headline.weight(.bold))
                    }
                    .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if isPosting || photo == nil {
                        AnyView(purpleHi.opacity(0.30))
                    } else {
                        AnyView(
                            LinearGradient(
                                colors: [purpleHi, Color(red: 0.45, green: 0.25, blue: 0.90)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                }
            )
            .cornerRadius(16)
        }
        .disabled(isPosting || photo == nil)
    }

    // MARK: - Submit

    private func submitPost() {
        guard let image = photo else { return }
        captionFocused = false

        withAnimation { errorMessage = nil }
        isPosting = true

        let author = PostService.PostAuthor(
            userID:              userSettings.userID,
            username:            userSettings.username.isEmpty ? "user" : userSettings.username,
            whoName:             userSettings.name.isEmpty
                                     ? userSettings.username
                                     : userSettings.name,
            userProfilePhotoURL: "",   // populated once profile-photo upload is wired to Storage
            auraLevel:           userSettings.auraLevel,
            auraPoints:          userSettings.auraPoints,
            auraTitle:           userSettings.auraTitle,
            streak:              userSettings.macroStreak,
            memeType:            memeKey(for: userSettings.auraLevel),
            isPublic:            !userSettings.isPrivateAccount,
            isProSubscriber:     AISubscriptionStore.shared.isSubscribed
        )

        let cityName  = userSettings.postLocation(gpsCity: locationManager.city)
        let latitude  = locationManager.coordinate?.latitude  ?? 0
        let longitude = locationManager.coordinate?.longitude ?? 0
        let trimmed   = caption.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                _ = try await PostService.shared.createPost(
                    photo:        image,
                    author:       author,
                    foodName:     foodName,
                    mealType:     selectedMealType,
                    caption:      trimmed,
                    calories:     calories,
                    protein:      protein,
                    carbs:        carbs,
                    fat:          fat,
                    goalCalories: goalCalories,
                    goalProtein:  goalProtein,
                    goalCarbs:    goalCarbs,
                    goalFat:      goalFat,
                    locationName: cityName,
                    latitude:     latitude,
                    longitude:    longitude,
                    macroDate:    Date()
                )
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    isPosting = false
                    withAnimation { errorMessage = error.localizedDescription }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Maps aura level to a meme asset key that matches the imageset names in Assets.xcassets.
    private func memeKey(for level: Int) -> String {
        switch level {
        case 0:       return "bro"
        case 1...9:   return "looksmaxx"
        case 10...24: return "roman"
        case 25...39: return "sigma"
        case 40...59: return "king"
        case 60...79: return "gigachad"
        case 80...94: return "silverback"
        default:      return "finalform"
        }
    }
}
