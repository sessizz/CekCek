import Foundation
import SwiftData

enum ImportError: LocalizedError {
    case wrongFileType
    case duplicate(title: String)
    case marketplaceMissingItems
    case invalidFile
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .wrongFileType:
            return String(localized: "import.wrongFileType")
        case .duplicate(let title):
            return String(localized: "import.duplicate \(title)")
        case .marketplaceMissingItems:
            return String(localized: "marketplace.error.missingItems")
        case .invalidFile:
            return String(localized: "import.invalidFile")
        case .unsupportedVersion(let version):
            return String(localized: "import.unsupportedVersion \(version)")
        }
    }
}

enum ChecklistImporter {
    static func importChecklist(from url: URL, context: ModelContext) throws {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        guard url.pathExtension.lowercased() == "cekcek" else {
            throw ImportError.wrongFileType
        }

        let data = try Data(contentsOf: url)
        let transfer: ChecklistTransferData
        do {
            transfer = try JSONDecoder().decode(ChecklistTransferData.self, from: data)
        } catch {
            throw ImportError.invalidFile
        }

        guard transfer.version == 1 else {
            throw ImportError.unsupportedVersion(transfer.version)
        }

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

    @discardableResult
    static func importMarketplaceChecklist(
        _ marketplaceChecklist: MarketplaceChecklist,
        context: ModelContext
    ) throws -> Checklist {
        guard let marketplaceItems = marketplaceChecklist.items else {
            throw ImportError.marketplaceMissingItems
        }

        let marketplaceId = marketplaceChecklist.id
        let duplicateDescriptor = FetchDescriptor<Checklist>(
            predicate: #Predicate { $0.marketplaceSourceId == marketplaceId }
        )
        if (try? context.fetchCount(duplicateDescriptor)) ?? 0 > 0 {
            throw ImportError.duplicate(title: marketplaceChecklist.title)
        }

        let descriptor = FetchDescriptor<Checklist>(
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )
        let maxOrder = (try? context.fetch(descriptor).first?.sortOrder) ?? -1

        let checklist = Checklist(
            titleKey: "",
            iconName: marketplaceChecklist.iconName,
            sortOrder: maxOrder + 1,
            isDefault: false
        )
        checklist.customTitle = marketplaceChecklist.title
        checklist.marketplaceSourceId = marketplaceChecklist.id
        context.insert(checklist)

        for marketplaceItem in marketplaceItems.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let item = ChecklistItem(
                titleKey: "",
                sortOrder: marketplaceItem.sortOrder,
                isDefault: false
            )
            item.customTitle = marketplaceItem.title
            item.checklist = checklist
            context.insert(item)
        }

        try context.save()
        return checklist
    }
}
