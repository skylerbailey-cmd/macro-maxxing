//
//  LogMealSheet.swift
//  Wellness
//
//  Unified meal logging screen — saved meals at top, then capture options.
//

import SwiftUI
import PhotosUI

struct LogMealSheet: View {
    let userSettings: UserSettings
    let selectedDate: Date
    /// Set this to pass a selected image back to ContentView → FoodLogView
    @Binding var selectedImage: UIImage?
    /// Switch to the Log tab after selecting a capture method
    var onImageSelected: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    @State private var savedMeals:    [FoodEntry] = []
    @State private var isLoadingMeals = true
    @State private var showingCamera  = false
    @State private var photosItem:    PhotosPickerItem? = nil

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let accent = Color(red: 0.65, green: 0.45, blue: 1.00)
    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Saved meals quick-select
                        if isLoadingMeals {
                            ProgressView().tint(accent).padding(.vertical, 20)
                        } else if !savedMeals.isEmpty {
                            savedMealsSection
                        }

                        // Capture options
                        captureSection

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Log a Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .preferredColorScheme(.dark)
            .task {
                savedMeals = (try? await FoodEntryService.shared.fetchSavedMeals(userID: userSettings.userID)) ?? []
                isLoadingMeals = false
            }
            .sheet(isPresented: $showingCamera) {
                ImagePickerView(sourceType: .camera, selectedImage: Binding(
                    get: { nil },
                    set: { img in
                        if let img {
                            selectedImage = img
                            onImageSelected()
                            dismiss()
                        }
                    }
                ))
            }
            .onChange(of: photosItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        selectedImage = img
                        onImageSelected()
                        dismiss()
                    }
                    photosItem = nil
                }
            }
        }
    }

    // MARK: - Saved Meals

    private var savedMealsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Saved Meals")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(savedMeals) { meal in
                        Button { logSavedMeal(meal) } label: {
                            savedMealChip(meal)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteSavedMeal(meal)
                            } label: {
                                Label("Delete Saved Meal", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    private func savedMealChip(_ meal: FoodEntry) -> some View {
        HStack(spacing: 10) {
            if let url = URL(string: meal.photoURL), !meal.photoURL.isEmpty {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFill()
                    } else {
                        Color.white.opacity(0.05)
                    }
                }
                .frame(width: 38, height: 38)
                .clipped()
                .cornerRadius(8)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accent.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 14))
                        .foregroundStyle(accent.opacity(0.60))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(meal.foodName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(Int(meal.calories)) cal · \(String(format: "%.0f", meal.protein))p")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accent.opacity(0.20), lineWidth: 1)
        )
    }

    // MARK: - Capture Section

    private var captureSection: some View {
        VStack(spacing: 12) {
            Button { showingCamera = true } label: {
                captureRow(
                    icon: "camera.fill",
                    title: "Take a Photo",
                    subtitle: "Snap your meal and AI estimates your macros",
                    color: accent,
                    disabled: !UIImagePickerController.isSourceTypeAvailable(.camera)
                )
            }
            .buttonStyle(.plain)
            .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

            PhotosPicker(selection: $photosItem, matching: .images) {
                captureRow(
                    icon: "photo.on.rectangle",
                    title: "Choose from Library",
                    subtitle: "Select a photo you've already taken",
                    color: accent,
                    disabled: false
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func captureRow(icon: String, title: String, subtitle: String, color: Color, disabled: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(disabled ? 0.05 : 0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(disabled ? color.opacity(0.30) : color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(disabled ? .white.opacity(0.30) : .white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(disabled ? 0.20 : 0.45))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(disabled ? 0.15 : 0.30))
        }
        .padding(14)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func logSavedMeal(_ meal: FoodEntry) {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let now = Date()
        comps.hour   = calendar.component(.hour,   from: now)
        comps.minute = calendar.component(.minute, from: now)
        comps.second = calendar.component(.second, from: now)
        let loggedAt = calendar.date(from: comps) ?? selectedDate

        let entry = FoodEntry(
            loggedAt: loggedAt,
            userID:   userSettings.userID,
            foodName: meal.foodName,
            calories: meal.calories,
            protein:  meal.protein,
            carbs:    meal.carbs,
            fat:      meal.fat
        )

        Task {
            _ = try? await FoodEntryService.shared.save(entry: entry, image: nil)
            NotificationCenter.default.post(name: FuelLogService.mealChangedNotification, object: nil)
        }
        dismiss()
    }

    private func deleteSavedMeal(_ meal: FoodEntry) {
        savedMeals.removeAll { $0.id == meal.id }
        Task { await FoodEntryService.shared.delete(entryID: meal.firebaseEntryID, userID: userSettings.userID) }
    }
}
