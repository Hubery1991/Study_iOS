import XCTest
@testable import VermessaCore

final class LibraryTests: XCTestCase {
    private let today = CalendarDay(year: 2026, month: 11, day: 13)

    private func merlotDraft(ownership: Ownership = .owned, name: String = " Cellar Merlot ") -> LipstickDraft {
        LipstickDraft(
            name: name,
            brand: "  Orchard Lacquer  ",
            finish: .stain,
            undertone: .cool,
            colorFamily: .wine,
            occasions: [.date, .evening, .evening],
            shade: try! ShadeColor(hex: "6E2436"),
            swatchFileName: " tube.jpg ",
            ownership: ownership
        )
    }

    func testAddTrimsAndOrdersFields() throws {
        var library = WardrobeLibrary()
        let created = Date(timeIntervalSince1970: 1_700_100_000)
        let id = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let saved = try library.add(merlotDraft(), id: id, createdAt: created)
        XCTAssertEqual(saved.name, "Cellar Merlot")
        XCTAssertEqual(saved.brand, "Orchard Lacquer")
        XCTAssertEqual(saved.occasions, [.date, .evening])
        XCTAssertEqual(saved.swatchFileName, "tube.jpg")
        XCTAssertEqual(saved.createdAt, created)
        XCTAssertEqual(library.lipsticks.count, 1)
    }

    func testEmptyNameAndUnsafePhotoAreRejected() {
        var library = WardrobeLibrary()
        XCTAssertThrowsError(try library.add(merlotDraft(name: "   "))) { error in
            XCTAssertEqual(error as? WardrobeError, .emptyName)
        }
        var draft = merlotDraft()
        draft.swatchFileName = "../secret.jpg"
        XCTAssertThrowsError(try library.add(draft)) { error in
            XCTAssertEqual(error as? WardrobeError, .unsafeFileName)
        }
        draft.swatchFileName = "notes/tube.jpg"
        XCTAssertThrowsError(try library.add(draft)) { error in
            XCTAssertEqual(error as? WardrobeError, .unsafeFileName)
        }
        XCTAssertTrue(library.lipsticks.isEmpty)
    }

    func testBlankBrandBecomesNil() throws {
        var library = WardrobeLibrary()
        var draft = merlotDraft()
        draft.brand = "   "
        let saved = try library.add(draft)
        XCTAssertNil(saved.brand)
    }

    func testUpdateKeepsCreatedAtAndRejectsMissing() throws {
        var library = WardrobeLibrary()
        let created = Date(timeIntervalSince1970: 50)
        let saved = try library.add(merlotDraft(), createdAt: created)
        var edited = saved
        edited.name = "Evening Merlot"
        edited.finish = .matte
        edited.createdAt = Date(timeIntervalSince1970: 99)
        try library.update(edited)
        let stored = try XCTUnwrap(library.lipstick(id: saved.id))
        XCTAssertEqual(stored.name, "Evening Merlot")
        XCTAssertEqual(stored.finish, .matte)
        XCTAssertEqual(stored.createdAt, created)

        edited.id = UUID()
        XCTAssertThrowsError(try library.update(edited)) { error in
            XCTAssertEqual(error as? WardrobeError, .missingLipstick)
        }
    }

    func testDeleteRemovesWearHistory() throws {
        var library = WardrobeLibrary()
        let saved = try library.add(merlotDraft())
        _ = try library.markWorn(lipstickID: saved.id, on: today)
        try library.delete(id: saved.id)
        XCTAssertTrue(library.lipsticks.isEmpty)
        XCTAssertTrue(library.wears.isEmpty)
        XCTAssertThrowsError(try library.delete(id: saved.id)) { error in
            XCTAssertEqual(error as? WardrobeError, .missingLipstick)
        }
    }

    func testWearIsIdempotentAndWishlistIsBlocked() throws {
        var library = WardrobeLibrary()
        let saved = try library.add(merlotDraft())
        let first = try library.markWorn(lipstickID: saved.id, on: today, id: UUID())
        let second = try library.markWorn(lipstickID: saved.id, on: today, id: UUID())
        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(library.wears.count, 1)
        XCTAssertTrue(library.clearWorn(lipstickID: saved.id, on: today))
        XCTAssertFalse(library.clearWorn(lipstickID: saved.id, on: today))

        let wished = try library.add(merlotDraft(ownership: .wishlist, name: "Winter Currant"))
        XCTAssertThrowsError(try library.markWorn(lipstickID: wished.id, on: today)) { error in
            XCTAssertEqual(error as? WardrobeError, .wishlistCannotBeWorn)
        }
        XCTAssertThrowsError(try library.markWorn(lipstickID: UUID(), on: today)) { error in
            XCTAssertEqual(error as? WardrobeError, .missingLipstick)
        }
    }

    func testHistoryGroupsDaysAndIgnoresFutureWhenScoringRecency() throws {
        var library = WardrobeLibrary()
        let saved = try library.add(merlotDraft())
        let yesterday = try XCTUnwrap(today.adding(days: -1))
        let nextWeek = try XCTUnwrap(today.adding(days: 7))
        _ = try library.markWorn(lipstickID: saved.id, on: yesterday)
        _ = try library.markWorn(lipstickID: saved.id, on: nextWeek)
        XCTAssertEqual(library.daysSinceLastWear(for: saved.id, on: today), 1)
        XCTAssertEqual(library.wornLipsticks(on: nextWeek).map(\.id), [saved.id])
        XCTAssertEqual(library.history().map(\.day), [nextWeek, yesterday])
    }

    func testFiltersCombineAndSearchNames() throws {
        var library = WardrobeLibrary()
        _ = library.installStarterIfNeeded(today: today)
        let nudes = library.filtered(WardrobeFilter(families: [.nude], ownership: .owned))
        XCTAssertEqual(nudes.map(\.name), ["Bare Apricot", "Dusty Blush"])

        let eveningMatte = library.filtered(WardrobeFilter(finishes: [.matte], occasions: [.evening], ownership: .owned))
        XCTAssertEqual(eveningMatte.map(\.name), ["Ink Plum"])

        let orchard = library.filtered(WardrobeFilter(text: "ORCHARD", ownership: .owned))
        XCTAssertEqual(orchard.map(\.name), ["Cellar Merlot", "Ink Plum"])

        let none = library.filtered(WardrobeFilter(text: "zzz", ownership: .owned))
        XCTAssertTrue(none.isEmpty)

        let wish = library.filtered(WardrobeFilter(ownership: .wishlist))
        XCTAssertEqual(wish.map(\.name), ["Noon Terracotta", "Winter Currant"])

        let narrowed = WardrobeFilter(text: "coral", finishes: [.cream])
        XCTAssertTrue(narrowed.isNarrowed)
        XCTAssertFalse(WardrobeFilter().isNarrowed)
    }

    func testOwnershipMove() throws {
        var library = WardrobeLibrary()
        let saved = try library.add(merlotDraft(ownership: .wishlist, name: "Winter Currant"))
        try library.setOwnership(id: saved.id, to: .owned)
        XCTAssertEqual(library.lipstick(id: saved.id)?.ownership, .owned)
        XCTAssertThrowsError(try library.setOwnership(id: UUID(), to: .owned))
    }
}
