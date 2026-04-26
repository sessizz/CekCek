import SwiftUI
import SwiftData

struct AddChecklistSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedIcon = "checklist"

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "addChecklist.titleSection")) {
                    TextField(String(localized: "addChecklist.titlePlaceholder"), text: $title)
                }

                Section(String(localized: "addChecklist.iconSection")) {
                    IconPickerGrid(selectedIcon: $selectedIcon)
                        .padding(.vertical, 4)
                }
            }
            .navigationTitle(String(localized: "addChecklist.title"))
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
        let checklist = Checklist(
            titleKey: "",
            iconName: selectedIcon,
            sortOrder: 999,
            isDefault: false
        )
        checklist.customTitle = title.trimmingCharacters(in: .whitespaces)
        modelContext.insert(checklist)
        dismiss()
    }
}
