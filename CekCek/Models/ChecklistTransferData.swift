import Foundation
import UniformTypeIdentifiers
import CoreTransferable

struct ChecklistTransferData: Codable, Sendable {
    let version: Int
    let id: UUID
    let title: String
    let iconName: String
    let items: [ChecklistItemTransferData]
}

struct ChecklistItemTransferData: Codable, Sendable {
    let title: String
    let sortOrder: Int
}

// MARK: - Transferable

extension ChecklistTransferData: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .cekcek) { transferData in
            let data = try JSONEncoder().encode(transferData)
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
    func temporaryFileURL() throws -> URL {
        let data = try JSONEncoder().encode(self)
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

