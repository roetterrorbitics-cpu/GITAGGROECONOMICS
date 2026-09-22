import Foundation
import Security

enum KeychainStore {
    private static let service = "com.roetterrorbitics.Rendert"
    private static let accessTokenKey = "access_token"
    private static let refreshTokenKey = "refresh_token"

    static func saveSession(accessToken: String, refreshToken: String) {
        save(accessToken, key: accessTokenKey)
        save(refreshToken, key: refreshTokenKey)
    }

    static func loadSession() -> (accessToken: String, refreshToken: String)? {
        guard let access = read(accessTokenKey), let refresh = read(refreshTokenKey) else { return nil }
        return (access, refresh)
    }

    static func clearSession() {
        delete(accessTokenKey)
        delete(refreshTokenKey)
    }

    private static func save(_ value: String, key: String) {
        delete(key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: Data(value.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func read(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
