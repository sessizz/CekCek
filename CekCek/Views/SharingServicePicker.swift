#if os(macOS)
import AppKit

enum MacSharingService {
    static func share(items: [Any]) {
        guard let window = NSApp.keyWindow,
              let contentView = window.contentView else { return }
        let picker = NSSharingServicePicker(items: items)
        let mouseLocation = window.mouseLocationOutsideOfEventStream
        let rect = CGRect(x: mouseLocation.x, y: mouseLocation.y, width: 1, height: 1)
        picker.show(relativeTo: rect, of: contentView, preferredEdge: .minY)
    }
}
#endif
