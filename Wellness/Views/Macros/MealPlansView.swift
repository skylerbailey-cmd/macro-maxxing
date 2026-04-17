//
//  MealPlansView.swift
//  Wellness
//
//  Manage meal plans — named groups of saved meals.
//  Accessed from Settings → Body & Nutrition → Meal Plans.
//

import SwiftUI

// MARK: - Meal Plans List

struct MealPlansView: View {
    let userSettings: UserSettings

    @State private var plans:          [MealPlan]   = []
    @State private var savedMeals:     [FoodEntry]  = []
    @State private var showingNewPlan  = false
    @State private var newPlanName     = ""
    @State private var isLoading       = true

    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var accent: Color { ThemeStore.shared.accent }

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(accent)
            } else if plans.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(plans) { plan in
                            NavigationLink {
                                MealPlanDetailView(
                                    plan: plan,
                                    userSettings: userSettings,
                                    savedMeals: savedMeals,
                                    onUpdate: reload
                                )
                            } label: {
                                planCard(plan)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Meal Plans")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingNewPlan = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accent)
                }
            }
        }
        .alert("New Meal Plan", isPresented: $showingNewPlan) {
            TextField("Plan name", text: $newPlanName)
            Button("Create") {
                let name = newPlanName.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                FoodEntryService.shared.addMealPlan(
                    MealPlan(name: name, days: [PlanDay(label: "Day 1")]),
                    userID: userSettings.userID
                )
                newPlanName = ""
                Task { await reload() }
            }
            Button("Cancel", role: .cancel) { newPlanName = "" }
        } message: {
            Text("Give your plan a name — e.g. \"Cutting Plan\" or \"High Protein Week\"")
        }
        .task { await loadData() }
    }

    private func loadData() async {
        savedMeals = (try? await FoodEntryService.shared.fetchSavedMeals(userID: userSettings.userID)) ?? []
        plans = await FoodEntryService.shared.fetchMealPlans(userID: userSettings.userID)
        isLoading = false
    }

    private func reload() async {
        plans = await FoodEntryService.shared.fetchMealPlans(userID: userSettings.userID)
    }

    // MARK: - Card

    private func planCard(_ plan: MealPlan) -> some View {
        let meals = plan.allMealIDs.compactMap { id in
            savedMeals.first { $0.firebaseEntryID == id }
        }
        let totalCal = meals.reduce(0.0) { $0 + $1.calories }
        let totalPro = meals.reduce(0.0) { $0 + $1.protein }

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(plan.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(meals.count) meal\(meals.count == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.40))
                    if !meals.isEmpty {
                        Text("\(Int(totalCal)) cal \u{00B7} \(Int(totalPro))g protein")
                            .font(.system(size: 11))
                            .foregroundStyle(accent.opacity(0.70))
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.30))
            }

            if !meals.isEmpty {
                HStack(spacing: 6) {
                    ForEach(meals.prefix(4), id: \.firebaseEntryID) { meal in
                        mealThumbnail(meal)
                    }
                    if meals.count > 4 {
                        Text("+\(meals.count - 4)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.40))
                    }
                }
            }
        }
        .padding(14)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.15), lineWidth: 1))
    }

    private func mealThumbnail(_ meal: FoodEntry) -> some View {
        HStack(spacing: 4) {
            if !meal.photoURL.isEmpty {
                CachedAsyncImage(
                    url: URL(string: meal.photoURL),
                    content: { img in
                        img.resizable().scaledToFill()
                            .frame(width: 20, height: 20)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    },
                    placeholder: {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 20, height: 20)
                    }
                )
            }
            Text(meal.foodName)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(accent)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(accent.opacity(0.12), in: Capsule())
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 40))
                .foregroundStyle(accent.opacity(0.35))
            Text("No Meal Plans Yet")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Group your saved meals into plans\nlike \"Cutting Plan\" or \"High Protein Week\".")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
            Button {
                showingNewPlan = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Plan")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }
}

// MARK: - Meal Plan Detail

