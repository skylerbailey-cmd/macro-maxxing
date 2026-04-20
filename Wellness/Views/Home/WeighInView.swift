//
//  WeighInView.swift
//  Wellness
//
//  Full-screen weigh-in popup. Shows the user's current weight, lets them
//  enter a new weight, then displays a motivational result screen based on
//  whether they moved toward or away from their goal. Also offers the option
//  to adjust the goal weight inline.
//

import SwiftUI

struct WeighInView: View {
    let userSettings: UserSettings
    let onDismiss: () -> Void

    // MARK: - Flow state

    private enum Step { case input, result }
    @State private var step: Step = .input

    // MARK: - Input

    @State private var newWeightText: String = ""
    @FocusState private var weightFocused: Bool

    // MARK: - Result

    /// Snapshot of the weight *before* the user logs a new one.
    /// Captured when "Log Weight" is tapped so it survives the
    /// `userSettings.currentWeight` update.
    @State private var previousWeight: Double = 0
    @State private var editingGoal: Bool = false
    @State private var newGoalText: String = ""
    @State private var showingNewPost: Bool = false

    // MARK: - Design

    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)
    private var accent: Color { ThemeStore.shared.accent }

    private var oldWeight: Double { previousWeight }
    private var goalWeight: Double { userSettings.goalWeight }

    private var newWeight: Double { Double(newWeightText) ?? oldWeight }

    /// True if the user's goal is to lose weight (goal < old weight before weigh-in).
    private var isLossGoal: Bool { goalWeight < oldWeight }

    /// True if the new weight moved toward the goal (or hit it).
    private var movedTowardGoal: Bool {
        if isLossGoal {
            return newWeight <= oldWeight
        } else {
            return newWeight >= oldWeight
        }
    }

    private var hitGoal: Bool {
        if isLossGoal { return newWeight <= goalWeight }
        else          { return newWeight >= goalWeight }
    }

    private var weightDelta: Double { newWeight - oldWeight }

    // MARK: - Body

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag indicator
                Capsule()
                    .fill(Color.white.opacity(0.20))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)

                Spacer()

                switch step {
                case .input:  inputContent
                case .result: resultContent
                }

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            previousWeight = userSettings.currentWeight
            newWeightText  = "\(Int(userSettings.currentWeight))"
            newGoalText    = "\(Int(goalWeight))"
        }
    }

    // MARK: - Input Step

    private var inputContent: some View {
        VStack(spacing: 28) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(accent)
                Text("Ready to weigh in?")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            // Current weight display
            VStack(spacing: 4) {
                Text("Current Weight")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.40))
                Text("\(Int(oldWeight)) lbs")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }

            // New weight input
            VStack(spacing: 8) {
                Text("New Weight")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.40))
                HStack(spacing: 8) {
                    TextField("0", text: $newWeightText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .focused($weightFocused)
                    Text("lbs")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .frame(maxWidth: 220)
            }
            .padding(20)
            .background(cardBg, in: RoundedRectangle(cornerRadius: 16))

            // Goal reference
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accent)
                Text("Goal: \(Int(goalWeight)) lbs")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
                Text("(\(isLossGoal ? "losing" : "gaining"))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.30))
            }

            // Next button
            Button {
                guard let w = Double(newWeightText), w > 0 else { return }
                previousWeight = userSettings.currentWeight
                userSettings.currentWeight = w
                userSettings.lastLocalSettingsSave = Date()
                // Sync to Firestore so the change survives app restart
                Task {
                    try? await UserProfileService.shared.updatePrivateProfile(
                        userID: userSettings.userID,
                        fields: ["currentWeight": w])
                }
                withAnimation(.spring(duration: 0.35)) { step = .result }
            } label: {
                Text("Log Weight")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(accent, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Result Step

    private var resultContent: some View {
        VStack(spacing: 24) {
            // Emoji + headline
            VStack(spacing: 12) {
                Text(hitGoal ? "🏆" : movedTowardGoal ? "🔥" : "💪")
                    .font(.system(size: 56))

                Text(headline)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Weight change card
            HStack(spacing: 20) {
                weightStat(label: "Before", value: "\(Int(oldWeight))", color: .white.opacity(0.55))
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(accent)
                weightStat(label: "Now", value: "\(Int(newWeight))", color: accent)
            }
            .padding(16)
            .background(cardBg, in: RoundedRectangle(cornerRadius: 14))

            // Delta badge
            let delta = weightDelta
            let deltaStr = delta >= 0 ? "+\(String(format: "%.1f", delta))" : String(format: "%.1f", delta)
            Text("\(deltaStr) lbs")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(movedTowardGoal ? Color(red: 0.25, green: 0.85, blue: 0.50) : Color(red: 1.00, green: 0.55, blue: 0.15))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    (movedTowardGoal ? Color(red: 0.25, green: 0.85, blue: 0.50) : Color(red: 1.00, green: 0.55, blue: 0.15)).opacity(0.12),
                    in: Capsule()
                )

            // Adjust goal section
            VStack(spacing: 10) {
                Button {
                    withAnimation(.spring(duration: 0.2)) { editingGoal.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 12, weight: .bold))
                        Text(editingGoal ? "Hide" : "Adjust Goal Weight")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(accent)
                }
                .buttonStyle(.plain)

                if editingGoal {
                    HStack(spacing: 10) {
                        TextField("Goal", text: $newGoalText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(12)
                            .background(cardBg, in: RoundedRectangle(cornerRadius: 10))
                            .frame(width: 120)

                        Text("lbs")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.35))

                        Button {
                            if let g = Double(newGoalText), g > 0 {
                                userSettings.goalWeight = g
                                userSettings.lastLocalSettingsSave = Date()
                                Task {
                                    try? await UserProfileService.shared.updatePrivateProfile(
                                        userID: userSettings.userID,
                                        fields: ["goalWeight": g])
                                }
                            }
                            withAnimation(.spring(duration: 0.2)) { editingGoal = false }
                        } label: {
                            Text("Save")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(accent, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }

            // Done + Back buttons
            VStack(spacing: 10) {
                Button {
                    showingNewPost = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 14, weight: .bold))
                        Text("Share Progress")
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(accent, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Button {
                    onDismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.50))
                }
                .buttonStyle(.plain)

                Button {
                    // Restore previous weight so the user can re-enter
                    userSettings.currentWeight = previousWeight
                    newWeightText = "\(Int(previousWeight))"
                    withAnimation(.spring(duration: 0.35)) { step = .input }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                        Text("Back")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.35))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, 24)
        .sheet(isPresented: $showingNewPost, onDismiss: { onDismiss() }) {
            NavigationStack {
                NewPostView(
                    userSettings: userSettings,
                    preSelectedLabel: .goalPost,
                    prePopulatedPreviousWeight: previousWeight,
                    prePopulatedCurrentWeight:  newWeight,
                    prePopulatedGoalWeight:     goalWeight
                )
            }
        }
    }

    // MARK: - Helpers

    private var headline: String {
        if hitGoal {
            return "You hit your goal!"
        } else if movedTowardGoal {
            return "You're making progress!"
        } else {
            return "Keep pushing!"
        }
    }

    private var subtitle: String {
        if hitGoal {
            return "You reached \(Int(goalWeight)) lbs. Time to set a new target."
        } else if movedTowardGoal {
            let remaining = abs(newWeight - goalWeight)
            return "Only \(String(format: "%.1f", remaining)) lbs to go. You've got this."
        } else {
            let remaining = abs(newWeight - goalWeight)
            return "\(String(format: "%.1f", remaining)) lbs from your goal. Every day is a fresh start."
        }
    }

    private func weightStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.35))
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text("lbs")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.30))
        }
    }
}
