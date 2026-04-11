import SwiftUI

struct EditItemSheet: View {
    @Bindable var item: ChecklistItem
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "editItem.titleSection")) {
                    TextField(String(localized: "editItem.titlePlaceholder"), text: $title)
                }
            }
            .navigationTitle(String(localized: "editItem.title"))
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
            .onAppear {
                title = item.displayTitle
            }
        }
    }

    private func save() {
        item.customTitle = title.trimmingCharacters(in: .whitespaces)
        dismiss()
    }
}
