import SwiftUI
import SwiftData

struct ChecklistRowView: View {
    let checklist: Checklist
    @Query private var items: [ChecklistItem]

    init(checklist: Checklist) {
        self.checklist = checklist
        let id = checklist.persistentModelID
        _items = Query(filter: #Predicate<ChecklistItem> { $0.checklist?.persistentModelID == id })
    }

    private var checkedCount: Int { items.filter(\.isChecked).count }
    private var totalCount: Int { items.count }
    private var remainingCount: Int { totalCount - checkedCount }
    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(checkedCount) / Double(totalCount)
    }
    private var isComplete: Bool { totalCount > 0 && checkedCount == totalCount }
    private var isMarketplaceDownload: Bool { checklist.marketplaceSourceId != nil }
    private var marketplaceGold: Color { Color(red: 1.0, green: 0.72, blue: 0.16) }

    var body: some View {
        HStack(spacing: 12) {
            // Icon badge — SF Symbol or emoji
            Group {
                if checklist.iconName.isEmoji {
                    Text(checklist.iconName)
                        .font(.system(size: 28))
                } else {
                    Image(systemName: checklist.iconName)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 36, height: 36)
            .background {
                RoundedRectangle(cornerRadius: 9)
                    .fill(iconBackgroundColor)
            }
            .overlay {
                if isMarketplaceDownload {
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(marketplaceGold.opacity(0.72), lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .shadow(
                color: isMarketplaceDownload
                    ? marketplaceGold.opacity(0.72)
                    : .clear,
                radius: 10, x: 0, y: 3
            )

            // Title + subtitle
            VStack(alignment: .leading, spacing: 3) {
                Text(checklist.displayTitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)

                Text("\(checkedCount)/\(totalCount)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Remaining count badge + progress ring
            HStack(spacing: 10) {
                if !isComplete && totalCount > 0 {
                    Text("\(remainingCount)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(Capsule())
                }
                ProgressRingView(progress: progress, size: 26)
            }
        }
        .padding(.vertical, 4)
    }

    private var iconBackgroundColor: Color {
        if checklist.iconName.isEmoji {
            return isMarketplaceDownload ? marketplaceGold.opacity(0.16) : .clear
        }

        return isMarketplaceDownload ? Color.accentColor.opacity(0.92) : Color.accentColor
    }
}
