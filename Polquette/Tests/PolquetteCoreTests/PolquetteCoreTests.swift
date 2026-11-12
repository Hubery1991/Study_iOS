import XCTest
@testable import PolquetteCore

final class PolquetteCoreTests: XCTestCase {
    func testPaletteIsCompleteAndUnique() {
        XCTAssertEqual(NailShape.allCases.count, 6)
        XCTAssertEqual(Finish.allCases.count, 6)
        XCTAssertEqual(DecorationKind.allCases.count, 6)
        XCTAssertEqual(Set(Palette.colors.map(\.id)).count, Palette.colors.count)
        XCTAssertGreaterThanOrEqual(Palette.colors.count, 24)
        XCTAssertEqual(Set(Palette.motifs.map(\.id)).count, Palette.motifs.count)
        for color in Palette.colors {
            XCTAssertEqual(color.hex.count, 6)
            let rgba = color.rgba
            XCTAssertGreaterThan(rgba.red + rgba.green + rgba.blue, 0)
        }
        XCTAssertEqual(Palette.color(id: "burgundy")?.family, .berry)
        XCTAssertEqual(Palette.motif(id: "pearl")?.kind, .pearl)
        XCTAssertEqual(Palette.motif(id: "tip-line")?.kind, .line)
        XCTAssertEqual(Palette.motif(id: "daisy")?.kind, .flower)
        XCTAssertNil(Palette.color(id: "nope"))
    }

    func testBlankManicureHasFiveNails() {
        let manicure = Manicure.blank(id: StableID.uuid(1), now: date(0))
        XCTAssertEqual(manicure.nails.count, 5)
        XCTAssertTrue(manicure.nails.allSatisfy { $0 == .bare })
        XCTAssertEqual(manicure.nail(.ring).shape, .almond)
    }

    func testShortNailListIsPadded() {
        let manicure = Manicure(id: StableID.uuid(2), name: "Short", nails: [.bare], createdAt: date(0))
        XCTAssertEqual(manicure.nails.count, 5)
        XCTAssertEqual(manicure.nail(.pinky), .bare)
    }

    func testPaintAllFiveAndASingleNail() {
        var studio = NailStudio(manicure: Manicure.blank(id: StableID.uuid(3), now: date(0)))
        XCTAssertTrue(studio.setColor("burgundy"))
        XCTAssertTrue(studio.manicure.nails.allSatisfy { $0.colorID == "burgundy" })
        studio.select(.ring)
        XCTAssertEqual(studio.scope.title, "Ring")
        XCTAssertTrue(studio.setShape(.stiletto))
        XCTAssertTrue(studio.setFinish(.chrome))
        XCTAssertEqual(studio.manicure.nail(.ring).shape, .stiletto)
        XCTAssertEqual(studio.manicure.nail(.ring).finish, .chrome)
        XCTAssertEqual(studio.manicure.nail(.index).shape, .almond)
        XCTAssertEqual(studio.manicure.nail(.index).finish, .gloss)
        XCTAssertEqual(studio.manicure.nail(.index).colorID, "burgundy")
    }

    func testUnknownColorDoesNotUndo() {
        var studio = NailStudio()
        XCTAssertFalse(studio.setColor("missing"))
        XCTAssertFalse(studio.canUndo)
        XCTAssertEqual(studio.manicure.nail(.thumb).colorID, Palette.balletID)
    }

    func testFrenchAndGradientClamp() {
        var studio = NailStudio()
        XCTAssertTrue(studio.setFrench(enabled: true, colorID: "white", coverage: 0.9))
        XCTAssertEqual(studio.manicure.nail(.thumb).french.coverage, 0.48, accuracy: 0.0001)
        XCTAssertTrue(studio.manicure.nails.allSatisfy { $0.french.enabled && $0.french.colorID == "white" })
        XCTAssertTrue(studio.setGradient(enabled: true, endColorID: "coral", angle: -28))
        XCTAssertEqual(studio.manicure.nail(.middle).gradient.angle, 332, accuracy: 0.0001)
        XCTAssertTrue(studio.manicure.nail(.middle).gradient.enabled)
        XCTAssertFalse(studio.setFrench(enabled: true, colorID: "no-such-color"))
        XCTAssertFalse(studio.setGradient(enabled: true, endColorID: "no-such-color"))
    }

