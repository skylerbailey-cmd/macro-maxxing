//
//  AIConsentView.swift
//  Wellness
//
//  One-time consent prompt shown before any AI features are used.
//  No data is sent to Anthropic's Claude API until the user agrees.
//

import SwiftUI

struct AIConsentSheet: View {
    let onAgree: () -> Void
    let onDecline: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let accent = Color(red: 0.65, green: 0.45, blue: 1.00)

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(accent)
                }

                // Title
                Text("AI-Powered Nutrition Analysis")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                // Disclosure
                VStack(alignment: .leading, spacing: 12) {
                    disclosureRow(
                        icon: "camera.fill",
                        text: "Macromaxxing sends your food photos to Anthropic's Claude AI to estimate nutritional content."
                    )
                    disclosureRow(
                        icon: "lock.shield.fill",
                        text: "Photos are processed for analysis only and are not stored by the AI provider."
                    )
                    disclosureRow(
                        icon: "pencil.line",
                        text: "You can always use manual entry instead — no AI required."
                    )
                }
                .padding(20)
                .background(cardBg, in: RoundedRectangle(cornerRadius: 16))

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        onAgree()
                        dismiss()
                    } label: {
                        Text("I Agree — Enable AI Features")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(accent, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button {
                        onDecline()
                        dismiss()
                    } label: {
                        Text("No Thanks — I'll Enter Manually")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled()
    }

    private func disclosureRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 20)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.80))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
