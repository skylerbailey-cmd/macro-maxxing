//
//  FoodLogViewModel.swift
//  Wellness
//

import UIKit

enum AnalysisState: Equatable {
    case idle
    case analyzing
    case result
    case error(String)
}

/// Which tier produced the current result.
enum AnalysisTier: Equatable {
    case none
    case local   // Tier 1 — on-device + USDA
    case claude  // Tier 2 — Claude API
}

@Observable final class FoodLogViewModel {
    // MARK: - Selected date (drives all fetches and new entry timestamps)
    var selectedDate: Date {
        didSet {
            if !Calendar.current.isDate(selectedDate, inSameDayAs: oldValue) {
                Task { await loadTodayEntries() }
            }
        }
    }

    var selectedImage: UIImage?
    var showingCamera = false
    var showingPhotoLibrary = false
    var analysisState: AnalysisState = .idle

    /// Which recognition tier produced the current result.
    var analysisTier: AnalysisTier = .none

    var foodName = ""
    var caloriesText = ""
    var proteinText = ""
    var carbsText = ""
    var fatText = ""
    var voiceNote = ""
    /// Whether to mark the next saved entry as a saved meal.
    var saveMeal: Bool = false
    /// True when the current entry fields were pre-filled from a saved meal.
    var isFromSavedMeal: Bool = false

    var todayEntries: [FoodEntry] = []
    var savedMeals:   [FoodEntry] = []

    private let service: ClaudeVisionService
    private(set) var userID: String

    // MARK: - Tier tracking (UserDefaults)

    static var tier1Count: Int {
        get { UserDefaults.standard.integer(forKey: "analysisTier1Count") }
        set { UserDefaults.standard.set(newValue, forKey: "analysisTier1Count") }
    }
    static var tier2Count: Int {
        get { UserDefaults.standard.integer(forKey: "analysisTier2Count") }
        set { UserDefaults.standard.set(newValue, forKey: "analysisTier2Count") }
    }

    init(selectedDate: Date = Calendar.current.startOfDay(for: Date()),
         userID: String = "",
         service: ClaudeVisionService = ClaudeVisionService()) {
        self.selectedDate = selectedDate
        self.userID       = userID
        self.service      = service
    }

    func loadTodayEntries() async {
        todayEntries = (try? await FoodEntryService.shared.fetch(userID: userID, date: selectedDate)) ?? []
    }

    func loadSavedMeals() async {
        savedMeals = (try? await FoodEntryService.shared.fetchSavedMeals(userID: userID)) ?? []
    }

    /// Pre-fills entry fields from a saved meal and switches to the result state.
    func populateFromSavedMeal(_ entry: FoodEntry) {
        foodName         = entry.foodName
        caloriesText     = String(format: "%.0f", entry.calories)
        proteinText      = String(format: "%.1f", entry.protein)
        carbsText        = String(format: "%.1f", entry.carbs)
        fatText          = String(format: "%.1f", entry.fat)
        isFromSavedMeal  = true
        analysisState    = .result
    }

    /// Two-tier food recognition:
    /// Tier 1: On-device classifier + USDA lookup (free, offline-capable, < 1s)
    /// Tier 2: Claude Vision API (paid, handles complex/mixed meals)
    func analyzeImage() async {
        guard let image = selectedImage else { return }
        analysisState = .analyzing
        analysisTier  = .none

        // ── Tier 1: On-device classification ──────────────────────────────
        let local = await LocalFoodClassifier.shared.classify(image)
        print("[Tier1] \"\(local.foodName)\" confidence=\(String(format: "%.2f", local.confidence)) needsClaude=\(local.needsClaudeAnalysis)")

        if local.confidence >= 0.80 && !local.needsClaudeAnalysis {
            // Simple, high-confidence food → look up macros from USDA
            if let usda = await USDAFoodService.shared.lookup(foodName: local.foodName) {
                foodName     = usda.food
                caloriesText = String(format: "%.0f", usda.calories)
                proteinText  = String(format: "%.1f", usda.protein)
                carbsText    = String(format: "%.1f", usda.carbs)
                fatText      = String(format: "%.1f", usda.fat)
                analysisTier  = .local
                analysisState = .result
                Self.tier1Count += 1
                print("[Tier1] ✓ Resolved locally: \(usda.food) — \(Int(usda.calories)) kcal")
                return
            }
            print("[Tier1] USDA lookup failed for \"\(local.foodName)\", falling back to Claude")
        }

        // ── Tier 2: Claude Vision API ─────────────────────────────────────
        await analyzeWithClaude(image: image, localHint: local.foodName)
    }

