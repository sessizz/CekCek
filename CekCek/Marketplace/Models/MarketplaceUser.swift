import Foundation

struct MarketplaceUser: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let cloudKitUserId: String
    var displayName: String
    var avatarURL: URL?
}
