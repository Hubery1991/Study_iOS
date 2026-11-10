import XCTest
@testable import ClavewellCore

final class ClavewellCoreTests: XCTestCase {
    func testScoreFormula() {
        XCTAssertEqual(ScoreFormula.points(count: 0, chain: 1), 0)
        XCTAssertEqual(ScoreFormula.points(count: 3, chain: 0), 0)
        XCTAssertEqual(ScoreFormula.points(count: 1, chain: 1), 100)
        XCTAssertEqual(ScoreFormula.points(count: 2, chain: 1), 200)
        XCTAssertEqual(ScoreFormula.points(count: 3, chain: 1), 300)
        XCTAssertEqual(ScoreFormula.points(count: 4, chain: 1), 440)
        XCTAssertEqual(ScoreFormula.points(count: 5, chain: 2), 1160)
        XCTAssertEqual(ScoreFormula.points(count: 3, chain: 2), 600)
    }

    func testDiagonalDoesNotMatchAndCheckerboardIsQuiet() {
        var board = WellBoard()
        board.set(CellCoord(row: 9, column: 0), .amber)
        board.set(CellCoord(row: 9, column: 1), .tide)
        board.set(CellCoord(row: 8, column: 0), .tide)
        board.set(CellCoord(row: 8, column: 1), .amber)
        XCTAssertTrue(board.groups().isEmpty)

        var checker = WellBoard()
        for row in 0..<WellBoard.rows {
            for column in 0..<WellBoard.columns {
                let hue: Hue = (row + column).isMultiple(of: 2) ? .amber : .tide
                checker.set(CellCoord(row: row, column: column), hue)
            }
        }
        XCTAssertTrue(checker.groups().isEmpty)
        XCTAssertFalse(checker.hasOpenColumn())
    }

    func testOrthogonalGroupAndCollapse() {
        var board = WellBoard()
        board.set(CellCoord(row: 9, column: 0), .rose)
        board.set(CellCoord(row: 9, column: 1), .amber)
        board.set(CellCoord(row: 9, column: 2), .amber)
        board.set(CellCoord(row: 8, column: 1), .amber)
        board.set(CellCoord(row: 7, column: 0), .moss)
        let groups = board.groups()
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(Set(groups[0]).count, 3)

        board.remove(groups[0])
        board.collapse()
        XCTAssertEqual(board.hue(CellCoord(row: 9, column: 0)), .rose)
        XCTAssertEqual(board.hue(CellCoord(row: 8, column: 0)), .moss)
        XCTAssertNil(board.hue(CellCoord(row: 9, column: 1)))
        XCTAssertTrue(board.groups().isEmpty)
    }

    func testHorizontalThreeClearsForThreeHundred() {
        let session = MatchSession(
            mode: .stillwater,
            seed: 7,
            scriptedQueue: [.amber, .amber, .amber, .tide, .moss, .violet]
        )
        XCTAssertEqual(session.current, .amber)
        XCTAssertFalse(session.drop(in: 0).gameOver)
        XCTAssertEqual(session.score, 0)
        XCTAssertFalse(session.drop(in: 1).gameOver)
        XCTAssertEqual(session.score, 0)
        let third = session.drop(in: 2)
        XCTAssertTrue(third.accepted)
        XCTAssertFalse(third.gameOver)
        XCTAssertEqual(session.score, 300)
        XCTAssertEqual(session.motesCleared, 3)
        XCTAssertEqual(session.chainBest, 1)
        XCTAssertEqual(session.board.occupiedCount, 0)
        XCTAssertEqual(points(in: third), 300)
        XCTAssertEqual(third.frames.first?.kind, .place)
        XCTAssertTrue(third.frames.contains { $0.banner == "Resonance ×1" })
    }

