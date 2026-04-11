import SwiftUI

struct CompletionRecordRowView: View {
    let record: CompletionRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.completedAt, style: .date)
                    .font(.headline)
                Text(record.completedAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(record.checkedItems)/\(record.totalItems)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if record.checkedItems == record.totalItems {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}
