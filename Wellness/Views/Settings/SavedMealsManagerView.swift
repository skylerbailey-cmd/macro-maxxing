//
//  SavedMealsManagerView.swift
//  Wellness
//
//  Manage saved meals — view, delete individually, or bulk-select and delete
//  from Settings → Body & Nutrition.
//

import SwiftUI

struct SavedMealsManagerView: View {
    let userSettings: UserSettings

    @State private var savedMeals: [FoodEntry] = []
    @State private var isLoading = true
    @State private var deleteConfirm: FoodEntry? = nil

    // Multi-select state
    @State private var isSelecting = false
    @State private var selectedIDs: Set<String> = []
    @State private var showBulkDeleteConfirm = false

    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var accent: Color { ThemeStore.shared.accent }

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(accent)
            } else if savedMeals.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.20))
                    Text("No saved meals")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.50))
                    Text("Meals you save from the log tab will appear here.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            } else {
                VStack(spacing: 0) {
                    // Bulk delete bar (shown during selection)
                    if isSelecting, !selectedIDs.isEmpty {
                        bulkDeleteBar
                    }

                    List {
                        ForEach(savedMeals, id: \.firebaseEntryID) { meal in
                            mealRow(meal)
                                .listRowBackground(cardBg)
                        }
                        .onDelete { offsets in
                            guard !isSelecting else { return }
                            let mealsToDelete = offsets.map { savedMeals[$0] }
                            for meal in mealsToDelete {
                                Task {
                                    try? await FoodEntryService.shared.delete(
                                        entryID: meal.firebaseEntryID, userID: userSettings.userID)
                                }
                            }
                            savedMeals.remove(atOffsets: offsets)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
                .alert("Delete Saved Meal?", isPresented: Binding(
                    get: { deleteConfirm != nil },
                    set: { if !$0 { deleteConfirm = nil } }
                )) {
                    Button("Cancel", role: .cancel) { deleteConfirm = nil }
                    Button("Delete", role: .destructive) {
                        if let meal = deleteConfirm {
                            deleteMeals([meal.firebaseEntryID])
                            deleteConfirm = nil
                        }
                    }
                } message: {
                    if let meal = deleteConfirm {
                        Text("Are you sure you want to delete \"\(meal.foodName)\"? This cannot be undone.")
                    }
                }
                .alert("Delete \(selectedIDs.count) Saved Meals?", isPresented: $showBulkDeleteConfirm) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete \(selectedIDs.count) Meals", role: .destructive) {
                        deleteMeals(selectedIDs)
                        isSelecting = false
                        selectedIDs.removeAll()
                    }
                } message: {
                    Text("This will permanently delete the selected meals. This cannot be undone.")
                }
            }
        }
        .navigationTitle("Saved Meals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if !savedMeals.isEmpty {
                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            isSelecting.toggle()
                            if !isSelecting { selectedIDs.removeAll() }
                        }
                    } label: {
                        Text(isSelecting ? "Done" : "Select")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                }
            }
        }
        .task {
            savedMeals = (try? await FoodEntryService.shared.fetchSavedMeals(userID: userSettings.userID)) ?? []
            isLoading = false
        }
    }

    // MARK: - Meal row

    @ViewBuilder
    private func mealRow(_ meal: FoodEntry) -> some View {
        let entryID = meal.firebaseEntryID
        let isSelected = selectedIDs.contains(entryID)

        HStack(spacing: 12) {
            // Selection circle (shown in select mode)
            if isSelecting {
                Button {
                    withAnimation(.spring(duration: 0.15)) {
                        if isSelected { selectedIDs.remove(entryID) }
                        else          { selectedIDs.insert(entryID) }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .stroke(isSelected ? accent : Color.white.opacity(0.25), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        if isSelected {
                            Circle()
                                .fill(accent)
                                .frame(width: 24, height: 24)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.black)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            // Photo
            if !meal.photoURL.isEmpty {
                CachedAsyncImage(
                    url: URL(string: meal.photoURL),
                    content: { img in
                        img.resizable().scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    },
                    placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 40, height: 40)
                    }
                )
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(meal.foodName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("\(Int(meal.calories)) cal")
                        .foregroundStyle(Color(red: 1.00, green: 0.55, blue: 0.15))
                    Text("\(Int(meal.protein))g P")
                        .foregroundStyle(Color(red: 0.35, green: 0.75, blue: 1.00))
                    Text("\(Int(meal.carbs))g C")
                        .foregroundStyle(Color(red: 0.40, green: 0.90, blue: 0.72))
                    Text("\(Int(meal.fat))g F")
                        .foregroundStyle(Color(red: 1.00, green: 0.50, blue: 0.72))
                }
                .font(.system(size: 11, weight: .semibold))
            }
            Spacer()

            // Delete button (single, only when NOT in select mode)
            if !isSelecting {
                Button { deleteConfirm = meal } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.35))
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard isSelecting else { return }
            withAnimation(.spring(duration: 0.15)) {
                if isSelected { selectedIDs.remove(entryID) }
                else          { selectedIDs.insert(entryID) }
            }
        }
    }

    // MARK: - Bulk delete bar

    private var bulkDeleteBar: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(duration: 0.15)) {
                    if selectedIDs.count == savedMeals.count {
                        selectedIDs.removeAll()
                    } else {
                        selectedIDs = Set(savedMeals.map(\.firebaseEntryID))
                    }
                }
            } label: {
                Text(selectedIDs.count == savedMeals.count ? "Deselect All" : "Select All")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("\(selectedIDs.count) selected")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.50))

            Spacer()

            Button { showBulkDeleteConfirm = true } label: {
                HStack(spacing: 5) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .bold))
                    Text("Delete")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.85), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(cardBg)
    }

    // MARK: - Delete helper

    private func deleteMeals(_ ids: Set<String>) {
        for id in ids {
            Task {
                try? await FoodEntryService.shared.delete(entryID: id, userID: userSettings.userID)
            }
        }
        withAnimation {
            savedMeals.removeAll { ids.contains($0.firebaseEntryID) }
        }
    }
}
