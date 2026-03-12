//
//  FoodLogViewModel.swift
//  Wellness
//

import UIKit
import SwiftData

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
                loadTodayEntries()
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

    var todayEntries: [FoodEntry] = []

    private let modelContext: ModelContext
    private let service: ClaudeVisionService

    init(modelContext: ModelContext,
         selectedDate: Date = Calendar.current.startOfDay(for: Date()),
         service: ClaudeVisionService = ClaudeVisionService()) {
        self.modelContext = modelContext
        self.selectedDate = selectedDate
        self.service      = service
        // Loaded lazily from the view's onAppear
    }

    func loadTodayEntries() {
        let calendar   = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        let predicate  = #Predicate<FoodEntry> { $0.loggedAt >= startOfDay && $0.loggedAt < endOfDay }
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
        )
        todayEntries = (try? modelContext.fetch(descriptor)) ?? []
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

        let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
        let entry = FoodEntry(
            loggedAt: loggedAt,
            foodName: foodName.isEmpty ? "Unknown Food" : foodName,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            imageData: imageData
        )
        modelContext.insert(entry)
        resetFields()
        loadTodayEntries()
        return true
    }

    func deleteEntry(_ entry: FoodEntry) {
        modelContext.delete(entry)
        loadTodayEntries()
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
        analysisState = .idle
    }
}
