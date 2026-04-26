import SwiftUI

#if os(iOS)
/// Floating pill bar docked to the bottom of the checklist detail screen on iOS.
/// Typing in the text field and pressing Return adds the item inline.
/// Tapping the + button opens the full add sheet.
struct FloatingAddBar: View {
    @Binding var text: String
    let onSubmit: () -> Void
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField(String(localized: "addItem.floatingPlaceholder"), text: $text)
                .font(.system(size: 16))
                .submitLabel(.done)
                .onSubmit {
                    let trimmed = text.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    onSubmit()
                }

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 26)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
                )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
#endif
