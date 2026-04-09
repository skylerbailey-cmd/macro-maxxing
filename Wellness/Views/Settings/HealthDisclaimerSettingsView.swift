//
//  HealthDisclaimerSettingsView.swift
//  Wellness
//
//  Read-only health disclaimer shown from Settings.
//

import SwiftUI

struct HealthDisclaimerSettingsView: View {

    private let purpl = Color(red: 0.65, green: 0.45, blue: 1.00)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    row(icon: "heart.text.clipboard",
                        text: "This app is for fitness tracking only and does not provide medical advice.")
                    row(icon: "sparkles",
                        text: "AI-estimated nutritional values are approximations and may not be fully accurate.")
                    row(icon: "stethoscope",
                        text: "Consult a healthcare professional before making significant changes to your diet or exercise routine.")
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )

                Text("By using this app you acknowledge that you have read and understood this disclaimer.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .navigationTitle("Health Disclaimer")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private func row(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(purpl)
                .frame(width: 30)
            Text(text)
                .font(.body)
                .foregroundStyle(.white.opacity(0.80))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
