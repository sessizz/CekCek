import Foundation

struct MarketplaceConfiguration: Sendable {
    let apiBaseURL: URL?
    let anonKey: String?

    var isConfigured: Bool {
        apiBaseURL != nil && !(anonKey?.isEmpty ?? true)
    }

    static var current: MarketplaceConfiguration {
        let info = Bundle.main.infoDictionary ?? [:]
        let baseURLString = info["MarketplaceAPIBaseURL"] as? String
        let anonKey = info["MarketplaceAnonKey"] as? String

        return MarketplaceConfiguration(
            apiBaseURL: baseURLString.flatMap(URL.init(string:)),
            anonKey: anonKey
        )
    }
}
