import Combine
import Foundation

@MainActor
final class MarketplaceAPIService: ObservableObject {
    @Published private(set) var categories: [MarketplaceCategory] = []
    @Published private(set) var featuredChecklists: [MarketplaceChecklist] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let client: MarketplaceClient

    init(client: MarketplaceClient? = nil) {
        self.client = client ?? MarketplaceClientFactory.makeClient()
    }

    func loadBrowseData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let categories = client.fetchCategories()
            async let checklists = client.fetchFeaturedChecklists()
            let fetchedCategories = try await categories
            let fetchedChecklists = try await checklists
            self.categories = fetchedCategories.sorted { $0.sortOrder < $1.sortOrder }
            self.featuredChecklists = fetchedChecklists
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func checklists(in category: MarketplaceCategory) async throws -> [MarketplaceChecklist] {
        try await client.fetchChecklists(categoryId: category.id)
    }

    func checklistDetail(id: UUID) async throws -> MarketplaceChecklist {
        try await client.fetchChecklistDetail(id: id)
    }

    func downloadChecklist(id: UUID) async throws -> MarketplaceChecklist {
        try await client.downloadChecklist(id: id)
    }

    func publishChecklist(_ request: MarketplacePublishRequest, accessToken: String) async throws -> MarketplaceChecklist {
        let publishedChecklist = try await client.publishChecklist(request, accessToken: accessToken)
        await loadBrowseData()
        return publishedChecklist
    }

    func updateChecklist(id: UUID, _ request: MarketplacePublishRequest, accessToken: String) async throws -> MarketplaceChecklist {
        let updated = try await client.updateChecklist(id: id, request, accessToken: accessToken)
        await loadBrowseData()
        return updated
    }

    func rateChecklist(id: UUID, rating: Int, accessToken: String) async throws -> MarketplaceChecklist {
        try await client.rateChecklist(id: id, rating: rating, accessToken: accessToken)
    }

    func fetchMyRating(checklistId: UUID, accessToken: String) async throws -> Int? {
        try await client.fetchMyRating(checklistId: checklistId, accessToken: accessToken)
    }
}

protocol MarketplaceClient {
    func fetchCategories() async throws -> [MarketplaceCategory]
    func fetchFeaturedChecklists() async throws -> [MarketplaceChecklist]
    func fetchChecklists(categoryId: UUID) async throws -> [MarketplaceChecklist]
    func fetchChecklistDetail(id: UUID) async throws -> MarketplaceChecklist
    func downloadChecklist(id: UUID) async throws -> MarketplaceChecklist
    func publishChecklist(_ request: MarketplacePublishRequest, accessToken: String) async throws -> MarketplaceChecklist
    func updateChecklist(id: UUID, _ request: MarketplacePublishRequest, accessToken: String) async throws -> MarketplaceChecklist
    func rateChecklist(id: UUID, rating: Int, accessToken: String) async throws -> MarketplaceChecklist
    func fetchMyRating(checklistId: UUID, accessToken: String) async throws -> Int?
}

struct MarketplacePublishRequest: Encodable, Sendable {
    let title: String
    let description: String?
    let iconName: String
    let categoryId: UUID?
    let language: String
    let sourceChecklistId: UUID
    let items: [MarketplacePublishItem]
}

struct MarketplacePublishItem: Encodable, Sendable {
    let title: String
    let sortOrder: Int
}

struct MarketplaceRatingRequest: Encodable, Sendable {
    let rating: Int
}

private struct MarketplaceMyRatingResponse: Decodable {
    let rating: Int?
}

enum MarketplaceClientFactory {
    static func makeClient() -> MarketplaceClient {
        let configuration = MarketplaceConfiguration.current
        if configuration.isConfigured {
            return HTTPMarketplaceClient(configuration: configuration)
        }

        return LocalMarketplaceClient()
    }
}

enum MarketplaceAPIError: LocalizedError {
    case invalidResponse
    case serverStatus(Int)
    case checklistNotFound

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return String(localized: "marketplace.error.invalidResponse")
        case .serverStatus(let statusCode):
            return String(localized: "marketplace.error.serverStatus \(statusCode)")
        case .checklistNotFound:
            return String(localized: "marketplace.error.notFound")
        }
    }
}

