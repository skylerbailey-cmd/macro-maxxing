//
//  Config.swift
//  Wellness
//

struct Config {
    // MARK: - Anthropic (Claude)
    static let claudeApiKey = "REDACTED"
    /// Backward-compatible alias used by ClaudeAnalysisService.
    static let anthropicAPIKey = claudeApiKey

    // MARK: - USDA FoodData Central
    static let usdaApiKey = "YOUR_USDA_KEY"

    // MARK: - FatSecret Platform
    static let fatSecretClientId = "REDACTED"
    static let fatSecretClientSecret = "REDACTED"
}
