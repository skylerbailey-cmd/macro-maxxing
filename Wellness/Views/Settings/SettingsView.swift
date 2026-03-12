//
//  SettingsView.swift
//  Wellness
//

import SwiftUI

struct SettingsView: View {
    @Bindable var userSettings: UserSettings
    @FocusState private var nameFocused: Bool

    // Local state — only writes to userSettings on commit, preventing re-renders on every input
    @State private var nameText:         String = ""
    @State private var usernameText:     String = ""
    @State private var currentWeightVal: Double = 160
    @State private var goalWeightVal:    Double = 160
    @State private var proteinPerLbVal:  Double = 0.9

    var body: some View {
        Form {
            // MARK: Profile
            Section("Profile") {
                HStack {
                    Text("Name")
                    Spacer()
                    TextField("Your name", text: $nameText)
                        .multilineTextAlignment(.trailing)
                        .focused($nameFocused)
                        .submitLabel(.next)
                        .onSubmit { nameFocused = false }
                }
                HStack {
                    Text("Username")
                    Spacer()
                    HStack(spacing: 2) {
                        Text("@").foregroundStyle(.secondary)
                        TextField("handle", text: $usernameText)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($nameFocused)
                            .submitLabel(.done)
                            .onSubmit { commitAll(); nameFocused = false }
                    }
                }
            }

            // MARK: Body
            Section("Body") {
                sliderRow(
                    label: "Current Weight",
                    value: $currentWeightVal,
                    range: 100...300,
                    step: 1,
                    display: "\(Int(currentWeightVal)) lbs"
                ) { editing in
                    if !editing { userSettings.currentWeight = currentWeightVal }
                }

                sliderRow(
                    label: "Goal Weight",
                    value: $goalWeightVal,
                    range: 100...300,
                    step: 1,
                    display: "\(Int(goalWeightVal)) lbs"
                ) { editing in
                    if !editing { userSettings.goalWeight = goalWeightVal }
                }
            }

            // MARK: Nutrition
            Section {
                sliderRow(
                    label: "Protein per lb",
                    value: $proteinPerLbVal,
                    range: 0.7...1.0,
                    step: 0.05,
                    display: String(format: "%.2f g/lb", proteinPerLbVal)
                ) { editing in
                    if !editing { userSettings.proteinPerLb = proteinPerLbVal }
                }
                HStack {
                    Text("0.7").font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Text("1.0").font(.caption2).foregroundStyle(.secondary)
                }
                .listRowSeparator(.hidden)
                .padding(.top, -8)
            } header: {
                Text("Nutrition")
            } footer: {
                Text("Grams of protein per pound of goal body weight. General fitness: 0.7–0.8 g/lb. Strength training: 0.8–1.0 g/lb.")
            }

            // MARK: Intermittent Fasting
            Section {
                Toggle("Track Eating Window", isOn: $userSettings.fastingEnabled)
            } header: {
                Text("Intermittent Fasting")
            } footer: {
                Text(userSettings.fastingEnabled
                     ? "Your eating window is shown on the Home screen. Tap Edit to adjust the start time and duration."
                     : "Enable to track your daily eating window on the Home screen.")
            }
        }
        .onAppear {
            nameText         = userSettings.name
            usernameText     = userSettings.username
            currentWeightVal = userSettings.currentWeight > 0 ? userSettings.currentWeight : 160
            goalWeightVal    = userSettings.goalWeight    > 0 ? userSettings.goalWeight    : 160
            proteinPerLbVal  = userSettings.proteinPerLb
        }
        .onDisappear { commitAll() }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { commitAll(); nameFocused = false }
                    .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sliderRow(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        display: String,
        onEditingChanged: @escaping (Bool) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                Spacer()
                Text(display)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step, onEditingChanged: onEditingChanged)
                .tint(Color(red: 0.65, green: 0.45, blue: 1.0))
        }
        .padding(.vertical, 4)
    }

    private func commitAll() {
        userSettings.name     = nameText.trimmingCharacters(in: .whitespaces)
        userSettings.username = usernameText
            .trimmingCharacters(in: .whitespaces)
            .lowercased()
            .replacingOccurrences(of: "@", with: "")
        userSettings.currentWeight = currentWeightVal
        userSettings.goalWeight    = goalWeightVal
        userSettings.proteinPerLb  = proteinPerLbVal
    }
}

#Preview {
    NavigationStack {
        SettingsView(userSettings: UserSettings())
    }
}
