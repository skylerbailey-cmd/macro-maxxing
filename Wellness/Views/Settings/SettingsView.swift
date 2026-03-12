//
//  SettingsView.swift
//  Wellness
//

import SwiftUI

struct SettingsView: View {
    @Bindable var userSettings: UserSettings

    var body: some View {
        Form {
            // MARK: Profile
            Section("Profile") {
                HStack {
                    Text("Name")
                    Spacer()
                    TextField("Your name", text: $userSettings.name)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.primary)
                }
            }

            // MARK: Body
            Section("Body") {
                HStack {
                    Text("Current Weight")
                    Spacer()
                    TextField("0", value: $userSettings.currentWeight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("lbs").foregroundStyle(.secondary)
                }
                HStack {
                    Text("Goal Weight")
                    Spacer()
                    TextField("0", value: $userSettings.goalWeight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
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
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    NavigationStack {
        SettingsView(userSettings: UserSettings())
    }
}
