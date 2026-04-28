import Foundation
import SwiftData

@Model
final class Checklist {
    var id: UUID = UUID()
    var titleKey: String = ""
    var customTitle: String?
    var iconName: String = "checklist"
    var sortOrder: Int = 0
    var isDefault: Bool = true
    var marketplaceSourceId: UUID?   // set when downloaded from marketplace
    var marketplacePublishedId: UUID? // set when published to marketplace
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \ChecklistItem.checklist)
    var items: [ChecklistItem]?

    @Relationship(deleteRule: .cascade, inverse: \CompletionRecord.checklist)
    var completionRecords: [CompletionRecord]?

    init(titleKey: String, iconName: String, sortOrder: Int, isDefault: Bool = true) {
        self.id = UUID()
        self.titleKey = titleKey
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.createdAt = Date()
    }
}
