import SwiftUI

/// Small "çekçek" wordmark shown in the navigation bar principal slot on iOS.
/// "çek" in primary color + "çek" in accent color, lowercase, slightly custom weight.
struct CekCekLogoView: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("çek")
                .foregroundStyle(.primary)
            Text("çek")
                .foregroundStyle(Color.accentColor)
        }
        .font(.system(size: 18, weight: .semibold, design: .rounded))
        .kerning(-0.3)
    }
}
