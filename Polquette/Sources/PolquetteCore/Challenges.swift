import Foundation

public struct RequirementCheck: Equatable {
    public let label: String
    public let met: Bool

    public init(label: String, met: Bool) {
        self.label = label
        self.met = met
    }
}

public struct AppointmentScore: Equatable {
    public let checks: [RequirementCheck]

    public init(checks: [RequirementCheck]) {
        self.checks = checks
    }

    public var metCount: Int { checks.filter(\.met).count }
    public var total: Int { checks.count }

    public var stars: Int {
        guard total > 0 else { return 0 }
        if metCount == total { return 3 }
        if total >= 2 && metCount == total - 1 { return 2 }
        if metCount >= 1 { return 1 }
        return 0
    }
}

public struct DesignBrief: Equatable, Identifiable {
    public let id: String
    public let title: String
    public let client: String
    public let note: String
    public let shape: NailShape?
    public let finishes: [Finish]?
    public let family: ColorFamily?
    public let french: Bool?
    public let gradient: Bool?
    public let decoration: DecorationKind?
    public let decorationMinimum: Int

    public init(
        id: String,
        title: String,
        client: String,
        note: String,
        shape: NailShape? = nil,
        finishes: [Finish]? = nil,
        family: ColorFamily? = nil,
        french: Bool? = nil,
        gradient: Bool? = nil,
        decoration: DecorationKind? = nil,
        decorationMinimum: Int = 3
    ) {
        self.id = id
        self.title = title
        self.client = client
        self.note = note
        self.shape = shape
        self.finishes = finishes
        self.family = family
        self.french = french
        self.gradient = gradient
        self.decoration = decoration
        self.decorationMinimum = decorationMinimum
    }
}

public enum Scoring {
    public static func score(_ manicure: Manicure, brief: DesignBrief) -> AppointmentScore {
        var checks: [RequirementCheck] = []
        if let shape = brief.shape {
            checks.append(RequirementCheck(
                label: "\(shape.title) shape",
                met: manicure.nails.allSatisfy { $0.shape == shape }
            ))
        }
        if let finishes = brief.finishes, !finishes.isEmpty {
            let label: String
            if finishes.count == 1 {
                label = "\(finishes[0].title) finish"
            } else if finishes == Finish.allCases.filter({ $0 != .gloss }) {
                label = "Any finish but gloss"
            } else {
                label = finishes.map(\.title).joined(separator: " or ")
            }
            checks.append(RequirementCheck(
                label: label,
                met: manicure.nails.allSatisfy { finishes.contains($0.finish) }
            ))
        }
        if let family = brief.family {
            checks.append(RequirementCheck(
                label: "\(family.title) colors",
                met: manicure.nails.allSatisfy { Palette.color(id: $0.colorID)?.family == family }
            ))
        }
        if let french = brief.french {
            checks.append(RequirementCheck(
                label: french ? "French tips" : "No French tips",
                met: manicure.nails.allSatisfy { $0.french.enabled == french }
            ))
        }
        if let gradient = brief.gradient {
            checks.append(RequirementCheck(
                label: gradient ? "A gradient" : "No gradient",
                met: manicure.nails.allSatisfy { $0.gradient.enabled == gradient }
            ))
        }
        if let decoration = brief.decoration {
            let nailsWith = manicure.nails.filter { $0.has(kind: decoration) }.count
            checks.append(RequirementCheck(
                label: "\(decoration.plural) on \(brief.decorationMinimum) nails",
                met: nailsWith >= brief.decorationMinimum
            ))
        }
        return AppointmentScore(checks: checks)
    }
}

public struct CareerProgress: Codable, Equatable {
    public var bestStars: [String: Int]

    public init(bestStars: [String: Int] = [:]) {
        self.bestStars = bestStars
    }

    public func stars(for id: String) -> Int {
        bestStars[id] ?? 0
    }

