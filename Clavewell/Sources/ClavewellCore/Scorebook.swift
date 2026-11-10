import Foundation

public struct RunRecord: Codable, Equatable, Identifiable {
    public var id: UUID
    public var score: Int
    public var bestChain: Int
    public var motesCleared: Int
    public var mode: GameMode
    public var playedAt: Date

    public init(
        id: UUID = UUID(),
        score: Int,
        bestChain: Int,
        motesCleared: Int,
        mode: GameMode,
        playedAt: Date = Date()
    ) {
        self.id = id
        self.score = score
        self.bestChain = bestChain
        self.motesCleared = motesCleared
        self.mode = mode
        self.playedAt = playedAt
    }
}

public struct LifetimeStats: Codable, Equatable {
    public var gamesPlayed: Int
    public var motesCleared: Int
    public var bestChain: Int

    public init(gamesPlayed: Int = 0, motesCleared: Int = 0, bestChain: Int = 0) {
        self.gamesPlayed = gamesPlayed
        self.motesCleared = motesCleared
        self.bestChain = bestChain
    }
}

/// High scores, lifetime totals, and settings stored only in UserDefaults on this device.
public final class Scorebook {
    public static let shared = Scorebook()

    private let defaults: UserDefaults

    private enum Key {
        static let records = "clavewell.records"
        static let stats = "clavewell.stats"
        static let sound = "clavewell.sound"
        static let haptics = "clavewell.haptics"
        static let patterns = "clavewell.patterns"
        static let guide = "clavewell.guide"
        static let seenHowTo = "clavewell.seenHowTo"
    }

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public convenience init() {
        self.init(defaults: .standard)
    }

    public var soundEnabled: Bool {
        get { defaults.object(forKey: Key.sound) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.sound) }
    }

    public var hapticsEnabled: Bool {
        get { defaults.object(forKey: Key.haptics) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.haptics) }
    }

    public var patternsEnabled: Bool {
        get { defaults.object(forKey: Key.patterns) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.patterns) }
    }

    public var landingGuideEnabled: Bool {
        get { defaults.object(forKey: Key.guide) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.guide) }
    }

    public var seenHowTo: Bool {
        get { defaults.bool(forKey: Key.seenHowTo) }
        set { defaults.set(newValue, forKey: Key.seenHowTo) }
    }

    public func bestScore(for mode: GameMode) -> Int {
        top(for: mode).map(\.score).max() ?? 0
    }

    public func top(for mode: GameMode, limit: Int = 5) -> [RunRecord] {
        Array(sorted(records(for: mode)).prefix(limit))
    }

    /// Saves a finished run. Returns true when the score strictly beats the previous best and is above zero.
    @discardableResult
    public func record(
        score: Int,
        bestChain: Int,
        motesCleared: Int,
        mode: GameMode,
        at date: Date = Date()
    ) -> Bool {
        let previousBest = bestScore(for: mode)
        var all = loadRecords()
        all.append(RunRecord(
            score: score,
            bestChain: bestChain,
            motesCleared: motesCleared,
            mode: mode,
            playedAt: date
        ))
        var kept: [RunRecord] = []
        for item in GameMode.allCases {
            kept.append(contentsOf: sorted(all.filter { $0.mode == item }).prefix(5))
        }
        save(records: kept)

        var stats = loadStats()
        stats.gamesPlayed += 1
        stats.motesCleared += max(0, motesCleared)
        stats.bestChain = max(stats.bestChain, bestChain)
        save(stats: stats)
        return score > 0 && score > previousBest
    }

    public var stats: LifetimeStats { loadStats() }

    public func resetRecords() {
        defaults.removeObject(forKey: Key.records)
        defaults.removeObject(forKey: Key.stats)
    }

    private func records(for mode: GameMode) -> [RunRecord] {
        loadRecords().filter { $0.mode == mode }
    }

    private func sorted(_ runs: [RunRecord]) -> [RunRecord] {
        runs.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.playedAt > rhs.playedAt
        }
    }

    private func loadRecords() -> [RunRecord] {
        guard let data = defaults.data(forKey: Key.records) else { return [] }
        return (try? JSONDecoder().decode([RunRecord].self, from: data)) ?? []
    }

    private func save(records: [RunRecord]) {
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: Key.records)
        }
    }

    private func loadStats() -> LifetimeStats {
        guard let data = defaults.data(forKey: Key.stats) else { return LifetimeStats() }
        return (try? JSONDecoder().decode(LifetimeStats.self, from: data)) ?? LifetimeStats()
    }

    private func save(stats: LifetimeStats) {
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: Key.stats)
        }
    }
}