    func testChainReactionScoresBothSteps() {
        let session = MatchSession(
            mode: .stillwater,
            seed: 3,
            scriptedQueue: [.tide, .amber, .amber, .amber]
        )
        session.board.set(CellCoord(row: 9, column: 1), .tide)
        session.board.set(CellCoord(row: 9, column: 2), .tide)
        session.board.set(CellCoord(row: 8, column: 2), .rose)
        session.board.set(CellCoord(row: 7, column: 2), .rose)
        session.board.set(CellCoord(row: 9, column: 3), .rose)

        let outcome = session.drop(in: 0)
        XCTAssertTrue(outcome.accepted)
        XCTAssertFalse(outcome.gameOver)
        XCTAssertEqual(session.score, 900)
        XCTAssertEqual(session.chainBest, 2)
        XCTAssertEqual(session.motesCleared, 6)
        XCTAssertEqual(session.board.occupiedCount, 0)
        XCTAssertEqual(points(in: outcome), 900)
        XCTAssertTrue(outcome.frames.contains { $0.banner == "Resonance ×2" })
        XCTAssertTrue(session.board.groups().isEmpty)
    }

    func testTwoGroupsShareOneChainStep() {
        let session = MatchSession(
            mode: .stillwater,
            seed: 1,
            scriptedQueue: [.violet, .tide, .tide, .tide]
        )
        let floor: [Hue] = [.amber, .amber, .amber, .rose, .rose, .rose]
        for column in 0..<WellBoard.columns {
            session.board.set(CellCoord(row: 9, column: column), floor[column])
        }
        let outcome = session.drop(in: 0)
        XCTAssertEqual(session.score, 600)
        XCTAssertTrue(outcome.frames.contains { $0.banner == "Double ring ×1" })
        XCTAssertEqual(session.board.hue(CellCoord(row: 9, column: 0)), .violet)
        XCTAssertEqual(session.board.occupiedCount, 1)
    }

    func testSparkBurstsNeighborsThenLeavesNoSpark() {
        let session = MatchSession(
            mode: .stillwater,
            seed: 4,
            scriptedQueue: [.spark, .amber, .tide]
        )
        session.board.set(CellCoord(row: 9, column: 0), .amber)
        session.board.set(CellCoord(row: 9, column: 2), .moss)
        let outcome = session.drop(in: 1)
        XCTAssertEqual(session.score, 200)
        XCTAssertEqual(session.motesCleared, 2)
        XCTAssertEqual(session.board.occupiedCount, 0)
        XCTAssertTrue(outcome.frames.contains { $0.banner == "Spark ×1" })
        XCTAssertTrue(session.board.coordinates { $0 == .spark }.isEmpty)
    }

    func testFullColumnRejectsWithoutSpendingTheMote() {
        let session = MatchSession(
            mode: .stillwater,
            seed: 9,
            scriptedQueue: [.amber, .tide, .moss, .violet]
        )
        let current = session.current
        let upcoming = session.upcoming
        for row in 0..<WellBoard.rows {
            let hue: Hue = row.isMultiple(of: 2) ? .amber : .tide
            session.board.set(CellCoord(row: row, column: 0), hue)
        }
        let outcome = session.drop(in: 0)
        XCTAssertFalse(outcome.accepted)
        XCTAssertFalse(outcome.gameOver)
        XCTAssertEqual(session.current, current)
        XCTAssertEqual(session.upcoming, upcoming)
        XCTAssertEqual(session.drops, 0)
        XCTAssertEqual(session.score, 0)
    }

    func testStillwaterLocksWhenTheRimIsSealed() {
        let session = MatchSession(
            mode: .stillwater,
            seed: 11,
            scriptedQueue: [.violet, .rose, .rose, .rose]
        )
        for row in 0..<WellBoard.rows {
            for column in 0..<WellBoard.columns {
                if row == 0 && column == 0 { continue }
                let hue: Hue = (row + column).isMultiple(of: 2) ? .amber : .tide
                session.board.set(CellCoord(row: row, column: column), hue)
            }
        }
        let outcome = session.drop(in: 0)
        XCTAssertTrue(outcome.gameOver)
        XCTAssertEqual(outcome.reason, .locked)
        XCTAssertEqual(session.board.occupiedCount, WellBoard.rows * WellBoard.columns)
        XCTAssertTrue(session.board.groups().isEmpty)
    }

