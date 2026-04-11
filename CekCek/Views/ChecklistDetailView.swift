import SwiftUI
import SwiftData

struct ChecklistDetailView: View {
    @Bindable var checklist: Checklist
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddItem = false
    @State private var showingHistory = false
    @State private var editingItem: ChecklistItem?

    var body: some View {
        List {
            Section {
                HStack {
                    ProgressRingView(progress: checklist.progress, size: 56, lineWidth: 6)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(checklist.displayTitle)
                            .font(.title2.bold())
                        Text(String(localized: "checklist.progressLabel \(checklist.checkedCount) \(checklist.totalCount)"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 8)

                    Spacer()
                }
                .padding(.vertical, 8)
                .listRowSeparator(.hidden)
            }

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
                            .tint(.orange)
                        }
                }
            }
        }
        .listStyle(.inset)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showingHistory = true
                } label: {
                    Label(String(localized: "checklist.history"), systemImage: "clock.arrow.circlepath")
                }

                Button {
                    showingAddItem = true
                } label: {
                    Label(String(localized: "checklist.addItem"), systemImage: "plus")
                }
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
}
