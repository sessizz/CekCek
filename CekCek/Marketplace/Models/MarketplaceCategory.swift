import Foundation

struct MarketplaceCategory: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let nameKey: String
    let displayNameTr: String?
    let displayNameEn: String?
    let iconName: String
    let sortOrder: Int
    let isActive: Bool

    var displayName: String {
        let languageCode = Locale.current.language.languageCode?.identifier
        let localizedName = languageCode == "tr" ? displayNameTr : displayNameEn

        if let localizedName, !localizedName.isEmpty {
            return localizedName
        }

        if let displayNameTr, !displayNameTr.isEmpty {
            return displayNameTr
        }

        if let displayNameEn, !displayNameEn.isEmpty {
            return displayNameEn
        }

        return String(localized: String.LocalizationValue(nameKey))
    }
}
