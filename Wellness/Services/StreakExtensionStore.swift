//
//  StreakExtensionStore.swift
//  Wellness
//
//  Handles the StoreKit 2 purchase for the 7-day streak extension.
//  Product type: Consumable (can be purchased multiple times).
//
//  Setup required in App Store Connect:
//    1. Create a new In-App Purchase → Consumable
//    2. Product ID: com.sbailey.Wellness.streakExtension
//    3. Price tier: $4.99
//    4. Add to your app's StoreKit configuration file for sandbox testing
//

import StoreKit

@MainActor @Observable final class StreakExtensionStore {

    static let shared    = StreakExtensionStore()
    static let productID = "com.sbailey.Wellness.streakExtension"

    private init() {}

    var product:      Product? = nil
    var isPurchasing: Bool     = false
    var errorMessage: String?  = nil

    func loadProduct() async {
        guard product == nil else { return }
        do {
            let results = try await Product.products(for: [Self.productID])
            product = results.first
            if product == nil {
                print("[StreakExtensionStore] Product not found — check App Store Connect configuration")
            }
        } catch {
            print("[StreakExtensionStore] Failed to load product: \(error)")
        }
    }

    func purchase() async -> Bool {
        guard let product else {
            errorMessage = "Product unavailable. Please try again later."
            return false
        }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    print("[StreakExtensionStore] Purchase verified — transaction \(transaction.id)")
                    return true
                case .unverified(_, let error):
                    errorMessage = "Purchase could not be verified: \(error.localizedDescription)"
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                errorMessage = "Purchase is pending approval."
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            print("[StreakExtensionStore] Purchase error: \(error)")
            return false
        }
    }

    var priceString: String {
        product?.displayPrice ?? "$4.99"
    }
}
