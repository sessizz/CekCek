import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        ContentUnavailableView(
            String(localized: "empty.title"),
            systemImage: "checklist",
            description: Text(String(localized: "empty.description"))
        )
    }
}
