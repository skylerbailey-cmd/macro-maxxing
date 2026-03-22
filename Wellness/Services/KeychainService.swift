//
//  KeychainService.swift
//  Wellness
//
//  Thin wrapper around Security.framework for storing small sensitive values
//  (e.g. cached user IDs) in the iOS Keychain instead of UserDefaults.
//

import Foundation
import Security

enum KeychainService {

    // MARK: - Public API

    /// Saves `value` under `key`. Overwrites any existing entry.
    @discardableResult
    static func set(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        // Delete any existing item first to avoid errSecDuplicateItem
        delete(key: key)
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: serviceName,
            kSecValueData as String:   data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Returns the string stored under `key`, or `nil` if not found.
    static func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: serviceName,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Removes the entry stored under `key`.
    @discardableResult
    static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: serviceName,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Private

    private static let serviceName = "com.sbailey.Wellness"
}
