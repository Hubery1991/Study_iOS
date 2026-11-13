import Foundation

public enum WardrobeStoreError: Error, Equatable, Sendable {
    case unreadable
    case unwritable

    public var message: String {
        switch self {
        case .unreadable:
            return "The saved drawer could not be read."
        case .unwritable:
            return "The drawer could not be saved on this device."
        }
    }
}

public struct JSONWardrobeStore: Sendable {
    public var fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func load() throws -> WardrobeSnapshot {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .empty
        }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(WardrobeSnapshot.self, from: data)
        } catch {
            throw WardrobeStoreError.unreadable
        }
    }

    public func save(_ snapshot: WardrobeSnapshot) throws {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(snapshot)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw WardrobeStoreError.unwritable
        }
    }
}
