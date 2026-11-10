import SwiftUI

enum ClearKind: Equatable {
    case first
    case better
    case again
}

struct SparkEvent: Equatable {
    var crateID: Int
    var point: GridPoint
    var token: Int
}

final class PlayModel: ObservableObject {
    let level: LevelDefinition
    @Published private(set) var puzzle: Puzzle
    @Published private(set) var facing: Direction = .down
    @Published var won = false
    @Published var clearKind: ClearKind = .first
    @Published var blockedToken = 0
    @Published var moveToken = 0
    @Published var spark: SparkEvent?
    @Published var bumpCrateID: Int?

    private var sparkToken = 0

    init(level: LevelDefinition) {
        self.level = level
        do {
            puzzle = try Puzzle(level: level)
        } catch {
            preconditionFailure("Level \(level.index) failed to build: \(error)")
        }
    }

    @discardableResult
    func move(_ direction: Direction) -> StepOutcome {
        guard !puzzle.isWon else { return .blocked }
        facing = direction
        let outcome = puzzle.step(direction)
        switch outcome {
        case .blocked:
            blockedToken += 1
        case .walked:
            moveToken += 1
            bumpCrateID = nil
        case .pushed(let ontoGoal, let crateID):
            moveToken += 1
            if ontoGoal, let crate = puzzle.crates.first(where: { $0.id == crateID }) {
                sparkToken += 1
                spark = SparkEvent(crateID: crateID, point: crate.point, token: sparkToken)
                bumpCrateID = crateID
            } else {
                bumpCrateID = nil
            }
        }
        if puzzle.isWon {
            won = true
        }
        return outcome
    }

    func undo() {
        guard puzzle.undo() else { return }
        won = puzzle.isWon
        bumpCrateID = nil
        moveToken += 1
    }

    func restart() {
        puzzle.restart()
        won = false
        bumpCrateID = nil
        spark = nil
        moveToken += 1
    }
}
