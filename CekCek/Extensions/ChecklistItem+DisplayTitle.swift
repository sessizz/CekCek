import Foundation

extension ChecklistItem {
    var displayTitle: String {
        if let custom = customTitle, !custom.isEmpty {
            return custom
        }
        return String(localized: String.LocalizationValue(titleKey))
    }
}
