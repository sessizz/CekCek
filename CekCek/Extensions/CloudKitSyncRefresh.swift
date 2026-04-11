import SwiftUI
import CoreData

/// View modifier that forces a SwiftUI refresh when CloudKit finishes importing remote changes.
/// Works around a known SwiftData bug where @Query does not reactively update on CloudKit sync.
struct CloudKitSyncRefresh: ViewModifier {
    @State private var refreshID = UUID()

    func body(content: Content) -> some View {
        content
            .id(refreshID)
            .onReceive(NotificationCenter.default.publisher(
                for: NSPersistentCloudKitContainer.eventChangedNotification
            )) { notification in
                guard let event = notification.userInfo?[
                    NSPersistentCloudKitContainer.eventNotificationUserInfoKey
                ] as? NSPersistentCloudKitContainer.Event else { return }

                // Only refresh after a completed import event
                if event.endDate != nil && event.type == .import {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        refreshID = UUID()
                    }
                }
            }
    }
}

extension View {
    func cloudKitSyncRefresh() -> some View {
        modifier(CloudKitSyncRefresh())
    }
}
