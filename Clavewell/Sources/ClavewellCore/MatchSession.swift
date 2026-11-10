import Foundation

public struct WellRNG: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed == 0 ? 0xC0FFEE5EED : seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

struct HueSource {
    var rng: WellRNG
    private var bag: [Hue] = []
    private var untilSpark: Int
    private var script: [Hue]
    private var scripted: Bool

    init(seed: UInt64, scripted queue: [Hue]?) {
        rng = WellRNG(seed: seed)
        if let queue {
            script = queue
            scripted = true
        } else {
            script = []
            scripted = false
        }
        // Eleven color draws, then a spark, so every 12th mote dealt is a spark.
        untilSpark = 11
    }

    /// Color draws remaining before a spark is dealt. Meaningful for unscripted wells.
    var sparkIn: Int { untilSpark }

    mutating func next() -> Hue {
        if scripted {
            if !script.isEmpty {
                return script.removeFirst()
            }
            scripted = false
        }
        if untilSpark == 0 {
            untilSpark = 11
            return .spark
        }
        untilSpark -= 1
        if bag.isEmpty {
            refill()
        }
        return bag.removeLast()
    }

    mutating func riseRow() -> [Hue] {
        WellBoard.fairRow(using: &rng)
    }

    private mutating func refill() {
        var items: [Hue] = []
        for hue in Hue.colors {
            items.append(hue)
            items.append(hue)
        }
        var index = items.count - 1
        while index > 0 {
            let swap = Int(rng.next() % UInt64(index + 1))
            items.swapAt(index, swap)
            index -= 1
        }
        bag = items
    }
}

public struct Frame: Equatable {
    public enum Kind: String, Equatable {
        case place
        case clear
        case settle
        case rise
    }

    public var board: WellBoard
    public var score: Int
    public var clearing: [CellCoord]
    public var banner: String?
    public var kind: Kind
    public var chain: Int
    public var pointsJustEarned: Int
    public var placed: CellCoord?
    public var now: Hue
    public var next: Hue
    public var dropsUntilRise: Int
    public var riseInterval: Int
}

public struct DropOutcome: Equatable {
    public var accepted: Bool
    public var frames: [Frame]
    public var gameOver: Bool
    public var reason: EndReason?
}

public final class MatchSession {
    public static let flareDuration: TimeInterval = 75
    public static let openingInterval = 8
    public static let minimumInterval = 4

    public let mode: GameMode
    public let seed: UInt64

    public internal(set) var board: WellBoard
    public internal(set) var current: Hue
    public internal(set) var upcoming: Hue
    public internal(set) var score: Int
    public internal(set) var chainBest: Int
    public internal(set) var motesCleared: Int
    public internal(set) var dropsUntilRise: Int
    public internal(set) var riseInterval: Int
    public internal(set) var timeRemaining: TimeInterval
    public internal(set) var ended: EndReason?
    public internal(set) var drops: Int
    /// When set, the next successful rise inserts this row instead of a random one.
    public internal(set) var nextRiseRow: [Hue]?

    private var source: HueSource
    private var risesDone = 0

    public var isOver: Bool { ended != nil }
    public var sparkIn: Int { source.sparkIn }

    public init(mode: GameMode, seed: UInt64? = nil, scriptedQueue: [Hue]? = nil) {
        let resolved = seed ?? UInt64.random(in: 1...UInt64.max)
        self.mode = mode
        self.seed = resolved
        board = WellBoard()
        score = 0
        chainBest = 0
        motesCleared = 0
        riseInterval = Self.openingInterval
        dropsUntilRise = Self.openingInterval
        timeRemaining = Self.flareDuration
        ended = nil
        drops = 0
        nextRiseRow = nil
        var source = HueSource(seed: resolved, scripted: scriptedQueue)
        let first = source.next()
        let second = source.next()
        self.source = source
        current = first
        upcoming = second
    }

    public static func interval(afterRises risesDone: Int) -> Int {
        max(minimumInterval, openingInterval - risesDone / 2)
    }

    /// Advances the flare clock. Returns `.time` only on the tick that reaches zero.
    public func tick(_ delta: TimeInterval) -> EndReason? {
        guard mode == .flare, ended == nil, delta > 0 else { return nil }
        timeRemaining -= delta
        // Snap floating-point dust so a clock that has reached zero actually ends.
        if timeRemaining <= 0.0001 {
            timeRemaining = 0
            ended = .time
            return .time
        }
        return nil
    }

