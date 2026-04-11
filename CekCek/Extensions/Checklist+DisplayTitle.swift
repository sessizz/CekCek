import Foundation

extension Checklist {
    var displayTitle: String {
        if let custom = customTitle, !custom.isEmpty {
            return custom
        }
        return String(localized: String.LocalizationValue(titleKey))
    }
}
