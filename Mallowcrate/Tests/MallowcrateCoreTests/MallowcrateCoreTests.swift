import XCTest
@testable import MallowcrateCore

final class MallowcrateCoreTests: XCTestCase {
    func testCatalogShape() {
        XCTAssertGreaterThanOrEqual(LevelCatalog.levels.count, 30)
        XCTAssertEqual(LevelCatalog.levels.count, 36)
        for (offset, level) in LevelCatalog.levels.enumerated() {
            XCTAssertEqual(level.index, offset + 1)
            XCTAssertEqual(level.world, (offset / 6) + 1)
            XCTAssertGreaterThan(level.par, 0)
            XCTAssertFalse(level.title.isEmpty)
            XCTAssertFalse(level.rows.isEmpty)
        }
        for world in LevelCatalog.worlds {
            XCTAssertEqual(LevelCatalog.levels.filter { $0.world == world }.count, 6)
        }
    }

    func testEveryLevelIsSolvedByTheVerifiedLine() throws {
        XCTAssertEqual(VerifiedSolutions.moves.count, LevelCatalog.levels.count)
        for level in LevelCatalog.levels {
            let letters = try XCTUnwrap(VerifiedSolutions.moves[level.index])
            let start = try Puzzle(level: level)
            XCTAssertEqual(start.crates.count, start.goals.count)
            XCTAssertFalse(start.isWon)
            let finished = start.applying(letters)
            XCTAssertTrue(finished.isWon, "level \(level.index) \(level.title) did not clear")
            XCTAssertEqual(finished.moves, letters.count)
            XCTAssertEqual(finished.moves, level.par)
            XCTAssertGreaterThan(finished.pushes, 0)
        }
    }

    func testParsRiseAcrossTheMeadow() {
        let pars = LevelCatalog.levels.map(\.par)
        XCTAssertEqual(pars.first, 1)
        XCTAssertGreaterThanOrEqual(pars.last ?? 0, 24)
        XCTAssertLessThanOrEqual(pars[5], 6)
        XCTAssertGreaterThan(pars[17], pars[5])
        XCTAssertGreaterThan(pars[35], pars[23])
    }

    func testWallsCratesAndUndo() throws {
        let level = try XCTUnwrap(LevelCatalog.level(1))
        var puzzle = try Puzzle(level: level)
        XCTAssertEqual(puzzle.step(.left), .blocked)
        XCTAssertEqual(puzzle.step(.up), .blocked)
        XCTAssertEqual(puzzle.moves, 0)
        XCTAssertFalse(puzzle.canUndo)
        let pushed = puzzle.step(.right)
        XCTAssertEqual(pushed, .pushed(ontoGoal: true, crateID: 1))
        XCTAssertTrue(puzzle.isWon)
        XCTAssertEqual(puzzle.moves, 1)
        XCTAssertEqual(puzzle.pushes, 1)
        XCTAssertTrue(puzzle.undo())
        XCTAssertFalse(puzzle.isWon)
        XCTAssertEqual(puzzle.moves, 0)
        XCTAssertFalse(puzzle.canUndo)
    }

    func testCannotPushTwoCratesOrIntoAWall() throws {
        let level = LevelDefinition(
            index: 900,
            world: 1,
            worldName: "Meadow",
            title: "Fixture",
            par: 1,
            rows: [
                "#######",
                "#@$$..#",
                "#######",
            ]
        )
        var puzzle = try Puzzle(level: level)
        XCTAssertEqual(puzzle.step(.right), .blocked)
        XCTAssertEqual(puzzle.moves, 0)
        XCTAssertEqual(puzzle.crates.map(\.point.col), [2, 3])
    }

    func testWalkOntoADaisyAndPushOffIt() throws {
        let level = LevelDefinition(
            index: 901,
            world: 1,
            worldName: "Meadow",
            title: "Daisy",
            par: 3,
            rows: [
                "######",
                "#@.$ #",
                "######",
            ]
        )
        var puzzle = try Puzzle(level: level)
        XCTAssertEqual(puzzle.step(.right), .walked)
        XCTAssertTrue(puzzle.goals.contains(puzzle.player))
        XCTAssertEqual(puzzle.step(.right), .pushed(ontoGoal: false, crateID: 1))
        XCTAssertFalse(puzzle.isWon)
        puzzle.restart()
        XCTAssertEqual(puzzle.moves, 0)
        XCTAssertEqual(puzzle.player, GridPoint(row: 1, col: 1))
    }

    func testRejectedLevels() {
        let ragged = LevelDefinition(index: 1, world: 1, worldName: "Meadow", title: "Rag", par: 1, rows: ["###", "#@"])
        XCTAssertThrowsError(try Puzzle(level: ragged)) { error in
            XCTAssertEqual(error as? LevelError, .ragged)
        }
        let mismatch = LevelDefinition(index: 1, world: 1, worldName: "Meadow", title: "Bad", par: 1, rows: ["####", "#@.#", "####"])
        XCTAssertThrowsError(try Puzzle(level: mismatch))
    }

    func testStarsUnlockAndRoundTrip() throws {
        XCTAssertEqual(SaveGame.stars(moves: 10, par: 10), 3)
        XCTAssertEqual(SaveGame.stars(moves: 12, par: 10), 3)
        XCTAssertEqual(SaveGame.stars(moves: 13, par: 10), 2)
        XCTAssertEqual(SaveGame.stars(moves: 40, par: 10), 1)

        var save = SaveGame()
        XCTAssertTrue(save.isUnlocked(1, levelCount: 36))
        XCTAssertFalse(save.isUnlocked(2, levelCount: 36))
        XCTAssertEqual(save.nextPlayableIndex(levelCount: 36), 1)

        XCTAssertTrue(save.recordClear(level: 1, moves: 20, par: 8))
        XCTAssertEqual(save.records[1]?.stars, 1)
        XCTAssertTrue(save.isUnlocked(2, levelCount: 36))
        XCTAssertFalse(save.recordClear(level: 1, moves: 30, par: 8))
        XCTAssertEqual(save.records[1]?.bestMoves, 20)
        XCTAssertTrue(save.recordClear(level: 1, moves: 9, par: 8))
        XCTAssertEqual(save.records[1]?.bestMoves, 9)
        XCTAssertEqual(save.records[1]?.stars, 3)
        XCTAssertEqual(save.clearedCount, 1)
        XCTAssertEqual(save.starCount, 3)
        XCTAssertEqual(save.nextPlayableIndex(levelCount: 36), 2)

        save.soundOn = false
        save.sawHint = true
        let decoded = try SaveGame.decoded(try save.encoded())
        XCTAssertEqual(decoded, save)
    }
}
