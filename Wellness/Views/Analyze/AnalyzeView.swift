//
//  AnalyzeView.swift
//  Wellness
//

import SwiftUI
import SwiftData

// MARK: - Color palette (matches app theme)

private extension Color {
    static let pageBg   = Color(red: 0.07, green: 0.05, blue: 0.12)
    static let cardBg   = Color(red: 0.13, green: 0.10, blue: 0.22)
    static let purpleHi = Color(red: 0.65, green: 0.45, blue: 1.00)
}

// MARK: - AnalyzeView

struct AnalyzeView: View {
    @State private var viewModel: AnalyzeViewModel
    @Binding var selectedDate: Date
    @Environment(SessionManager.self) private var sessionManager

    init(selectedDate: Binding<Date>) {
        _selectedDate = selectedDate
        // viewModel will be initialized in onAppear with the actual userID
        _viewModel = State(wrappedValue: AnalyzeViewModel(
            userID: "",
            selectedDate: selectedDate.wrappedValue
        ))
    }

    var body: some View {
        ZStack {
            Color.pageBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    DateNavigatorView(selectedDate: $selectedDate)

                    descriptionCard

                    switch viewModel.state {
                    case .idle:
                        analyzeButton

                    case .analyzing:
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(Color.purpleHi)
                                .scaleEffect(1.3)
                            Text("Analyzing your nutrition…")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.50))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)

                    case .result(let text):
                        resultCard(text)
                        analyzeButton

                    case .error(let message):
                        errorCard(message)
                        analyzeButton
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Initialize viewModel with the actual userID when view appears
            if let userID = sessionManager.currentUID {
                viewModel = AnalyzeViewModel(userID: userID, selectedDate: selectedDate)
            }
        }
        .onChange(of: selectedDate) { _, newDate in
            viewModel.selectedDate = newDate
            viewModel.reset()
        }
    }

    // MARK: - Description card

    private var descriptionCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Color.purpleHi)

            VStack(spacing: 6) {
                Text("AI Nutrition Coach")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Text("Tap **Analyze** and Claude will review everything you've logged for the selected day — your meals, current macro totals, and goals — then give you personalized suggestions.\n\nYou'll get specific meal swaps, snack ideas, or simple tweaks to help you hit your targets.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.cardBg)
        .cornerRadius(16)
    }

    // MARK: - Analyze button

    private var analyzeButton: some View {
        Button {
            Task { await viewModel.analyze() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 16, weight: .semibold))
                Text(viewModel.state == .idle ? "Analyze" : "Re-Analyze")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.purpleHi)
        .disabled(viewModel.state == .analyzing)
    }

    // MARK: - Result card

    private func resultCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.purpleHi)
                Text("Analysis")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            Divider().background(Color.white.opacity(0.08))

            // Render Claude's markdown response
            if let attrStr = try? AttributedString(
                markdown: text,
                options: AttributedString.MarkdownParsingOptions(
                    interpretedSyntax: .inlineOnlyPreservingWhitespace
                )
            ) {
                Text(attrStr)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(16)
    }

    // MARK: - Error card

    private func errorCard(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.70))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBg)
        .cornerRadius(14)
    }
}

// MARK: - Preview

#Preview {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodEntry.self, configurations: config)
    let sessionManager = SessionManager()
    return NavigationStack {
        AnalyzeView(selectedDate: .constant(Calendar.current.startOfDay(for: Date())))
            .environment(sessionManager)
            .navigationTitle("Analyze")
    }
}
