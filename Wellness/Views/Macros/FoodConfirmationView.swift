//
//  FoodConfirmationView.swift
//  Wellness
//
//  Post-scan confirmation view with portion slider, tier badge,
//  and option to escalate to a better scan.
//

import SwiftUI

struct FoodConfirmationView: View {
    let image: UIImage
    @Binding var recognitionResult: FoodRecognitionResult
    @Binding var saveMeal: Bool
    let onConfirm: (FoodRecognitionResult) -> Void
    let onEscalate: () -> Void
    let onCancel: () -> Void

    @State private var editableFoodName: String = ""
    @State private var portionMultiplier: Double = 1.0
    @State private var isEscalating = false

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let accent = Color(red: 0.65, green: 0.45, blue: 1.00)

    // Scaled macros based on portion multiplier
    private var scaledCalories: Int {
        Int(Double(recognitionResult.calories) * portionMultiplier)
    }
    private var scaledProtein: Double {
        recognitionResult.protein * portionMultiplier
    }
    private var scaledCarbs: Double {
        recognitionResult.carbs * portionMultiplier
    }
    private var scaledFat: Double {
        recognitionResult.fat * portionMultiplier
    }
    private var scaledPortion: Double {
        recognitionResult.portionGrams * portionMultiplier
    }

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Food photo
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(16)

                        // Tier badge
                        HStack {
                            Text(recognitionResult.tierBadge)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(tierColor.opacity(0.15))
                                .foregroundStyle(tierColor)
                                .cornerRadius(8)

                            Spacer()

                            if recognitionResult.confidence > 0 {
                                Text("\(Int(recognitionResult.confidence * 100))% confident")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                        }

                        // Warning banner
                        if recognitionResult.needsUserConfirmation {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("We're not 100% sure about this one — please review")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.70))
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.10))
                            .cornerRadius(10)
                        }

                        // Editable food name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Food Name")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.50))
                            TextField("Food name", text: $editableFoodName)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(cardBg)
                                .cornerRadius(10)
                        }

                        // Macro breakdown card
                        macroCard

                        // Portion slider
                        portionSlider

                        // Components breakdown (Tier 3 mixed meals)
                        if let components = recognitionResult.components, components.count > 1 {
                            componentsSection(components)
                        }

                        // Save meal toggle
                        saveMealToggle

                        // Action buttons
                        actionButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Confirm Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                editableFoodName = recognitionResult.foodName
            }
        }
    }

    // MARK: - Macro Card

    private var macroCard: some View {
        VStack(spacing: 12) {
            // Calories
            HStack {
                Text("Calories")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.70))
                Spacer()
                Text("\(scaledCalories)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("kcal")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
            }

            Divider().background(.white.opacity(0.10))

            // Macros row
            HStack(spacing: 0) {
                macroColumn(label: "Protein", value: scaledProtein, color: .blue)
                macroColumn(label: "Carbs", value: scaledCarbs, color: .green)
                macroColumn(label: "Fat", value: scaledFat, color: .orange)
            }
        }
        .padding(16)
        .background(cardBg)
        .cornerRadius(14)
    }

    private func macroColumn(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1fg", value))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.50))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Portion Slider

    private var portionSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Portion Size")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.70))
                Spacer()
                Text("\(Int(scaledPortion))g")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(accent)
            }

            Slider(value: $portionMultiplier, in: 0.5...3.0, step: 0.1)
                .tint(accent)

            HStack {
                Text("0.5x")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.30))
                Spacer()
                Text("1x")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.30))
                Spacer()
                Text("3x")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.30))
            }
        }
        .padding(16)
        .background(cardBg)
        .cornerRadius(14)
    }

    // MARK: - Components (Tier 3)

    private func componentsSection(_ components: [MealComponent]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meal Breakdown")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.70))

            ForEach(components, id: \.name) { component in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(component.name)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Text("\(Int(component.portionGrams))g")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.40))
                    }
                    Spacer()
                    Text("\(component.calories) kcal")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.70))
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(cardBg)
        .cornerRadius(14)
    }

    // MARK: - Save Meal Toggle

    private var saveMealToggle: some View {
        Toggle(isOn: $saveMeal) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Save as Saved Meal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Quick-select this meal next time")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.40))
            }
        }
        .tint(accent)
        .padding(14)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            // Log it
            Button {
                var finalResult = recognitionResult
                finalResult.foodName = editableFoodName
                finalResult.calories = scaledCalories
                finalResult.protein = scaledProtein
                finalResult.carbs = scaledCarbs
                finalResult.fat = scaledFat
                finalResult.portionGrams = scaledPortion
                onConfirm(finalResult)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Looks right, log it")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(accent, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            // Try better scan (only if not already at Tier 2 / Sonnet full vision)
            if recognitionResult.tier < 2 {
                Button {
                    isEscalating = true
                    onEscalate()
                } label: {
                    HStack(spacing: 8) {
                        if isEscalating {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text("Try better scan")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.70))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(isEscalating)
            }
        }
    }

    // MARK: - Helpers

    private var tierColor: Color {
        switch recognitionResult.tier {
        case 1: return .green
        case 2: return .blue
        case 3: return .purple
        default: return .gray
        }
    }
}
