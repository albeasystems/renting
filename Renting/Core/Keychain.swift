//
//  Keychain.swift
//  Renting
//
//  Credentials never leave the device: they are stored in the Keychain
//  (this-device-only, available after first unlock so background refresh works)
//  and sent only to LevelPlay's and Apple's own API hosts.
//

import Foundation
import Security

enum Keychain {
    private static let service = "com.albeasystems.renting.credentials"

    enum Key: String, CaseIterable {
        case lpSecretKey = "lp.secretKey"
        case lpRefreshToken = "lp.refreshToken"
        case asaClientId = "asa.clientId"
        case asaTeamId = "asa.teamId"
        case asaKeyId = "asa.keyId"
        case asaPrivateKey = "asa.privateKey"
    }

    static func get(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func set(_ value: String?, for key: Key) -> Bool {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        SecItemDelete(base as CFDictionary)
        guard let value, !value.isEmpty, let data = value.data(using: .utf8) else { return true }
        var add = base
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }

    static func clear(_ keys: [Key]) {
        for k in keys { set(nil, for: k) }
    }
}
