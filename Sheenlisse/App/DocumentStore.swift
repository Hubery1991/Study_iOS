import Foundation

enum DocumentStore {
    static func load() -> MirrorDocument {
        guard let data = try? Data(contentsOf: fileURL()),
              let document = try? MirrorDocument.decodeData(data) else {
            return .initial
        }
        return document
    }

    static func save(_ document: MirrorDocument) {
        guard let data = try? document.encodeData() else { return }
        let url = fileURL()
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: url, options: .atomic)
    }

    private static func fileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("Sheenlisse", isDirectory: true)
            .appendingPathComponent("mirror.json")
    }
}