    func testSameValueDoesNotPushUndo() {
        var studio = NailStudio()
        XCTAssertFalse(studio.setShape(.almond))
        XCTAssertFalse(studio.setFinish(.gloss))
        XCTAssertFalse(studio.canUndo)
        XCTAssertTrue(studio.setFinish(.matte))
        XCTAssertTrue(studio.canUndo)
        XCTAssertFalse(studio.setFinish(.matte))
        XCTAssertEqual(studio.undoStack.count, 1)
    }

    func testDecorationCapUndoAndClear() {
        var studio = NailStudio()
        studio.select(.index)
        for _ in 0..<NailDesign.maxDecorations {
            XCTAssertTrue(studio.addDecoration(motifID: "pearl", colorID: "white"))
        }
        XCTAssertEqual(studio.manicure.nail(.index).decorations.count, 4)
        XCTAssertEqual(studio.manicure.nail(.thumb).decorations.count, 0)
        XCTAssertFalse(studio.addDecoration(motifID: "pearl", colorID: "white"))
        XCTAssertEqual(studio.undoStack.count, 4)
        XCTAssertFalse(studio.addDecoration(motifID: "missing", colorID: "white"))
        XCTAssertTrue(studio.undo())
        XCTAssertEqual(studio.manicure.nail(.index).decorations.count, 3)
        XCTAssertTrue(studio.redo())
        XCTAssertEqual(studio.manicure.nail(.index).decorations.count, 4)
        XCTAssertTrue(studio.clearDecorations())
        XCTAssertTrue(studio.manicure.nail(.index).decorations.isEmpty)
        XCTAssertFalse(studio.canRedo)
    }

    func testLinePlacementSitsNearTheTip() {
        let line = PlacedDecoration.automatic(motifID: "tip-line", colorID: "gold", index: 0, id: StableID.uuid(9))
        XCTAssertEqual(line.y, 0.28, accuracy: 0.0001)
        let slant = PlacedDecoration.automatic(motifID: "slant", colorID: "gold", index: 1, id: StableID.uuid(10))
        XCTAssertEqual(slant.rotation, -28, accuracy: 0.0001)
        let pearl = PlacedDecoration.automatic(motifID: "pearl", colorID: "white", index: 3, id: StableID.uuid(11))
        XCTAssertEqual(pearl.y, 0.72, accuracy: 0.0001)
    }

    func testUndoRedoAndLimit() {
        var studio = NailStudio(manicure: Manicure.blank(id: StableID.uuid(4), now: date(0)))
        for index in 0..<(NailStudio.undoLimit + 5) {
            XCTAssertTrue(studio.setColor(index.isMultiple(of: 2) ? "wine" : "sage"))
        }
        XCTAssertEqual(studio.undoStack.count, NailStudio.undoLimit)
        let latest = studio.manicure
        XCTAssertTrue(studio.undo())
        XCTAssertNotEqual(studio.manicure, latest)
        XCTAssertTrue(studio.redo())
        XCTAssertEqual(studio.manicure, latest)
        XCTAssertFalse(studio.redo())
        XCTAssertTrue(studio.setFinish(.glitter))
        XCTAssertFalse(studio.canRedo)
    }

    func testApplyLookIsUndoable() {
        var studio = NailStudio(manicure: Manicure.blank(id: StableID.uuid(5), now: date(0)))
        let before = studio.manicure
        XCTAssertTrue(studio.apply(look: Lookbook.burgundyFoil))
        XCTAssertEqual(studio.manicure.name, "Burgundy Foil")
        XCTAssertTrue(studio.manicure.nails.allSatisfy { $0.shape == .coffin && $0.colorID == "burgundy" })
        XCTAssertEqual(studio.manicure.id, before.id)
        XCTAssertTrue(studio.undo())
        XCTAssertEqual(studio.manicure, before)
    }

    func testCuratedLooksMatchTheirChairs() {
        XCTAssertGreaterThanOrEqual(Lookbook.looks.count, 8)
        XCTAssertEqual(Set(Lookbook.looks.map(\.id)).count, Lookbook.looks.count)
        let names = Set(Lookbook.looks.map(\.name))
        XCTAssertTrue(names.contains("Blush Pearl"))
        XCTAssertTrue(names.contains("Burgundy Foil"))
        XCTAssertTrue(names.contains("Colorful Bloom"))
        XCTAssertTrue(names.contains("Nude Gold Line"))
        assertThreeStars(Lookbook.blushPearl, briefID: "blush-appointment")
        assertThreeStars(Lookbook.burgundyFoil, briefID: "evening-foil")
        assertThreeStars(Lookbook.colorfulBloom, briefID: "garden-party")
        assertThreeStars(Lookbook.nudeGoldLine, briefID: "quiet-gold")
        assertThreeStars(Lookbook.midnightChrome, briefID: "midnight-chrome")
        assertThreeStars(Lookbook.sageCream, briefID: "sage-cream")
        assertThreeStars(Lookbook.coralGlitter, briefID: "coral-glitter")
        assertThreeStars(Lookbook.ivoryFrench, briefID: "ivory-french")
    }

