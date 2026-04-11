import Foundation
import SwiftData

@Model
final class CompletionRecord {
    var id: UUID = UUID()
    var completedAt: Date = Date()
    var totalItems: Int = 0
    var checkedItems: Int = 0
    var checklist: Checklist?

    @Relationship(deleteRule: .cascade, inverse: \CompletionRecordItem.record)
    var itemSnapshots: [CompletionRecordItem]?

    init(totalItems: Int, checkedItems: Int) {
        self.id = UUID()
        self.completedAt = Date()
        self.totalItems = totalItems
        self.checkedItems = checkedItems
    }
}
