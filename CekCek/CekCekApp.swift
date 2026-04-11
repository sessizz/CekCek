import SwiftUI
import SwiftData

@main
struct CekCekApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    let modelContainer: ModelContainer

    init() {
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
        } catch {
            print("CloudKit ModelContainer failed: \(error)")
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

        self.modelContainer = container
        let context = ModelContext(container)
        DefaultDataSeeder.seedIfNeeded(context: context)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    #if os(macOS)
                    NSApplication.shared.registerForRemoteNotifications()
                    #else
                    UIApplication.shared.registerForRemoteNotifications()
                    #endif
                }
        }
        .modelContainer(modelContainer)
    }
}
