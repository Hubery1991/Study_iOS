import Foundation

public struct LevelRecord: Codable, Equatable, Sendable {
    public var bestMoves: Int
    public var stars: Int

    public init(bestMoves: Int, stars: Int) {
        self.bestMoves = bestMoves
        self.stars = stars
    }
}

/// Local progress. Nothing here leaves the device.
public struct SaveGame: Codable, Equatable, Sendable {
    public var soundOn: Bool
    public var hapticsOn: Bool
    public var sawHint: Bool
    public var records: [Int: LevelRecord]

    public init(
        soundOn: Bool = true,
        hapticsOn: Bool = true,
        sawHint: Bool = false,
        records: [Int: LevelRecord] = [:]
    ) {
        self.soundOn = soundOn
        self.hapticsOn = hapticsOn
        self.sawHint = sawHint
        self.records = records
    }

    /// Three stars for a solve within two steps of par. Two stars for a roomier band.
    /// Any clear still earns one star.
    public static func stars(moves: Int, par: Int) -> Int {
        if moves <= par + 2 { return 3 }
        if moves <= par + max(6, par / 2) { return 2 }
        return 1
    }

    public func isUnlocked(_ index: Int, levelCount: Int) -> Bool {
        if index == 1 { return true }
        guard index > 1, index <= levelCount else { return false }
        return records[index - 1] != nil
    }

    public func nextPlayableIndex(levelCount: Int) -> Int {
        guard levelCount > 0 else { return 1 }
        for index in 1...levelCount where isUnlocked(index, levelCount: levelCount) && records[index] == nil {
            return index
        }
        return levelCount
    }

    /// Stores a clear. Returns true when the stored best move count improved.
    @discardableResult
    public mutating func recordClear(level: Int, moves: Int, par: Int) -> Bool {
        let earned = Self.stars(moves: moves, par: par)
        if let existing = records[level] {
            if moves < existing.bestMoves {
                records[level] = LevelRecord(bestMoves: moves, stars: max(existing.stars, earned))
                return true
            }
            if earned > existing.stars {
                records[level] = LevelRecord(bestMoves: existing.bestMoves, stars: earned)
            }
            return false
        }
        records[level] = LevelRecord(bestMoves: moves, stars: earned)
        return true
    }

    public var clearedCount: Int { records.count }

    public var starCount: Int { records.values.reduce(0) { $0 + $1.stars } }

    public func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }

    public static func decoded(_ data: Data) throws -> SaveGame {
        try JSONDecoder().decode(SaveGame.self, from: data)
    }
}
