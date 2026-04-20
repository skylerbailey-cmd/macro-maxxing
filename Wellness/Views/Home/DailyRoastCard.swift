//
//  DailyRoastView.swift
//  Wellness
//
//  Full-screen AI Roast page. Tap "Roast Me" to generate. Past roasts
//  are saved and shown as compact rows (emoji + headline + date).
//  Tapping a past roast expands it. Share renders a card image for
//  Instagram Stories, save to Photos, or post to the feed.
//

import SwiftUI
import UIKit

struct DailyRoastView: View {
    let userSettings: UserSettings
    let selectedDate: Date

    @Environment(\.dismiss) private var dismiss

    @State private var currentRoast: DailyRoast? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var mealPhotoURLs: [String] = []
    @State private var pastRoasts: [DailyRoast] = []
    @State private var showPhotoViewer = false
    @State private var photoViewerURL: String? = nil

    // Detail / share
    @State private var detailRoast: DailyRoast? = nil
    @State private var shareRoast: DailyRoast? = nil
    @State private var showShareActions = false

    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)

    private static let storageKey = "savedDailyRoasts"
    private static let maxSavedRoasts = 20

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    roastMeButton

                    if let roast = currentRoast {
                        fullRoastCard(roast)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    if let err = errorMessage { errorCard(err) }

                    if !pastRoasts.isEmpty { pastRoastsSection }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("AI Roast")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onAppear { loadPastRoasts() }
        .fullScreenCover(isPresented: $showPhotoViewer) {
            if let url = photoViewerURL {
                PhotoViewerSheet(urls: [url], initialIndex: 0)
            }
        }
        .sheet(item: $detailRoast) { roast in
            roastDetailSheet(roast)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Share Roast", isPresented: $showShareActions, titleVisibility: .visible) {
            Button("Instagram Story") { shareToInstagram() }
            Button("Save to Photos") { saveToPhotos() }
            Button("Post to Feed") { postToFeed() }
            Button("Cancel", role: .cancel) { shareRoast = nil }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 12) {
            Text("🔥")
                .font(.system(size: 48))
            Text("AI ROAST")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.premiumGold)
            Text("Log your meals and workouts, then let the AI destroy you.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [Color.premiumGold.opacity(0.08), .clear],
                           startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.premiumGold.opacity(0.15), lineWidth: 1))
    }

    // MARK: - Generate button

    private var roastMeButton: some View {
        Button { Task { await generate() } } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().tint(.black)
                    Text("Cooking up your roast...")
                        .font(.system(size: 16, weight: .bold))
                } else {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("Roast Me")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isLoading
                    ? AnyShapeStyle(Color.premiumGold.opacity(0.40))
                    : AnyShapeStyle(LinearGradient(
                        colors: [Color.premiumGold, Color(red: 0.85, green: 0.65, blue: 0.10)],
                        startPoint: .leading, endPoint: .trailing)),
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    // MARK: - Error

    private func errorCard(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.premiumGold)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.60))
            Spacer()
        }
        .padding(14)
        .background(Color.premiumGold.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Full roast card (current result)

    private func fullRoastCard(_ roast: DailyRoast) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(roast.emoji).font(.system(size: 36))
                VStack(alignment: .leading, spacing: 2) {
                    Text(roast.headline.uppercased())
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(Color.premiumGold)
                        .lineLimit(2)
                }
                Spacer()
                Button { toggleSave(roast) } label: {
                    Image(systemName: roast.isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(roast.isSaved ? Color.premiumGold : .white.opacity(0.45))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                Button { shareRoast = roast; showShareActions = true } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.45))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
            }

            // Targeted meal photo
            if roast.targetMealIndex >= 0,
               roast.targetMealIndex < mealPhotoURLs.count,
               !mealPhotoURLs[roast.targetMealIndex].isEmpty {
                mealPhotoView(url: mealPhotoURLs[roast.targetMealIndex])
            }

            Text(roast.roastText)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            roastFooter
        }
        .padding(16)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.premiumGold.opacity(0.25), lineWidth: 1))
    }

    // MARK: - Meal photo

    @ViewBuilder
    private func mealPhotoView(url: String) -> some View {
        Button { photoViewerURL = url; showPhotoViewer = true } label: {
            CachedAsyncImage(
                url: URL(string: url),
                content: { img in
                    img.resizable().scaledToFill()
                        .frame(maxWidth: .infinity).frame(height: 180)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.premiumGold.opacity(0.30), lineWidth: 1))
                        .overlay(alignment: .topTrailing) {
                            Text("EXHIBIT A")
                                .font(.system(size: 9, weight: .black)).tracking(1)
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.premiumGold, in: Capsule())
                                .padding(8)
                        }
                },
                placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05)).frame(height: 180)
                        .overlay { ProgressView().tint(Color.premiumGold) }
                }
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer

    private var roastFooter: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill").font(.system(size: 9))
                .foregroundStyle(Color.premiumGold.opacity(0.40))
            Text("AI Roast").font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.20))
        }
    }

    // MARK: - Past roasts (compact rows)

    private var pastRoastsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PAST ROASTS")
                .font(.system(size: 11, weight: .black))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.30))

            ForEach(pastRoasts, id: \.id) { roast in
                Button { detailRoast = roast } label: {
                    HStack(spacing: 12) {
                        Text(roast.emoji)
                            .font(.system(size: 24))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(roast.headline)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text(roast.dateKey)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.30))
                        }

                        Spacer()

                        if roast.isSaved {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.premiumGold.opacity(0.55))
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.20))
                    }
                    .padding(12)
                    .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                        roast.isSaved ? Color.premiumGold.opacity(0.12) : Color.white.opacity(0.05), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Detail sheet (past roast expanded)

    private func roastDetailSheet(_ roast: DailyRoast) -> some View {
        let isSaved = roast.isSaved
        return ZStack {
            pageBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        Text(roast.emoji).font(.system(size: 40))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(roast.headline.uppercased())
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(Color.premiumGold)
                            Text(roast.dateKey)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.30))
                        }
                        Spacer()
                        Button {
                            toggleSave(roast)
                            detailRoast = nil
                        } label: {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(isSaved ? Color.premiumGold : .white.opacity(0.50))
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.08), in: Circle())
                        }
                        .buttonStyle(.plain)
                        Button { shareRoast = roast; detailRoast = nil; showShareActions = true } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white.opacity(0.50))
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.08), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    Text(roast.roastText)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(4)

                    roastFooter
                }
                .padding(20)
                .padding(.top, 12)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Share helpers

    private func renderShareCard(_ roast: DailyRoast) -> UIImage {
        let card = RoastShareCard(roast: roast, userName: userSettings.name)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        return renderer.uiImage ?? UIImage()
    }

    private func shareToInstagram() {
        guard let roast = shareRoast else { return }
        let image = renderShareCard(roast)
        guard let data = image.pngData(),
              let url  = URL(string: "instagram-stories://share?source_application=com.sbailey.Wellness")
        else { return }

        UIPasteboard.general.setItems([
            ["com.instagram.sharedSticker.backgroundImage": data,
             "com.instagram.sharedSticker.backgroundTopColor": "#080215",
             "com.instagram.sharedSticker.backgroundBottomColor": "#030108"]
        ], options: [.expirationDate: Date(timeIntervalSinceNow: 300)])

        UIApplication.shared.open(url) { success in
            if !success { saveToPhotos() }
        }
        shareRoast = nil
    }

    private func saveToPhotos() {
        guard let roast = shareRoast else { return }
        let image = renderShareCard(roast)
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        shareRoast = nil
    }

    private func postToFeed() {
        // TODO: Open NewPostView with the roast card image as a pre-attached photo
        guard let roast = shareRoast else { return }
        _ = renderShareCard(roast)
        shareRoast = nil
    }

    // MARK: - Generate

    @MainActor
    private func generate() async {
        guard !userSettings.userID.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        currentRoast = nil

        do {
            let entries = (try? await FoodEntryService.shared.fetch(
                userID: userSettings.userID, date: selectedDate)) ?? []

            let tf = DateFormatter()
            tf.dateFormat = "h:mm a"

            let meals = entries.map { e in (
                name: e.foodName, calories: Int(e.calories), protein: Int(e.protein),
                carbs: Int(e.carbs), fat: Int(e.fat),
                time: tf.string(from: e.loggedAt), photoURL: e.photoURL
            )}
            mealPhotoURLs = meals.map(\.photoURL)

            let workoutEntries = (try? await WorkoutService.shared.fetch(
                userID: userSettings.userID, date: selectedDate)) ?? []
            let workouts = workoutEntries.map { w in (
                name: w.name, type: w.workoutType.rawValue,
                duration: w.durationMinutes, calories: w.caloriesBurned,
                exercises: w.exercises.map(\.name)
            )}

            let goalCal = Int(UserDefaults.standard.double(forKey: "goalCalories"))
            let goalPro = Int(UserDefaults.standard.double(forKey: "goalProtein"))

            let result = try await DailyRoastService.shared.generateRoast(
                meals: meals, workouts: workouts,
                goalCalories: goalCal > 0 ? goalCal : 2000,
                goalProtein: goalPro > 0 ? goalPro : 150,
                streak: userSettings.macroStreak, userName: userSettings.name)

            withAnimation(.spring(duration: 0.35)) { currentRoast = result }
            saveRoast(result)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Persistence
    //
    // Storage policy: keep ALL saved (bookmarked) roasts forever,
    // plus the most recent 3 unsaved ones. Older unsaved roasts are trimmed.

    private func saveRoast(_ roast: DailyRoast) {
        var all = loadAllRoasts()
        all.removeAll { $0.id == roast.id }
        all.insert(roast, at: 0)
        persistAndRefresh(all)
    }

    private func toggleSave(_ roast: DailyRoast) {
        var all = loadAllRoasts()
        if let idx = all.firstIndex(where: { $0.id == roast.id }) {
            all[idx].isSaved.toggle()
        }
        persistAndRefresh(all)
        // Also update currentRoast if it's the same one
        if currentRoast?.id == roast.id {
            currentRoast?.isSaved.toggle()
        }
    }

    private func persistAndRefresh(_ roasts: [DailyRoast]) {
        // Keep all saved + most recent 3 unsaved
        let saved   = roasts.filter { $0.isSaved }
        let unsaved = roasts.filter { !$0.isSaved }
        let trimmed = saved + Array(unsaved.prefix(3))
        let sorted  = trimmed.sorted { $0.dateKey > $1.dateKey }

        if let data = try? JSONEncoder().encode(sorted) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
        pastRoasts = sorted
    }

    private func loadPastRoasts() {
        pastRoasts = loadAllRoasts()
    }

    private func loadAllRoasts() -> [DailyRoast] {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let roasts = try? JSONDecoder().decode([DailyRoast].self, from: data)
        else { return [] }
        return roasts
    }
}

// MARK: - Share Card (rendered to image)

/// Self-contained renderable roast card for sharing. 360×640 pt → 1080×1920 px @ 3×.
private struct RoastShareCard: View {
    let roast: DailyRoast
    let userName: String

    private let bg1 = Color(red: 0.08, green: 0.04, blue: 0.15)
    private let bg2 = Color(red: 0.03, green: 0.01, blue: 0.08)

    var body: some View {
        ZStack {
            LinearGradient(colors: [bg1, bg2], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(Color.premiumGold.opacity(0.20)).frame(width: 300).blur(radius: 80).offset(y: -180)

            VStack(spacing: 24) {
                Spacer()

                Text(roast.emoji).font(.system(size: 64))

                Text(roast.headline.uppercased())
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(Color.premiumGold)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 30)

                Text(roast.roastText)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 30)

                if !userName.isEmpty {
                    Text("roasting @\(userName)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.30))
                }

                Spacer()

                VStack(spacing: 4) {
                    Text("MACRO MAXXING")
                        .font(.system(size: 12, weight: .black))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.90))
                    Text("macromaxxing.app")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.40))
                }
                .padding(.bottom, 28)
            }
        }
        .frame(width: 360, height: 640)
        .preferredColorScheme(.dark)
    }
}
