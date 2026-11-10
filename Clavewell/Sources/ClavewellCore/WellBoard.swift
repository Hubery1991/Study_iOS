import Foundation

public struct CellCoord: Hashable, Equatable {
    public var row: Int
    public var column: Int

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
}

/// Row 0 is the rim. The highest row index is the floor of the well.
public struct WellBoard: Equatable {
    public static let columns = 6
    public static let rows = 10

    public private(set) var cells: [[Hue?]]

    public init() {
        cells = Array(
            repeating: Array(repeating: nil, count: Self.columns),
            count: Self.rows
        )
    }

    public init(cells: [[Hue?]]) {
        precondition(cells.count == Self.rows, "WellBoard requires \(Self.rows) rows")
        for row in cells {
            precondition(row.count == Self.columns, "WellBoard requires \(Self.columns) columns")
        }
        self.cells = cells
    }

    public func contains(_ coord: CellCoord) -> Bool {
        coord.row >= 0 && coord.row < Self.rows && coord.column >= 0 && coord.column < Self.columns
    }

    public func hue(_ coord: CellCoord) -> Hue? {
        guard contains(coord) else { return nil }
        return cells[coord.row][coord.column]
    }

    public mutating func set(_ coord: CellCoord, _ hue: Hue?) {
        precondition(contains(coord))
        cells[coord.row][coord.column] = hue
    }

    public func lowestEmptyRow(in column: Int) -> Int? {
        guard column >= 0, column < Self.columns else { return nil }
        for row in stride(from: Self.rows - 1, through: 0, by: -1) {
            if cells[row][column] == nil {
                return row
            }
        }
        return nil
    }

    /// A column is open when its rim cell is empty. Gravity keeps gaps below the rim impossible.
    public func hasOpenColumn() -> Bool {
        (0..<Self.columns).contains { cells[0][$0] == nil }
    }

    public func topRowOccupied() -> Bool {
        cells[0].contains { $0 != nil }
    }

    public func coordinates(where matches: (Hue) -> Bool) -> [CellCoord] {
        var result: [CellCoord] = []
        for row in 0..<Self.rows {
            for column in 0..<Self.columns {
                if let hue = cells[row][column], matches(hue) {
                    result.append(CellCoord(row: row, column: column))
                }
            }
        }
        return result
    }

    public func orthogonalNeighbors(of coord: CellCoord) -> [CellCoord] {
        let deltas = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        return deltas.compactMap { delta in
            let next = CellCoord(row: coord.row + delta.0, column: coord.column + delta.1)
            return contains(next) ? next : nil
        }
    }

    /// Orthogonal groups of the same color. Sparks never join a group.
    public func groups(minimum: Int = 3) -> [[CellCoord]] {
        var seen = Set<CellCoord>()
        var found: [[CellCoord]] = []
        for row in 0..<Self.rows {
            for column in 0..<Self.columns {
                let start = CellCoord(row: row, column: column)
                if seen.contains(start) { continue }
                guard let hue = cells[row][column], hue != .spark else {
                    seen.insert(start)
                    continue
                }
                var stack = [start]
                var group: [CellCoord] = []
                seen.insert(start)
                while let current = stack.popLast() {
                    group.append(current)
                    for neighbor in orthogonalNeighbors(of: current) where !seen.contains(neighbor) {
                        if cells[neighbor.row][neighbor.column] == hue {
                            seen.insert(neighbor)
                            stack.append(neighbor)
                        }
                    }
                }
                if group.count >= minimum {
                    found.append(group)
                }
            }
        }
        return found
    }

    public mutating func remove(_ coords: [CellCoord]) {
        for coord in coords where contains(coord) {
            cells[coord.row][coord.column] = nil
        }
    }

    /// Compact each column toward the floor.
    public mutating func collapse() {
        for column in 0..<Self.columns {
            var stack: [Hue] = []
            for row in stride(from: Self.rows - 1, through: 0, by: -1) {
                if let hue = cells[row][column] {
                    stack.append(hue)
                }
            }
            for row in 0..<Self.rows {
                cells[row][column] = nil
            }
            for (index, hue) in stack.enumerated() {
                cells[Self.rows - 1 - index][column] = hue
            }
        }
    }

    /// Move every mote one step toward the rim and insert a new floor.
    /// Caller must guarantee the rim is empty.
    public mutating func shiftUp(inserting bottom: [Hue]) {
        precondition(bottom.count == Self.columns)
        precondition(!topRowOccupied(), "Cannot rise while a mote sits on the rim")
        for row in 0..<(Self.rows - 1) {
            cells[row] = cells[row + 1]
        }
        cells[Self.rows - 1] = bottom.map { Optional($0) }
    }

    public var occupiedCount: Int {
        cells.reduce(0) { partial, row in
            partial + row.reduce(0) { $0 + ($1 == nil ? 0 : 1) }
        }
    }

    static func hasTripleRun(_ row: [Hue]) -> Bool {
        guard row.count >= 3 else { return false }
        for index in 0...(row.count - 3) {
            if row[index] == row[index + 1], row[index] == row[index + 2] {
                return true
            }
        }
        return false
    }

    static func fairRow<R: RandomNumberGenerator>(using rng: inout R) -> [Hue] {
        for _ in 0..<40 {
            var row: [Hue] = []
            row.reserveCapacity(columns)
            for _ in 0..<columns {
                let index = Int(rng.next() % UInt64(Hue.colors.count))
                row.append(Hue.colors[index])
            }
            if !hasTripleRun(row) {
                return row
            }
        }
        return [.amber, .tide, .moss, .violet, .rose, .amber]
    }
}

public enum ScoreFormula {
    /// 100 points per mote, plus 40 more for every mote past the third, times the chain step.
    public static func points(count: Int, chain: Int) -> Int {
        guard count > 0, chain > 0 else { return 0 }
        let base = count * 100 + max(0, count - 3) * 40
        return base * chain
    }
}
