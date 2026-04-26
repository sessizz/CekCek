import Foundation
import SwiftData

enum ImportError: LocalizedError {
    case wrongFileType
    case duplicate(title: String)

    var errorDescription: String? {
        switch self {
        case .wrongFileType:
            return String(localized: "import.wrongFileType")
        case .duplicate(let title):
            return String(localized: "import.duplicate \(title)")
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

        // Duplicate check by UUID
        let transferID = transfer.id
        let duplicateDescriptor = FetchDescriptor<Checklist>(
            predicate: #Predicate { $0.id == transferID }
        )
        if (try? context.fetchCount(duplicateDescriptor)) ?? 0 > 0 {
            throw ImportError.duplicate(title: transfer.title)
        }

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
        checklist.id = transfer.id
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
