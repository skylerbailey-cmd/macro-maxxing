//
//  SavedMealsView.swift
//  Wellness
//

import SwiftUI

struct SavedMealsView: View {
    let savedMeals: [FoodEntry]
    let onSelect: (FoodEntry) -> Void
    var onDelete: ((FoodEntry) -> Void)? = nil
    var onEdit: ((FoodEntry, String, Double, Double, Double, Double) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var mealToDelete: FoodEntry? = nil
    @State private var mealToEdit:   FoodEntry? = nil

    init(savedMeals: [FoodEntry], onSelect: @escaping (FoodEntry) -> Void,
         onDelete: ((FoodEntry) -> Void)? = nil,
         onEdit: ((FoodEntry, String, Double, Double, Double, Double) -> Void)? = nil) {
        self.savedMeals = savedMeals
        self.onSelect = onSelect
        self.onDelete = onDelete
        self.onEdit = onEdit
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
                                    if onEdit != nil {
                                        Button {
                                            mealToEdit = meal
                                        } label: {
                                            Label("Edit Saved Meal", systemImage: "pencil")
                                        }
                                    }
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
            .sheet(item: $mealToEdit) { meal in
                SavedMealEditSheet(meal: meal) { name, cal, pro, carb, fat in
                    onEdit?(meal, name, cal, pro, carb, fat)
                    mealToEdit = nil
                }
            }
        }
        .keyboardDoneToolbar()
    }

    private func savedMealRow(_ meal: FoodEntry) -> some View {
        HStack(spacing: 14) {
            // Thumbnail or placeholder
            if let url = URL(string: meal.photoURL), !meal.photoURL.isEmpty {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } placeholder: {
                    mealPlaceholder
                }
                .id(meal.photoURL)
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

// MARK: - Edit Sheet for Saved Meals

private struct SavedMealEditSheet: View {
    let meal: FoodEntry
    let onSave: (String, Double, Double, Double, Double) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var foodName:     String
    @State private var caloriesText: String
    @State private var proteinText:  String
    @State private var carbsText:    String
    @State private var fatText:      String
    @State private var isReanalyzing = false

    init(meal: FoodEntry, onSave: @escaping (String, Double, Double, Double, Double) -> Void) {
        self.meal   = meal
        self.onSave = onSave
        _foodName     = State(initialValue: meal.foodName)
        _caloriesText = State(initialValue: String(format: "%.0f", meal.calories))
        _proteinText  = State(initialValue: String(format: "%.1f", meal.protein))
        _carbsText    = State(initialValue: String(format: "%.1f", meal.carbs))
        _fatText      = State(initialValue: String(format: "%.1f", meal.fat))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Food name", text: $foodName)
                            .multilineTextAlignment(.trailing)
                    }
                    Button {
                        Task { await reanalyze() }
                    } label: {
                        HStack(spacing: 6) {
                            if isReanalyzing {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text("Reanalyze with AI")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.purpleHi)
                    }
                    .disabled(foodName.trimmingCharacters(in: .whitespaces).isEmpty || isReanalyzing)
                }
                Section("Macros") {
                    macroRow("Calories", unit: "kcal", text: $caloriesText)
                    macroRow("Protein",  unit: "g",    text: $proteinText)
                    macroRow("Carbs",    unit: "g",    text: $carbsText)
                    macroRow("Fat",      unit: "g",    text: $fatText)
                }
            }
            .navigationTitle("Edit Saved Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        Double(caloriesText) != nil && Double(proteinText) != nil &&
        Double(carbsText) != nil && Double(fatText) != nil
    }

    private func save() {
        guard let cal = Double(caloriesText), let pro = Double(proteinText),
              let carb = Double(carbsText), let fat = Double(fatText) else { return }
        onSave(foodName, cal, pro, carb, fat)
        dismiss()
    }

    private func reanalyze() async {
        let name = foodName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        isReanalyzing = true
        defer { isReanalyzing = false }

        let result = await FoodRecognitionManager.shared.recognizeFoodByName(name)
        if result.calories > 0 {
            caloriesText = String(format: "%.0f", Double(result.calories))
            proteinText  = String(format: "%.1f", result.protein)
            carbsText    = String(format: "%.1f", result.carbs)
            fatText      = String(format: "%.1f", result.fat)
            if !result.foodName.isEmpty { foodName = result.foodName }
        }
    }

    @ViewBuilder
    private func macroRow(_ label: String, unit: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit).foregroundStyle(.secondary)
        }
    }
}