    func testRiseInsertsThePreparedRowAndLiftsTheMote() {
        let session = MatchSession(
            mode: .cadence,
            seed: 15,
            scriptedQueue: [.amber, .tide, .moss, .violet, .rose, .amber]
        )
        session.dropsUntilRise = 1
        session.nextRiseRow = [.moss, .violet, .moss, .violet, .moss, .violet]
        let outcome = session.drop(in: 0)
        XCTAssertFalse(outcome.gameOver)
        XCTAssertEqual(session.board.hue(CellCoord(row: 8, column: 0)), .amber)
        XCTAssertEqual(
            (0..<WellBoard.columns).map { session.board.hue(CellCoord(row: 9, column: $0)) },
            [.moss, .violet, .moss, .violet, .moss, .violet]
        )
        XCTAssertEqual(session.dropsUntilRise, 8)
        XCTAssertEqual(session.riseInterval, 8)
        XCTAssertTrue(outcome.frames.contains { $0.kind == .rise && $0.banner == "The well rises" })
        XCTAssertTrue(session.board.groups().isEmpty)
    }

    func testOverflowDoesNotInsertARow() {
        let session = MatchSession(
            mode: .cadence,
            seed: 21,
            scriptedQueue: [.rose, .tide, .tide, .tide]
        )
        session.board.set(CellCoord(row: 0, column: 0), .amber)
        session.dropsUntilRise = 1
        let outcome = session.drop(in: 1)
        XCTAssertEqual(outcome.reason, .overflow)
        XCTAssertEqual(session.board.occupiedCount, 2)
        XCTAssertEqual(session.board.hue(CellCoord(row: 0, column: 0)), .amber)
        XCTAssertEqual(session.board.hue(CellCoord(row: 9, column: 1)), .rose)
        XCTAssertFalse(outcome.frames.contains { $0.kind == .rise })
    }

    func testRiseIntervalEasesDownToFour() {
        XCTAssertEqual(MatchSession.interval(afterRises: 1), 8)
        XCTAssertEqual(MatchSession.interval(afterRises: 2), 7)
        XCTAssertEqual(MatchSession.interval(afterRises: 3), 7)
        XCTAssertEqual(MatchSession.interval(afterRises: 8), 4)
        XCTAssertEqual(MatchSession.interval(afterRises: 9), 4)
        XCTAssertEqual(MatchSession.interval(afterRises: 100), 4)
    }

    func testFairRowsNeverContainATripleRun() {
        var rng = WellRNG(seed: 99)
        for _ in 0..<200 {
            let row = WellBoard.fairRow(using: &rng)
            XCTAssertEqual(row.count, WellBoard.columns)
            XCTAssertFalse(WellBoard.hasTripleRun(row))
        }
    }

    func testSparkArrivesEveryTwelfthDrawAndBagsStayEven() {
        var source = HueSource(seed: 5, scripted: nil)
        var firstBag: [Hue] = []
        for _ in 0..<10 {
            let hue = source.next()
            XCTAssertNotEqual(hue, .spark)
            firstBag.append(hue)
        }
        XCTAssertNotEqual(source.next(), .spark)
        XCTAssertEqual(source.next(), .spark)
        for hue in Hue.colors {
            XCTAssertEqual(firstBag.filter { $0 == hue }.count, 2, "\(hue.name) should appear twice in the first bag")
        }
        XCTAssertNotEqual(source.next(), .spark)
    }

    func testFlareClockAndClearBonus() {
        let session = MatchSession(
            mode: .flare,
            seed: 8,
            scriptedQueue: [.amber, .amber, .amber, .tide, .moss, .violet, .rose]
        )
        XCTAssertNil(session.tick(10))
        XCTAssertEqual(session.timeRemaining, 65, accuracy: 0.001)
        _ = session.drop(in: 0)
        _ = session.drop(in: 1)
        let cleared = session.drop(in: 2)
        XCTAssertEqual(session.score, 300)
        XCTAssertEqual(session.timeRemaining, 65.45, accuracy: 0.001)
        XCTAssertEqual(points(in: cleared), 300)
        XCTAssertNil(session.tick(65))
        XCTAssertEqual(session.tick(0.45), .time)
        XCTAssertEqual(session.timeRemaining, 0, accuracy: 0.001)
        let ignored = session.drop(in: 0)
        XCTAssertFalse(ignored.accepted)
        XCTAssertEqual(ignored.reason, .time)
    }

