import Foundation

public enum StyleTag: String, Codable, CaseIterable, Sendable, Equatable {
    case natural
    case work
    case evening
    case weekend
    case party

    public var title: String {
        switch self {
        case .natural: return "Natural"
        case .work: return "Work"
        case .evening: return "Evening"
        case .weekend: return "Weekend"
        case .party: return "Party"
        }
    }
}

public enum ProductKind: String, Codable, CaseIterable, Sendable, Equatable {
    case lipstick
    case eyeshadow
    case foundation
    case blush
    case liner
    case brow
    case mascara
    case bronzer
    case highlighter
    case primer
    case powder
    case other

    public var title: String {
        switch self {
        case .lipstick: return "Lipstick"
        case .eyeshadow: return "Eyeshadow"
        case .foundation: return "Foundation"
        case .blush: return "Blush"
        case .liner: return "Liner"
        case .brow: return "Brow"
        case .mascara: return "Mascara"
        case .bronzer: return "Bronzer"
        case .highlighter: return "Highlighter"
        case .primer: return "Primer"
        case .powder: return "Powder"
        case .other: return "Other"
        }
    }
}

public struct UsedProduct: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var kind: ProductKind

    public init(id: UUID = UUID(), name: String, kind: ProductKind) {
        self.id = id
        self.name = name
        self.kind = kind
    }
}

public struct MakeupLook: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var wornOn: Date
    public var styleTags: [StyleTag]
    public var products: [UsedProduct]
    public var notes: String
    public var isFavorite: Bool
    public var photoFileName: String?
    public var recreatedFrom: UUID?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID,
        title: String,
        wornOn: Date,
        styleTags: [StyleTag],
        products: [UsedProduct],
        notes: String,
        isFavorite: Bool,
        photoFileName: String?,
        recreatedFrom: UUID?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.wornOn = wornOn
        self.styleTags = styleTags
        self.products = products
        self.notes = notes
        self.isFavorite = isFavorite
        self.photoFileName = photoFileName
        self.recreatedFrom = recreatedFrom
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var productSummary: String {
        let names = products.map(\.name).filter { !$0.isEmpty }
        if names.isEmpty {
            return "No products listed"
        }
        if names.count <= 3 {
            return names.joined(separator: ", ")
        }
        let head = names.prefix(3).joined(separator: ", ")
        return "\(head), +\(names.count - 3)"
    }
}

public enum LookLimits {
    public static let title = 80
    public static let notes = 2000
    public static let productName = 60
    public static let products = 24
    public static let photoFileName = 120
}

public enum LookDraftError: Error, Equatable, Sendable {
    case titleEmpty
    case titleTooLong(limit: Int)
    case missingStyleTag
    case productNameEmpty(index: Int)
    case productNameTooLong(index: Int, limit: Int)
    case duplicateProductName(String)
    case tooManyProducts(limit: Int)
    case notesTooLong(limit: Int)
    case unsafePhotoFileName

    public var message: String {
        switch self {
        case .titleEmpty:
            return "Give this look a title."
        case .titleTooLong(let limit):
            return "The title can be \(limit) characters at most."
        case .missingStyleTag:
            return "Choose at least one style."
        case .productNameEmpty:
            return "Every product needs a name, or remove the empty row."
        case .productNameTooLong(_, let limit):
            return "A product name can be \(limit) characters at most."
        case .duplicateProductName(let name):
            return "\(name) is listed twice. Keep one row for each product."
        case .tooManyProducts(let limit):
            return "A look can list \(limit) products at most."
        case .notesTooLong(let limit):
            return "Notes can be \(limit) characters at most."
        case .unsafePhotoFileName:
            return "That photo could not be stored with the look."
        }
    }
}

public struct ValidatedLook: Equatable, Sendable {
    public var title: String
    public var wornOn: Date
    public var styleTags: [StyleTag]
    public var products: [UsedProduct]
    public var notes: String
    public var isFavorite: Bool
    public var photoFileName: String?
}

public struct LookDraft: Equatable, Sendable {
    public var title: String
    public var wornOn: Date
    public var styleTags: [StyleTag]
    public var products: [UsedProduct]
    public var notes: String
    public var isFavorite: Bool
    public var photoFileName: String?

    public init(
        title: String = "",
        wornOn: Date = Date(),
        styleTags: [StyleTag] = [],
        products: [UsedProduct] = [],
        notes: String = "",
        isFavorite: Bool = false,
        photoFileName: String? = nil
    ) {
        self.title = title
        self.wornOn = wornOn
        self.styleTags = styleTags
        self.products = products
        self.notes = notes
        self.isFavorite = isFavorite
        self.photoFileName = photoFileName
    }

    public func validate() throws -> ValidatedLook {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            throw LookDraftError.titleEmpty
        }
        if trimmedTitle.count > LookLimits.title {
            throw LookDraftError.titleTooLong(limit: LookLimits.title)
        }

        let tags = StyleTag.allCases.filter { styleTags.contains($0) }
        if tags.isEmpty {
            throw LookDraftError.missingStyleTag
        }

        if products.count > LookLimits.products {
            throw LookDraftError.tooManyProducts(limit: LookLimits.products)
        }

        var cleaned: [UsedProduct] = []
        var seen: Set<String> = []
        for (index, product) in products.enumerated() {
            let name = product.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty {
                throw LookDraftError.productNameEmpty(index: index)
            }
            if name.count > LookLimits.productName {
                throw LookDraftError.productNameTooLong(index: index, limit: LookLimits.productName)
            }
            let key = name.lowercased()
            if seen.contains(key) {
                throw LookDraftError.duplicateProductName(name)
            }
            seen.insert(key)
            cleaned.append(UsedProduct(id: product.id, name: name, kind: product.kind))
        }

        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedNotes.count > LookLimits.notes {
            throw LookDraftError.notesTooLong(limit: LookLimits.notes)
        }

        let photo = try Self.cleanedPhotoFileName(photoFileName)

        return ValidatedLook(
            title: trimmedTitle,
            wornOn: wornOn,
            styleTags: tags,
            products: cleaned,
            notes: trimmedNotes,
            isFavorite: isFavorite,
            photoFileName: photo
        )
    }

    public static func isSafePhotoFileName(_ name: String) -> Bool {
        (try? cleanedPhotoFileName(name)) != nil && !(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    static func cleanedPhotoFileName(_ raw: String?) throws -> String? {
        guard let raw else { return nil }
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { return nil }
        if name.count > LookLimits.photoFileName {
            throw LookDraftError.unsafePhotoFileName
        }
        if name.contains("/") || name.contains("\\") || name.contains("..") {
            throw LookDraftError.unsafePhotoFileName
        }
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-")
        if name.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            throw LookDraftError.unsafePhotoFileName
        }
        guard let dot = name.lastIndex(of: ".") else {
            throw LookDraftError.unsafePhotoFileName
        }
        let stem = name[..<dot]
        let ext = name[name.index(after: dot)...].lowercased()
        if stem.isEmpty || !["jpg", "jpeg", "png"].contains(ext) {
            throw LookDraftError.unsafePhotoFileName
        }
        return name
    }
}
