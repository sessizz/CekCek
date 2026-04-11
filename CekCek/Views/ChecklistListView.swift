import SwiftUI
import SwiftData

struct ChecklistListView: View {
    @Query(sort: \Checklist.sortOrder) private var checklists: [Checklist]
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedChecklist: Checklist?
    @State private var showingAddSheet = false
    @State private var editingChecklist: Checklist?

    var body: some View {
        List(selection: $selectedChecklist) {
            ForEach(checklists) { checklist in
                NavigationLink(value: checklist) {
                    ChecklistRowView(checklist: checklist)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation {
                            if selectedChecklist == checklist { selectedChecklist = nil }
                            modelContext.delete(checklist)
                        }
                    } label: {
                        Label(String(localized: "common.delete"), systemImage: "trash")
                    }

                    #if os(macOS)
                    Button {
                        if let url = try? checklist.transferData.temporaryFileURL() {
                            MacSharingService.share(items: [url])
                        }
                    } label: {
                        Label(String(localized: "common.share"), systemImage: "square.and.arrow.up")
                    }
                    .tint(.blue)
                    #else
                    ShareLink(
                        item: checklist.transferData,
                        preview: SharePreview(
                            checklist.displayTitle,
                            image: Image(systemName: checklist.iconName)
                        )
                    ) {
                        Label(String(localized: "common.share"), systemImage: "square.and.arrow.up")
                    }
                    .tint(.blue)
                    #endif
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        editingChecklist = checklist
                    } label: {
                        Label(String(localized: "common.edit"), systemImage: "pencil")
                    }
                    .tint(.orange)
                }
                .contextMenu {
                    Button {
                        editingChecklist = checklist
                    } label: {
                        Label(String(localized: "common.edit"), systemImage: "pencil")
                    }

                    ShareLink(
                        item: checklist.transferData,
                        preview: SharePreview(
                            checklist.displayTitle,
                            image: Image(systemName: checklist.iconName)
                        )
                    ) {
                        Label(String(localized: "common.share"), systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Button(role: .destructive) {
                        withAnimation {
                            if selectedChecklist == checklist { selectedChecklist = nil }
                            modelContext.delete(checklist)
                        }
                    } label: {
                        Label(String(localized: "common.delete"), systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(String(localized: "app.title"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label(String(localized: "checklist.add"), systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddChecklistSheet()
        }
        .sheet(item: $editingChecklist) { checklist in
            EditChecklistSheet(checklist: checklist)
        }
        .onChange(of: checklists.count) {
            DefaultDataSeeder.deduplicateDefaults(context: modelContext)
        }
        .cloudKitSyncRefresh()
    }
}
