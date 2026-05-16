import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedChecklist: Checklist?
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var cloudKitSyncMonitor: CloudKitSyncMonitor
    @State private var showImportSuccess = false
    @State private var showImportError = false
    @State private var importErrorMessage = ""
    @State private var showTemporaryStorageWarning = false

    var body: some View {
        TabView {
            checklistNavigation
                .tabItem {
                    Label(String(localized: "tab.myLists"), systemImage: "checklist")
                }

            MarketplaceTabView()
                .tabItem {
                    Label(String(localized: "marketplace.title"), systemImage: "shippingbox")
                }
        }
        .onOpenURL { url in
            handleImport(url: url)
        }
        .onAppear {
            if cloudKitSyncMonitor.storageMode == .inMemoryFallback {
                showTemporaryStorageWarning = true
            }
        }
        .safeAreaInset(edge: .top) {
            if cloudKitSyncMonitor.shouldShowIssueBanner {
                CloudKitStatusBanner()
            }
        }
        #if os(iOS)
        .onReceive(NotificationCenter.default.publisher(for: .cekcekFileOpened)) { notification in
            if let url = notification.object as? URL {
                handleImport(url: url)
            }
        }
        #endif
        .alert(String(localized: "import.success"), isPresented: $showImportSuccess) {
            Button(String(localized: "common.done")) {}
        } message: {
            Text(String(localized: "import.successMessage"))
        }
        .alert(String(localized: "import.error"), isPresented: $showImportError) {
            Button(String(localized: "common.done")) {}
        } message: {
            Text(importErrorMessage)
        }
        .alert(String(localized: "storage.temporary.title"), isPresented: $showTemporaryStorageWarning) {
            Button(String(localized: "common.done")) {}
        } message: {
            Text(String(localized: "storage.temporary.message"))
        }
    }

    private var checklistNavigation: some View {
        NavigationSplitView {
            ChecklistListView(selectedChecklist: $selectedChecklist)
            #if os(macOS)
                .navigationSplitViewColumnWidth(min: 220, ideal: 280)
            #endif
        } detail: {
            if let checklist = selectedChecklist {
                ChecklistDetailView(checklist: checklist)
            } else {
                EmptyStateView()
            }
        }
    }

    private func handleImport(url: URL) {
        do {
            try ChecklistImporter.importChecklist(from: url, context: modelContext)
            showImportSuccess = true
        } catch {
            importErrorMessage = error.localizedDescription
            showImportError = true
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Checklist.self, ChecklistItem.self, CompletionRecord.self], inMemory: true)
        .environmentObject(CloudKitSyncMonitor())
        .environmentObject(MarketplaceAuthService())
        .environmentObject(MarketplaceAPIService())
}
