//
//  ShareView.swift
//  Wellness
//

import SwiftUI
import UIKit

// MARK: - ShareView

struct ShareView: View {
    let viewModel: HomeViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var renderedImage: UIImage?
    @State private var showingActivitySheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.05, blue: 0.12).ignoresSafeArea()

                VStack(spacing: 24) {
                    // Card preview
                    cardPreview

                    // Share buttons
                    VStack(spacing: 10) {
                        shareButton(
                            title: "Instagram Stories",
                            subtitle: "Share directly to your story",
                            icon: "camera.fill",
                            colors: [Color(red: 0.88, green: 0.19, blue: 0.42),
                                     Color(red: 0.98, green: 0.35, blue: 0.00)]
                        ) { shareToInstagram() }

                        shareButton(
                            title: "Share / Save / More",
                            subtitle: "Messages, AirDrop, save to Photos…",
                            icon: "square.and.arrow.up",
                            colors: [Color(red: 0.65, green: 0.45, blue: 1.00),
                                     Color(red: 0.40, green: 0.20, blue: 0.85)]
                        ) { showingActivitySheet = true }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 8)
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Share Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task { await renderCard() }
        .sheet(isPresented: $showingActivitySheet) {
            if let img = renderedImage { ActivitySheet(items: [img]) }
        }
    }

    // MARK: - Card preview

    private var cardPreview: some View {
        Group {
            if let image = renderedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .purple.opacity(0.35), radius: 24, y: 8)
                    .frame(maxHeight: 320)
                    .padding(.horizontal, 40)
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.13, green: 0.10, blue: 0.22))
                    .frame(height: 280)
                    .padding(.horizontal, 40)
                    .overlay {
                        VStack(spacing: 10) {
                            ProgressView().tint(Color(red: 0.65, green: 0.45, blue: 1.0))
                            Text("Rendering…")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.40))
                        }
                    }
            }
        }
    }

    // MARK: - Share button

    private func shareButton(title: String, subtitle: String,
                             icon: String, colors: [Color],
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(colors: colors,
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.30))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(red: 0.13, green: 0.10, blue: 0.22))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .disabled(renderedImage == nil)
    }

    // MARK: - Render

    @MainActor
    private func renderCard() async {
        let met  = viewModel.macroGoalsMet
        let card = ShareCardView(data: ShareCardData(
            totalCalories: viewModel.totalCalories,
            goalCalories:  viewModel.goalCalories,
            totalProtein:  viewModel.totalProtein,
            goalProtein:   viewModel.goalProtein,
            totalCarbs:    viewModel.totalCarbs,
            goalCarbs:     viewModel.goalCarbs,
            totalFat:      viewModel.totalFat,
            goalFat:       viewModel.goalFat,
            calMet:  met.indices.contains(0) ? met[0] : false,
            proMet:  met.indices.contains(1) ? met[1] : false,
            carbMet: met.indices.contains(2) ? met[2] : false,
            fatMet:  met.indices.contains(3) ? met[3] : false,
            streak:  viewModel.macroStreak,
            date:    viewModel.selectedDate,
            name:    viewModel.userSettings.name,
            meme:    viewModel.macroGoalsMet.allSatisfy({ $0 }) ? GymMeme.random() : nil
        ))

        let renderer   = ImageRenderer(content: card)
        renderer.scale = 3.0          // 360 × 640 pt  →  1080 × 1920 px
        renderedImage  = renderer.uiImage
    }

    // MARK: - Platform share actions

    private func shareToInstagram() {
        guard let image = renderedImage,
              let data  = image.pngData(),
              let url   = URL(string: "instagram-stories://share?source_application=com.sbailey.Wellness")
        else { showingActivitySheet = true; return }

        let items: [String: Any] = [
            "com.instagram.sharedSticker.backgroundImage": data,
            "com.instagram.sharedSticker.backgroundTopColor":    "#080215",
            "com.instagram.sharedSticker.backgroundBottomColor": "#030108"
        ]
        UIPasteboard.general.setItems(
            [items],
            options: [.expirationDate: Date(timeIntervalSinceNow: 300)]
        )
        UIApplication.shared.open(url) { success in
            if !success { showingActivitySheet = true }
        }
    }

}

// MARK: - UIActivityViewController wrapper

struct ActivitySheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_: UIActivityViewController, context: Context) {}
}
