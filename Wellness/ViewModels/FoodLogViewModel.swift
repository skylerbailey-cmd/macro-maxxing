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
    var selectedImage: UIImage?
    var showingCamera = false
    var showingPhotoLibrary = false
    var analysisState: AnalysisState = .idle

    var foodName = ""
    var caloriesText = ""
    var proteinText = ""
    var carbsText = ""
    var fatText = ""

    private let modelContext: ModelContext
    private let service: ClaudeVisionService

    init(modelContext: ModelContext, service: ClaudeVisionService = ClaudeVisionService()) {
        self.modelContext = modelContext
        self.service = service
    }

    func analyzeImage() async {
        guard let image = selectedImage else { return }
        analysisState = .analyzing
        do {
            let result = try await service.analyzeFoodImage(image)
            foodName = result.food
            caloriesText = String(format: "%.0f", result.calories)
            proteinText = String(format: "%.1f", result.protein)
            carbsText = String(format: "%.1f", result.carbs)
            fatText = String(format: "%.1f", result.fat)
            analysisState = .result
        } catch {
            analysisState = .error(error.localizedDescription)
        }
    }

    @discardableResult
    func saveEntry() -> Bool {
        guard
            let calories = Double(caloriesText),
            let protein = Double(proteinText),
            let carbs = Double(carbsText),
            let fat = Double(fatText)
        else { return false }

        let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
        let entry = FoodEntry(
            foodName: foodName.isEmpty ? "Unknown Food" : foodName,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            imageData: imageData
        )
        modelContext.insert(entry)
        resetFields()
        return true
    }

    func discardEntry() {
        resetFields()
    }

    func resetFields() {
        selectedImage = nil
        foodName = ""
        caloriesText = ""
        proteinText = ""
        carbsText = ""
        fatText = ""
        analysisState = .idle
    }
}
