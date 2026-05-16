import Combine
import CoreData
import CloudKit
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
    @Published private(set) var lastWarningMessage: String?
    @Published private(set) var lastDebugDetails: String?
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
            let syncIssue = CloudKitSyncIssue(error: error)
            lastDebugDetails = syncIssue.debugDetails

            if syncIssue.isTransient {
                lastWarningMessage = syncIssue.message
                lastErrorMessage = nil
            } else {
                lastErrorMessage = syncIssue.message
                lastWarningMessage = nil
            }

            print("CloudKit \(event.type) event failed: \(syncIssue.debugDetails)")
            return
        }

        if event.type == .import || event.type == .export {
            lastSyncDate = event.endDate
        }

        if event.type == .setup {
            print("CloudKit setup completed successfully.")
        }

        lastErrorMessage = nil
        lastWarningMessage = nil
        lastDebugDetails = nil
    }
}

private struct CloudKitSyncIssue {
    let message: String
    let debugDetails: String
    let isTransient: Bool

    init(error: Error) {
        let nsError = error as NSError
        let partialDetails = Self.partialErrorDetails(from: nsError)
        let underlyingDetails = Self.underlyingErrorDetails(from: nsError)
        let debugPieces = [
            "\(nsError.domain) code \(nsError.code): \(nsError.localizedDescription)",
            partialDetails,
            underlyingDetails,
        ].compactMap { $0 }

        debugDetails = debugPieces.joined(separator: "\n")
        isTransient = Self.isTransient(nsError)
        message = Self.message(for: nsError, isTransient: isTransient)
    }

    private static func message(for error: NSError, isTransient: Bool) -> String {
        if error.domain == CKError.errorDomain,
           let code = CKError.Code(rawValue: error.code) {
            switch code {
            case .partialFailure:
                return String(localized: "cloudkit.status.partialFailure")
            case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy:
                return String(localized: "cloudkit.status.temporaryIssue")
            case .notAuthenticated:
                return String(localized: "cloudkit.status.notAuthenticated")
            case .quotaExceeded:
                return String(localized: "cloudkit.status.quotaExceeded")
            default:
                break
            }
        }

        return isTransient
            ? String(localized: "cloudkit.status.temporaryIssue")
            : error.localizedDescription
    }

    private static func isTransient(_ error: NSError) -> Bool {
        if error.domain == CKError.errorDomain,
           let code = CKError.Code(rawValue: error.code) {
            switch code {
            case .partialFailure, .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy, .serverResponseLost:
                return true
            default:
                return false
            }
        }

        if let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            return isTransient(underlying)
        }

        return false
    }

    private static func partialErrorDetails(from error: NSError) -> String? {
        guard let partialErrors = error.userInfo[CKPartialErrorsByItemIDKey] as? [AnyHashable: NSError],
              !partialErrors.isEmpty else {
            return nil
        }

        return partialErrors
            .map { key, value in
                "\(key): \(value.domain) code \(value.code): \(value.localizedDescription)"
            }
            .sorted()
            .joined(separator: "\n")
    }

    private static func underlyingErrorDetails(from error: NSError) -> String? {
        guard let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError else {
            return nil
        }

        return "Underlying: \(underlying.domain) code \(underlying.code): \(underlying.localizedDescription)"
    }
}
