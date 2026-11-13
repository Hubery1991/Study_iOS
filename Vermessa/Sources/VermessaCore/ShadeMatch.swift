import Foundation

public struct ShadeScore: Equatable, Sendable {
    public var occasionPoints: Int
    public var undertonePoints: Int
    public var recencyPoints: Int
    public var daysSinceWorn: Int?
    public var reasons: [String]

    public var total: Int {
        occasionPoints + undertonePoints + recencyPoints
    }

    public init(occasionPoints: Int, undertonePoints: Int, recencyPoints: Int, daysSinceWorn: Int?, reasons: [String]) {
        self.occasionPoints = occasionPoints
        self.undertonePoints = undertonePoints
        self.recencyPoints = recencyPoints
        self.daysSinceWorn = daysSinceWorn
        self.reasons = reasons
    }
}

public struct ShadeRecommendation: Equatable, Identifiable, Sendable {
    public var lipstick: Lipstick
    public var score: ShadeScore

    public var id: UUID { lipstick.id }

    public init(lipstick: Lipstick, score: ShadeScore) {
        self.lipstick = lipstick
        self.score = score
    }
}

public struct RecommendationQuery: Equatable, Sendable {
    public var occasion: Occasion?
    public var undertone: Undertone?
    public var day: CalendarDay
    public var limit: Int

    public init(occasion: Occasion? = nil, undertone: Undertone? = nil, day: CalendarDay, limit: Int = 8) {
        self.occasion = occasion
        self.undertone = undertone
        self.day = day
        self.limit = limit
    }
}

/// Scores lipsticks the person already owns. Points are intentionally small and additive:
/// occasion up to 40, undertone up to 30, recency up to 30.
public enum ShadeMatch {
    public static func occasionPoints(tags: [Occasion], requested: Occasion?) -> Int {
        guard let requested else { return 16 }
        if tags.contains(requested) { return 40 }
        if tags.isEmpty { return 10 }
        return 0
    }

    public static func undertonePoints(shade: Undertone, requested: Undertone?) -> Int {
        guard let requested else { return 12 }
        if shade == requested { return 30 }
        if shade == .neutral { return 14 }
        if requested == .neutral { return 10 }
        return 0
    }

    /// `nil` means the shade has never been logged on or before the requested day.
    public static func recencyPoints(daysSinceWorn: Int?) -> Int {
        guard let daysSinceWorn else { return 26 }
        if daysSinceWorn <= 0 { return 0 }
        switch daysSinceWorn {
        case 1: return 4
        case 2...3: return 8
        case 4...6: return 14
        case 7...13: return 20
        case 14...29: return 26
        default: return 30
        }
    }

    public static func occasionReason(tags: [Occasion], requested: Occasion?) -> String {
        guard let requested else { return "Any occasion" }
        if tags.contains(requested) { return "Fits \(requested.title.lowercased())" }
        if tags.isEmpty { return "Occasion not set" }
        return "Another occasion"
    }

    public static func undertoneReason(shade: Undertone, requested: Undertone?) -> String {
        guard let requested else { return "Any undertone" }
        if shade == requested { return "Matches \(requested.title.lowercased())" }
        if shade == .neutral { return "Neutral can bridge \(requested.title.lowercased())" }
        if requested == .neutral { return "Close to neutral" }
        return "Opposite undertone"
    }

    public static func recencyReason(daysSinceWorn: Int?) -> String {
        guard let daysSinceWorn else { return "Not worn yet" }
        if daysSinceWorn <= 0 { return "Worn today" }
        if daysSinceWorn == 1 { return "Worn yesterday" }
        return "Quiet for \(daysSinceWorn) days"
    }

    public static func score(
        lipstick: Lipstick,
        daysSinceWorn: Int?,
        query: RecommendationQuery
    ) -> ShadeScore {
        let occasion = occasionPoints(tags: lipstick.occasions, requested: query.occasion)
        let undertone = undertonePoints(shade: lipstick.undertone, requested: query.undertone)
        let recency = recencyPoints(daysSinceWorn: daysSinceWorn)
        return ShadeScore(
            occasionPoints: occasion,
            undertonePoints: undertone,
            recencyPoints: recency,
            daysSinceWorn: daysSinceWorn,
            reasons: [
                occasionReason(tags: lipstick.occasions, requested: query.occasion),
                undertoneReason(shade: lipstick.undertone, requested: query.undertone),
                recencyReason(daysSinceWorn: daysSinceWorn)
            ]
        )
    }
}
