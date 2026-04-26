import Combine
import CoreData
import Foundation

@MainActor
final class CloudKitSyncMonitor: ObservableObject {
    enum StorageMode {
        case cloudKit
        case localFallback
        case inMemoryFallback
    }

    @Published private(set) var storageMode: StorageMode = .localFallback
    @Published private(set) var isSyncInProgress = false
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var startupErrorMessage: String?

    private var cancellables: Set<AnyCancellable> = []

    init() {
        NotificationCenter.default.publisher(
            for: NSPersistentCloudKitContainer.eventChangedNotification
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] notification in
            self?.handleCloudKitEvent(notification)
        }
        .store(in: &cancellables)
    }

    var shouldShowIssueBanner: Bool {
        storageMode != .cloudKit || lastErrorMessage != nil
    }

    func setStartupResult(mode: StorageMode, error: Error? = nil) {
        storageMode = mode
        startupErrorMessage = error?.localizedDescription

        switch mode {
        case .cloudKit:
            print("CloudKit sync enabled.")
        case .localFallback:
            print("CloudKit unavailable. Falling back to local storage. Error: \(error?.localizedDescription ?? "unknown")")
        case .inMemoryFallback:
            print("Persistent storage unavailable. Falling back to in-memory storage. Error: \(error?.localizedDescription ?? "unknown")")
        }
    }

    private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[
            NSPersistentCloudKitContainer.eventNotificationUserInfoKey
        ] as? NSPersistentCloudKitContainer.Event else { return }

        if event.endDate == nil {
            isSyncInProgress = true
            return
        }

        isSyncInProgress = false

        if let error = event.error {
            lastErrorMessage = error.localizedDescription
            print("CloudKit \(event.type) event failed: \(error.localizedDescription)")
            return
        }

        if event.type == .import || event.type == .export {
            lastSyncDate = event.endDate
        }

        if event.type == .setup {
            print("CloudKit setup completed successfully.")
        }

        lastErrorMessage = nil
    }
}