    func testFlareBonusIsCappedPerDrop() {
        let session = MatchSession(
            mode: .flare,
            seed: 2,
            scriptedQueue: [.spark, .amber, .tide]
        )
        for column in 0..<WellBoard.columns {
            session.board.set(CellCoord(row: 9, column: column), .amber)
        }
        // Spark lands on column 1, beside and above nothing but the floor of ambers.
        // Left, right, and below are amber, so three colored motes burst: bonus 0.45.
        _ = session.drop(in: 1)
        XCTAssertLessThanOrEqual(session.timeRemaining, MatchSession.flareDuration + 2.5 + 0.001)
        XCTAssertGreaterThan(session.motesCleared, 0)
    }

    func testRandomPlayKeepsTheWellSettled() {
        let session = MatchSession(mode: .cadence, seed: 42)
        var rng = WellRNG(seed: 42)
        for _ in 0..<80 {
            if session.isOver { break }
            let column = Int(rng.next() % UInt64(WellBoard.columns))
            let before = session.score
            let outcome = session.drop(in: column)
            if !outcome.accepted {
                XCTAssertNil(session.board.lowestEmptyRow(in: column))
                continue
            }
            XCTAssertEqual(session.score - before, points(in: outcome))
            XCTAssertGreaterThanOrEqual(session.score, 0)
            XCTAssertTrue(session.board.groups().isEmpty)
            XCTAssertTrue(session.board.coordinates { $0 == .spark }.isEmpty)
        }
    }

    func testScorebookKeepsFiveRemembersSettingsAndResetsScoresOnly() throws {
        let suite = "clavewell.test.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let book = Scorebook(defaults: defaults)
        XCTAssertTrue(book.soundEnabled)
        XCTAssertTrue(book.hapticsEnabled)
        XCTAssertFalse(book.patternsEnabled)
        XCTAssertTrue(book.landingGuideEnabled)
        XCTAssertFalse(book.seenHowTo)

        XCTAssertTrue(book.record(score: 100, bestChain: 2, motesCleared: 6, mode: .cadence, at: date(1)))
        XCTAssertFalse(book.record(score: 100, bestChain: 2, motesCleared: 6, mode: .cadence, at: date(2)))
        XCTAssertTrue(book.record(score: 240, bestChain: 4, motesCleared: 12, mode: .cadence, at: date(3)))
        XCTAssertFalse(book.record(score: 0, bestChain: 0, motesCleared: 0, mode: .stillwater, at: date(4)))
        XCTAssertEqual(book.bestScore(for: .cadence), 240)
        XCTAssertEqual(book.top(for: .cadence).map(\.score), [240, 100, 100])
        XCTAssertEqual(book.stats.gamesPlayed, 4)
        XCTAssertEqual(book.stats.motesCleared, 24)
        XCTAssertEqual(book.stats.bestChain, 4)

        for index in 0..<6 {
            book.record(score: 10 + index, bestChain: 1, motesCleared: 1, mode: .flare, at: date(10 + index))
        }
        XCTAssertEqual(book.top(for: .flare).map(\.score), [15, 14, 13, 12, 11])

        book.soundEnabled = false
        book.patternsEnabled = true
        book.seenHowTo = true
        book.resetRecords()
        XCTAssertEqual(book.bestScore(for: .cadence), 0)
        XCTAssertEqual(book.stats.gamesPlayed, 0)
        XCTAssertFalse(book.soundEnabled)
        XCTAssertTrue(book.patternsEnabled)
        XCTAssertTrue(book.seenHowTo)
        defaults.removePersistentDomain(forName: suite)
    }

    private func points(in outcome: DropOutcome) -> Int {
        outcome.frames.reduce(0) { $0 + $1.pointsJustEarned }
    }

    private func date(_ offset: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(1_700_000_000 + offset))
    }
}