final class HTTPMarketplaceClient: MarketplaceClient {
    private let configuration: MarketplaceConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(configuration: MarketplaceConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .custom(MarketplaceDateDecoding.decode)
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    func fetchCategories() async throws -> [MarketplaceCategory] {
        try await fetch("marketplace/categories")
    }

    func fetchFeaturedChecklists() async throws -> [MarketplaceChecklist] {
        try await fetch("marketplace/checklists/featured")
    }

    func fetchChecklists(categoryId: UUID) async throws -> [MarketplaceChecklist] {
        try await fetch("marketplace/categories/\(categoryId.uuidString)/checklists")
    }

    func fetchChecklistDetail(id: UUID) async throws -> MarketplaceChecklist {
        try await fetch("marketplace/checklists/\(id.uuidString)")
    }

    func downloadChecklist(id: UUID) async throws -> MarketplaceChecklist {
        try await fetch("marketplace/checklists/\(id.uuidString)/download", method: "POST")
    }

    func publishChecklist(_ request: MarketplacePublishRequest, accessToken: String) async throws -> MarketplaceChecklist {
        let bodyData = try encoder.encode(request)
        return try await fetch(
            "marketplace/checklists/publish",
            method: "POST",
            accessToken: accessToken,
            bodyData: bodyData
        )
    }

    func updateChecklist(id: UUID, _ request: MarketplacePublishRequest, accessToken: String) async throws -> MarketplaceChecklist {
        let bodyData = try encoder.encode(request)
        return try await fetch(
            "marketplace/checklists/\(id.uuidString)",
            method: "PUT",
            accessToken: accessToken,
            bodyData: bodyData
        )
    }

    func rateChecklist(id: UUID, rating: Int, accessToken: String) async throws -> MarketplaceChecklist {
        let bodyData = try encoder.encode(MarketplaceRatingRequest(rating: rating))
        return try await fetch(
            "marketplace/checklists/\(id.uuidString)/rate",
            method: "POST",
            accessToken: accessToken,
            bodyData: bodyData
        )
    }

    func fetchMyRating(checklistId: UUID, accessToken: String) async throws -> Int? {
        let response: MarketplaceMyRatingResponse = try await fetch(
            "marketplace/checklists/\(checklistId.uuidString)/my-rating",
            accessToken: accessToken
        )
        return response.rating
    }

    private func fetch<T: Decodable>(
        _ path: String,
        method: String = "GET",
        accessToken: String? = nil,
        bodyData: Data? = nil
    ) async throws -> T {
        guard let baseURL = configuration.apiBaseURL else {
            throw MarketplaceAPIError.invalidResponse
        }

        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let anonKey = configuration.anonKey {
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
        }

        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        if let bodyData {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MarketplaceAPIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw MarketplaceAPIError.serverStatus(httpResponse.statusCode)
        }

        return try decoder.decode(T.self, from: data)
    }
}

private enum MarketplaceDateDecoding {
    static func decode(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: value) {
            return date
        }

        let plainFormatter = ISO8601DateFormatter()
        plainFormatter.formatOptions = [.withInternetDateTime]
        if let date = plainFormatter.date(from: value) {
            return date
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Invalid ISO 8601 date: \(value)"
        )
    }
}

final class LocalMarketplaceClient: MarketplaceClient {
    func fetchCategories() async throws -> [MarketplaceCategory] {
        MarketplaceSampleData.categories
    }

    func fetchFeaturedChecklists() async throws -> [MarketplaceChecklist] {
        MarketplaceSampleData.checklists
    }

    func fetchChecklists(categoryId: UUID) async throws -> [MarketplaceChecklist] {
        MarketplaceSampleData.checklists.filter { $0.categoryId == categoryId }
    }

    func fetchChecklistDetail(id: UUID) async throws -> MarketplaceChecklist {
        guard let checklist = MarketplaceSampleData.checklists.first(where: { $0.id == id }) else {
            throw MarketplaceAPIError.checklistNotFound
        }

        return checklist
    }

    func downloadChecklist(id: UUID) async throws -> MarketplaceChecklist {
        try await fetchChecklistDetail(id: id)
    }

    func fetchMyRating(checklistId: UUID, accessToken: String) async throws -> Int? {
        return nil
    }

