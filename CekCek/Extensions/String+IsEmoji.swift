import Foundation

extension String {
    /// Returns true when the string is an emoji character rather than an SF Symbol name.
    /// SF Symbol names consist only of ASCII letters, digits, dots, and hyphens.
    var isEmoji: Bool {
        guard !isEmpty else { return false }
        return unicodeScalars.contains { $0.value > 127 }
    }
}