    /// Forces a Claude API analysis, bypassing Tier 1.
    /// Called when the user taps "Not right? Try AI scan".
    func reanalyzeWithClaude() async {
        guard let image = selectedImage else { return }
        analysisState = .analyzing
        analysisTier  = .none
        await analyzeWithClaude(image: image, localHint: nil)
    }

    /// Runs Claude Vision analysis, optionally passing a local classifier hint.
    private func analyzeWithClaude(image: UIImage, localHint: String?) async {
        do {
            let result: MacroResult
            if let hint = localHint, !hint.isEmpty {
                // Pass the local model's best guess as context to improve accuracy
                result = try await service.analyzeFoodImageWithVoice(image, voiceNote: "The food appears to be: \(hint)")
            } else {
                result = try await service.analyzeFoodImage(image)
            }
            foodName     = result.food
            caloriesText = String(format: "%.0f", result.calories)
            proteinText  = String(format: "%.1f", result.protein)
            carbsText    = String(format: "%.1f", result.carbs)
            fatText      = String(format: "%.1f", result.fat)
            analysisTier  = .claude
            analysisState = .result
            Self.tier2Count += 1
            print("[Tier2] ✓ Claude result: \(result.food) — \(Int(result.calories)) kcal")
        } catch {
            analysisState = .error(error.localizedDescription)
        }
    }

    func analyzeImageWithVoice() async {
        guard let image = selectedImage else { return }
        analysisState = .analyzing
        do {
            let result = try await service.analyzeFoodImageWithVoice(image, voiceNote: voiceNote)
            foodName     = result.food
            caloriesText = String(format: "%.0f", result.calories)
            proteinText  = String(format: "%.1f", result.protein)
            carbsText    = String(format: "%.1f", result.carbs)
            fatText      = String(format: "%.1f", result.fat)
            analysisState = .result
        } catch {
            analysisState = .error(error.localizedDescription)
        }
    }

    @discardableResult
    func saveEntry() -> Bool {
        guard
            let calories = Double(caloriesText),
            let protein  = Double(proteinText),
            let carbs    = Double(carbsText),
            let fat      = Double(fatText)
        else { return false }

        // Use current time-of-day on the selected date
        let calendar  = Calendar.current
        var comps     = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let now       = Date()
        comps.hour    = calendar.component(.hour,   from: now)
        comps.minute  = calendar.component(.minute, from: now)
        comps.second  = calendar.component(.second, from: now)
        let loggedAt  = calendar.date(from: comps) ?? selectedDate

        let image     = selectedImage
        let imageData = image?.jpegData(compressionQuality: 0.8)
        let entry = FoodEntry(
            loggedAt: loggedAt,
            userID:   userID,
            foodName: foodName.isEmpty ? "Unknown Food" : foodName,
            calories: calories,
            protein:  protein,
            carbs:    carbs,
            fat:      fat,
            imageData: imageData
        )
        entry.isSavedMeal = saveMeal

        // Optimistic local insert so UI updates instantly
        todayEntries.insert(entry, at: 0)
        resetFields()

        // Persist to Firestore
        Task {
            if let result = try? await FoodEntryService.shared.save(entry: entry, image: image) {
                entry.firebaseEntryID = result.docID
                entry.photoURL        = result.photoURL
            }
        }

        return true
    }

    func deleteEntry(_ entry: FoodEntry) {
        todayEntries.removeAll { $0.id == entry.id }
        let entryID = entry.firebaseEntryID
        let uid     = entry.userID
        Task { await FoodEntryService.shared.delete(entryID: entryID, userID: uid) }
    }

    func updateEntry(_ entry: FoodEntry,
                     foodName: String,
                     calories: Double,
                     protein: Double,
                     carbs: Double,
                     fat: Double,
                     loggedAt: Date? = nil) {
        entry.foodName = foodName.isEmpty ? "Unknown Food" : foodName
        entry.calories = calories
        entry.protein  = protein
        entry.carbs    = carbs
        entry.fat      = fat
        if let loggedAt { entry.loggedAt = loggedAt }

        let entryID = entry.firebaseEntryID
        let uid     = entry.userID
        Task {
            await FoodEntryService.shared.update(
                entryID:  entryID,
                userID:   uid,
                foodName: entry.foodName,
                calories: entry.calories,
                protein:  entry.protein,
                carbs:    entry.carbs,
                fat:      entry.fat,
                loggedAt: loggedAt
            )
        }
    }

    func discardEntry() {
        resetFields()
    }

    func resetFields() {
        selectedImage = nil
        foodName      = ""
        caloriesText  = ""
        proteinText   = ""
        carbsText     = ""
        fatText       = ""
        voiceNote     = ""
        saveMeal        = false
        isFromSavedMeal = false
        analysisState   = .idle
        analysisTier    = .none
    }
}
