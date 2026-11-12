import Foundation

public enum Direction: String, CaseIterable, Sendable {
    case up, down, left, right

    public var deltaRow: Int {
        switch self {
        case .up: return -1
        case .down: return 1
        case .left, .right: return 0
        }
    }

    public var deltaCol: Int {
        switch self {
        case .left: return -1
        case .right: return 1
        case .up, .down: return 0
        }
    }

    public init?(letter: Character) {
        switch letter {
        case "U": self = .up
        case "D": self = .down
        case "L": self = .left
        case "R": self = .right
        default: return nil
        }
    }
}

public struct GridPoint: Hashable, Codable, Sendable {
    public var row: Int
    public var col: Int

    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }

    public func moved(_ direction: Direction) -> GridPoint {
        GridPoint(row: row + direction.deltaRow, col: col + direction.deltaCol)
    }
}
