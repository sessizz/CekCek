import SwiftUI

struct ChecklistItemRowView: View {
    @Bindable var item: ChecklistItem

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                item.isChecked.toggle()
            }
        } label: {
            HStack(spacing: 14) {
                CheckboxCircle(isChecked: item.isChecked)

                Text(item.displayTitle)
                    .font(.system(size: 16))
                    .foregroundStyle(item.isChecked ? .secondary : .primary)
                    .strikethrough(item.isChecked, color: .secondary)
                    .animation(.easeInOut(duration: 0.2), value: item.isChecked)

                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        #if os(iOS)
        .sensoryFeedback(item.isChecked ? .success : .impact(weight: .light), trigger: item.isChecked)
        #endif
    }
}

// MARK: - Checkbox

private struct CheckboxCircle: View {
    let isChecked: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    isChecked ? Color.accentColor : Color.secondary.opacity(0.35),
                    lineWidth: 1.8
                )
                .background(
                    Circle().fill(isChecked ? Color.accentColor : Color.clear)
                )
                .frame(width: 26, height: 26)
                .animation(.easeInOut(duration: 0.18), value: isChecked)

            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(isChecked ? 1 : 0)
                .animation(
                    .spring(response: 0.22, dampingFraction: 0.6),
                    value: isChecked
                )
        }
    }
}
