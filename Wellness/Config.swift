//
//  Config.swift
//  Wellness
//
//  ⚠️  SECURITY WARNING:
//  These keys are embedded in the app binary. Before App Store submission,
//  migrate all API calls through a server-side proxy (e.g. Firebase Cloud
//  Functions) so secrets never ship to client devices.
//
//  This file should NOT be committed to source control.
//  See .gitignore for the exclusion rule.
//

struct Config {
    // MARK: - Anthropic (Claude)
    //
    // TODO: Move to server-side proxy before production release.
    // Embedding this key in the binary allows anyone to extract and abuse it.
    #warning("API keys are hardcoded — migrate to server-side proxy before App Store submission")
    static let claudeApiKey = "REDACTED"
    /// Backward-compatible alias used by ClaudeAnalysisService.
    static let anthropicAPIKey = claudeApiKey

    // MARK: - USDA FoodData Central
    static let usdaApiKey = "REDACTED"

    // MARK: - FatSecret Platform
    static let fatSecretClientId = "REDACTED"
    static let fatSecretClientSecret = "REDACTED"
}
