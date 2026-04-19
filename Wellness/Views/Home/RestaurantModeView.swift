//
//  RestaurantModeView.swift
//  Wellness
//
//  Full navigation page for AI Restaurant Mode — scan a menu photo or paste
//  a URL, get macro-matched picks. Persists the last 3 scans.
//

import SwiftUI
import PhotosUI

struct RestaurantModeView: View {
    let remainingCalories: Int
    let remainingProtein: Int
    let remainingCarbs: Int
    let remainingFat: Int
    let goalCalories: Int
    let goalProtein: Int
    let goalCarbs: Int
    let goalFat: Int

    @State private var savedScans: [SavedMenuScan] = []

    // New-scan flow
    @State private var isScanning = false
    @State private var menuImage: UIImage?
    @State private var showingCamera = false
    @State private var photoItem: PhotosPickerItem?
    @State private var menuURLText: String = ""
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    // Viewing a scan (saved or freshly created)
    @State private var viewingScan: SavedMenuScan?
    @State private var currentPage = 0

    private var accent: Color { Color.premiumGold }
    private let pageBg = Color(red: 0.05, green: 0.05, blue: 0.07)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            if isAnalyzing {
                analyzingPhase
            } else if let scan = viewingScan {
                scanDetailView(scan)
            } else if isScanning {
                newScanPhase
            } else {
                landingPhase
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("AI Restaurant Mode")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCamera) {
            ImagePickerView(sourceType: .camera, selectedImage: $menuImage)
        }
        .onChange(of: menuImage) { _, img in
            if img != nil { analyzeMenuPhoto() }
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    menuImage = img
                }
            }
        }
        .onAppear { savedScans = SavedMenuScanStore.load() }
    }

    // MARK: - Landing: History + New Scan

    private var landingPhase: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Remaining macros
                remainingMacrosBar
                    .padding(.top, 12)

                // New scan button
                Button { isScanning = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 18, weight: .semibold))
                        Text("New Menu Scan")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.30))
                    }
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(accent.opacity(0.18), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(accent.opacity(0.35), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                // Saved scans
                if savedScans.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Scans")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.50))
                            .padding(.horizontal, 20)

                        ForEach(savedScans) { scan in
                            savedScanRow(scan)
                        }
                    }
                }
            }
            .padding(.bottom, 30)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 40)
            Image(systemName: "menucard")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.15))
            Text("No scans yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.30))
            Text("Snap a menu or paste a URL to get\nmacro-matched picks from any restaurant.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.20))
                .multilineTextAlignment(.center)
        }
    }

    private func savedScanRow(_ scan: SavedMenuScan) -> some View {
        Button {
            currentPage = 0
            viewingScan = scan
        } label: {
            HStack(spacing: 14) {
                // Source icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.premiumGold.opacity(0.14))
                        .frame(width: 40, height: 40)
                    Image(systemName: scan.source == "Photo" ? "camera.fill" : "link")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.premiumGold)
                }

                VStack(alignment: .leading, spacing: 3) {
                    // Top pick name
                    Text(scan.recommendations.first?.itemName ?? "Menu Scan")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(scan.source)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                        Text("·")
                            .foregroundStyle(.white.opacity(0.20))
                        Text(scan.date.formatted(.relative(presentation: .named)))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                        Text("·")
                            .foregroundStyle(.white.opacity(0.20))
                        Text("\(scan.recommendations.count) picks")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                    }
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
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { deleteScan(scan) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive) { deleteScan(scan) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - New Scan Phase

    private var newScanPhase: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "menucard.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(accent)
            }

            VStack(spacing: 6) {
                Text("Scan a Menu")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text("Take a photo or paste a link to the menu.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                Button {
                    showingCamera = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Take Photo")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accent, in: RoundedRectangle(cornerRadius: 14))
                }

                PhotosPicker(selection: $photoItem, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Choose from Library")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                }

                // Divider
                HStack(spacing: 12) {
                    Rectangle().fill(Color.white.opacity(0.10)).frame(height: 1)
                    Text("or")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.30))
                    Rectangle().fill(Color.white.opacity(0.10)).frame(height: 1)
                }

                // URL input
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.35))
                    TextField("", text: $menuURLText, prompt:
                        Text("Paste menu URL")
                            .foregroundStyle(.white.opacity(0.25))
                    )
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .submitLabel(.go)
                    .onSubmit { analyzeURL() }

                    if !menuURLText.isEmpty {
                        Button { analyzeURL() } label: {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(accent)
                        }
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)

            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.premiumGold)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // Back
            Button {
                isScanning = false
                menuURLText = ""
                errorMessage = nil
            } label: {
                Text("Cancel")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.40))
            }
            .padding(.bottom, 16)
        }
    }

    // MARK: - Analyzing Phase

    private var analyzingPhase: some View {
        VStack(spacing: 24) {
            Spacer()

            if let img = menuImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(accent.opacity(0.30), lineWidth: 1)
                    )
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 10) {
                ProgressView()
                    .tint(accent)
                    .scaleEffect(1.2)
                Text(menuImage != nil ? "Reading your menu..." : "Loading menu from URL...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Finding the best items for your macros")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.40))
            }

            Spacer()
        }
    }

    // MARK: - Scan Detail (swipeable cards)

    private func scanDetailView(_ scan: SavedMenuScan) -> some View {
        VStack(spacing: 16) {
            remainingMacrosBar
                .padding(.top, 8)

            // Swipeable recommendation cards
            TabView(selection: $currentPage) {
                ForEach(Array(scan.recommendations.enumerated()), id: \.element.id) { idx, rec in
                    recommendationCard(rec)
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: .infinity)

            // Page dots
            HStack(spacing: 6) {
                ForEach(0..<scan.recommendations.count, id: \.self) { idx in
                    Circle()
                        .fill(idx == currentPage ? accent : Color.white.opacity(0.20))
                        .frame(width: 8, height: 8)
                        .scaleEffect(idx == currentPage ? 1.2 : 1.0)
                        .animation(.spring(duration: 0.2), value: currentPage)
                }
            }

            HStack(spacing: 12) {
                // Back to list
                Button {
                    viewingScan = nil
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("All Scans")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }

                // New scan
                Button {
                    viewingScan = nil
                    isScanning = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.viewfinder")
                        Text("New Scan")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accent)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Recommendation Card

    private func recommendationCard(_ rec: MenuRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                rankBadge(rec.rank)
                Spacer()
                Text("\(rec.estimatedCalories) cal")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(.bottom, 14)

            Text(rec.itemName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)

            if !rec.description.isEmpty {
                Text(rec.description)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.bottom, 14)
            }

            HStack(spacing: 8) {
                macroPill("P", value: rec.estimatedProtein, color: Color(red: 0.35, green: 0.75, blue: 1.0))
                macroPill("C", value: rec.estimatedCarbs, color: Color(red: 0.40, green: 0.90, blue: 0.72))
                macroPill("F", value: rec.estimatedFat, color: Color(red: 1.0, green: 0.60, blue: 0.40))
            }
            .padding(.bottom, 16)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.green.opacity(0.80))
                    .padding(.top, 1)
                Text(rec.reason)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !rec.modification.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 13))
                        .foregroundStyle(accent.opacity(0.80))
                        .padding(.top, 1)
                    Text(rec.modification)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(accent.opacity(0.70))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 10)
            }

            Spacer(minLength: 0)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(borderColor(for: rec.rank), lineWidth: 1.5)
                )
        )
        .padding(.horizontal, 20)
    }

    private func rankBadge(_ rank: Int) -> some View {
        let (label, color): (String, Color) = switch rank {
        case 1: ("BEST PICK", Color(red: 1.0, green: 0.80, blue: 0.20))
        case 2: ("RUNNER UP", Color(red: 0.75, green: 0.75, blue: 0.80))
        case 3: ("SOLID OPTION", Color(red: 0.80, green: 0.55, blue: 0.35))
        default: ("#\(rank)", .white.opacity(0.50))
        }
        return Text(label)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12), in: Capsule())
    }

    private func borderColor(for rank: Int) -> Color {
        switch rank {
        case 1: Color(red: 1.0, green: 0.80, blue: 0.20).opacity(0.30)
        case 2: Color.white.opacity(0.10)
        case 3: Color.white.opacity(0.07)
        default: Color.white.opacity(0.05)
        }
    }

    private func macroPill(_ label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
            Text("\(value)g")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Remaining Macros Bar

    private var remainingMacrosBar: some View {
        HStack(spacing: 12) {
            miniMacro("Cal", value: remainingCalories, unit: "", color: accent)
            miniMacro("Pro", value: remainingProtein, unit: "g", color: Color(red: 0.35, green: 0.75, blue: 1.0))
            miniMacro("Carb", value: remainingCarbs, unit: "g", color: Color(red: 0.40, green: 0.90, blue: 0.72))
            miniMacro("Fat", value: remainingFat, unit: "g", color: Color(red: 1.0, green: 0.60, blue: 0.40))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }

    private func miniMacro(_ label: String, value: Int, unit: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text("\(max(0, value))\(unit)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.40))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Analyze & Save

    private var macroContext: RestaurantMenuService.MacroContext {
        RestaurantMenuService.MacroContext(
            remainingCalories: remainingCalories,
            remainingProtein:  remainingProtein,
            remainingCarbs:    remainingCarbs,
            remainingFat:      remainingFat,
            goalCalories:      goalCalories,
            goalProtein:       goalProtein,
            goalCarbs:         goalCarbs,
            goalFat:           goalFat
        )
    }

    private func analyzeMenuPhoto() {
        guard let image = menuImage else { return }
        isAnalyzing = true
        isScanning = false
        errorMessage = nil

        Task {
            do {
                let recs = try await RestaurantMenuService.shared.analyzeMenu(image: image, macros: macroContext)
                let scan = SavedMenuScan(source: "Photo", recommendations: recs)
                saveScan(scan)
                viewingScan = scan
                currentPage = 0
            } catch {
                errorMessage = error.localizedDescription
                isScanning = true
                menuImage = nil
            }
            isAnalyzing = false
        }
    }

    private func analyzeURL() {
        let trimmed = menuURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlString = trimmed.hasPrefix("http") ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: urlString), url.host != nil else {
            errorMessage = "Enter a valid URL (e.g. restaurant.com/menu)"
            return
        }
        isAnalyzing = true
        isScanning = false
        errorMessage = nil

        let source = url.host ?? "URL"

        Task {
            do {
                let recs = try await RestaurantMenuService.shared.analyzeMenuURL(url, macros: macroContext)
                let scan = SavedMenuScan(source: source, recommendations: recs)
                saveScan(scan)
                viewingScan = scan
                currentPage = 0
            } catch {
                errorMessage = error.localizedDescription
                isScanning = true
            }
            isAnalyzing = false
        }
    }

    private func saveScan(_ scan: SavedMenuScan) {
        SavedMenuScanStore.save(scan)
        savedScans = SavedMenuScanStore.load()
        menuImage = nil
        menuURLText = ""
    }

    private func deleteScan(_ scan: SavedMenuScan) {
        SavedMenuScanStore.delete(scan.id)
        savedScans = SavedMenuScanStore.load()
        if viewingScan?.id == scan.id { viewingScan = nil }
    }
}
