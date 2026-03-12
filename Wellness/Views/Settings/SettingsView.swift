//
//  SettingsView.swift
//  Wellness
//

import SwiftUI

struct SettingsView: View {
    @Bindable var userSettings: UserSettings
    @FocusState private var focus: Field?

    private enum Field: Hashable { case name, currentWeight, goalWeight }

    // Local text state — avoids re-rendering the whole app on every keystroke
    @State private var nameText          = ""
    @State private var currentWeightText = ""
    @State private var goalWeightText    = ""

    var body: some View {
        Form {
            // MARK: Profile
            Section("Profile") {
                HStack {
                    Text("Name")
                    Spacer()
                    TextField("Your name", text: $nameText)
                        .multilineTextAlignment(.trailing)
                        .focused($focus, equals: .name)
                        .submitLabel(.done)
                        .onSubmit { commitAll(); focus = nil }
                }
            }

            // MARK: Body
            Section("Body") {
                HStack {
                    Text("Current Weight")
                    Spacer()
                    TextField("0", text: $currentWeightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .focused($focus, equals: .currentWeight)
                    Text("lbs").foregroundStyle(.secondary)
                }
                HStack {
                    Text("Goal Weight")
                    Spacer()
                    TextField("0", text: $goalWeightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .focused($focus, equals: .goalWeight)
                    Text("lbs").foregroundStyle(.secondary)
                }
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
            nameText          = userSettings.name
            currentWeightText = userSettings.currentWeight > 0
                ? String(format: "%.1f", userSettings.currentWeight) : ""
            goalWeightText    = userSettings.goalWeight > 0
                ? String(format: "%.0f", userSettings.goalWeight) : ""
        }
        // Commit when navigating away without tapping Done
        .onDisappear { commitAll() }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    commitAll()
                    focus = nil
                }
                .fontWeight(.semibold)
            }
        }
    }

    private func commitAll() {
        let trimmedName = nameText.trimmingCharacters(in: .whitespaces)
        userSettings.name = trimmedName

        if let cw = Double(currentWeightText), cw > 0 { userSettings.currentWeight = cw }
        if let gw = Double(goalWeightText),    gw > 0 { userSettings.goalWeight    = gw }
    }
}

#Preview {
    NavigationStack {
        SettingsView(userSettings: UserSettings())
    }
}