    public var totalStars: Int {
        Career.clients.reduce(0) { $0 + stars(for: $1.brief.id) }
    }

    public var unlockedCount: Int {
        Career.clients.filter { Career.isUnlocked(index: $0.index, progress: self) }.count
    }

    @discardableResult
    public mutating func record(index: Int, stars: Int) -> Bool {
        guard Career.isUnlocked(index: index, progress: self) else { return false }
        guard Career.clients.indices.contains(index) else { return false }
        let clamped = min(3, max(0, stars))
        let id = Career.clients[index].brief.id
        let current = bestStars[id] ?? 0
        guard clamped > current else { return false }
        bestStars[id] = clamped
        return true
    }
}

public struct CareerClient: Equatable, Identifiable {
    public let index: Int
    public let brief: DesignBrief

    public var id: String { brief.id }

    public init(index: Int, brief: DesignBrief) {
        self.index = index
        self.brief = brief
    }
}

public enum Career {
    public static let clients: [CareerClient] = briefs.enumerated().map { CareerClient(index: $0.offset, brief: $0.element) }

    public static func isUnlocked(index: Int, progress: CareerProgress) -> Bool {
        guard clients.indices.contains(index) else { return false }
        if index == 0 { return true }
        for earlier in 0..<index {
            if progress.stars(for: clients[earlier].brief.id) < 1 { return false }
        }
        return true
    }

    public static let briefs: [DesignBrief] = [
        DesignBrief(
            id: "blush-appointment",
            title: "Blush Pearl",
            client: "Mira, a morning guest",
            note: "Almond nails, a blush color, shimmer, and pearls on at least three nails.",
            shape: .almond,
            finishes: [.shimmer],
            family: .blush,
            decoration: .pearl,
            decorationMinimum: 3
        ),
        DesignBrief(
            id: "evening-foil",
            title: "Burgundy Foil",
            client: "Elena, after six",
            note: "Coffin nails in a berry color, a gloss finish, and gold foil on at least three nails.",
            shape: .coffin,
            finishes: [.gloss],
            family: .berry,
            decoration: .foil,
            decorationMinimum: 3
        ),
        DesignBrief(
            id: "garden-party",
            title: "Colorful Bloom",
            client: "A guest from the garden",
            note: "Oval nails, French tips, and a flower on at least three nails.",
            shape: .oval,
            french: true,
            decoration: .flower,
            decorationMinimum: 3
        ),
        DesignBrief(
            id: "quiet-gold",
            title: "Nude Gold Line",
            client: "A quiet afternoon",
            note: "Almond nails in a nude color, a cream finish, and a thin line on at least three nails.",
            shape: .almond,
            finishes: [.cream],
            family: .nude,
            decoration: .line,
            decorationMinimum: 3
        ),
        DesignBrief(
            id: "midnight-chrome",
            title: "Midnight Chrome",
            client: "A late booking",
            note: "Stiletto nails in a dark color, with a chrome finish.",
            shape: .stiletto,
            finishes: [.chrome],
            family: .dark
        ),
        DesignBrief(
            id: "sage-cream",
            title: "Sage Cream",
            client: "A Saturday regular",
            note: "Square nails in green, with a cream finish.",
            shape: .square,
            finishes: [.cream],
            family: .green
        ),
        DesignBrief(
            id: "coral-glitter",
            title: "Coral Glitter",
            client: "A birthday table",
            note: "Oval nails in coral, covered in glitter.",
            shape: .oval,
            finishes: [.glitter],
            family: .coral
        ),
        DesignBrief(
            id: "ivory-french",
            title: "Ivory French",
            client: "A classic request",
            note: "Rounded nails in a nude color, gloss, with French tips.",
            shape: .rounded,
            finishes: [.gloss],
            family: .nude,
            french: true
        ),
        DesignBrief(
            id: "lilac-gem",
            title: "Lilac Gem",
            client: "A lilac hour",
            note: "Almond nails in lilac, shimmer, and a gem on at least three nails.",
            shape: .almond,
            finishes: [.shimmer],
            family: .lilac,
            decoration: .gem,
            decorationMinimum: 3
        ),
        DesignBrief(
            id: "dawn-gradient",
            title: "Dawn Gradient",
            client: "First light",
            note: "A gradient on every nail, in a coral color, with gloss.",
            finishes: [.gloss],
            family: .coral,
            gradient: true
        ),
        DesignBrief(
            id: "pearl-row",
            title: "Pearl Row",
            client: "A wedding guest",
            note: "Gloss on every nail, and a pearl on all five.",
            finishes: [.gloss],
            decoration: .pearl,
            decorationMinimum: 5
        ),
        DesignBrief(
            id: "house-signature",
            title: "House Signature",
            client: "The owner's chair",
            note: "Any finish except gloss, and a gem on at least three nails.",
            finishes: Finish.allCases.filter { $0 != .gloss },
            decoration: .gem,
            decorationMinimum: 3
        ),
    ]
}