    func rateChecklist(id: UUID, rating: Int, accessToken: String) async throws -> MarketplaceChecklist {
        // Local mock: return checklist with simulated updated rating
        let base = try await fetchChecklistDetail(id: id)
        let newCount = base.ratingCount + 1
        let newAvg = ((base.averageRating * Double(base.ratingCount)) + Double(rating)) / Double(newCount)
        return MarketplaceChecklist(
            id: base.id, authorDisplayName: base.authorDisplayName,
            categoryId: base.categoryId, title: base.title,
            description: base.description, iconName: base.iconName,
            language: base.language, version: base.version, itemCount: base.itemCount,
            downloadCount: base.downloadCount,
            averageRating: newAvg, ratingCount: newCount,
            items: base.items, createdAt: base.createdAt
        )
    }

    func publishChecklist(_ request: MarketplacePublishRequest, accessToken: String) async throws -> MarketplaceChecklist {
        MarketplaceChecklist(
            id: UUID(),
            authorDisplayName: String(localized: "marketplace.profile.defaultName"),
            categoryId: request.categoryId,
            title: request.title,
            description: request.description,
            iconName: request.iconName,
            language: request.language,
            version: 1,
            itemCount: request.items.count,
            downloadCount: 0,
            averageRating: 0,
            ratingCount: 0,
            items: request.items.map { item in
                MarketplaceChecklistItem(id: UUID(), title: item.title, sortOrder: item.sortOrder)
            },
            createdAt: Date()
        )
    }

    func updateChecklist(id: UUID, _ request: MarketplacePublishRequest, accessToken: String) async throws -> MarketplaceChecklist {
        // Local mock: just return same checklist with bumped version
        let base = try await fetchChecklistDetail(id: id)
        return MarketplaceChecklist(
            id: base.id, authorDisplayName: base.authorDisplayName,
            categoryId: request.categoryId, title: request.title,
            description: request.description, iconName: request.iconName,
            language: request.language, version: base.version + 1,
            itemCount: request.items.count,
            downloadCount: base.downloadCount,
            averageRating: base.averageRating, ratingCount: base.ratingCount,
            items: request.items.map { item in
                MarketplaceChecklistItem(id: UUID(), title: item.title, sortOrder: item.sortOrder)
            },
            createdAt: base.createdAt
        )
    }
}

private enum MarketplaceSampleData {
    static let rvCategoryId = UUID(uuidString: "92EEA4ED-8D85-4E86-A08F-8A4F037A1E01")!
    static let campingCategoryId = UUID(uuidString: "88C8F636-68A7-4C62-BAF0-8ECA55C0B12A")!
    static let travelCategoryId = UUID(uuidString: "2A06B90F-7AF5-43DD-936C-18BB845E09F8")!
    static let aviationCategoryId = UUID(uuidString: "8B38E06F-2652-49E2-A015-DF3B9332F650")!
    static let marineCategoryId = UUID(uuidString: "7231B0D0-8045-4D77-A018-842DC5FC1A2C")!
    static let homeCategoryId = UUID(uuidString: "0529798D-2F25-454F-B1A4-4421E2A3F693")!
    static let vehicleCategoryId = UUID(uuidString: "3C6047C3-50B6-43C2-8ED6-DF109688ED92")!
    static let otherCategoryId = UUID(uuidString: "F38B10A0-071B-41D3-A556-BFB60C46EF86")!

