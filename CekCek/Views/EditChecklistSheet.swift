import SwiftUI
import SwiftData

struct EditChecklistSheet: View {
    @Bindable var checklist: Checklist
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedIcon = ""

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
            .navigationTitle(String(localized: "editChecklist.title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save")) { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                title = checklist.displayTitle
                selectedIcon = checklist.iconName
            }
        }
    }

    private func save() {
        checklist.customTitle = title.trimmingCharacters(in: .whitespaces)
        checklist.iconName = selectedIcon
        // Clear titleKey so displayTitle uses customTitle
        if !checklist.customTitle!.isEmpty {
            checklist.titleKey = ""
        }
        dismiss()
    }
}
