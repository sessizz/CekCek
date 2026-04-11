import Foundation
import SwiftData

@Model
final class ChecklistItem {
    var id: UUID = UUID()
    var titleKey: String = ""
    var customTitle: String?
    var isChecked: Bool = false
    var sortOrder: Int = 0
    var isDefault: Bool = true
    var checklist: Checklist?

    init(titleKey: String, sortOrder: Int, isDefault: Bool = true) {
        self.id = UUID()
        self.titleKey = titleKey
        self.sortOrder = sortOrder
        self.isDefault = isDefault
    }
}