    static let categories: [MarketplaceCategory] = [
        MarketplaceCategory(
            id: rvCategoryId,
            nameKey: "marketplace.category.rv",
            displayNameTr: "Karavan",
            displayNameEn: "RV",
            iconName: "car.side",
            sortOrder: 0,
            isActive: true
        ),
        MarketplaceCategory(
            id: campingCategoryId,
            nameKey: "marketplace.category.camping",
            displayNameTr: "Kamp",
            displayNameEn: "Camping",
            iconName: "tent",
            sortOrder: 1,
            isActive: true
        ),
        MarketplaceCategory(
            id: travelCategoryId,
            nameKey: "marketplace.category.travel",
            displayNameTr: "Seyahat",
            displayNameEn: "Travel",
            iconName: "map",
            sortOrder: 2,
            isActive: true
        ),
        MarketplaceCategory(
            id: aviationCategoryId,
            nameKey: "marketplace.category.aviation",
            displayNameTr: "Havacılık",
            displayNameEn: "Aviation",
            iconName: "airplane",
            sortOrder: 3,
            isActive: true
        ),
        MarketplaceCategory(
            id: marineCategoryId,
            nameKey: "marketplace.category.marine",
            displayNameTr: "Denizcilik",
            displayNameEn: "Marine",
            iconName: "ferry",
            sortOrder: 4,
            isActive: true
        ),
        MarketplaceCategory(
            id: homeCategoryId,
            nameKey: "marketplace.category.home",
            displayNameTr: "Ev",
            displayNameEn: "Home",
            iconName: "house",
            sortOrder: 5,
            isActive: true
        ),
        MarketplaceCategory(
            id: vehicleCategoryId,
            nameKey: "marketplace.category.vehicle",
            displayNameTr: "Araç",
            displayNameEn: "Vehicle",
            iconName: "wrench.and.screwdriver",
            sortOrder: 6,
            isActive: true
        ),
        MarketplaceCategory(
            id: otherCategoryId,
            nameKey: "marketplace.category.other",
            displayNameTr: "Diğer",
            displayNameEn: "Other",
            iconName: "square.grid.2x2",
            sortOrder: 7,
            isActive: true
        ),
    ]

