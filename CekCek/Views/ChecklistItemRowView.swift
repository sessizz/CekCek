import SwiftUI

struct ChecklistItemRowView: View {
    @Bindable var item: ChecklistItem

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                item.isChecked.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isChecked ? .green : .secondary)

                Text(item.displayTitle)
                    .strikethrough(item.isChecked)
                    .foregroundStyle(item.isChecked ? .secondary : .primary)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        #if os(iOS)
        .sensoryFeedback(item.isChecked ? .success : .impact(weight: .light), trigger: item.isChecked)
        #endif
    }
}
