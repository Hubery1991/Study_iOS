import Foundation

public struct SuggestQuery: Equatable {
    public var occasion: Occasion
    public var weather: WeatherChoice
    public var season: Season
    public var day: DayStamp
    public var repeatWindowDays: Int
    public var limit: Int

    public init(
        occasion: Occasion,
        weather: WeatherChoice,
        season: Season,
        day: DayStamp,
        repeatWindowDays: Int = 7,
        limit: Int = 6
    ) {
        self.occasion = occasion
        self.weather = weather
        self.season = season
        self.day = day
        self.repeatWindowDays = min(21, max(3, repeatWindowDays))
        self.limit = max(1, limit)
    }
}

public struct SuggestedLook: Equatable, Identifiable {
    public var pieces: [Garment]
    public var score: Int
    public var reasons: [String]
    public var title: String
    public var signature: String

    public var id: String { signature }
}

public enum ColorHarmony {
    public static func score(of colors: [GarmentColor]) -> Int {
        let unique = Array(Set(colors))
        if unique.isEmpty { return 0 }
        let accents = unique.filter { !$0.isNeutral }
        if accents.isEmpty { return 12 }
        if accents.count == 1 { return 14 }
        if accents.count == 2 {
            return related(accents[0], accents[1]) ? 8 : -6
        }
        return -10
    }

    public static func related(_ lhs: GarmentColor, _ rhs: GarmentColor) -> Bool {
        let pair: Set<GarmentColor> = [lhs, rhs]
        let families: [Set<GarmentColor>] = [
            [.coral, .blush],
            [.lavender, .blue],
            [.olive, .blue],
            [.coral, .lavender]
        ]
        return families.contains(pair)
    }
}

public struct ScoredLook: Equatable {
    public var score: Int
    public var reasons: [String]
}

public enum OutfitEngine {
    public static func signature(for ids: [UUID]) -> String {
        ids.map(\.uuidString).sorted().joined(separator: "+")
    }

    public static func title(for pieces: [Garment]) -> String {
        let ordered = pieces.sorted { $0.category.sortIndex < $1.category.sortIndex }
        if let dress = ordered.first(where: { $0.category == .dress }) {
            if let layer = ordered.first(where: { $0.category == .outerwear }) {
                return "\(dress.name) and \(layer.name)"
            }
            return dress.name
        }
        if let top = ordered.first(where: { $0.category == .top }),
           let bottom = ordered.first(where: { $0.category == .bottom }) {
            return "\(top.name) and \(bottom.name)"
        }
        return ordered.first?.name ?? "Look"
    }

    public static func issues(for slots: LookSlots) -> [LookIssue] {
        let hasDress = slots.dress != nil
        let hasTop = slots.top != nil
        let hasBottom = slots.bottom != nil
        var issues: [LookIssue] = []
        if !hasDress && !hasTop && !hasBottom && slots.outerwear == nil && slots.shoes == nil && slots.accessory == nil {
            issues.append(.empty)
            return issues
        }
        if hasDress && hasTop { issues.append(.dressWithTop) }
        if hasDress && hasBottom { issues.append(.dressWithBottom) }
        if !hasDress && hasBottom && !hasTop { issues.append(.missingTop) }
        if !hasDress && hasTop && !hasBottom { issues.append(.missingBottom) }
        if !hasDress && !hasTop && !hasBottom { issues.append(.empty) }
        if slots.shoes == nil { issues.append(.missingShoes) }
        return issues
    }

    public static func pieces(in slots: LookSlots, garments: [Garment]) -> [Garment] {
        let byID = Dictionary(uniqueKeysWithValues: garments.map { ($0.id, $0) })
        return slots.pieceIDs.compactMap { byID[$0] }.sorted { $0.category.sortIndex < $1.category.sortIndex }
    }

