//
//  Config.swift
//  Wellness
//
//  All API keys have been migrated to server-side Firebase Cloud Function
//  proxies. No secrets are embedded in the app binary.
//

struct Config {
    // All API calls are now proxied through Firebase Cloud Functions:
    //   proxyClaude    → Anthropic API
    //   proxyUSDA      → USDA FoodData Central
    //   proxyFatSecret → FatSecret Platform
    //
    // Keys are stored in Firebase Functions Secrets Manager.
    // No client-side keys needed.
}
