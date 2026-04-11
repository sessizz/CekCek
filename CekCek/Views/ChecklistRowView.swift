import SwiftUI

struct ChecklistRowView: View {
    let checklist: Checklist

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: checklist.iconName)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(checklist.displayTitle)
                    .font(.headline)

                Text("\(checklist.checkedCount)/\(checklist.totalCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            ProgressRingView(progress: checklist.progress, size: 28)
        }
        .padding(.vertical, 4)
    }
}
