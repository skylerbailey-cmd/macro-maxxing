//
//  AccentColorPickerView.swift
//  Wellness
//
//  Settings → Appearance → Accent Color.
//

import SwiftUI

struct AccentColorPickerView: View {
    @State private var theme = ThemeStore.shared

    var body: some View {
        List {
            Section {
                ForEach(AccentChoice.allCases) { choice in
                    row(for: choice)
                }
            } footer: {
                Text("The selected color tints buttons, highlights, chips, and progress throughout the app.")
            }
        }
        .navigationTitle("Accent Color")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func row(for choice: AccentChoice) -> some View {
        Button {
            theme.selectedAccent = choice
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(choice.color)
                        .frame(width: 28, height: 28)
                    if choice == theme.selectedAccent {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))

                Text(choice.displayName)
                    .foregroundStyle(.primary)

                Spacer()

                if choice == theme.selectedAccent {
                    Text("Selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { AccentColorPickerView() }
        .preferredColorScheme(.dark)
}
