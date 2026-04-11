import SwiftUI
import SwiftData

struct HistoryView: View {
    let checklist: Checklist
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRecord: CompletionRecord?

    @Query private var records: [CompletionRecord]

    init(checklist: Checklist) {
        self.checklist = checklist
        let id = checklist.id
        self._records = Query(
            filter: #Predicate<CompletionRecord> { $0.checklist?.id == id },
            sort: \CompletionRecord.completedAt,
            order: .reverse
        )
    }

    var body: some View {
        // Avoid NavigationStack inside sheet — it breaks content rendering on macOS.
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(String(localized: "checklist.history"))
                    .font(.headline)
                Spacer()
                Button(String(localized: "common.done")) { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()

            // Content
            if records.isEmpty {
                ContentUnavailableView(
                    String(localized: "history.empty"),
                    systemImage: "clock.arrow.circlepath",
                    description: Text(String(localized: "history.emptyDescription"))
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(records) { record in
                        Button {
                            selectedRecord = record
                        } label: {
                            CompletionRecordRowView(record: record)
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
        }
        .frame(minWidth: 480, minHeight: 360)
        .sheet(item: $selectedRecord) { record in
            CompletionDetailView(record: record)
        }
    }
}
