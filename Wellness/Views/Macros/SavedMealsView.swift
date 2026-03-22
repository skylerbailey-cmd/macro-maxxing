//
//  SavedMealsView.swift
//  Wellness
//

import SwiftUI

struct SavedMealsView: View {
    let savedMeals: [FoodEntry]
    let onSelect: (FoodEntry) -> Void
    var onDelete: ((FoodEntry) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var mealToDelete: FoodEntry? = nil

    init(savedMeals: [FoodEntry], onSelect: @escaping (FoodEntry) -> Void, onDelete: ((FoodEntry) -> Void)? = nil) {
        self.savedMeals = savedMeals
        self.onSelect = onSelect
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Group {
                if savedMeals.isEmpty {
                    ContentUnavailableView(
                        "No Saved Meals",
                        systemImage: "bookmark.slash",
                        description: Text("When you log a meal and mark it as saved, it will appear here for quick re-logging.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(savedMeals) { meal in
                                Button {
                                    onSelect(meal)
                                    dismiss()
                                } label: {
                                    savedMealRow(meal)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    if onDelete != nil {
                                        Button(role: .destructive) {
                                            mealToDelete = meal
                                        } label: {
                                            Label("Delete Saved Meal", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Saved Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .preferredColorScheme(.dark)
            .alert("Delete Saved Meal?", isPresented: Binding(
                get: { mealToDelete != nil },
                set: { if !$0 { mealToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) { mealToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let meal = mealToDelete {
                        onDelete?(meal)
                        mealToDelete = nil
                    }
                }
            } message: {
                if let meal = mealToDelete {
                    Text("Are you sure you want to delete \"\(meal.foodName)\"? This cannot be undone.")
                }
            }
        }
    }

    private func savedMealRow(_ meal: FoodEntry) -> some View {
        HStack(spacing: 14) {
            // Thumbnail or placeholder
            if let url = URL(string: meal.photoURL), !meal.photoURL.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    default:
                        mealPlaceholder
                    }
                }
            } else {
                mealPlaceholder
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(meal.foodName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    macroLabel("\(Int(meal.calories))", unit: "kcal", color: .white.opacity(0.7))
                    macroLabel(String(format: "%.0f", meal.protein), unit: "P", color: .green)
                    macroLabel(String(format: "%.0f", meal.carbs), unit: "C", color: .blue)
                    macroLabel(String(format: "%.0f", meal.fat), unit: "F", color: .red)
                }
            }

            Spacer()

            Image(systemName: "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(Color.purpleHi)
        }
        .padding(12)
        .background(Color.cardBg)
        .cornerRadius(14)
    }

    private var mealPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.06))
                .frame(width: 52, height: 52)
            Image(systemName: "fork.knife")
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.25))
        }
    }

    private func macroLabel(_ value: String, unit: String, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
            Text(unit)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(color.opacity(0.6))
        }
    }
}
