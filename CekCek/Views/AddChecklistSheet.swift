import SwiftUI
import SwiftData

struct AddChecklistSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedIcon = "checklist"

    private let iconOptions = [
        "checklist", "car.side", "tent", "arrow.right.circle",
        "snowflake", "sun.max", "wrench.and.screwdriver",
        "star", "heart", "flag", "bolt", "gear",
        "list.bullet", "doc.text", "folder"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "addChecklist.titleSection")) {
                    TextField(String(localized: "addChecklist.titlePlaceholder"), text: $title)
                }

                Section(String(localized: "addChecklist.iconSection")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedIcon == icon ? Color.accentColor : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
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
