import Foundation

public enum SamplePhoto {
    public static let everyday = "sample-everyday.jpg"
    public static let evening = "sample-evening.jpg"
    public static let work = "sample-work.jpg"
    public static let fileNames = [everyday, evening, work]
}

public enum SampleID {
    public static let everyday = UUID(uuidString: "A1A1A1A1-0000-4000-8000-000000000001")!
    public static let work = UUID(uuidString: "A1A1A1A1-0000-4000-8000-000000000002")!
    public static let evening = UUID(uuidString: "A1A1A1A1-0000-4000-8000-000000000003")!
}

public enum SampleCatalog {
    public static func document(now: Date, calendar: Calendar) -> JournalDocument {
        let today = calendar.startOfDay(for: now)
        let workDay = calendar.date(byAdding: .day, value: -3, to: today) ?? today
        let eveningDay = calendar.date(byAdding: .day, value: -6, to: today) ?? today

        let everyday = MakeupLook(
            id: SampleID.everyday,
            title: "Soft peach morning",
            wornOn: today,
            styleTags: [.natural, .weekend],
            products: [
                UsedProduct(id: UUID(uuidString: "B1B1B1B1-0000-4000-8000-000000000011")!, name: "Peach coral satin", kind: .lipstick),
                UsedProduct(id: UUID(uuidString: "B1B1B1B1-0000-4000-8000-000000000012")!, name: "Light ivory veil", kind: .foundation),
                UsedProduct(id: UUID(uuidString: "B1B1B1B1-0000-4000-8000-000000000013")!, name: "Warm apricot cream", kind: .blush),
                UsedProduct(id: UUID(uuidString: "B1B1B1B1-0000-4000-8000-000000000014")!, name: "Soft brown", kind: .mascara)
            ],
            notes: "Errands and a cream sweater. Skin still looks like skin. No heavy liner.",
            isFavorite: false,
            photoFileName: SamplePhoto.everyday,
            recreatedFrom: nil,
            createdAt: now,
            updatedAt: now
        )

        let work = MakeupLook(
            id: SampleID.work,
            title: "Office berry",
            wornOn: workDay,
            styleTags: [.work],
            products: [
                UsedProduct(id: UUID(uuidString: "B1B1B1B1-0000-4000-8000-000000000021")!, name: "Berry silk", kind: .lipstick),
                UsedProduct(id: UUID(uuidString: "B1B1B1B1-0000-4000-8000-000000000022")!, name: "Taupe wash", kind: .eyeshadow),
                UsedProduct(id: UUID(uuidString: "B1B1B1B1-0000-4000-8000-000000000023")!, name: "Soft blonde pencil", kind: .brow),
                UsedProduct(id: UUID(uuidString: "B1B1B1B1-0000-4000-8000-000000000024")!, name: "Light ivory veil", kind: .foundation),
                UsedProduct(id: UUID(uuidString: "B1B1B1B1-0000-4000-8000-000000000025")!, name: "Fine brown", kind: .liner)
            ],
            notes: "Office windows, a white blouse, and a berry lip that does the talking.",
            isFavorite: false,
            photoFileName: SamplePhoto.work,
            recreatedFrom: nil,
            createdAt: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
            updatedAt: calendar.date(byAdding: .day, value: -3, to: now) ?? now
        )

        let evening = MakeupLook(
            id: SampleID.evening,
            title: "Rose after dark",
            wornOn: eveningDay,
            styleTags: [.evening, .party],
            products: [
                UsedProduct(id: UUID(uuidString: "B1B1B1B1-0000-4000-8000-000000000031")!, name: "Rose velvet", kind: .lipstick),
                UsedProduct(id: UUID(uuidString: "B1B1B1B1-0000-4000-8000-000000000032")!, name: "Smoked plum", kind: .eyeshadow),
                UsedProduct(id: UUID(uuidString: "B1B1B1B1-0000-4000-8000-000000000033")!, name: "Black wing", kind: .liner),
                UsedProduct(id: UUID(uuidString: "B1B1B1B1-0000-4000-8000-000000000034")!, name: "Cool rose", kind: .blush),
                UsedProduct(id: UUID(uuidString: "B1B1B1B1-0000-4000-8000-000000000035")!, name: "Inner-corner pearl", kind: .highlighter)
            ],
            notes: "Dinner lighting. This is the rose lipstick to repeat.",
            isFavorite: true,
            photoFileName: SamplePhoto.evening,
            recreatedFrom: nil,
            createdAt: calendar.date(byAdding: .day, value: -6, to: now) ?? now,
            updatedAt: calendar.date(byAdding: .day, value: -6, to: now) ?? now
        )

        return JournalDocument(
            journal: LookJournal(looks: [everyday, work, evening]),
            reminder: .off,
            didInstallSamples: true
        )
    }
}

public struct JournalDocument: Codable, Equatable, Sendable {
    public static let currentSchema = 1

    public var schema: Int
    public var journal: LookJournal
    public var reminder: ReminderPreference
    public var didInstallSamples: Bool

    public init(
        journal: LookJournal,
        reminder: ReminderPreference,
        didInstallSamples: Bool,
        schema: Int = JournalDocument.currentSchema
    ) {
        self.schema = schema
        self.journal = journal
        self.reminder = reminder
        self.didInstallSamples = didInstallSamples
    }
}

public enum JournalStoreError: Error, Equatable, Sendable {
    case unreadable
}

public struct JournalFileStore {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func load() throws -> JournalDocument? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: fileURL)
        do {
            return try Self.decoder.decode(JournalDocument.self, from: data)
        } catch {
            throw JournalStoreError.unreadable
        }
    }

    public func save(_ document: JournalDocument) throws {
        let folder = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let data = try Self.encoder.encode(document)
        try data.write(to: fileURL, options: .atomic)
    }

    public func loadOrSeed(now: Date, calendar: Calendar) throws -> (document: JournalDocument, seeded: Bool) {
        if let existing = try load() {
            return (existing, false)
        }
        let seeded = SampleCatalog.document(now: now, calendar: calendar)
        try save(seeded)
        return (seeded, true)
    }

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
}
