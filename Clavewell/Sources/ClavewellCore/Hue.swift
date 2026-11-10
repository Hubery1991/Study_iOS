import Foundation

/// A mote color, or the spark that bursts its neighbors.
public enum Hue: Int, Codable, CaseIterable, Equatable {
    case amber
    case tide
    case moss
    case violet
    case rose
    case spark

    /// Colors that form resonance groups. Spark is deliberately absent.
    public static let colors: [Hue] = [.amber, .tide, .moss, .violet, .rose]

    public var name: String {
        switch self {
        case .amber: return "Amber"
        case .tide: return "Tide"
        case .moss: return "Moss"
        case .violet: return "Violet"
        case .rose: return "Rose"
        case .spark: return "Spark"
        }
    }
}

public enum GameMode: String, Codable, CaseIterable, Equatable, Identifiable {
    case cadence
    case stillwater
    case flare

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .cadence: return "Cadence"
        case .stillwater: return "Stillwater"
        case .flare: return "Flare"
        }
    }

    public var summary: String {
        switch self {
        case .cadence: return "A row rises from the deep."
        case .stillwater: return "Nothing rises. Fill with care."
        case .flare: return "Seventy-five seconds on the clock."
        }
    }

    public var detail: String {
        switch self {
        case .cadence:
            return "Every few drops, a new row climbs into the well. The pace quickens the longer you last. The run ends when a rise would pass the rim."
        case .stillwater:
            return "The well stays put. Clear space and chase a score until no column can take another mote."
        case .flare:
            return "You have 75 seconds. Each mote you clear returns a little time, up to two and a half seconds on a single drop."
        }
    }
}

public enum EndReason: String, Equatable {
    case overflow
    case locked
    case time

    public var title: String {
        switch self {
        case .overflow: return "The rim silted shut"
        case .locked: return "The well is full"
        case .time: return "Time ran out"
        }
    }

    public var detail: String {
        switch self {
        case .overflow: return "A rise would have pushed a mote past the rim."
        case .locked: return "No column can take another mote."
        case .time: return "The flare burned down."
        }
    }
}
