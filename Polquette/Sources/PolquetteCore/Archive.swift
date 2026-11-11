import Foundation

public struct SavedLook: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var manicure: Manicure
    public var savedAt: Date

    public init(id: UUID, name: String, manicure: Manicure, savedAt: Date) {
        self.id = id
        self.name = name
        self.manicure = manicure
        self.savedAt = savedAt
    }
}

public struct SalonArchive: Codable, Equatable {
    public var looks: [SavedLook]
    public var career: CareerProgress
    public var challenges: ChallengeRecord
    public var hapticsEnabled: Bool
    public var hasSeenPrimer: Bool

    public init(
        looks: [SavedLook] = [],
        career: CareerProgress = CareerProgress(),
        challenges: ChallengeRecord = ChallengeRecord(),
        hapticsEnabled: Bool = true,
        hasSeenPrimer: Bool = false
    ) {
        self.looks = looks
        self.career = career
        self.challenges = challenges
        self.hapticsEnabled = hapticsEnabled
        self.hasSeenPrimer = hasSeenPrimer
    }

    public static let empty = SalonArchive()

    public static func cleanedName(_ raw: String) -> String {
        let collapsed = raw.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        if collapsed.isEmpty { return "Untitled look" }
        if collapsed.count <= 40 { return collapsed }
        return String(collapsed.prefix(40))
    }

    @discardableResult
    public mutating func saveLook(name: String, manicure: Manicure, now: Date = Date(), id: UUID = UUID()) -> SavedLook {
        var stored = manicure
        let cleaned = Self.cleanedName(name)
        stored.name = cleaned
        let look = SavedLook(id: id, name: cleaned, manicure: stored, savedAt: now)
        looks.insert(look, at: 0)
        return look
    }

    @discardableResult
    public mutating func deleteLook(id: UUID) -> Bool {
        guard let index = looks.firstIndex(where: { $0.id == id }) else { return false }
        looks.remove(at: index)
        return true
    }

    public func look(id: UUID) -> SavedLook? {
        looks.first { $0.id == id }
    }

    public mutating func resetProgress() {
        looks = []
        career = CareerProgress()
        challenges = ChallengeRecord()
    }
}

public struct SalonStore {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func load() throws -> SalonArchive {
        guard FileManager.default.fileExists(atPath: url.path) else { return .empty }
        let data = try Data(contentsOf: url)
        let archive = try Self.decoder.decode(SalonArchive.self, from: data)
        return archive
    }

    public func save(_ archive: SalonArchive) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try Self.encoder.encode(archive)
        try data.write(to: url, options: .atomic)
    }

    public static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    public static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
