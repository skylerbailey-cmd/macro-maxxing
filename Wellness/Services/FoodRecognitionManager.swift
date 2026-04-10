//
//  FoodRecognitionManager.swift
//  Wellness
//
//  Single entry point for the two-tier food recognition pipeline.
//  Tier 1: Haiku vision (ID + macros), with Sonnet text-only fallback for low confidence.
//  Tier 2: Sonnet full vision analysis (fallback / escalation / voice notes).
//

import UIKit
import Network

final class FoodRecognitionManager {
    static let shared = FoodRecognitionManager()

    private let haiku = ClaudeHaikuService.shared
    private let sonnet = ClaudeSonnetService.shared
    private let cache = FoodRecognitionCache.shared

    private let monitor = NWPathMonitor()
    private var isOnline = true

    /// Confidence threshold below which Haiku's macro estimates are cross-checked
    /// by sending the identified items to Sonnet as a cheap text-only call.
    private let sonnetEscalationThreshold: Double = 0.80

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isOnline = path.status == .satisfied
        }
        monitor.start(queue: DispatchQueue(label: "FoodRecognitionManager.network"))
    }

    // MARK: - Main Entry Point

    /// Recognizes food from an image using the two-tier system.
    /// Always returns a result — never throws to the caller.
    func recognizeFood(image: UIImage, voiceNote: String? = nil, userID: String = "") async -> FoodRecognitionResult {
        // Voice notes skip straight to Sonnet, which can understand natural language
        // like "1 tablespoon of olive oil" regardless of what the photo shows.
        if let voice = voiceNote, !voice.isEmpty {
            AppLogger.log("[FoodRecognition] Voice note present — going to Sonnet: \"\(voice)\"")
            if let result = await attemptSonnetVision(image: image, previousGuess: nil, voiceNote: voice, userID: userID) {
                return result
            }
            return fallbackResult()
        }

        // Tier 1: Haiku vision — identifies food + estimates macros in one call.
        // If Haiku is confident, we use its macros directly (~$0.002/scan).
        // If not, Sonnet recalculates macros from text only (~$0.005/scan).
        if let result = await attemptHaiku(image: image, userID: userID) {
            return result
        }

        // Tier 2: Full Sonnet vision — fallback when Haiku fails entirely.
        if isOnline {
            if let result = await attemptSonnetVision(image: image, previousGuess: nil, voiceNote: nil, userID: userID) {
                return result
            }
        }

        return fallbackResult()
    }

    // MARK: - Tier 1: Haiku Vision (ID + Macros)

    private func attemptHaiku(image: UIImage, userID: String) async -> FoodRecognitionResult? {
        do {
            let haikuResult = try await haiku.identifyFood(image: image)

            // Check cache
            if let cached = cache.scaledMacros(for: haikuResult.foodName, portionGrams: haikuResult.portionGrams) {
                ScanAnalyticsService.shared.recordScan(userID: userID, tier: 1, cacheHit: true)
                return FoodRecognitionResult(
                    foodName: haikuResult.foodName,
                    calories: Int(cached.calories),
                    protein: cached.protein,
                    carbs: cached.carbs,
                    fat: cached.fat,
                    portionGrams: haikuResult.portionGrams,
                    tier: 1,
                    source: "Cache",
                    confidence: haikuResult.confidence,
                    needsUserConfirmation: haikuResult.confidence < 0.75 || haikuResult.isMixedMeal
                )
            }

            let isMixed = (haikuResult.components?.count ?? 0) > 1

            // If Haiku is confident, use its macros directly (cheapest path)
            if haikuResult.confidence >= sonnetEscalationThreshold {
                if haikuResult.portionGrams > 0 {
                    let factor = 100.0 / haikuResult.portionGrams
                    cache.store(
                        foodName: haikuResult.foodName,
                        macrosPer100g: MacrosPer100g(
                            calories: Double(haikuResult.calories) * factor,
                            protein: haikuResult.protein * factor,
                            carbs: haikuResult.carbs * factor,
                            fat: haikuResult.fat * factor
                        )
                    )
                }

                AppLogger.log("[Tier1] ✅ Haiku (confident \(Int(haikuResult.confidence * 100))%) for \"\(haikuResult.foodName)\" — \(haikuResult.calories) kcal / \(Int(haikuResult.portionGrams))g")
                ScanAnalyticsService.shared.recordScan(userID: userID, tier: 1, cacheHit: false)

                return FoodRecognitionResult(
                    foodName: haikuResult.foodName,
                    calories: haikuResult.calories,
                    protein: haikuResult.protein,
                    carbs: haikuResult.carbs,
                    fat: haikuResult.fat,
                    portionGrams: haikuResult.portionGrams,
                    tier: 1,
                    source: "Claude Haiku",
                    confidence: haikuResult.confidence,
                    needsUserConfirmation: haikuResult.confidence < 0.75 || isMixed,
                    components: haikuResult.components
                )
            }

            // Low confidence — ask Sonnet to recalculate macros (text only, no image)
            let components = haikuResult.components ?? [
                MealComponent(name: haikuResult.foodName, portionGrams: haikuResult.portionGrams,
                              calories: haikuResult.calories, protein: haikuResult.protein,
                              carbs: haikuResult.carbs, fat: haikuResult.fat)
            ]
            let items = components.map { HaikuFoodItem(name: $0.name, portionGrams: $0.portionGrams) }

            let sonnetResult = try await sonnet.estimateMacros(
                items: items,
                fullMealName: haikuResult.foodName
            )

            if sonnetResult.portionGrams > 0 {
                let factor = 100.0 / sonnetResult.portionGrams
                cache.store(
                    foodName: haikuResult.foodName,
                    macrosPer100g: MacrosPer100g(
                        calories: Double(sonnetResult.calories) * factor,
                        protein: sonnetResult.protein * factor,
                        carbs: sonnetResult.carbs * factor,
                        fat: sonnetResult.fat * factor
                    )
                )
            }

            AppLogger.log("[Tier1] ✅ Haiku→Sonnet(text) for \"\(haikuResult.foodName)\" — \(sonnetResult.calories) kcal (Haiku confidence was \(Int(haikuResult.confidence * 100))%)")
            ScanAnalyticsService.shared.recordScan(userID: userID, tier: 1, cacheHit: false)

            let sonnetIsMixed = (sonnetResult.components?.count ?? 0) > 1

            return FoodRecognitionResult(
                foodName: sonnetResult.foodName,
                calories: sonnetResult.calories,
                protein: sonnetResult.protein,
                carbs: sonnetResult.carbs,
                fat: sonnetResult.fat,
                portionGrams: sonnetResult.portionGrams,
                tier: 1,
                source: "Haiku Vision + Sonnet Macros",
                confidence: haikuResult.confidence,
                needsUserConfirmation: haikuResult.confidence < 0.75 || sonnetIsMixed,
                components: sonnetResult.components
            )
        } catch {
            return nil
        }
    }

    // MARK: - Tier 2: Claude Sonnet Full Vision Analysis

    private func attemptSonnetVision(image: UIImage, previousGuess: String?, voiceNote: String?, userID: String) async -> FoodRecognitionResult? {
        do {
            let sonnetResult = try await sonnet.analyzeFood(
                image: image,
                previousGuess: previousGuess,
                voiceNote: voiceNote
            )

            if sonnetResult.portionGrams > 0 {
                let factor = 100.0 / sonnetResult.portionGrams
                cache.store(
                    foodName: sonnetResult.foodName,
                    macrosPer100g: MacrosPer100g(
                        calories: Double(sonnetResult.calories) * factor,
                        protein: sonnetResult.protein * factor,
                        carbs: sonnetResult.carbs * factor,
                        fat: sonnetResult.fat * factor
                    )
                )
            }

            ScanAnalyticsService.shared.recordScan(userID: userID, tier: 2, cacheHit: false)

            let isMixed = (sonnetResult.components?.count ?? 0) > 1

            return FoodRecognitionResult(
                foodName: sonnetResult.foodName,
                calories: sonnetResult.calories,
                protein: sonnetResult.protein,
                carbs: sonnetResult.carbs,
                fat: sonnetResult.fat,
                portionGrams: sonnetResult.portionGrams,
                tier: 2,
                source: "Claude Sonnet",
                confidence: sonnetResult.confidenceScore,
                needsUserConfirmation: sonnetResult.confidenceScore < 0.75 || isMixed,
                components: sonnetResult.components
            )
        } catch {
            return nil
        }
    }

    // MARK: - Fallback

    private func fallbackResult() -> FoodRecognitionResult {
        FoodRecognitionResult(
            foodName: "Unknown Food",
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            portionGrams: 0,
            tier: 0,
            source: "Manual entry needed",
            confidence: 0,
            needsUserConfirmation: true
        )
    }

    // MARK: - Escalation

    /// Manually escalates to Sonnet full vision. Used by the "Try better scan" button.
    func escalate(image: UIImage, fromTier: Int, voiceNote: String? = nil, userID: String = "") async -> FoodRecognitionResult {
        if let result = await attemptSonnetVision(image: image, previousGuess: nil, voiceNote: voiceNote, userID: userID) {
            return result
        }
        return fallbackResult()
    }

    // MARK: - Text-Only Recognition

    /// Estimates macros from a food name string (no image required).
    /// Used by the edit entry "Reanalyze with AI" button.
    func recognizeFoodByName(_ name: String) async -> FoodRecognitionResult {
        // Send as a text-only Sonnet call via estimateMacros
        let items = [HaikuFoodItem(name: name, portionGrams: 150)]
        if let result = try? await sonnet.estimateMacros(items: items, fullMealName: name) {
            if result.portionGrams > 0 {
                let factor = 100.0 / result.portionGrams
                cache.store(
                    foodName: result.foodName,
                    macrosPer100g: MacrosPer100g(
                        calories: Double(result.calories) * factor,
                        protein: result.protein * factor,
                        carbs: result.carbs * factor,
                        fat: result.fat * factor
                    )
                )
            }
            return FoodRecognitionResult(
                foodName: result.foodName,
                calories: result.calories,
                protein: result.protein,
                carbs: result.carbs,
                fat: result.fat,
                portionGrams: result.portionGrams,
                tier: 1,
                source: "Claude Sonnet",
                confidence: result.confidenceScore,
                needsUserConfirmation: result.confidenceScore < 0.75,
                components: result.components
            )
        }

        return fallbackResult()
    }
}
