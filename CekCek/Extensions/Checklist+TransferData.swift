import Foundation

extension Checklist {
    var transferData: ChecklistTransferData {
        ChecklistTransferData(
            version: 1,
            id: id,
            title: displayTitle,
            iconName: iconName,
            items: sortedItems.map { item in
                ChecklistItemTransferData(
                    title: item.displayTitle,
                    sortOrder: item.sortOrder
                )
            }
        )
    }
}
