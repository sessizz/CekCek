import Foundation

struct MarketplaceChecklist: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let authorDisplayName: String
    let categoryId: UUID?
    let title: String
    let description: String?
    let iconName: String
    let language: String
    let version: Int
    let itemCount: Int
    let downloadCount: Int
    let averageRating: Double
    let ratingCount: Int
    let items: [MarketplaceChecklistItem]?
    let createdAt: Date
}

struct MarketplaceChecklistItem: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let title: String
    let sortOrder: Int
}

extension MarketplaceChecklist {
    private enum CodingKeys: String, CodingKey {
        case id
        case authorDisplayName
        case categoryId
        case title
        case description
        case iconName
        case language
        case version
        case itemCount
        case downloadCount
        case averageRating
        case ratingCount
        case items
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        authorDisplayName = try container.decode(String.self, forKey: .authorDisplayName)
        categoryId = try container.decodeIfPresent(UUID.self, forKey: .categoryId)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        iconName = try container.decode(String.self, forKey: .iconName)
        language = try container.decode(String.self, forKey: .language)
        version = (try? container.decodeIfPresent(Int.self, forKey: .version)) ?? 1
        itemCount = try container.decode(Int.self, forKey: .itemCount)
        downloadCount = try container.decode(Int.self, forKey: .downloadCount)
        averageRating = try container.decode(Double.self, forKey: .averageRating)
        ratingCount = try container.decode(Int.self, forKey: .ratingCount)
        items = try? container.decodeIfPresent([MarketplaceChecklistItem].self, forKey: .items)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
