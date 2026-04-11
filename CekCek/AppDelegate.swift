#if os(iOS)
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        NotificationCenter.default.post(name: .cekcekFileOpened, object: url)
        return true
    }
}

extension Notification.Name {
    static let cekcekFileOpened = Notification.Name("cekcekFileOpened")
}
#endif
