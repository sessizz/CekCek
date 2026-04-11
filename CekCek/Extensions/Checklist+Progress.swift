import Foundation

extension Checklist {
    var checkedCount: Int {
        (items ?? []).filter(\.isChecked).count
    }

    var totalCount: Int {
        (items ?? []).count
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(checkedCount) / Double(totalCount)
    }

    var isComplete: Bool {
        totalCount > 0 && checkedCount == totalCount
    }

    var sortedItems: [ChecklistItem] {
        (items ?? []).sorted { $0.sortOrder < $1.sortOrder }
    }
}