public struct ChallengeRecord: Codable, Equatable {
    public var bestStarsByDay: [String: Int]

    public init(bestStarsByDay: [String: Int] = [:]) {
        self.bestStarsByDay = bestStarsByDay
    }

    public func stars(on day: String) -> Int {
        bestStarsByDay[day] ?? 0
    }

    @discardableResult
    public mutating func record(day: String, stars: Int) -> Bool {
        let clamped = min(3, max(0, stars))
        let current = bestStarsByDay[day] ?? 0
        guard clamped > current else { return false }
        bestStarsByDay[day] = clamped
        return true
    }
}

public enum DailyChallenge {
    public static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    public static let catalog: [DesignBrief] = [
        retitle(Career.briefs[0], id: "daily-blush", title: "Today: Blush Pearl"),
        retitle(Career.briefs[1], id: "daily-foil", title: "Today: Burgundy Foil"),
        retitle(Career.briefs[2], id: "daily-bloom", title: "Today: Colorful Bloom"),
        retitle(Career.briefs[3], id: "daily-gold", title: "Today: Nude Gold Line"),
        retitle(Career.briefs[4], id: "daily-chrome", title: "Today: Midnight Chrome"),
        retitle(Career.briefs[5], id: "daily-sage", title: "Today: Sage Cream"),
        retitle(Career.briefs[6], id: "daily-glitter", title: "Today: Coral Glitter"),
        retitle(Career.briefs[7], id: "daily-french", title: "Today: Ivory French"),
        retitle(Career.briefs[8], id: "daily-gem", title: "Today: Lilac Gem"),
        retitle(Career.briefs[9], id: "daily-dawn", title: "Today: Dawn Gradient"),
    ]

    public static func brief(on date: Date, calendar: Calendar = DailyChallenge.calendar) -> DesignBrief {
        catalog[index(for: date, calendar: calendar)]
    }

    public static func index(for date: Date, calendar: Calendar = DailyChallenge.calendar) -> Int {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let year = parts.year ?? 0
        let month = parts.month ?? 1
        let day = parts.day ?? 1
        let seed = year * 400 + month * 32 + day
        let count = catalog.count
        let mod = seed % count
        return mod >= 0 ? mod : mod + count
    }

    public static func dayKey(on date: Date, calendar: Calendar = DailyChallenge.calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let year = parts.year ?? 0
        let month = parts.month ?? 1
        let day = parts.day ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private static func retitle(_ brief: DesignBrief, id: String, title: String) -> DesignBrief {
        DesignBrief(
            id: id,
            title: title,
            client: brief.client,
            note: brief.note,
            shape: brief.shape,
            finishes: brief.finishes,
            family: brief.family,
            french: brief.french,
            gradient: brief.gradient,
            decoration: brief.decoration,
            decorationMinimum: brief.decorationMinimum
        )
    }
}
