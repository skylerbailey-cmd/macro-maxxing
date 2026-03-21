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
    private let fatSecret = FatSecretService.shared
    private let openFoodFacts = OpenFoodFactsService.shared
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
            if let cached = cache.scaledMacros(for: name, portionGrams: 150) {
                ScanAnalyticsService.shared.recordScan(userID: userID, tier: 1, cacheHit: true)
                let conf = max(coreMLConfidence, localResult.confidence)
                return FoodRecognitionResult(
                    foodName: name,
                    calories: Int(cached.calories),
                    protein: cached.protein,
                    carbs: cached.carbs,
                    fat: cached.fat,
                    portionGrams: 150,
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

        if coreMLConfidence >= 0.60 || (coreMLConfidence >= 0.90 && classification?.isSingleIngredient == false) {
            if let result = await attemptTier2(image: image, coreMLHint: bestHint, voiceNote: voiceNote, userID: userID) {
                return result
            }
        }

        // Low confidence or previous tiers failed — go to Tier 3
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
        // Check cache first
        if let cached = cache.scaledMacros(for: localResult.foodName, portionGrams: 150) {
            ScanAnalyticsService.shared.recordScan(userID: userID, tier: 1, cacheHit: true)
            return FoodRecognitionResult(
                foodName: localResult.foodName,
                calories: Int(cached.calories),
                protein: cached.protein,
                carbs: cached.carbs,
                fat: cached.fat,
                portionGrams: 150,
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

            let portionGrams = 150.0
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
        do {
            // Check cache first
            if let cached = cache.scaledMacros(for: classification.foodName, portionGrams: 150) {
                ScanAnalyticsService.shared.recordScan(userID: userID, tier: 1, cacheHit: true)
                return FoodRecognitionResult(
                    foodName: classification.foodName,
                    calories: Int(cached.calories),
                    protein: cached.protein,
                    carbs: cached.carbs,
                    fat: cached.fat,
                    portionGrams: 150,
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

            // Scale to estimated portion (default 150g for whole foods)
            let portionGrams = 150.0
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

    // MARK: - Tier 2: Claude Haiku + Parallel DB Lookup

    private func attemptTier2(image: UIImage, coreMLHint: String?, voiceNote: String?, userID: String) async -> FoodRecognitionResult? {
        do {
            // Step 1: Claude Haiku identifies the food
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

            // Step 2: Parallel database lookups
            async let fatSecretResult = fatSecret.searchFood(
                query: haikuResult.foodName,
                targetPortionGrams: haikuResult.portionGrams
            )
            async let offResult = openFoodFacts.searchFood(
                query: haikuResult.foodName,
                targetPortionGrams: haikuResult.portionGrams
            )

            let fs = try? await fatSecretResult
            let off = try? await offResult

            // Step 3: Merge results
            guard let merged = NutritionResultMerger.merge(
                fatSecret: fs,
                openFoodFacts: off,
                isMixedMeal: haikuResult.isMixedMeal
            ) else {
                return nil  // Neither database returned results → escalate to Tier 3
            }

            // Cache the base macros
            cache.storeFromResult(
                foodName: haikuResult.foodName,
                macroResult: merged.result,
                portionGrams: haikuResult.portionGrams
            )

            // Sanity check: reject results with unreasonable calorie density
            // Most whole foods are under 400 kcal/100g (nuts/oils can be higher but are rarely misidentified)
            let calPer100g = merged.result.calories / (haikuResult.portionGrams / 100.0)
            if calPer100g > 400 && !haikuResult.isMixedMeal {
                print("[Tier2] ⚠️ Rejected: \(haikuResult.foodName) has \(Int(calPer100g)) kcal/100g — likely wrong product match")
                return nil  // escalate to Tier 3
            }

            ScanAnalyticsService.shared.recordScan(userID: userID, tier: 2, cacheHit: false)

            return FoodRecognitionResult(
                foodName: haikuResult.foodName,
                calories: Int(merged.result.calories),
                protein: merged.result.protein,
                carbs: merged.result.carbs,
                fat: merged.result.fat,
                portionGrams: haikuResult.portionGrams,
                tier: 2,
                source: merged.result.source,
                confidence: haikuResult.confidence,
                needsUserConfirmation: merged.flagged || haikuResult.confidence < 0.75 || haikuResult.isMixedMeal
            )
        } catch let error as FoodRecognitionError {
            // Rate limited or overloaded → try Tier 3
            switch error {
            case .rateLimited, .overloaded:
                return nil
            default:
                return nil
            }
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
}
