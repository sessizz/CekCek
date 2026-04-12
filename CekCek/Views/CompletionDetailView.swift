import SwiftUI

struct CompletionDetailView: View {
    let record: CompletionRecord
    @Environment(\.dismiss) private var dismiss

    private var sortedSnapshots: [CompletionRecordItem] {
        (record.itemSnapshots ?? []).sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        // Avoid NavigationStack inside sheet — breaks content rendering on macOS.
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "history.detail"))
                        .font(.headline)
                    Text(record.completedAt, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(record.checkedItems)/\(record.totalItems)")
                        .font(.title3.bold())
                        .foregroundStyle(record.checkedItems == record.totalItems ? .green : .primary)
                    if record.checkedItems == record.totalItems {
                        Label(String(localized: "history.allDone"), systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                Button(String(localized: "common.done")) { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .padding(.leading, 12)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()

            // Items list
            if sortedSnapshots.isEmpty {
                ContentUnavailableView(
                    String(localized: "history.noSnapshot"),
                    systemImage: "list.bullet"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section(header: Text(String(localized: "history.items"))) {
                        ForEach(sortedSnapshots) { snapshot in
                            HStack(spacing: 12) {
                                Image(systemName: snapshot.isChecked ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(snapshot.isChecked ? .green : .secondary)
                                    .font(.title3)
                                Text(snapshot.itemTitle)
                                    .foregroundStyle(snapshot.isChecked ? .primary : .secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 360)
        #endif
    }
}
