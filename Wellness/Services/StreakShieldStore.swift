//
//  StreakShieldStore.swift
//  Wellness
//
//  Handles the StoreKit 2 purchase for restoring a broken streak.
//  Product type: Consumable (can be purchased multiple times — once per streak break).
//
//  Setup required in App Store Connect:
//    1. Create a new In-App Purchase → Consumable
//    2. Product ID: com.sbailey.Wellness.streakRestore
//    3. Price tier: $0.99 (or your preferred price)
//    4. Add to your app's StoreKit configuration file for sandbox testing
//

import StoreKit

@MainActor @Observable final class StreakShieldStore {

    static let shared    = StreakShieldStore()
    static let productID = "com.sbailey.Wellness.streakRestore"

    private init() {}

    var product:     Product? = nil
    var isPurchasing: Bool    = false
    var errorMessage: String? = nil

    /// Loads the product from the App Store. Call once when the shield popup appears.
    func loadProduct() async {
        guard product == nil else { return }
        do {
            let results = try await Product.products(for: [Self.productID])
            product = results.first
            if product == nil {
                print("[StreakShieldStore] Product not found — check App Store Connect configuration")
            }
        } catch {
            print("[StreakShieldStore] Failed to load product: \(error)")
        }
    }

    /// Initiates the purchase flow. Returns `true` if the transaction verified successfully.
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
                    print("[StreakShieldStore] Purchase verified — transaction \(transaction.id)")
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
            print("[StreakShieldStore] Purchase error: \(error)")
            return false
        }
    }

    /// Formatted price string from the App Store (e.g. "$0.99").
    /// Falls back to "$0.99" while the product is still loading.
    var priceString: String {
        product?.displayPrice ?? "$0.99"
    }
}
