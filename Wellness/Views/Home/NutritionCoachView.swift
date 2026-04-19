//
//  NutritionCoachView.swift
//  Wellness
//
//  Full navigation page for the AI Nutrition Coach — analyzes the user's
//  full day of meals and gives a personalized debrief. Persists last 3.
//

import SwiftUI

struct NutritionCoachView: View {
    let userID: String
    let selectedDate: Date

    @State private var savedResults: [SavedCoachResult] = []
    @State private var viewingResult: SavedCoachResult?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var showConfirm = false

    private let analyzeVM: AnalyzeViewModel

    private var accent: Color { Color.premiumGold }
    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)

    init(userID: String, selectedDate: Date) {
        self.userID = userID
        self.selectedDate = selectedDate
        self.analyzeVM = AnalyzeViewModel(userID: userID, selectedDate: selectedDate)
    }

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            if isAnalyzing {
                analyzingPhase
            } else if let result = viewingResult {
                resultDetailView(result)
            } else {
                landingPhase
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("AI Nutrition Coach")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { savedResults = SavedCoachResultStore.load() }
        .alert("Get My Recommendation?", isPresented: $showConfirm) {
            Button("Let's Go", role: .none) { runAnalysis() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Reviews your full day of meals, macros, and workouts to give you a personalized nutrition debrief. Once per day.")
        }
    }

    // MARK: - Landing

    private var landingPhase: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status card
                statusCard
                    .padding(.top, 12)

                // Analyze button
                Button {
                    if analyzeVM.hasRunToday {
                        return
                    }
                    showConfirm = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: analyzeVM.hasRunToday ? "checkmark.circle.fill" : "wand.and.stars")
                            .font(.system(size: 18, weight: .semibold))
                        Text(analyzeVM.hasRunToday ? "Done for Today" : "Get My Recommendation")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        if !analyzeVM.hasRunToday {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.30))
                        }
                    }
                    .foregroundStyle(.black)
                    .padding(16)
                    .background(
                        analyzeVM.hasRunToday ? Color.gray : Color.premiumGold,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .shimmering(cornerRadius: 16)
                }
                .buttonStyle(.plain)
                .disabled(analyzeVM.hasRunToday)
                .padding(.horizontal, 20)

                if let error = errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .padding(.horizontal, 20)
                }

                // Saved results
                if savedResults.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Debriefs")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.50))
                            .padding(.horizontal, 20)

                        ForEach(savedResults) { result in
                            savedResultRow(result)
                        }
                    }
                }
            }
            .padding(.bottom, 30)
        }
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.premiumGold.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.premiumGold)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Daily Debrief")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text(analyzeVM.hasRunToday
                     ? "Already logged today. Come back tomorrow."
                     : "Reviews every meal, macro, and workout for personalized advice.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.40))
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 40)
            Image(systemName: "wand.and.stars")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.15))
            Text("No debriefs yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.30))
            Text("Get your daily recommendation to see\npersonalized nutrition advice here.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.20))
                .multilineTextAlignment(.center)
        }
    }

    private func savedResultRow(_ result: SavedCoachResult) -> some View {
        Button {
            viewingResult = result
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.premiumGold.opacity(0.14))
                        .frame(width: 40, height: 40)
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.premiumGold)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(firstLinePreview(result.text))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(result.date.formatted(.relative(presentation: .named)))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.20))
            }
            .padding(14)
            .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .contextMenu {
            Button(role: .destructive) { deleteResult(result) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Analyzing

    private var analyzingPhase: some View {
        VStack(spacing: 24) {
            Spacer()
            CoachSkeletonView()
                .padding(.horizontal, 20)
            VStack(spacing: 8) {
                Text("Analyzing your day...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Reviewing meals, macros, and workouts")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.40))
            }
            Spacer()
        }
    }

    // MARK: - Result Detail

    private func resultDetailView(_ result: SavedCoachResult) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Date header
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.white.opacity(0.40))
                        Text(result.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.40))
                    }
                    .padding(.top, 12)

                    // Result paragraphs as cards
                    let paragraphs = parseParagraphs(result.text)
                    ForEach(Array(paragraphs.enumerated()), id: \.offset) { idx, paragraph in
                        paragraphCard(paragraph, index: idx)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }

            // Bottom bar
            Button {
                viewingResult = nil
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("All Debriefs")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }

    private func paragraphCard(_ text: String, index: Int) -> some View {
        let icons = ["clock.fill", "leaf.fill", "star.fill"]
        let colors: [Color] = [
            Color(red: 0.35, green: 0.75, blue: 1.0),
            Color(red: 0.40, green: 0.90, blue: 0.72),
            Color(red: 1.0, green: 0.80, blue: 0.20)
        ]
        let icon = index < icons.count ? icons[index] : "lightbulb.fill"
        let color = index < colors.count ? colors[index] : accent

        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 20)
                .padding(.top, 2)

            if let attr = try? AttributedString(
                markdown: text,
                options: AttributedString.MarkdownParsingOptions(
                    interpretedSyntax: .full
                )
            ) {
                Text(attr)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.80))
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.80))
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func parseParagraphs(_ text: String) -> [String] {
        let processed = text.replacingOccurrences(
            of: #"([.!?;—])\s*(\d*\.?\s*\*\*[A-Z])"#,
            with: "$1\n\n$2",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        return processed
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func firstLinePreview(_ text: String) -> String {
        // Extract bold text from first paragraph as preview
        let paragraphs = parseParagraphs(text)
        guard let first = paragraphs.first else { return "Nutrition Debrief" }
        // Try to find bold header
        if let range = first.range(of: #"\*\*(.+?)\*\*"#, options: .regularExpression) {
            var match = String(first[range])
            match = match.replacingOccurrences(of: "**", with: "")
            return match
        }
        return String(first.prefix(40))
    }

    // MARK: - Actions

    private func runAnalysis() {
        isAnalyzing = true
        errorMessage = nil

        Task {
            await analyzeVM.analyze()

            switch analyzeVM.state {
            case .result(let text):
                let saved = SavedCoachResult(text: text)
                SavedCoachResultStore.save(saved)
                savedResults = SavedCoachResultStore.load()
                viewingResult = saved
            case .error(let msg):
                errorMessage = msg
            default:
                break
            }
            isAnalyzing = false
        }
    }

    private func deleteResult(_ result: SavedCoachResult) {
        SavedCoachResultStore.delete(result.id)
        savedResults = SavedCoachResultStore.load()
        if viewingResult?.id == result.id { viewingResult = nil }
    }
}
