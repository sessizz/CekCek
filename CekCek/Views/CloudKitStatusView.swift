import SwiftUI

struct CloudKitStatusBanner: View {
    @EnvironmentObject private var cloudKitSyncMonitor: CloudKitSyncMonitor
    @State private var showingDetails = false

    var body: some View {
        Button {
            showingDetails = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: cloudKitSyncMonitor.statusIconName)
                    .foregroundStyle(cloudKitSyncMonitor.statusColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(cloudKitSyncMonitor.bannerTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text(cloudKitSyncMonitor.bannerMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(cloudKitSyncMonitor.statusColor.opacity(0.25), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetails) {
            CloudKitStatusSheet()
                .environmentObject(cloudKitSyncMonitor)
        }
    }
}

struct CloudKitStatusSheet: View {
    @EnvironmentObject private var cloudKitSyncMonitor: CloudKitSyncMonitor
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: cloudKitSyncMonitor.statusIconName)
                            .foregroundStyle(cloudKitSyncMonitor.statusColor)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(cloudKitSyncMonitor.statusTitle)
                                .font(.headline)
                            Text(cloudKitSyncMonitor.statusDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(String(localized: "cloudkit.status.storageMode")) {
                    Text(cloudKitSyncMonitor.storageModeText)
                }

                if cloudKitSyncMonitor.isSyncInProgress {
                    Section {
                        Label(String(localized: "cloudkit.status.syncing"), systemImage: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.orange)
                    }
                }

                if let lastSyncDate = cloudKitSyncMonitor.lastSyncDate {
                    Section(String(localized: "cloudkit.status.lastSync")) {
                        Text(lastSyncDate.formatted(date: .abbreviated, time: .shortened))
                    }
                }

                if let errorMessage = cloudKitSyncMonitor.lastVisibleErrorMessage {
                    Section(String(localized: "cloudkit.status.reason")) {
                        Text(errorMessage)
                            .textSelection(.enabled)
                    }
                }

                if let debugMessage = cloudKitSyncMonitor.debugDetails {
                    Section(String(localized: "cloudkit.status.debugDetails")) {
                        Text(debugMessage)
                            .font(.footnote.monospaced())
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle(String(localized: "cloudkit.status.button"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #if os(macOS)
            .frame(minWidth: 380, minHeight: 280)
            #endif
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.done")) {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button(String(localized: "common.done")) {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
}

extension CloudKitSyncMonitor {
    var statusIconName: String {
        if lastErrorMessage != nil {
            return "exclamationmark.icloud"
        }

        switch storageMode {
        case .cloudKit:
            return isSyncInProgress ? "arrow.triangle.2.circlepath.icloud" : "checkmark.icloud"
        case .localFallback:
            return "icloud.slash"
        case .inMemoryFallback:
            return "externaldrive.badge.xmark"
        }
    }

    var statusColor: Color {
        if lastErrorMessage != nil {
            return .orange
        }

        switch storageMode {
        case .cloudKit:
            return .green
        case .localFallback, .inMemoryFallback:
            return .red
        }
    }

    var statusTitle: String {
        if lastErrorMessage != nil {
            return String(localized: "cloudkit.status.lastError")
        }

        switch storageMode {
        case .cloudKit:
            return String(localized: "cloudkit.status.connected")
        case .localFallback:
            return String(localized: "cloudkit.status.localFallback")
        case .inMemoryFallback:
            return String(localized: "cloudkit.status.memoryFallback")
        }
    }

    var statusDescription: String {
        if lastErrorMessage != nil {
            return String(localized: "cloudkit.status.banner.error")
        }

        switch storageMode {
        case .cloudKit:
            return String(localized: "cloudkit.status.connectedDetail")
        case .localFallback:
            return String(localized: "cloudkit.status.localFallbackDetail")
        case .inMemoryFallback:
            return String(localized: "cloudkit.status.memoryFallbackDetail")
        }
    }

    var storageModeText: String {
        switch storageMode {
        case .cloudKit:
            return String(localized: "cloudkit.status.storage.cloud")
        case .localFallback:
            return String(localized: "cloudkit.status.storage.local")
        case .inMemoryFallback:
            return String(localized: "cloudkit.status.storage.memory")
        }
    }

    var bannerTitle: String {
        storageMode == .cloudKit && lastErrorMessage != nil
            ? String(localized: "cloudkit.status.lastError")
            : statusTitle
    }

    var bannerMessage: String {
        if storageMode == .cloudKit && lastErrorMessage != nil {
            return String(localized: "cloudkit.status.banner.error")
        }

        return String(localized: "cloudkit.status.banner.issue")
    }

    var lastVisibleErrorMessage: String? {
        lastErrorMessage ?? startupErrorMessage
    }

    var debugDetails: String? {
        startupErrorMessage ?? lastErrorMessage
    }
}
