import Foundation
import UniformTypeIdentifiers
import CoreTransferable

struct ChecklistTransferData: Sendable {
    let version: Int
    let id: UUID
    let title: String
    let iconName: String
    let items: [ChecklistItemTransferData]
}

struct ChecklistItemTransferData: Sendable {
    let title: String
    let sortOrder: Int
}

// MARK: - Codable (nonisolated to avoid @MainActor inference from Transferable)

extension ChecklistTransferData: Codable {
    private enum CodingKeys: String, CodingKey {
        case version, id, title, iconName, items
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(version, forKey: .version)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(iconName, forKey: .iconName)
        try c.encode(items, forKey: .items)
    }

    nonisolated init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version  = try c.decode(Int.self,    forKey: .version)
        id       = try c.decode(UUID.self,   forKey: .id)
        title    = try c.decode(String.self, forKey: .title)
        iconName = try c.decode(String.self, forKey: .iconName)
        items    = try c.decode([ChecklistItemTransferData].self, forKey: .items)
    }
}

extension ChecklistItemTransferData: Codable {
    private enum CodingKeys: String, CodingKey {
        case title, sortOrder
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(title, forKey: .title)
        try c.encode(sortOrder, forKey: .sortOrder)
    }

    nonisolated init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title     = try c.decode(String.self, forKey: .title)
        sortOrder = try c.decode(Int.self,    forKey: .sortOrder)
    }
}

// MARK: - Transferable

extension ChecklistTransferData: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .cekcek) { transferData in
            let data = try transferData.encodeToJSON()
            let sanitizedTitle = transferData.title
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(sanitizedTitle)
                .appendingPathExtension("cekcek")
            try data.write(to: url)
            return SentTransferredFile(url)
        }
    }
}

// MARK: - Temp file export (macOS NSSharingServicePicker)

extension ChecklistTransferData {
    /// Nonisolated helper so `Encodable` is called outside any actor context.
    nonisolated func encodeToJSON() throws -> Data {
        try JSONEncoder().encode(self)
    }

    func temporaryFileURL() throws -> URL {
        let data = try encodeToJSON()
        let sanitizedTitle = title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(sanitizedTitle)
            .appendingPathExtension("cekcek")
        try data.write(to: url)
        return url
    }
}

