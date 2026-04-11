import Foundation
import SwiftData

enum DefaultDataSeeder {

    /// Seeds default checklists only if none exist. Guarded by UserDefaults
    /// so it runs at most once per device, avoiding CloudKit race conditions.
    static func seedIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: "hasSeededDefaultData") else { return }

        let descriptor = FetchDescriptor<Checklist>(
            predicate: #Predicate { $0.isDefault == true }
        )
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else {
            UserDefaults.standard.set(true, forKey: "hasSeededDefaultData")
            return
        }

        for seedChecklist in DefaultChecklists.all {
            let checklist = Checklist(
                titleKey: seedChecklist.titleKey,
                iconName: seedChecklist.iconName,
                sortOrder: seedChecklist.sortOrder
            )
            context.insert(checklist)

            for seedItem in seedChecklist.items {
                let item = ChecklistItem(
                    titleKey: seedItem.titleKey,
                    sortOrder: seedItem.sortOrder
                )
                item.checklist = checklist
                context.insert(item)
            }
        }

        try? context.save()
        UserDefaults.standard.set(true, forKey: "hasSeededDefaultData")
    }

    /// Removes duplicate default checklists (keeps oldest per titleKey).
    static func deduplicateDefaults(context: ModelContext) {
        let descriptor = FetchDescriptor<Checklist>(
            predicate: #Predicate { $0.isDefault == true }
        )
        guard let allDefaults = try? context.fetch(descriptor),
              allDefaults.count > DefaultChecklists.all.count else { return }

        var seen: [String: Checklist] = [:]
        for checklist in allDefaults.sorted(by: { $0.createdAt < $1.createdAt }) {
            if seen[checklist.titleKey] != nil {
                context.delete(checklist)
            } else {
                seen[checklist.titleKey] = checklist
            }
        }

        try? context.save()
    }
}
