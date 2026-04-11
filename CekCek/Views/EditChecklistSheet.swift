import SwiftUI
import SwiftData

struct EditChecklistSheet: View {
    @Bindable var checklist: Checklist
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedIcon = ""

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