    public static func score(
        pieces: [Garment],
        wears: [WearEntry],
        query: SuggestQuery,
        calendar: Calendar
    ) -> ScoredLook {
        let ordered = pieces.sorted { $0.category.sortIndex < $1.category.sortIndex }
        var score = 0
        var reasons: [String] = []

        let dress = ordered.first { $0.category == .dress }
        let top = ordered.first { $0.category == .top }
        let bottom = ordered.first { $0.category == .bottom }
        let outer = ordered.first { $0.category == .outerwear }
        let shoes = ordered.first { $0.category == .shoes }
        let accessory = ordered.first { $0.category == .accessory }

        let hasBase = dress != nil || (top != nil && bottom != nil)
        if hasBase { score += 36 }

        if shoes != nil {
            score += 14
        } else {
            score -= 10
        }
        if accessory != nil { score += 3 }

        let need = LayerNeed.forWeather(query.weather)
        switch need {
        case .required:
            if let outer {
                switch outer.weight {
                case .heavy: score += 20
                case .medium: score += 14
                case .light: score += 8
                }
                reasons.append("A layer for \(query.weather.band.displayName.lowercased()) weather.")
            } else {
                score -= 16
            }
        case .welcome:
            if outer != nil {
                score += 6
                reasons.append("A light layer for a mild day.")
            }
        case .lightOnly:
            if let outer {
                if outer.weight == .heavy {
                    score -= 12
                } else {
                    score += 4
                }
            } else {
                score += 2
            }
        case .avoid:
            if outer != nil {
                score -= 18
            } else {
                score += 6
                reasons.append("No coat. It is warm enough.")
            }
        }

        let core = ordered.filter { $0.category != .accessory }
        if !core.isEmpty {
            let sum = core.reduce(0) { $0 + formalityPoints($1.formality, occasion: query.occasion) }
            let average = Int((Double(sum) / Double(core.count)).rounded())
            score += average
            if average >= 8 {
                reasons.append("Fits a \(query.occasion.displayName.lowercased()) day.")
            }
        }

        for piece in ordered {
            if piece.suits(season: query.season) {
                score += 5
            } else {
                score -= 9
            }
            if (query.weather.band == .hot || query.weather.band == .warm),
               piece.seasons == [.winter] || Set(piece.seasons) == [.autumn, .winter] || Set(piece.seasons) == [.winter, .autumn] {
                score -= 6
            }
            if query.weather.band == .cold,
               piece.seasons == [.summer] || Set(piece.seasons) == [.spring, .summer] || Set(piece.seasons) == [.summer, .spring] {
                score -= 6
            }
        }

        score += ColorHarmony.score(of: ordered.map(\.primaryColor))

        let favorites = ordered.filter(\.isFavorite).count
        if favorites > 0 {
            score += min(9, favorites * 3)
        }

        let signature = signature(for: ordered.map(\.id))
        if let gap = daysSince(target: signature, before: query.day, wears: wears, calendar: calendar),
           gap > 0, gap <= query.repeatWindowDays {
            score -= 80
            reasons.append("Worn \(gap) \(gap == 1 ? "day" : "days") ago.")
        } else {
            reasons.append("Not worn in the last \(query.repeatWindowDays) days.")
        }

        let recent = pieceIDsWorn(within: 2, of: query.day, wears: wears, calendar: calendar)
        let reused = Set(ordered.map(\.id)).intersection(recent).count
        if reused > 0 {
            score -= min(18, reused * 6)
        }

        var seen = Set<String>()
        let trimmed = reasons.filter { seen.insert($0).inserted }
        return ScoredLook(score: score, reasons: Array(trimmed.prefix(3)))
    }

    public static func suggestions(
        garments: [Garment],
        wears: [WearEntry],
        query: SuggestQuery,
        calendar: Calendar
    ) -> [SuggestedLook] {
        let tops = garments.filter { $0.category == .top }
        let bottoms = garments.filter { $0.category == .bottom }
        let dresses = garments.filter { $0.category == .dress }
        let outers = garments.filter { $0.category == .outerwear }
        let shoes = garments.filter { $0.category == .shoes }
        let accessories = garments.filter { $0.category == .accessory }

        var bases: [[Garment]] = []
        for dress in dresses {
            bases.append([dress])
        }
        for top in tops {
            for bottom in bottoms {
                bases.append([top, bottom])
            }
        }
        if bases.isEmpty { return [] }

        let outerOptions: [[Garment]] = [[]] + outers.map { [$0] }
        let shoeOptions: [[Garment]] = [[]] + shoes.map { [$0] }
        let extraOptions: [[Garment]] = [[]] + accessories.map { [$0] }

        var best: [String: SuggestedLook] = [:]
        for base in bases {
            for outer in outerOptions {
                for shoe in shoeOptions {
                    for extra in extraOptions {
                        let pieces = (base + outer + shoe + extra).sorted { $0.category.sortIndex < $1.category.sortIndex }
                        let scored = score(pieces: pieces, wears: wears, query: query, calendar: calendar)
                        let signature = signature(for: pieces.map(\.id))
                        let look = SuggestedLook(
                            pieces: pieces,
                            score: scored.score,
                            reasons: scored.reasons,
                            title: title(for: pieces),
                            signature: signature
                        )
                        if let existing = best[signature], existing.score >= look.score {
                            continue
                        }
                        best[signature] = look
                    }
                }
            }
        }

        return best.values.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.signature < rhs.signature
        }
        .prefix(query.limit)
        .map { $0 }
    }

    public static func formalityPoints(_ formality: Formality, occasion: Occasion) -> Int {
        switch occasion {
        case .work:
            switch formality {
            case .smart: return 10
            case .formal: return 1
            case .casual: return -6
            }
        case .casual:
            switch formality {
            case .casual: return 10
            case .smart: return -2
            case .formal: return -14
            }
        case .weekend:
            switch formality {
            case .casual: return 12
            case .smart: return -4
            case .formal: return -16
            }
        case .date:
            switch formality {
            case .formal: return 12
            case .smart: return 10
            case .casual: return -8
            }
        case .formal:
            switch formality {
            case .formal: return 14
            case .smart: return 2
            case .casual: return -18
            }
        }
    }

    private static func daysSince(
        target: String,
        before day: DayStamp,
        wears: [WearEntry],
        calendar: Calendar
    ) -> Int? {
        var closest: Int?
        for wear in wears {
            guard signature(for: wear.pieceIDs) == target,
                  let gap = wear.day.distance(to: day, calendar: calendar),
                  gap >= 0 else {
                continue
            }
            if let closest, closest <= gap { continue }
            closest = gap
        }
        return closest
    }

    private static func pieceIDsWorn(
        within days: Int,
        of day: DayStamp,
        wears: [WearEntry],
        calendar: Calendar
    ) -> Set<UUID> {
        var ids = Set<UUID>()
        for wear in wears {
            guard let gap = wear.day.distance(to: day, calendar: calendar), gap > 0, gap <= days else {
                continue
            }
            ids.formUnion(wear.pieceIDs)
        }
        return ids
    }
}
