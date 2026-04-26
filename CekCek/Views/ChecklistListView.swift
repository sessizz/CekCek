import SwiftUI
import SwiftData

struct ChecklistListView: View {
    @Query(sort: \Checklist.sortOrder) private var checklists: [Checklist]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var cloudKitSyncMonitor: CloudKitSyncMonitor
    @Binding var selectedChecklist: Checklist?
    @State private var showingAddSheet = false
    @State private var editingChecklist: Checklist?
    @State private var showingCloudKitStatus = false
    #if os(iOS)
    @State private var editMode = EditMode.inactive
    #endif

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
                    .tint(Color.accentColor)
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
            .onMove(perform: move)
        }
        #if os(iOS)
        .environment(\.editMode, $editMode)
        .listSectionSpacing(0)
        #endif
        .navigationTitle("")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .principal) {
                CekCekLogoView()
            }
            #endif

            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCloudKitStatus = true
                } label: {
                    Image(systemName: cloudKitStatusIconName)
                }
                .help(cloudKitSyncMonitor.statusTitle)
            }

            #if os(iOS)
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation {
                        editMode = editMode == .active ? .inactive : .active
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundStyle(editMode == .active ? Color.accentColor : Color.primary)
                }
            }
            #endif

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
        .sheet(isPresented: $showingCloudKitStatus) {
            CloudKitStatusSheet()
                .environmentObject(cloudKitSyncMonitor)
        }
        .onChange(of: checklists.count) {
            DefaultDataSeeder.deduplicateDefaults(context: modelContext)
        }
        .cloudKitSyncRefresh()
    }
}

private extension ChecklistListView {
    func move(from source: IndexSet, to destination: Int) {
        var reordered = checklists
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, checklist) in reordered.enumerated() {
            checklist.sortOrder = index
        }
    }

    var cloudKitStatusIconName: String {
        if cloudKitSyncMonitor.isSyncInProgress {
            return "arrow.triangle.2.circlepath.icloud"
        }

        if cloudKitSyncMonitor.shouldShowIssueBanner {
            return "exclamationmark.icloud"
        }

        return "checkmark.icloud"
    }
}
