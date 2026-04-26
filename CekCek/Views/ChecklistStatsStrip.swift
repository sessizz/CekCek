import SwiftUI

#if os(iOS)
/// Three-card stats row shown above the checklist list on iOS.
struct ChecklistStatsStrip: View {
    let activeCount: Int
    let completedCount: Int
    let listCount: Int

    var body: some View {
        HStack(spacing: 10) {
            StatCard(
                value: activeCount,
                label: String(localized: "stats.active"),
                isAccent: true
            )
            StatCard(
                value: completedCount,
                label: String(localized: "stats.completed"),
                isAccent: false
            )
            StatCard(
                value: listCount,
                label: String(localized: "stats.lists"),
                isAccent: false
            )
        }
    }
}

// MARK: - Single stat card

private struct StatCard: View {
    let value: Int
    let label: String
    let isAccent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(value)")
                .font(.system(size: 28, weight: .bold))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: value)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .opacity(isAccent ? 0.9 : 0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            isAccent
                ? Color.accentColor
                : Color(UIColor.secondarySystemGroupedBackground)
        )
        .foregroundStyle(isAccent ? Color.white : Color.primary)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
#endif