    func testStarBands() {
        let brief = Career.clients[4].brief
        let none = Scoring.score(Manicure.blank(now: date(0)), brief: brief)
        XCTAssertEqual(none.stars, 0)
        XCTAssertEqual(none.metCount, 0)

        var studio = NailStudio(manicure: Manicure.blank(id: StableID.uuid(6), now: date(0)))
        studio.setShape(.stiletto)
        let one = Scoring.score(studio.manicure, brief: brief)
        XCTAssertEqual(one.stars, 1)

        var almost = Lookbook.blushPearl.manicure
        almost.nails[Finger.pinky.rawValue].finish = .gloss
        let two = Scoring.score(almost, brief: Career.clients[0].brief)
        XCTAssertEqual(two.metCount, two.total - 1)
        XCTAssertEqual(two.stars, 2)
    }

    func testDecorationCountsNailsNotPieces() {
        var nail = NailDesign(shape: .oval, colorID: "petal", finish: .gloss)
        nail.decorations = [
            PlacedDecoration.automatic(motifID: "daisy", colorID: "coral", index: 0, id: StableID.uuid(21)),
            PlacedDecoration.automatic(motifID: "blossom", colorID: "coral", index: 1, id: StableID.uuid(22)),
        ]
        let manicure = Manicure(
            id: StableID.uuid(7),
            name: "One nail",
            nails: [nail, .bare, .bare, .bare, .bare],
            createdAt: date(0)
        )
        let score = Scoring.score(manicure, brief: Career.clients[2].brief)
        let flower = score.checks.first { $0.label.contains("Flowers") }
        XCTAssertEqual(flower?.met, false)
    }

    func testDailyChallengeIsDeterministic() {
        let first = DailyChallenge.brief(on: day(2026, 11, 11))
        let again = DailyChallenge.brief(on: day(2026, 11, 11))
        let next = DailyChallenge.brief(on: day(2026, 11, 12))
        XCTAssertEqual(first, again)
        XCTAssertNotEqual(first.id, next.id)
        XCTAssertEqual(DailyChallenge.dayKey(on: day(2026, 11, 11)), "2026-11-11")
        XCTAssertEqual(DailyChallenge.index(for: day(2026, 11, 11)), DailyChallenge.index(for: day(2026, 11, 11)))
        XCTAssertTrue(DailyChallenge.catalog.contains { $0.id == first.id })
        let seeded = (2026 * 400 + 11 * 32 + 11) % DailyChallenge.catalog.count
        XCTAssertEqual(DailyChallenge.index(for: day(2026, 11, 11)), seeded)
    }

    func testCareerUnlocksInOrderAndKeepsTheBest() {
        var progress = CareerProgress()
        XCTAssertTrue(Career.isUnlocked(index: 0, progress: progress))
        XCTAssertFalse(Career.isUnlocked(index: 1, progress: progress))
        XCTAssertFalse(progress.record(index: 1, stars: 3))
        XCTAssertTrue(progress.record(index: 0, stars: 1))
        XCTAssertEqual(progress.unlockedCount, 2)
        XCTAssertTrue(Career.isUnlocked(index: 1, progress: progress))
        XCTAssertFalse(progress.record(index: 0, stars: 1))
        XCTAssertTrue(progress.record(index: 0, stars: 3))
        XCTAssertEqual(progress.stars(for: Career.clients[0].id), 3)
        XCTAssertEqual(progress.totalStars, 3)
        XCTAssertFalse(progress.record(index: 0, stars: 2))
        XCTAssertEqual(progress.stars(for: Career.clients[0].id), 3)
    }

