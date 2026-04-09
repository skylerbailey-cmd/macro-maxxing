//
//  FoodLogViewModel.swift
//  Wellness
//

import UIKit

enum AnalysisState: Equatable {
    case idle
    case analyzing
    case result
    case confirmed(FoodRecognitionResult)
    case error(String)

    static func == (lhs: AnalysisState, rhs: AnalysisState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.analyzing, .analyzing), (.result, .result):
            return true
        case (.error(let a), .error(let b)):
            return a == b
        case (.confirmed, .confirmed):
            return true
        default:
            return false
        }
    }
}

/// Which tier produced the current result.
enum AnalysisTier: Equatable {
    case none
    case local   // Tier 1 — on-device + USDA
    case claude  // Tier 2/3 — Claude API (Haiku or Sonnet)
}

@MainActor @Observable final class FoodLogViewModel {
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

    /// The latest recognition result from the three-tier system.
    var recognitionResult: FoodRecognitionResult?

    var todayEntries: [FoodEntry] = []
    var savedMeals:   [FoodEntry] = []

    /// Entries added locally that haven't been confirmed in Firestore yet.
    /// Merged into todayEntries on each Firestore fetch to prevent disappearing.
    private var pendingLocalEntries: [FoodEntry] = []

    private let recognitionManager = FoodRecognitionManager.shared
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
         userID: String = "") {
        self.selectedDate = selectedDate
        self.userID       = userID
    }

    func loadTodayEntries() async {
        let firestoreEntries = (try? await FoodEntryService.shared.fetch(userID: userID, date: selectedDate)) ?? []

        // Remove pending entries that now appear in Firestore (synced successfully)
        let firestoreIDs = Set(firestoreEntries.map { $0.id })
        pendingLocalEntries.removeAll { firestoreIDs.contains($0.id) }

        // Merge: Firestore entries + any still-pending local entries
        if pendingLocalEntries.isEmpty {
            todayEntries = firestoreEntries
        } else {
            // Combine, deduplicate by ID, sort newest first
            var merged = firestoreEntries
            for local in pendingLocalEntries where !firestoreIDs.contains(local.id) {
                merged.insert(local, at: 0)
            }
            todayEntries = merged.sorted { $0.loggedAt > $1.loggedAt }
        }
    }

    func loadSavedMeals() async {
        savedMeals = (try? await FoodEntryService.shared.fetchSavedMeals(userID: userID)) ?? []
    }

    /// Returns saved meals sorted by relevance to the current recognition result.
    /// Meals whose name matches or overlaps with the recognized food appear first.
    var sortedSavedMeals: [FoodEntry] {
        guard let hint = recognitionResult?.foodName.lowercased(),
              !hint.isEmpty else {
            return savedMeals
        }

        let hintWords = Set(hint.split(separator: " ").map(String.init))

        return savedMeals.sorted { a, b in
            let aName = a.foodName.lowercased()
            let bName = b.foodName.lowercased()

            let aScore = Self.relevanceScore(name: aName, hint: hint, hintWords: hintWords)
            let bScore = Self.relevanceScore(name: bName, hint: hint, hintWords: hintWords)

            if aScore != bScore { return aScore > bScore }
            return a.loggedAt > b.loggedAt // tie-break: most recent first
        }
    }

    private static func relevanceScore(name: String, hint: String, hintWords: Set<String>) -> Int {
        // Exact match
        if name == hint { return 100 }
        // One contains the other
        if name.contains(hint) || hint.contains(name) { return 80 }
        // Word overlap
        let nameWords = Set(name.split(separator: " ").map(String.init))
        let overlap = nameWords.intersection(hintWords).count
        if overlap > 0 { return overlap * 20 }
        return 0
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

    // MARK: - Three-Tier Food Recognition

    /// Analyzes a food image through the three-tier recognition pipeline.
    func analyzeImage() async {
        guard let image = selectedImage else { return }
        analysisState = .analyzing
        analysisTier  = .none

        let result = await recognitionManager.recognizeFood(
            image: image,
            voiceNote: voiceNote.isEmpty ? nil : voiceNote,
            userID: userID
        )
        guard !Task.isCancelled else { return }

        recognitionResult = result
        populateFromRecognitionResult(result)
        analysisTier = .claude

        // Update tier counters
        if result.tier == 1 {
            Self.tier1Count += 1
            print("[Tier1] ✓ Haiku result: \(result.foodName) — \(result.calories) kcal")
        } else if result.tier == 2 {
            Self.tier2Count += 1
            print("[Tier2] ✓ Sonnet result: \(result.foodName) — \(result.calories) kcal")
        }

        if result.tier == 0 && result.calories == 0 {
            // All tiers failed — show error with manual entry option
            analysisState = .error(FoodRecognitionError.allTiersFailed.localizedDescription)
        } else {
            analysisState = .confirmed(result)
        }
    }

    /// Analyzes with voice note context.
    func analyzeImageWithVoice() async {
        guard let image = selectedImage else { return }
        analysisState = .analyzing
        analysisTier  = .none

        let result = await recognitionManager.recognizeFood(
            image: image,
            voiceNote: voiceNote,
            userID: userID
        )
        guard !Task.isCancelled else { return }

        recognitionResult = result
        populateFromRecognitionResult(result)
        analysisTier = .claude

        if result.tier == 1 { Self.tier1Count += 1 }
        else if result.tier == 2 { Self.tier2Count += 1 }

        if result.tier == 0 && result.calories == 0 {
            analysisState = .error(FoodRecognitionError.allTiersFailed.localizedDescription)
        } else {
            analysisState = .confirmed(result)
        }
    }

    /// Forces a Sonnet full vision analysis, bypassing Tier 1 (Haiku).
    /// Called when the user taps "Not right? Try AI scan".
    func reanalyzeWithClaude() async {
        guard let image = selectedImage else { return }
        analysisState = .analyzing
        analysisTier  = .none

        let result = await recognitionManager.escalate(
            image: image,
            fromTier: 1,
            voiceNote: voiceNote.isEmpty ? nil : voiceNote,
            userID: userID
        )
        guard !Task.isCancelled else { return }

        recognitionResult = result
        populateFromRecognitionResult(result)
        analysisTier = .claude
        Self.tier2Count += 1

        if result.tier == 0 && result.calories == 0 {
            analysisState = .error(FoodRecognitionError.allTiersFailed.localizedDescription)
        } else {
            analysisState = .confirmed(result)
        }
    }

    /// Escalates to Sonnet full vision when user taps "Try better scan".
    func escalateAnalysis() async {
        guard let image = selectedImage,
              let current = recognitionResult,
              current.tier < 2 else { return }

        analysisState = .analyzing

        let result = await recognitionManager.escalate(
            image: image,
            fromTier: current.tier,
            voiceNote: voiceNote.isEmpty ? nil : voiceNote,
            userID: userID
        )
        guard !Task.isCancelled else { return }

        recognitionResult = result
        populateFromRecognitionResult(result)
        analysisTier = .claude

        Self.tier2Count += 1

        if result.tier == 0 && result.calories == 0 {
            analysisState = .error(FoodRecognitionError.allTiersFailed.localizedDescription)
        } else {
            analysisState = .confirmed(result)
        }
    }

    /// Populates the text fields from a recognition result.
    private func populateFromRecognitionResult(_ result: FoodRecognitionResult) {
        foodName     = result.foodName
        caloriesText = String(format: "%.0f", Double(result.calories))
        proteinText  = String(format: "%.1f", result.protein)
        carbsText    = String(format: "%.1f", result.carbs)
        fatText      = String(format: "%.1f", result.fat)
    }

    /// Updates fields from a confirmed (possibly adjusted) result.
    func confirmResult(_ result: FoodRecognitionResult) {
        recognitionResult = result
        foodName     = result.foodName
        caloriesText = String(format: "%.0f", Double(result.calories))
        proteinText  = String(format: "%.1f", result.protein)
        carbsText    = String(format: "%.1f", result.carbs)
        fatText      = String(format: "%.1f", result.fat)
        analysisState = .result
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
        pendingLocalEntries.append(entry)
        resetFields()

        // Notify the Hub tab so macro KPIs refresh immediately
        NotificationCenter.default.post(name: FuelLogService.mealChangedNotification, object: nil)

        // Persist to Firestore
        Task {
            if let result = try? await FoodEntryService.shared.save(entry: entry, image: image) {
                entry.firebaseEntryID = result.docID
                entry.photoURL        = result.photoURL
            }
            // After Firestore write completes, remove from pending
            pendingLocalEntries.removeAll { $0.id == entry.id }
        }

        return true
    }

    /// Logs a new entry from a saved meal template, using the current selected date/time.
    func logFromSavedMeal(_ meal: FoodEntry) {
        let calendar  = Calendar.current
        var comps     = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let now       = Date()
        comps.hour    = calendar.component(.hour,   from: now)
        comps.minute  = calendar.component(.minute, from: now)
        comps.second  = calendar.component(.second, from: now)
        let loggedAt  = calendar.date(from: comps) ?? selectedDate

        let entry = FoodEntry(
            loggedAt: loggedAt,
            userID:   userID,
            foodName: meal.foodName,
            calories: meal.calories,
            protein:  meal.protein,
            carbs:    meal.carbs,
            fat:      meal.fat
        )

        todayEntries.insert(entry, at: 0)

        NotificationCenter.default.post(name: FuelLogService.mealChangedNotification, object: nil)

        Task {
            if let result = try? await FoodEntryService.shared.save(entry: entry, image: nil) {
                entry.firebaseEntryID = result.docID
                entry.photoURL        = result.photoURL
            }
        }
    }

    func deleteEntry(_ entry: FoodEntry) {
        todayEntries.removeAll { $0.id == entry.id }
        pendingLocalEntries.removeAll { $0.id == entry.id }

        NotificationCenter.default.post(name: FuelLogService.mealChangedNotification, object: nil)

        let entryID = entry.firebaseEntryID
        let uid     = entry.userID
        Task { await FoodEntryService.shared.delete(entryID: entryID, userID: uid) }
    }

    func deleteSavedMeal(_ meal: FoodEntry) {
        savedMeals.removeAll { $0.id == meal.id }
        let entryID = meal.firebaseEntryID
        let uid     = meal.userID
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

        NotificationCenter.default.post(name: FuelLogService.mealChangedNotification, object: nil)

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
        selectedImage     = nil
        foodName          = ""
        caloriesText      = ""
        proteinText       = ""
        carbsText         = ""
        fatText           = ""
        voiceNote         = ""
        saveMeal          = false
        isFromSavedMeal   = false
        recognitionResult = nil
        analysisState     = .idle
        analysisTier      = .none
    }
}