    public func drop(in column: Int) -> DropOutcome {
        if ended != nil {
            return DropOutcome(accepted: false, frames: [], gameOver: true, reason: ended)
        }
        guard let row = board.lowestEmptyRow(in: column) else {
            return DropOutcome(accepted: false, frames: [], gameOver: false, reason: nil)
        }

        let piece = current
        current = upcoming
        upcoming = source.next()
        drops += 1

        let landing = CellCoord(row: row, column: column)
        board.set(landing, piece)

        if mode == .cadence {
            dropsUntilRise -= 1
        }

        let timeAtDrop = timeRemaining
        var frames: [Frame] = []
        frames.append(makeFrame(kind: .place, clearing: [], banner: nil, chain: 0, points: 0, placed: landing))

        var chain = 0
        var motesThisDrop = 0
        resolve(into: &frames, chain: &chain, motesThisDrop: &motesThisDrop, timeAtDrop: timeAtDrop)

        if ended == nil, !board.hasOpenColumn() {
            ended = .locked
        }

        if mode == .cadence, ended == nil, dropsUntilRise <= 0 {
            if board.topRowOccupied() {
                ended = .overflow
            } else {
                let bottom = nextRiseRow ?? source.riseRow()
                nextRiseRow = nil
                board.shiftUp(inserting: bottom)
                risesDone += 1
                riseInterval = Self.interval(afterRises: risesDone)
                dropsUntilRise = riseInterval
                frames.append(makeFrame(kind: .rise, clearing: [], banner: "The well rises", chain: 0, points: 0, placed: nil))
                chain = 0
                resolve(into: &frames, chain: &chain, motesThisDrop: &motesThisDrop, timeAtDrop: timeAtDrop)
                if ended == nil, !board.hasOpenColumn() {
                    ended = .locked
                }
            }
        }

        return DropOutcome(
            accepted: true,
            frames: frames,
            gameOver: ended != nil,
            reason: ended
        )
    }

    private func resolve(
        into frames: inout [Frame],
        chain: inout Int,
        motesThisDrop: inout Int,
        timeAtDrop: TimeInterval
    ) {
        var guardCount = 0
        while guardCount < 24 {
            guardCount += 1
            let sparks = board.coordinates { $0 == .spark }
            if !sparks.isEmpty {
                var burst = Set<CellCoord>()
                for spark in sparks {
                    burst.insert(spark)
                    for neighbor in board.orthogonalNeighbors(of: spark) where board.hue(neighbor) != nil {
                        burst.insert(neighbor)
                    }
                }
                let coords = Array(burst)
                let colored = coords.reduce(0) { partial, coord in
                    partial + (board.hue(coord) == .spark ? 0 : 1)
                }
                chain += 1
                applyClear(
                    coords: coords,
                    coloredCount: colored,
                    chain: chain,
                    banner: "Spark ×\(chain)",
                    frames: &frames,
                    motesThisDrop: &motesThisDrop,
                    timeAtDrop: timeAtDrop
                )
                continue
            }

            let groups = board.groups()
            if groups.isEmpty { return }
            chain += 1
            let coords = groups.flatMap { $0 }
            let banner = groups.count > 1 ? "Double ring ×\(chain)" : "Resonance ×\(chain)"
            let colored = coords.count
            // Score each group, then remove them together so they share this chain step.
            let points = groups.reduce(0) { partial, group in
                partial + ScoreFormula.points(count: group.count, chain: chain)
            }
            score += points
            motesCleared += colored
            motesThisDrop += colored
            chainBest = max(chainBest, chain)
            applyFlareBonus(motesThisDrop: motesThisDrop, timeAtDrop: timeAtDrop)
            frames.append(makeFrame(
                kind: .clear,
                clearing: coords,
                banner: banner,
                chain: chain,
                points: points,
                placed: nil
            ))
            board.remove(coords)
            board.collapse()
            frames.append(makeFrame(kind: .settle, clearing: [], banner: nil, chain: chain, points: 0, placed: nil))
        }
    }

    private func applyClear(
        coords: [CellCoord],
        coloredCount: Int,
        chain: Int,
        banner: String,
        frames: inout [Frame],
        motesThisDrop: inout Int,
        timeAtDrop: TimeInterval
    ) {
        let points = ScoreFormula.points(count: coloredCount, chain: chain)
        score += points
        motesCleared += coloredCount
        motesThisDrop += coloredCount
        chainBest = max(chainBest, chain)
        applyFlareBonus(motesThisDrop: motesThisDrop, timeAtDrop: timeAtDrop)
        frames.append(makeFrame(
            kind: .clear,
            clearing: coords,
            banner: banner,
            chain: chain,
            points: points,
            placed: nil
        ))
        board.remove(coords)
        board.collapse()
        frames.append(makeFrame(kind: .settle, clearing: [], banner: nil, chain: chain, points: 0, placed: nil))
    }

    private func applyFlareBonus(motesThisDrop: Int, timeAtDrop: TimeInterval) {
        guard mode == .flare, ended == nil else { return }
        let bonus = min(2.5, Double(motesThisDrop) * 0.15)
        timeRemaining = timeAtDrop + bonus
    }

    private func makeFrame(
        kind: Frame.Kind,
        clearing: [CellCoord],
        banner: String?,
        chain: Int,
        points: Int,
        placed: CellCoord?
    ) -> Frame {
        Frame(
            board: board,
            score: score,
            clearing: clearing,
            banner: banner,
            kind: kind,
            chain: chain,
            pointsJustEarned: points,
            placed: placed,
            now: current,
            next: upcoming,
            dropsUntilRise: dropsUntilRise,
            riseInterval: riseInterval
        )
    }
}
