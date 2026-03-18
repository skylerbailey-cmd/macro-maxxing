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

    func analyzeImage() async {
        guard let image = selectedImage else { return }
        analysisState = .analyzing
        do {
            let result = try await service.analyzeFoodImage(image)
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
    }
}
