import Foundation

public enum LevelError: Error, Equatable, Sendable {
    case empty
    case ragged
    case badTile(Character)
    case playerCount
    case crateGoalMismatch(crates: Int, goals: Int)
    case alreadySolved
}

public enum StepOutcome: Equatable, Sendable {
    case blocked
    case walked
    case pushed(ontoGoal: Bool, crateID: Int)
}

/// Classic one-step crate pushing. Mallow walks one tile or nudges exactly one crate.
/// Crates cannot be pulled, and two crates cannot be pushed together.
public struct Puzzle: Equatable, Sendable {
    public struct Crate: Equatable, Identifiable, Sendable {
        public let id: Int
        public var point: GridPoint

        public init(id: Int, point: GridPoint) {
            self.id = id
            self.point = point
        }
    }

    public let levelIndex: Int
    public let walls: Set<GridPoint>
    public let goals: Set<GridPoint>
    public let width: Int
    public let height: Int

    public private(set) var player: GridPoint
    public private(set) var crates: [Crate]
    public private(set) var moves: Int
    public private(set) var pushes: Int

    private var history: [Snapshot]

    public var isWon: Bool {
        let placed = Set(crates.map(\.point))
        return goals.isSubset(of: placed)
    }

    public var canUndo: Bool { !history.isEmpty }

    public init(level: LevelDefinition) throws {
        let rows = level.rows
        guard let first = rows.first, !first.isEmpty else { throw LevelError.empty }
        guard rows.allSatisfy({ $0.count == first.count }) else { throw LevelError.ragged }

        var walls: Set<GridPoint> = []
        var goals: Set<GridPoint> = []
        var crates: [Crate] = []
        var player: GridPoint?
        var nextID = 1

        for (rowIndex, row) in rows.enumerated() {
            for (colIndex, tile) in row.enumerated() {
                let point = GridPoint(row: rowIndex, col: colIndex)
                switch tile {
                case "#":
                    walls.insert(point)
                case " ":
                    break
                case ".":
                    goals.insert(point)
                case "@":
                    guard player == nil else { throw LevelError.playerCount }
                    player = point
                case "+":
                    guard player == nil else { throw LevelError.playerCount }
                    player = point
                    goals.insert(point)
                case "$":
                    crates.append(Crate(id: nextID, point: point))
                    nextID += 1
                case "*":
                    crates.append(Crate(id: nextID, point: point))
                    nextID += 1
                    goals.insert(point)
                default:
                    throw LevelError.badTile(tile)
                }
            }
        }

        guard let player else { throw LevelError.playerCount }
        guard !crates.isEmpty, crates.count == goals.count else {
            throw LevelError.crateGoalMismatch(crates: crates.count, goals: goals.count)
        }
        let placed = Set(crates.map(\.point))
        guard !goals.isSubset(of: placed) else { throw LevelError.alreadySolved }

        self.levelIndex = level.index
        self.walls = walls
        self.goals = goals
        self.width = first.count
        self.height = rows.count
        self.player = player
        self.crates = crates
        self.moves = 0
        self.pushes = 0
        self.history = []
    }

    public func contains(_ point: GridPoint) -> Bool {
        point.row >= 0 && point.col >= 0 && point.row < height && point.col < width
    }

    @discardableResult
    public mutating func step(_ direction: Direction) -> StepOutcome {
        let next = player.moved(direction)
        guard contains(next), !walls.contains(next) else { return .blocked }

        if let index = crates.firstIndex(where: { $0.point == next }) {
            let beyond = next.moved(direction)
            let occupied = crates.contains { $0.point == beyond }
            guard contains(beyond), !walls.contains(beyond), !occupied else { return .blocked }
            history.append(snapshot())
            player = next
            crates[index].point = beyond
            moves += 1
            pushes += 1
            return .pushed(ontoGoal: goals.contains(beyond), crateID: crates[index].id)
        }

        history.append(snapshot())
        player = next
        moves += 1
        return .walked
    }

    @discardableResult
    public mutating func undo() -> Bool {
        guard let previous = history.popLast() else { return false }
        player = previous.player
        crates = previous.crates
        moves = previous.moves
        pushes = previous.pushes
        return true
    }

    public mutating func restart() {
        while undo() {}
    }

    public func applying(_ letters: String) -> Puzzle {
        var copy = self
        for letter in letters {
            guard let direction = Direction(letter: letter) else { continue }
            copy.step(direction)
        }
        return copy
    }

    private func snapshot() -> Snapshot {
        Snapshot(player: player, crates: crates, moves: moves, pushes: pushes)
    }

    private struct Snapshot: Equatable, Sendable {
        var player: GridPoint
        var crates: [Crate]
        var moves: Int
        var pushes: Int
    }
}