    static let checklists: [MarketplaceChecklist] = [
        MarketplaceChecklist(
            id: UUID(uuidString: "A5E9E72B-82CB-4A38-8C63-3C9706D3F07A")!,
            authorDisplayName: "CekCek",
            categoryId: rvCategoryId,
            title: "Hafta Sonu Karavan Hazırlığı",
            description: "Kısa kaçamaklar için yola çıkmadan önce hızlı ama kapsamlı kontrol.",
            iconName: "car.side",
            language: "tr",
            itemCount: 8,
            version: 1, downloadCount: 128,
            averageRating: 4.8,
            ratingCount: 24,
            items: [
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "D0566B6D-78A6-47A6-9169-60C32F42FB08")!,
                    title: "Lastik basınçlarını kontrol et",
                    sortOrder: 0
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "85365454-9F8B-40CA-A5E8-CB75DA2F0A21")!,
                    title: "Temiz su tankını doldur",
                    sortOrder: 1
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "0C115F8D-3182-42F5-8DD6-35333B2BF547")!,
                    title: "Gaz tüpü seviyesini kontrol et",
                    sortOrder: 2
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "9534A8FE-BDD1-43D7-9D68-558D389E2069")!,
                    title: "Buzdolabını seyahat moduna al",
                    sortOrder: 3
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "D3675D3D-6D00-4F8B-8B8F-8DF1430F8A92")!,
                    title: "Pencereleri ve dolapları kilitle",
                    sortOrder: 4
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "975FD5A5-BE5A-4900-B06B-AD899E11CBA6")!,
                    title: "Tente ve dış ekipmanları sabitle",
                    sortOrder: 5
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "D07928A0-0558-4BC2-8554-7ED8923E9A7D")!,
                    title: "Fren ve sinyal lambalarını test et",
                    sortOrder: 6
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "89D19D9A-38BB-4936-A641-22CF96CC91F8")!,
                    title: "Ruhsat, sigorta ve kamp rezervasyonunu kontrol et",
                    sortOrder: 7
                ),
            ],
            createdAt: Date(timeIntervalSince1970: 1_768_176_000)
        ),
        MarketplaceChecklist(
            id: UUID(uuidString: "CC01F501-8B2B-4D73-A127-46C51F98E826")!,
            authorDisplayName: "NomadTR",
            categoryId: campingCategoryId,
            title: "Minimal Kamp Mutfağı",
            description: "Az ekipmanla iki kişilik kamp mutfağı hazırlığı.",
            iconName: "flame",
            language: "tr",
            itemCount: 6,
            version: 1, downloadCount: 86,
            averageRating: 4.5,
            ratingCount: 15,
            items: [
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "5D86F55E-EA02-4966-B5A0-736D9B3B0794")!,
                    title: "Ocak ve yakıtı paketle",
                    sortOrder: 0
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "7A2C8849-14E9-407E-9F8F-D2F8771CF9AC")!,
                    title: "İki öğünlük kuru gıdayı ayır",
                    sortOrder: 1
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "588B10F5-9D74-423B-A3F9-D75D1F35A5D5")!,
                    title: "Kahve, çay ve filtreleri koy",
                    sortOrder: 2
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "C91BD522-9E1E-4101-B3E0-C50917683183")!,
                    title: "Çöp poşeti ve bulaşık süngerini ekle",
                    sortOrder: 3
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "C9C7380D-E2E2-4F41-A9EC-5B8233643699")!,
                    title: "Soğuk zincir için buz akülerini hazırla",
                    sortOrder: 4
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "C0A4A7DB-F80F-45D9-A306-980C71158DCE")!,
                    title: "Çakmak ve yedek kibriti kontrol et",
                    sortOrder: 5
                ),
            ],
            createdAt: Date(timeIntervalSince1970: 1_766_102_400)
        ),
        MarketplaceChecklist(
            id: UUID(uuidString: "C017BD07-4E72-4AC6-B487-6B241BE7C589")!,
            authorDisplayName: "RoadPilot",
            categoryId: vehicleCategoryId,
            title: "Long Drive Vehicle Check",
            description: "A practical pre-drive checklist for long highway trips.",
            iconName: "wrench.and.screwdriver",
            language: "en",
            itemCount: 7,
            version: 1, downloadCount: 214,
            averageRating: 4.7,
            ratingCount: 41,
            items: [
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "8CE769B6-2520-479F-8DE9-98B49FBD7051")!,
                    title: "Check tire pressure and tread",
                    sortOrder: 0
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "C254A6BB-0A5E-4BC8-A8F4-E63E9E83560B")!,
                    title: "Top up washer fluid",
                    sortOrder: 1
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "76446631-8D92-464C-B94B-A8294A9342D8")!,
                    title: "Inspect engine oil level",
                    sortOrder: 2
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "CB243B8D-36C3-4ED7-BDD3-53B5698359E4")!,
                    title: "Test headlights and signals",
                    sortOrder: 3
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "D6BE9088-A42B-4205-8B5D-16049B4675E1")!,
                    title: "Pack emergency kit",
                    sortOrder: 4
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "3B63D79D-41DA-4E1B-A9AF-975325169973")!,
                    title: "Download offline maps",
                    sortOrder: 5
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "F70A1483-AEF8-436E-A3DB-8B9E42B3C4D3")!,
                    title: "Confirm documents and insurance",
                    sortOrder: 6
                ),
            ],
            createdAt: Date(timeIntervalSince1970: 1_763_683_200)
        ),
        MarketplaceChecklist(
            id: UUID(uuidString: "725DFF66-61FD-4187-9D15-B3543402E3EA")!,
            authorDisplayName: "Denizci",
            categoryId: marineCategoryId,
            title: "Tekneye Çıkış Öncesi",
            description: "Günübirlik tekne planları için güvenlik odaklı hızlı kontrol.",
            iconName: "ferry",
            language: "tr",
            itemCount: 5,
            version: 1, downloadCount: 52,
            averageRating: 4.3,
            ratingCount: 9,
            items: [
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "E5F917F0-462D-43F4-B7FE-1B11F0A8267D")!,
                    title: "Can yeleklerini kişi sayısına göre kontrol et",
                    sortOrder: 0
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "B08E0967-49B3-4E37-A3BC-F3C9B38E5D68")!,
                    title: "Yakıt ve motor yağı seviyesini kontrol et",
                    sortOrder: 1
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "A74B487A-2734-4BD1-82F8-C31E4E481E87")!,
                    title: "Hava durumunu ve rüzgarı kontrol et",
                    sortOrder: 2
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "73034B8E-2E35-432D-88D4-3085E742B5B9")!,
                    title: "Telsiz veya telefon şarjını doğrula",
                    sortOrder: 3
                ),
                MarketplaceChecklistItem(
                    id: UUID(uuidString: "6BF78408-EF5A-4A4B-8B4D-B6E880557106")!,
                    title: "İlk yardım çantasını yerine koy",
                    sortOrder: 4
                ),
            ],
            createdAt: Date(timeIntervalSince1970: 1_760_486_400)
        ),
    ]
}