    func testChallengeDayKeepsTheBestStars() {
        var record = ChallengeRecord()
        XCTAssertTrue(record.record(day: "2026-11-11", stars: 2))
        XCTAssertFalse(record.record(day: "2026-11-11", stars: 1))
        XCTAssertTrue(record.record(day: "2026-11-11", stars: 9))
        XCTAssertEqual(record.stars(on: "2026-11-11"), 3)
        XCTAssertEqual(record.stars(on: "2026-11-12"), 0)
    }

    func testLookNamesAreCleaned() {
        XCTAssertEqual(SalonArchive.cleanedName("   "), "Untitled look")
        XCTAssertEqual(SalonArchive.cleanedName("  Blush   Pearl  "), "Blush Pearl")
        let long = String(repeating: "a", count: 50)
        XCTAssertEqual(SalonArchive.cleanedName(long).count, 40)
    }

    func testGalleryRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("polquette-\(UUID().uuidString).json")
        let store = SalonStore(url: url)
        var archive = try store.load()
        XCTAssertEqual(archive, .empty)
        let saved = archive.saveLook(
            name: "  Evening foil ",
            manicure: Lookbook.burgundyFoil.manicure,
            now: date(1_700_000_000),
            id: StableID.uuid(70)
        )
        XCTAssertEqual(saved.name, "Evening foil")
        archive.career.record(index: 0, stars: 3)
        archive.challenges.record(day: "2026-11-11", stars: 2)
        archive.hapticsEnabled = false
        archive.hasSeenPrimer = true
        try store.save(archive)
        let loaded = try store.load()
        XCTAssertEqual(loaded.looks.count, 1)
        XCTAssertEqual(loaded.looks[0].name, "Evening foil")
        XCTAssertEqual(loaded.looks[0].manicure.nail(.thumb).colorID, "burgundy")
        XCTAssertEqual(loaded.looks[0].manicure.nail(.thumb).decorations.count, 2)
        XCTAssertEqual(loaded.career.stars(for: "blush-appointment"), 3)
        XCTAssertEqual(loaded.challenges.stars(on: "2026-11-11"), 2)
        XCTAssertFalse(loaded.hapticsEnabled)
        XCTAssertTrue(loaded.hasSeenPrimer)
        XCTAssertTrue(archive.deleteLook(id: saved.id))
        XCTAssertFalse(archive.deleteLook(id: saved.id))
        archive.resetProgress()
        XCTAssertTrue(archive.looks.isEmpty)
        XCTAssertEqual(archive.career.totalStars, 0)
        try? FileManager.default.removeItem(at: url)
    }

    func testCorruptFileThrowsAndLoadRestoresASavedLook() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("polquette-bad-\(UUID().uuidString).json")
        try Data("not json".utf8).write(to: url)
        XCTAssertThrowsError(try SalonStore(url: url).load())
        try? FileManager.default.removeItem(at: url)

        var studio = NailStudio(manicure: Manicure.blank(id: StableID.uuid(8), now: date(0)))
        var archive = SalonArchive()
        let saved = archive.saveLook(name: "Sage", manicure: Lookbook.sageCream.manicure, now: date(50), id: StableID.uuid(80))
        XCTAssertTrue(studio.load(saved: saved))
        XCTAssertEqual(studio.manicure.name, "Sage")
        XCTAssertTrue(studio.manicure.nails.allSatisfy { $0.colorID == "sage" && $0.shape == .square })
        XCTAssertTrue(studio.undo())
        XCTAssertEqual(studio.manicure.nail(.thumb).colorID, Palette.balletID)
    }

    func testHouseSignatureRejectsPlainGloss() {
        let brief = Career.clients[11].brief
        let gloss = Scoring.score(Lookbook.ivoryFrench.manicure, brief: brief)
        XCTAssertEqual(gloss.checks.first { $0.label == "Any finish but gloss" }?.met, false)
        var studio = NailStudio(manicure: Manicure.blank(id: StableID.uuid(12), now: date(0)))
        studio.setFinish(.chrome)
        studio.addDecoration(motifID: "round-gem", colorID: "silver")
        let score = Scoring.score(studio.manicure, brief: brief)
        XCTAssertEqual(score.stars, 3)
    }

    private func assertThreeStars(_ look: CuratedLook, briefID: String) {
        let brief = Career.clients.first { $0.id == briefID }!.brief
        let score = Scoring.score(look.manicure, brief: brief)
        XCTAssertEqual(score.stars, 3, "\(look.name) missed \(score.checks.filter { !$0.met }.map(\.label))")
    }

    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: seconds)
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = 15
        return DailyChallenge.calendar.date(from: parts)!
    }
}
