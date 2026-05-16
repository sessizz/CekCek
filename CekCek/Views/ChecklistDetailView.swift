import SwiftUI
import SwiftData

struct ChecklistDetailView: View {
    @Bindable var checklist: Checklist
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddItem = false
    @State private var showingHistory = false
    @State private var showingMarketplaceUpload = false
    @State private var showingMarketplaceInfo = false
    @State private var editingItem: ChecklistItem?
    @State private var quickAddText = ""
    #if os(iOS)
    @State private var editMode = EditMode.inactive
    #endif

    var body: some View {
        List {
            // ── Header: ring + title + linear progress bar ──────────────
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center) {
                        ProgressRingView(progress: checklist.progress, size: 52, lineWidth: 5)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(checklist.displayTitle)
                                .font(.title2.bold())
                            Text(String(localized: "checklist.progressLabel \(checklist.checkedCount) \(checklist.totalCount)"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 10)

                        Spacer()
                    }

                    // Linear progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 6)
                            Capsule()
                                .fill(Color.accentColor)
                                .frame(
                                    width: geo.size.width * checklist.progress,
                                    height: 6
                                )
                                .animation(
                                    .spring(response: 0.35, dampingFraction: 0.7),
                                    value: checklist.progress
                                )
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.vertical, 8)
                .listRowSeparator(.hidden)
            }

            // ── Items ────────────────────────────────────────────────────
            Section {
                ForEach(checklist.sortedItems) { item in
                    ChecklistItemRowView(item: item)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    modelContext.delete(item)
                                }
                            } label: {
                                Label(String(localized: "common.delete"), systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                editingItem = item
                            } label: {
                                Label(String(localized: "common.edit"), systemImage: "pencil")
                            }
                            .tint(Color.accentColor.opacity(0.85))
                        }
                }
                .onMove(perform: moveItems)
            }
        }
        #if os(iOS)
        .environment(\.editMode, $editMode)
        #endif
        .listStyle(.inset)
        // ── Floating add bar (iOS only) ──────────────────────────────────
        #if os(iOS)
        .safeAreaInset(edge: .bottom) {
            FloatingAddBar(text: $quickAddText) {
                quickAddItem()
            } onAdd: {
                showingAddItem = true
            }
        }
        #endif
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if checklist.marketplaceSourceId != nil || checklist.marketplacePublishedId != nil {
                    Button {
                        showingMarketplaceInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel(String(localized: "marketplace.info.title"))
                }

                Button {
                    showingHistory = true
                } label: {
                    Label(String(localized: "checklist.history"), systemImage: "clock.arrow.circlepath")
                }
                #if os(iOS)
                Button {
                    withAnimation {
                        editMode = editMode == .active ? .inactive : .active
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundStyle(editMode == .active ? Color.accentColor : Color.primary)
                }
                #endif
                #if os(macOS)
                Button {
                    showingAddItem = true
                } label: {
                    Label(String(localized: "checklist.addItem"), systemImage: "plus")
                }
                #endif
            }

            ToolbarItemGroup(placement: .secondaryAction) {
                Button {
                    markComplete()
                } label: {
                    Label(String(localized: "checklist.markComplete"), systemImage: "checkmark.circle")
                }

                Button {
                    resetAll()
                } label: {
                    Label(String(localized: "checklist.resetAll"), systemImage: "arrow.counterclockwise")
                }

                Button {
                    showingMarketplaceUpload = true
                } label: {
                    Label(String(localized: "marketplace.upload.publish"), systemImage: "square.and.arrow.up")
                }
                .disabled(checklist.sortedItems.isEmpty)
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemSheet(checklist: checklist)
        }
        .sheet(item: $editingItem) { item in
            EditItemSheet(item: item)
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(checklist: checklist)
        }
        .sheet(isPresented: $showingMarketplaceUpload) {
            MarketplaceUploadView(checklist: checklist)
        }
        .sheet(isPresented: $showingMarketplaceInfo) {
            let marketplaceId = checklist.marketplaceSourceId ?? checklist.marketplacePublishedId
            if let marketplaceId {
                MarketplaceInfoSheet(marketplaceSourceId: marketplaceId)
            }
        }
        .cloudKitSyncRefresh()
    }

    private func markComplete() {
        let record = CompletionRecord(
            totalItems: checklist.totalCount,
            checkedItems: checklist.checkedCount
        )
        record.checklist = checklist
        modelContext.insert(record)

        for (index, item) in checklist.sortedItems.enumerated() {
            let snapshot = CompletionRecordItem(
                itemTitle: item.displayTitle,
                isChecked: item.isChecked,
                sortOrder: index
            )
            snapshot.record = record
            modelContext.insert(snapshot)
        }

        for item in checklist.items ?? [] {
            item.isChecked = false
        }
    }

    private func resetAll() {
        for item in checklist.items ?? [] {
            item.isChecked = false
        }
    }

    private func quickAddItem() {
        let title = quickAddText.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let maxOrder = (checklist.items ?? []).map(\.sortOrder).max() ?? -1
        let item = ChecklistItem(titleKey: "", sortOrder: maxOrder + 1, isDefault: false)
        item.customTitle = title
        item.checklist = checklist
        modelContext.insert(item)
        quickAddText = ""
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var reordered = checklist.sortedItems
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in reordered.enumerated() {
            item.sortOrder = index
        }
    }
}
