import Foundation
import SwiftData

enum ImportError: LocalizedError {
    case wrongFileType

    var errorDescription: String? {
        switch self {
        case .wrongFileType:
            return String(localized: "import.wrongFileType")
        }
    }
}

enum ChecklistImporter {
    static func importChecklist(from url: URL, context: ModelContext) throws {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        let data = try Data(contentsOf: url)
        let transfer = try JSONDecoder().decode(ChecklistTransferData.self, from: data)

        // Place after all existing checklists
        let descriptor = FetchDescriptor<Checklist>(
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )
        let maxOrder = (try? context.fetch(descriptor).first?.sortOrder) ?? -1

        let checklist = Checklist(
            titleKey: "",
            iconName: transfer.iconName,
            sortOrder: maxOrder + 1,
            isDefault: false
        )
        checklist.customTitle = transfer.title
        context.insert(checklist)

        for transferItem in transfer.items {
            let item = ChecklistItem(
                titleKey: "",
                sortOrder: transferItem.sortOrder,
                isDefault: false
            )
            item.customTitle = transferItem.title
            item.checklist = checklist
            context.insert(item)
        }

        try context.save()
    }
}
