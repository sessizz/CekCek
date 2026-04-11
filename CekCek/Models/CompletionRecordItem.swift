import Foundation
import SwiftData

@Model
final class CompletionRecordItem {
    var id: UUID = UUID()
    var itemTitle: String = ""
    var isChecked: Bool = false
    var sortOrder: Int = 0
    var record: CompletionRecord?

    init(itemTitle: String, isChecked: Bool, sortOrder: Int) {
        self.id = UUID()
        self.itemTitle = itemTitle
        self.isChecked = isChecked
        self.sortOrder = sortOrder
    }
}