struct MealPlanDetailView: View {
    @State var plan: MealPlan
    let userSettings: UserSettings
    let savedMeals:   [FoodEntry]
    var onUpdate:     () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingAddMeal       = false
    @State private var addingToDayIndex: Int? = nil
    @State private var showingRenameAlert   = false
    @State private var showingDeleteConfirm = false
    @State private var renameText           = ""
    @State private var renamingDayIndex: Int? = nil
    @State private var dayRenameText         = ""

    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var accent: Color { ThemeStore.shared.accent }

    private var allMeals: [FoodEntry] {
        plan.allMealIDs.compactMap { id in savedMeals.first { $0.firebaseEntryID == id } }
    }
    private var totalCalories: Double { allMeals.reduce(0) { $0 + $1.calories } }
    private var totalProtein:  Double { allMeals.reduce(0) { $0 + $1.protein  } }
    private var totalCarbs:    Double { allMeals.reduce(0) { $0 + $1.carbs    } }
    private var totalFat:      Double { allMeals.reduce(0) { $0 + $1.fat      } }

    var body: some View {
        List {
            // Macro summary header
            if !allMeals.isEmpty {
                Section {
                    macroSummaryBar
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            ForEach(Array(plan.days.enumerated()), id: \.element.id) { dayIdx, day in
                Section {
                    let resolved = day.itemIDs.compactMap { id in savedMeals.first { $0.firebaseEntryID == id } }
                    ForEach(resolved, id: \.firebaseEntryID) { meal in
                        mealRow(meal)
                    }
                    .onMove { from, to in
                        plan.days[dayIdx].itemIDs.move(fromOffsets: from, toOffset: to)
                        save()
                    }
                    .onDelete { offsets in
                        plan.days[dayIdx].itemIDs.remove(atOffsets: offsets)
                        save()
                    }

                    Button {
                        addingToDayIndex = dayIdx
                        showingAddMeal = true
                    } label: {
                        Label("Add Meal", systemImage: "plus.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                } header: {
                    HStack {
                        Button {
                            renamingDayIndex = dayIdx
                            dayRenameText = day.label
                        } label: {
                            HStack(spacing: 4) {
                                Text(day.label.uppercased())
                                    .font(.system(size: 11, weight: .black))
                                    .tracking(1.5)
                                Image(systemName: "pencil")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.30))
                            }
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Button(role: .destructive) {
                            plan.days.remove(at: dayIdx)
                            save()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(.red.opacity(0.60))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowBackground(cardBg)
            }

            // Add day
            Section {
                Button {
                    let nextNum = plan.days.count + 1
                    plan.days.append(PlanDay(label: "Day \(nextNum)"))
                    save()
                } label: {
                    Label("Add Day", systemImage: "plus.circle")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(accent)
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(pageBg.ignoresSafeArea())
        .environment(\.editMode, .constant(.active))
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        renameText = plan.name
                        showingRenameAlert = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("Delete Plan", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.60))
                }
            }
        }
        .sheet(isPresented: $showingAddMeal) {
            AddMealToPlanSheet(
                savedMeals: savedMeals,
                existingIDs: Set(plan.allMealIDs),
                onAdd: { selectedIDs in
                    if let idx = addingToDayIndex, idx < plan.days.count {
                        plan.days[idx].itemIDs.append(contentsOf: selectedIDs)
                    }
                    save()
                }
            )
        }
        .alert("Rename Plan", isPresented: $showingRenameAlert) {
            TextField("Name", text: $renameText)
            Button("Save") {
                let name = renameText.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                plan.name = name
                save()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete this meal plan?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                FoodEntryService.shared.deleteMealPlan(id: plan.id, userID: userSettings.userID)
                Task { await onUpdate() }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This won't delete the saved meals — just the plan grouping.")
        }
        .alert("Rename Day", isPresented: Binding(
            get: { renamingDayIndex != nil },
            set: { if !$0 { renamingDayIndex = nil } }
        )) {
            TextField("Day label", text: $dayRenameText)
            Button("Save") {
                let label = dayRenameText.trimmingCharacters(in: .whitespaces)
                guard !label.isEmpty, let idx = renamingDayIndex, idx < plan.days.count else { return }
                plan.days[idx].label = label
                save()
                renamingDayIndex = nil
            }
            Button("Cancel", role: .cancel) { renamingDayIndex = nil }
        } message: {
            Text("Rename this day — e.g. \"Monday\" or \"Breakfast\"")
        }
    }

    // MARK: - Macro summary

    private var macroSummaryBar: some View {
        HStack(spacing: 12) {
            macroPill(label: "Cal",     value: "\(Int(totalCalories))", color: Color(red: 1.00, green: 0.55, blue: 0.15))
            macroPill(label: "Protein", value: "\(Int(totalProtein))g", color: Color(red: 0.35, green: 0.75, blue: 1.00))
            macroPill(label: "Carbs",   value: "\(Int(totalCarbs))g",  color: Color(red: 0.40, green: 0.90, blue: 0.72))
            macroPill(label: "Fat",     value: "\(Int(totalFat))g",    color: Color(red: 1.00, green: 0.50, blue: 0.72))
        }
        .padding(.horizontal, 16)
    }

    private func macroPill(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.40))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Meal row

    private func mealRow(_ meal: FoodEntry) -> some View {
        HStack(spacing: 10) {
            if !meal.photoURL.isEmpty {
                CachedAsyncImage(
                    url: URL(string: meal.photoURL),
                    content: { img in
                        img.resizable().scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    },
                    placeholder: {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 36, height: 36)
                    }
                )
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.foodName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("\(Int(meal.calories)) cal")
                        .foregroundStyle(Color(red: 1.00, green: 0.55, blue: 0.15))
                    Text("\(Int(meal.protein))g P")
                        .foregroundStyle(Color(red: 0.35, green: 0.75, blue: 1.00))
                }
                .font(.system(size: 11, weight: .semibold))
            }
        }
    }

    private func save() {
        FoodEntryService.shared.updateMealPlan(plan, userID: userSettings.userID)
        Task { await onUpdate() }
    }
}

// MARK: - Add Meal to Plan Sheet

private struct AddMealToPlanSheet: View {
    let savedMeals:  [FoodEntry]
    let existingIDs: Set<String>
    let onAdd:       ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<String> = []

    private var accent: Color { ThemeStore.shared.accent }
    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()

                if savedMeals.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.25))
                        Text("No saved meals")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.50))
                        Text("Log a meal and toggle \"Save as Saved Meal\"\nto create reusable meals.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.35))
                            .multilineTextAlignment(.center)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(savedMeals, id: \.firebaseEntryID) { meal in
                                let alreadyAdded = existingIDs.contains(meal.firebaseEntryID)
                                let isSelected   = selected.contains(meal.firebaseEntryID)
                                Button {
                                    if isSelected {
                                        selected.remove(meal.firebaseEntryID)
                                    } else {
                                        selected.insert(meal.firebaseEntryID)
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundStyle(isSelected ? accent : .white.opacity(0.25))

                                        if !meal.photoURL.isEmpty {
                                            CachedAsyncImage(
                                                url: URL(string: meal.photoURL),
                                                content: { img in
                                                    img.resizable().scaledToFill()
                                                        .frame(width: 36, height: 36)
                                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                                },
                                                placeholder: {
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(Color.white.opacity(0.08))
                                                        .frame(width: 36, height: 36)
                                                }
                                            )
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(meal.foodName)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(.white)
                                                .lineLimit(1)
                                            HStack(spacing: 6) {
                                                Text("\(Int(meal.calories)) cal")
                                                Text("\(Int(meal.protein))g P")
                                            }
                                            .font(.system(size: 11))
                                            .foregroundStyle(.white.opacity(0.40))
                                        }
                                        Spacer()
                                        if alreadyAdded {
                                            Text("Added")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(.white.opacity(0.30))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(Color.white.opacity(0.08), in: Capsule())
                                        }
                                    }
                                    .padding(12)
                                    .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .disabled(alreadyAdded)
                                .opacity(alreadyAdded ? 0.50 : 1)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Add Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add \(selected.count > 0 ? "(\(selected.count))" : "")") {
                        onAdd(Array(selected))
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(selected.isEmpty)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
