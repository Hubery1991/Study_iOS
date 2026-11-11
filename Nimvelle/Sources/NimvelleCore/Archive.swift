import Foundation

public enum StudioArchive {
    public static func data(from studio: Studio) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(studio)
    }

    public static func studio(from data: Data) throws -> Studio {
        try JSONDecoder().decode(Studio.self, from: data)
    }
}
