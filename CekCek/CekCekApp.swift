import SwiftUI
import SwiftData

@main
struct CekCekApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    let modelContainer: ModelContainer
    let cloudKitSyncMonitor: CloudKitSyncMonitor
    let marketplaceAuthService: MarketplaceAuthService
    let marketplaceAPIService: MarketplaceAPIService

    init() {
        let syncMonitor = CloudKitSyncMonitor()
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: Checklist.self,
                ChecklistItem.self,
                CompletionRecord.self,
                CompletionRecordItem.self,
                configurations: ModelConfiguration(
                    cloudKitDatabase: .automatic
                )
            )
            syncMonitor.setStartupResult(mode: .cloudKit)
        } catch {
            print("CloudKit ModelContainer failed: \(error)")
            syncMonitor.setStartupResult(mode: .localFallback, error: error)
            do {
                container = try ModelContainer(
                    for: Checklist.self,
                    ChecklistItem.self,
                    CompletionRecord.self,
                    CompletionRecordItem.self,
                    configurations: ModelConfiguration(
                        cloudKitDatabase: .none
                    )
                )
            } catch {
                print("Local ModelContainer failed: \(error)")
                syncMonitor.setStartupResult(mode: .inMemoryFallback, error: error)
                container = try! ModelContainer(
                    for: Checklist.self,
                    ChecklistItem.self,
                    CompletionRecord.self,
                    CompletionRecordItem.self,
                    configurations: ModelConfiguration(
                        isStoredInMemoryOnly: true,
                        cloudKitDatabase: .none
                    )
                )
            }
        }

        self.cloudKitSyncMonitor = syncMonitor
        self.modelContainer = container
        self.marketplaceAuthService = MarketplaceAuthService()
        self.marketplaceAPIService = MarketplaceAPIService()
        let context = ModelContext(container)
        DefaultDataSeeder.seedIfNeeded(context: context)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cloudKitSyncMonitor)
                .environmentObject(marketplaceAuthService)
                .environmentObject(marketplaceAPIService)
                #if os(macOS)
                .handlesExternalEvents(preferring: Set(arrayLiteral: "file"), allowing: Set(arrayLiteral: "file"))
                #endif
                .onAppear {
                    #if os(macOS)
                    NSApplication.shared.registerForRemoteNotifications()
                    #else
                    UIApplication.shared.registerForRemoteNotifications()
                    #endif
                }
                .task {
                    await marketplaceAuthService.restoreSessionIfNeeded()
                }
        }
        #if os(macOS)
        .handlesExternalEvents(matching: Set(arrayLiteral: "file"))
        #endif
        .modelContainer(modelContainer)
    }
}
