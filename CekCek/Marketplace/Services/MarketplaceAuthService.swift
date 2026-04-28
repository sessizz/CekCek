import CloudKit
import Combine
import Foundation
import Security

@MainActor
final class MarketplaceAuthService: ObservableObject {
    enum AuthenticationState: Equatable {
        case unknown
        case browseOnly
        case authenticated
    }

    @Published private(set) var state: AuthenticationState = .unknown
    @Published private(set) var currentUser: MarketplaceUser?
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var accessToken: String?

    var isAuthenticated: Bool {
        currentUser != nil
    }

    /// Returns the stored access token if it exists and is not about to expire,
    /// without triggering a CloudKit login. Use this for optional auth scenarios.
    var currentTokenIfValid: String? {
        guard let token = accessToken,
              let exp = expiresAt,
              exp > Date().addingTimeInterval(60) else { return nil }
        return token
    }

    private var expiresAt: Date?
    private let configuration: MarketplaceConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(configuration: MarketplaceConfiguration? = nil, session: URLSession = .shared) {
        self.configuration = configuration ?? .current
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.accessToken = MarketplaceTokenStore.readToken()

        if let expiration = UserDefaults.standard.object(forKey: MarketplaceTokenStore.expiresAtKey) as? Date {
            self.expiresAt = expiration
        }
    }

    /// Called on app launch. Silently restores the session if the user has
    /// previously signed in. Does nothing if already authenticated or if no
    /// stored token hint exists (first-time / never signed in).
    func restoreSessionIfNeeded() async {
        guard !isAuthenticated, accessToken != nil else { return }
        _ = try? await ensureAuthenticated()
    }

    @discardableResult
    func ensureAuthenticated() async throws -> String {
        if let accessToken, let expiresAt, expiresAt > Date().addingTimeInterval(60), currentUser != nil {
            return accessToken
        }

        do {
            let cloudKitUserId = try await fetchCloudKitUserId()
            let displayName = UserDefaults.standard.string(forKey: "marketplaceDisplayName")
                ?? String(localized: "marketplace.profile.defaultName")
            let response = try await login(cloudKitUserId: cloudKitUserId, displayName: displayName)
            accessToken = response.accessToken
            expiresAt = Date(timeIntervalSince1970: TimeInterval(response.expiresAt))
            currentUser = response.marketplaceUser
            state = .authenticated
            lastErrorMessage = nil
            MarketplaceTokenStore.saveToken(response.accessToken)
            if let expiresAt {
                UserDefaults.standard.set(expiresAt, forKey: MarketplaceTokenStore.expiresAtKey)
            }
            return response.accessToken
        } catch {
            state = .browseOnly
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    func updateDisplayName(_ displayName: String) {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        UserDefaults.standard.set(trimmed, forKey: "marketplaceDisplayName")
        currentUser?.displayName = trimmed
    }

    private func fetchCloudKitUserId() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            CKContainer.default().fetchUserRecordID { recordID, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if let recordID {
                    continuation.resume(returning: recordID.recordName)
                    return
                }

                continuation.resume(throwing: MarketplaceAuthError.iCloudUnavailable)
            }
        }
    }

    private func login(cloudKitUserId: String, displayName: String) async throws -> CloudKitLoginResponse {
        guard let baseURL = configuration.apiBaseURL else {
            throw MarketplaceAuthError.configurationMissing
        }

        let url = baseURL.appendingPathComponent("marketplace-auth/cloudkit-login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let anonKey = configuration.anonKey {
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
        }

        let body = CloudKitLoginRequest(
            cloudKitUserId: cloudKitUserId,
            displayName: displayName
        )
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MarketplaceAuthError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw MarketplaceAuthError.serverStatus(httpResponse.statusCode)
        }

        return try decoder.decode(CloudKitLoginResponse.self, from: data)
    }
}

enum MarketplaceAuthError: LocalizedError {
    case iCloudUnavailable
    case configurationMissing
    case invalidResponse
    case serverStatus(Int)

    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable:
            return String(localized: "marketplace.auth.iCloudUnavailable")
        case .configurationMissing:
            return String(localized: "marketplace.auth.configurationMissing")
        case .invalidResponse:
            return String(localized: "marketplace.error.invalidResponse")
        case .serverStatus(let statusCode):
            return String(localized: "marketplace.error.serverStatus \(statusCode)")
        }
    }
}

private struct CloudKitLoginRequest: Encodable {
    let cloudKitUserId: String
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case cloudKitUserId = "cloudkit_user_id"
        case displayName = "display_name"
    }
}

private struct CloudKitLoginResponse: Decodable {
    let accessToken: String
    let expiresAt: Int
    let user: MarketplaceAuthUser

    var marketplaceUser: MarketplaceUser {
        MarketplaceUser(
            id: user.id,
            cloudKitUserId: user.cloudkitUserId,
            displayName: user.displayName,
            avatarURL: user.avatarUrl
        )
    }
}

private struct MarketplaceAuthUser: Decodable {
    let id: UUID
    let cloudkitUserId: String
    let displayName: String
    let avatarUrl: URL?
}

private enum MarketplaceTokenStore {
    static let service = "ssz.CekCek.marketplace"
    static let account = "accessToken"
    static let expiresAtKey = "marketplaceAccessTokenExpiresAt"

    static func readToken() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    static func saveToken(_ token: String) {
        deleteToken()

        var query = baseQuery
        query[kSecValueData as String] = Data(token.utf8)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(query as CFDictionary, nil)
    }

    static func deleteToken() {
        SecItemDelete(baseQuery as CFDictionary)
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
