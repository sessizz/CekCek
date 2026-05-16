import SwiftUI

// MARK: - Shared icon picker used by Add & Edit checklist sheets

struct IconPickerGrid: View {
    @Binding var selectedIcon: String

    // ── SF Symbols ──────────────────────────────────────────────
    private let symbolGroups: [(String, [String])] = [
        ("iconGroup.vehicleTravel", [
            "car.side", "bus", "truck.box", "bicycle",
            "airplane", "ferry", "tram", "fuelpump",
            "road.lanes", "map", "location.circle", "compass.drawing",
        ]),
        ("iconGroup.campingNature", [
            "tent", "mountain.2", "tree", "leaf",
            "flame", "drop", "wind", "snowflake",
            "sun.max", "cloud", "cloud.rain", "moon.stars",
        ]),
        ("iconGroup.tools", [
            "wrench.and.screwdriver", "hammer", "screwdriver",
            "bolt", "gear", "gearshape.2",
            "powerplug", "battery.100", "lightbulb", "flashlight.on.fill",
            "wrench", "archivebox",
        ]),
        ("iconGroup.general", [
            "checklist", "list.bullet", "doc.text", "folder",
            "star", "heart", "flag", "bell",
            "calendar", "clock", "house", "person",
        ]),
    ]

    // ── Emoji ────────────────────────────────────────────────────
    private let emojiGroups: [(String, [String])] = [
        ("iconGroup.vehicleTravel", [
            "🚗","🚙","🚌","🚛","🚐","🛻","🏕️","🚑","🚒","🚓",
            "✈️","🚢","🛳️","🛤️","⛽","🗺️","🧭","📍",
        ]),
        ("iconGroup.campingNature", [
            "⛺","🏔️","🌲","🌿","🍀","🔥","💧","❄️",
            "☀️","🌤️","🌧️","🌙","⭐","🌸","🍂","🌊",
        ]),
        ("iconGroup.tools", [
            "🔧","🔨","🪛","⚙️","🔩","🪜","🧰","🪝",
            "🔑","🗝️","💡","🔦","🧲","🪣","🧹","🪤",
        ]),
        ("iconGroup.general", [
            "✅","📋","📝","📌","🎯","🏆","❤️","⭐",
            "🔔","📅","🏠","👤","💼","🎒","🧳","📦",
        ]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // SF Symbols bölümü
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(symbolGroups, id: \.0) { group in
                        Text(String(localized: String.LocalizationValue(group.0)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                            spacing: 8
                        ) {
                            ForEach(group.1, id: \.self) { icon in
                                IconCell(name: icon, isSelected: selectedIcon == icon) {
                                    selectedIcon = icon
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            } label: {
                Label(String(localized: "iconPicker.sfSymbols"), systemImage: "square.grid.2x2")
                    .font(.subheadline.weight(.semibold))
            }

            // Emoji bölümü
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(emojiGroups, id: \.0) { group in
                        Text(String(localized: String.LocalizationValue(group.0)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                            spacing: 8
                        ) {
                            ForEach(group.1, id: \.self) { emoji in
                                EmojiCell(emoji: emoji, isSelected: selectedIcon == emoji) {
                                    selectedIcon = emoji
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            } label: {
                Label(String(localized: "iconPicker.emoji"), systemImage: "face.smiling")
                    .font(.subheadline.weight(.semibold))
            }
        }
    }
}

// MARK: - SF Symbol cell

private struct IconCell: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Emoji cell

private struct EmojiCell: View {
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}
