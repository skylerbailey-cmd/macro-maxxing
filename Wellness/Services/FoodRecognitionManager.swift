//
//  FoodRecognitionManager.swift
//  Wellness
//
//  Single entry point for the three-tier food recognition pipeline.
//

import UIKit
import Network

final class FoodRecognitionManager {
    static let shared = FoodRecognitionManager()

    private let classifier = CoreMLClassifierService.shared
    private let localClassifier = LocalFoodClassifier.shared
    private let usda = USDAService.shared
    private let haiku = ClaudeHaikuService.shared
    private let sonnet = ClaudeSonnetService.shared
    private let cache = FoodRecognitionCache.shared

    private let monitor = NWPathMonitor()
    private var isOnline = true

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isOnline = path.status == .satisfied
        }
        monitor.start(queue: DispatchQueue(label: "FoodRecognitionManager.network"))
    }

    // MARK: - Main Entry Point

    /// Recognizes food from an image using the three-tier system.
    /// Always returns a result — never throws to the caller.
    func recognizeFood(image: UIImage, voiceNote: String? = nil, userID: String = "") async -> FoodRecognitionResult {
        // When the user provides a voice description, it takes priority over the image.
        // Skip all on-device tiers and go straight to Sonnet, which can understand
        // natural language like "1 tablespoon of olive oil" regardless of what the photo shows.
        if let voice = voiceNote, !voice.isEmpty {
            print("[FoodRecognition] Voice note present — skipping Tier 1/2, going to Sonnet: \"\(voice)\"")
            if let result = await attemptTier3(image: image, previousGuess: nil, voiceNote: voice, userID: userID) {
                return result
            }
            return fallbackResult()
        }

        // Step 0: Try LocalFoodClassifier (Vision-based, no bundled model needed).
        // For whitelisted single-ingredient foods (fruits, veggies, eggs, etc.)
        // this resolves via USDA lookup — no AI cost, <500ms.
        let localResult = await localClassifier.classify(image)
        if !localResult.needsClaudeAnalysis && localResult.confidence >= 0.85 {
            if let result = await attemptTier1Local(localResult: localResult, userID: userID) {
                return result
            }
        }

        // Step 1: Run Core ML classifier
        let classification = await classifier.classify(image: image)
        let coreMLConfidence = classification?.confidence ?? 0
        let coreMLName = classification?.foodName

        // Use local classifier name as hint if Core ML has nothing
        let bestHint = coreMLName ?? (localResult.confidence > 0.5 ? localResult.foodName : nil)

        // Check cache first
        if let name = bestHint, (coreMLConfidence >= 0.60 || localResult.confidence >= 0.60) {
            let portion = estimatePortionGrams(for: name)
            if let cached = cache.scaledMacros(for: name, portionGrams: portion) {
                ScanAnalyticsService.shared.recordScan(userID: userID, tier: 1, cacheHit: true)
                let conf = max(coreMLConfidence, localResult.confidence)
                return FoodRecognitionResult(
                    foodName: name,
                    calories: Int(cached.calories),
                    protein: cached.protein,
                    carbs: cached.carbs,
                    fat: cached.fat,
                    portionGrams: portion,
                    tier: 1,
                    source: "Cache",
                    confidence: conf,
                    needsUserConfirmation: conf < 0.75
                )
            }
        }

        // Route based on Core ML confidence
        if coreMLConfidence >= 0.90, let cl = classification, cl.isSingleIngredient {
            if let result = await attemptTier1(classification: cl, image: image, voiceNote: voiceNote, userID: userID) {
                return result
            }
        }

        // Always attempt Tier 2 (Haiku) before Tier 3 — Haiku can read
        // branded/packaged labels that CoreML doesn't recognize, and is
        // much cheaper than Sonnet. Pass the CoreML hint when available.
        if let result = await attemptTier2(image: image, coreMLHint: bestHint, voiceNote: voiceNote, userID: userID) {
            return result
        }

        // Tier 2 failed or returned nil — go to Tier 3
        if isOnline {
            if let result = await attemptTier3(image: image, previousGuess: bestHint, voiceNote: voiceNote, userID: userID) {
                return result
            }
        }

        // If no internet, try offline with whatever we have
        if !isOnline, let cl = classification {
            return offlineResult(classification: cl)
        }

        // All tiers failed
        return fallbackResult()
    }

    // MARK: - Tier 1 (Local): Vision whitelist + USDA

    /// Fast path for obvious single-ingredient foods identified by Vision's
    /// built-in classifier. No bundled Core ML model required.
    private func attemptTier1Local(localResult: FoodClassification, userID: String) async -> FoodRecognitionResult? {
        let portion = estimatePortionGrams(for: localResult.foodName)
        // Check cache first
        if let cached = cache.scaledMacros(for: localResult.foodName, portionGrams: portion) {
            ScanAnalyticsService.shared.recordScan(userID: userID, tier: 1, cacheHit: true)
            return FoodRecognitionResult(
                foodName: localResult.foodName,
                calories: Int(cached.calories),
                protein: cached.protein,
                carbs: cached.carbs,
                fat: cached.fat,
                portionGrams: portion,
                tier: 1,
                source: "USDA (cached)",
                confidence: localResult.confidence,
                needsUserConfirmation: false
            )
        }

        do {
            guard let baseMacros = try await usda.fetchBaseMacros(query: localResult.foodName) else {
                return nil
            }

            cache.store(foodName: localResult.foodName, macrosPer100g: baseMacros)

            let portionGrams = estimatePortionGrams(for: localResult.foodName)
            let scaled = baseMacros.scaled(to: portionGrams)

            ScanAnalyticsService.shared.recordScan(userID: userID, tier: 1, cacheHit: false)

            return FoodRecognitionResult(
                foodName: localResult.foodName,
                calories: Int(scaled.calories),
                protein: scaled.protein,
                carbs: scaled.carbs,
                fat: scaled.fat,
                portionGrams: portionGrams,
                tier: 1,
                source: "USDA FoodData Central",
                confidence: localResult.confidence,
                needsUserConfirmation: false
            )
        } catch {
            return nil
        }
    }

    // MARK: - Tier 1: On-Device Core ML + USDA

    private func attemptTier1(classification: ClassificationResult, image: UIImage, voiceNote: String?, userID: String) async -> FoodRecognitionResult? {
        let portion = estimatePortionGrams(for: classification.foodName)
        do {
            // Check cache first
            if let cached = cache.scaledMacros(for: classification.foodName, portionGrams: portion) {
                ScanAnalyticsService.shared.recordScan(userID: userID, tier: 1, cacheHit: true)
                return FoodRecognitionResult(
                    foodName: classification.foodName,
                    calories: Int(cached.calories),
                    protein: cached.protein,
                    carbs: cached.carbs,
                    fat: cached.fat,
                    portionGrams: portion,
                    tier: 1,
                    source: "USDA (cached)",
                    confidence: classification.confidence,
                    needsUserConfirmation: false
                )
            }

            // Query USDA for base macros
            guard let baseMacros = try await usda.fetchBaseMacros(query: classification.foodName) else {
                return nil
            }

            // Cache the base macros
            cache.store(foodName: classification.foodName, macrosPer100g: baseMacros)

            // Scale to estimated portion based on food type
            let portionGrams = estimatePortionGrams(for: classification.foodName)
            let scaled = baseMacros.scaled(to: portionGrams)

            ScanAnalyticsService.shared.recordScan(userID: userID, tier: 1, cacheHit: false)

            return FoodRecognitionResult(
                foodName: classification.foodName,
                calories: Int(scaled.calories),
                protein: scaled.protein,
                carbs: scaled.carbs,
                fat: scaled.fat,
                portionGrams: portionGrams,
                tier: 1,
                source: "USDA FoodData Central",
                confidence: classification.confidence,
                needsUserConfirmation: false
            )
        } catch {
            return nil
        }
    }

    // MARK: - Tier 2: Haiku Vision (ID + Macros), Sonnet text-only fallback for low confidence

    /// Confidence threshold below which Haiku's macro estimates are cross-checked
    /// by sending the identified items to Sonnet as a cheap text-only call.
    private let sonnetEscalationThreshold: Double = 0.80

    private func attemptTier2(image: UIImage, coreMLHint: String?, voiceNote: String?, userID: String) async -> FoodRecognitionResult? {
        do {
            // Step 1: Haiku identifies food AND estimates macros in one vision call
            let haikuResult = try await haiku.identifyFood(image: image, coreMLHint: coreMLHint)

            // Check cache
            if let cached = cache.scaledMacros(for: haikuResult.foodName, portionGrams: haikuResult.portionGrams) {
                ScanAnalyticsService.shared.recordScan(userID: userID, tier: 2, cacheHit: true)
                return FoodRecognitionResult(
                    foodName: haikuResult.foodName,
                    calories: Int(cached.calories),
                    protein: cached.protein,
                    carbs: cached.carbs,
                    fat: cached.fat,
                    portionGrams: haikuResult.portionGrams,
                    tier: 2,
                    source: "Cache (Haiku-identified)",
                    confidence: haikuResult.confidence,
                    needsUserConfirmation: haikuResult.confidence < 0.75 || haikuResult.isMixedMeal
                )
            }

            // Step 2: For single-ingredient foods, try USDA first (free, most accurate)
            if !haikuResult.isMixedMeal {
                if let base = try? await usda.fetchBaseMacros(query: haikuResult.foodName) {
                    let scaled = base.scaled(to: haikuResult.portionGrams)
                    cache.store(foodName: haikuResult.foodName, macrosPer100g: base)
                    print("[Tier2] ✅ Using USDA for \"\(haikuResult.foodName)\" — \(Int(scaled.calories)) kcal / \(Int(haikuResult.portionGrams))g")
                    ScanAnalyticsService.shared.recordScan(userID: userID, tier: 2, cacheHit: false)
                    return FoodRecognitionResult(
                        foodName: haikuResult.foodName,
                        calories: Int(scaled.calories),
                        protein: scaled.protein,
                        carbs: scaled.carbs,
                        fat: scaled.fat,
                        portionGrams: haikuResult.portionGrams,
                        tier: 2,
                        source: "USDA FoodData Central (Haiku-identified)",
                        confidence: haikuResult.confidence,
                        needsUserConfirmation: haikuResult.confidence < 0.75
                    )
                }
            }

            // Step 3: If Haiku is confident, use its macros directly (cheapest path).
            // If confidence is low, escalate to Sonnet TEXT-ONLY to recalculate macros
            // using Haiku's food identification — no image sent to Sonnet.
            let isMixed = (haikuResult.components?.count ?? 0) > 1

            if haikuResult.confidence >= sonnetEscalationThreshold {
                // Haiku is confident — use its macros directly
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

                print("[Tier2] ✅ Haiku (confident \(Int(haikuResult.confidence * 100))%) for \"\(haikuResult.foodName)\" — \(haikuResult.calories) kcal / \(Int(haikuResult.portionGrams))g")
                ScanAnalyticsService.shared.recordScan(userID: userID, tier: 2, cacheHit: false)

                return FoodRecognitionResult(
                    foodName: haikuResult.foodName,
                    calories: haikuResult.calories,
                    protein: haikuResult.protein,
                    carbs: haikuResult.carbs,
                    fat: haikuResult.fat,
                    portionGrams: haikuResult.portionGrams,
                    tier: 2,
                    source: "Claude Haiku",
                    confidence: haikuResult.confidence,
                    needsUserConfirmation: haikuResult.confidence < 0.75 || isMixed,
                    components: haikuResult.components
                )
            }

            // Step 4: Low confidence — ask Sonnet to recalculate macros (text only, no image)
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

            print("[Tier2] ✅ Haiku→Sonnet(text) for \"\(haikuResult.foodName)\" — \(sonnetResult.calories) kcal / \(Int(haikuResult.portionGrams))g (Haiku confidence was \(Int(haikuResult.confidence * 100))%)")
            ScanAnalyticsService.shared.recordScan(userID: userID, tier: 2, cacheHit: false)

            let sonnetIsMixed = (sonnetResult.components?.count ?? 0) > 1

            return FoodRecognitionResult(
                foodName: sonnetResult.foodName,
                calories: sonnetResult.calories,
                protein: sonnetResult.protein,
                carbs: sonnetResult.carbs,
                fat: sonnetResult.fat,
                portionGrams: sonnetResult.portionGrams,
                tier: 2,
                source: "Haiku Vision + Sonnet Macros",
                confidence: haikuResult.confidence,
                needsUserConfirmation: haikuResult.confidence < 0.75 || sonnetIsMixed,
                components: sonnetResult.components
            )
        } catch {
            return nil
        }
    }

    // MARK: - Tier 3: Claude Sonnet Full Analysis

    private func attemptTier3(image: UIImage, previousGuess: String?, voiceNote: String?, userID: String) async -> FoodRecognitionResult? {
        do {
            let sonnetResult = try await sonnet.analyzeFood(
                image: image,
                previousGuess: previousGuess,
                voiceNote: voiceNote
            )

            // Cache the base macros
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

            ScanAnalyticsService.shared.recordScan(userID: userID, tier: 3, cacheHit: false)

            let isMixed = (sonnetResult.components?.count ?? 0) > 1

            return FoodRecognitionResult(
                foodName: sonnetResult.foodName,
                calories: sonnetResult.calories,
                protein: sonnetResult.protein,
                carbs: sonnetResult.carbs,
                fat: sonnetResult.fat,
                portionGrams: sonnetResult.portionGrams,
                tier: 3,
                source: "Claude Sonnet",
                confidence: sonnetResult.confidenceScore,
                needsUserConfirmation: sonnetResult.confidenceScore < 0.75 || isMixed,
                components: sonnetResult.components
            )
        } catch {
            return nil
        }
    }

    // MARK: - Portion Estimation

    /// Returns an estimated single-serving portion in grams based on the food name.
    /// Used by Tier 1 instead of a hardcoded 150g default.
    private func estimatePortionGrams(for foodName: String) -> Double {
        let name = foodName.lowercased()

        // Fruits — use realistic single-unit weights
        if name.contains("banana")      { return 118 }  // 1 medium banana
        if name.contains("apple")       { return 182 }  // 1 medium apple
        if name.contains("orange")      { return 131 }  // 1 medium orange
        if name.contains("pear")        { return 178 }  // 1 medium pear
        if name.contains("peach")       { return 150 }  // 1 medium peach
        if name.contains("mango")       { return 200 }  // 1 cup sliced
        if name.contains("kiwi")        { return 76  }  // 1 medium kiwi
        if name.contains("avocado")     { return 150 }  // 1 medium avocado
        if name.contains("strawberr")   { return 150 }  // ~1 cup
        if name.contains("blueberr")    { return 150 }  // ~1 cup
        if name.contains("raspberr")    { return 123 }  // ~1 cup
        if name.contains("grape")       { return 150 }  // ~1 cup
        if name.contains("watermelon")  { return 280 }  // 1 wedge
        if name.contains("pineapple")   { return 165 }  // ~1 cup

        // Vegetables
        if name.contains("broccoli")    { return 150 }
        if name.contains("carrot")      { return 120 }
        if name.contains("sweet potato") || name.contains("sweetpotato") { return 130 }
        if name.contains("potato")      { return 150 }  // 1 medium potato
        if name.contains("spinach")     { return 85  }
        if name.contains("tomato")      { return 125 }  // 1 medium tomato
        if name.contains("cucumber")    { return 120 }
        if name.contains("pepper")      { return 120 }

        // Proteins
        if ["chicken", "beef", "steak", "pork", "turkey", "salmon", "tuna", "shrimp", "fish"]
            .contains(where: { name.contains($0) }) { return 170 }  // ~6 oz
        if name.contains("egg")         { return 100 }  // ~2 eggs

        // Dairy
        if name.contains("milk")        { return 240 }
        if name.contains("yogurt")      { return 150 }
        if name.contains("cheese")      { return 30  }

        // Grains
        if name.contains("bread") || name.contains("toast") { return 60 }
        if ["rice", "oat", "cereal", "granola"].contains(where: { name.contains($0) }) { return 150 }

        // Nuts
        if ["almond", "peanut", "walnut", "cashew", "nut", "pistachio"]
            .contains(where: { name.contains($0) }) { return 30 }

        return 150  // generic default
    }

    // MARK: - Offline / Fallback

    private func offlineResult(classification: ClassificationResult) -> FoodRecognitionResult {
        FoodRecognitionResult(
            foodName: classification.foodName,
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            portionGrams: 0,
            tier: 1,
            source: "Offline (Core ML only)",
            confidence: classification.confidence,
            needsUserConfirmation: true
        )
    }

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

    /// Manually escalates to the next tier. Used by the "Try better scan" button.
    func escalate(image: UIImage, fromTier: Int, voiceNote: String? = nil, userID: String = "") async -> FoodRecognitionResult {
        switch fromTier {
        case 1:
            if let result = await attemptTier2(image: image, coreMLHint: nil, voiceNote: voiceNote, userID: userID) {
                return result
            }
            if let result = await attemptTier3(image: image, previousGuess: nil, voiceNote: voiceNote, userID: userID) {
                return result
            }
            return fallbackResult()

        case 2:
            if let result = await attemptTier3(image: image, previousGuess: nil, voiceNote: voiceNote, userID: userID) {
                return result
            }
            return fallbackResult()

        default:
            return fallbackResult()
        }
    }

    // MARK: - Text-Only Recognition

    /// Estimates macros from a food name string (no image required).
    /// Used by the edit entry "Reanalyze with AI" button.
    /// Tries USDA first (free), falls back to Sonnet if no result.
    func recognizeFoodByName(_ name: String) async -> FoodRecognitionResult {
        // Try USDA first (free, fast)
        if let usda = try? await usda.fetchBaseMacros(query: name) {
            let portion = estimatePortionGrams(for: name)
            let scaled = usda.scaled(to: portion)
            return FoodRecognitionResult(
                foodName: name.capitalized,
                calories: Int(scaled.calories),
                protein: scaled.protein,
                carbs: scaled.carbs,
                fat: scaled.fat,
                portionGrams: portion,
                tier: 1,
                source: "USDA FoodData Central",
                confidence: 0.85,
                needsUserConfirmation: false
            )
        }

        // USDA didn't have it — use Sonnet with a blank image placeholder
        // by sending the food name as the voice note (which takes priority)
        let placeholder = UIImage(systemName: "fork.knife")!
        if let result = await attemptTier3(image: placeholder, previousGuess: nil, voiceNote: name, userID: "") {
            return result
        }

        return fallbackResult()
    }
}
