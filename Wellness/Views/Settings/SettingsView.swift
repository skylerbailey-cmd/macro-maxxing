//
//  SettingsView.swift
//  Wellness
//

import SwiftUI

// MARK: - FAQ item model

private struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer:   String
}

private let faqItems: [FAQItem] = [
    FAQItem(
        question: "What are Aura Points?",
        answer: """
        Aura Points are the currency of your gains journey. Every rep in the gym and \
        every meal you track earns you Aura.

        How to earn them:
        • 3-day logging streak → +50 pts
        • 7-day streak → +150 pts
        • 14-day streak → +300 pts
        • 30-day streak → +500 pts
        • 60-day streak → +750 pts
        • 100-day streak → +1,000 pts
        • Post when you crush your macro goals → +75 pts
        • Drop a comment on someone's post → +10 pts

        Each streak milestone is awarded once. Keep the streak alive and the \
        aura farms itself, no cap.
        """
    ),
    FAQItem(
        question: "What are Aura Levels?",
        answer: """
        Aura Levels show where you stand on the looksmaxxing hierarchy. \
        Every 1,000 Aura Points = 1 level, up to a max of Level 100.

        Level titles:
        • Level 0 — (no title yet)
        • Levels 1–9 — Initiate
        • Levels 10–24 — Disciple
        • Levels 25–39 — Ascender
        • Levels 40–59 — Mog Apprentice
        • Levels 60–79 — Aura Farmer
        • Levels 80–94 — Elite Aesthetic
        • Levels 95–100 — Final Form

        Your level and title appear under your name on the Home screen and \
        next to your name on every post you make. Stack those points and ascend.
        """
    ),
]

// MARK: - SettingsView

struct SettingsView: View {
    @Bindable var userSettings: UserSettings
    @FocusState private var nameFocused: Bool

    // Local state — only writes to userSettings on commit, preventing re-renders on every input
    @State private var activeFAQ: FAQItem? = nil
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

            // MARK: FAQ
            Section("FAQ") {
                ForEach(faqItems) { item in
                    Button {
                        activeFAQ = item
                    } label: {
                        HStack {
                            Text(item.question)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
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
            nameText         = userSettings.name
            usernameText     = userSettings.username
            currentWeightVal = userSettings.currentWeight > 0 ? userSettings.currentWeight : 160
            goalWeightVal    = userSettings.goalWeight    > 0 ? userSettings.goalWeight    : 160
            proteinPerLbVal  = userSettings.proteinPerLb
        }
        .onDisappear { commitAll() }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .sheet(item: $activeFAQ) { item in
            FAQDetailView(item: item)
                .presentationDetents([.medium, .large])
        }
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

// MARK: - FAQ Detail Sheet

private struct FAQDetailView: View {
    let item: FAQItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(item.answer)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }
            .preferredColorScheme(.dark)
            .navigationTitle(item.question)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(userSettings: UserSettings())
    }
}
