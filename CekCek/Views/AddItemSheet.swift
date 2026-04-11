import SwiftUI
import SwiftData

struct AddItemSheet: View {
    let checklist: Checklist
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "addItem.titleSection")) {
                    TextField(String(localized: "addItem.titlePlaceholder"), text: $title)
                }
            }
            .navigationTitle(String(localized: "addItem.title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save")) {
                        save()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let maxOrder = (checklist.items ?? []).map(\.sortOrder).max() ?? -1
        let item = ChecklistItem(
            titleKey: "",
            sortOrder: maxOrder + 1,
            isDefault: false
        )
        item.customTitle = title.trimmingCharacters(in: .whitespaces)
        item.checklist = checklist
        modelContext.insert(item)
        dismiss()
    }
}
