import XCTest
@testable import VermessaCore

final class PersistenceAndStarterTests: XCTestCase {
    private let today = CalendarDay(year: 2026, month: 11, day: 13)

    func testStarterInstallsOnceAndKeepsAUsableSpread() throws {
        var library = WardrobeLibrary()
        XCTAssertTrue(library.installStarterIfNeeded(today: today))
        XCTAssertFalse(library.installStarterIfNeeded(today: today))
        XCTAssertEqual(library.lipsticks.filter { $0.ownership == .owned }.count, 8)
        XCTAssertEqual(library.lipsticks.filter { $0.ownership == .wishlist }.count, 2)
        XCTAssertEqual(Set(library.lipsticks.map(\.name)).count, 10)
        XCTAssertTrue(library.snapshot.starterInstalled)
        XCTAssertEqual(library.wears.count, 6)
        XCTAssertNil(library.lastWornDay(for: StarterWardrobe.identifier(1), onOrBefore: today))
        let rose = try XCTUnwrap(library.lastWornDay(for: StarterWardrobe.identifier(4), onOrBefore: today))
        XCTAssertEqual(rose, today.adding(days: -1))
        XCTAssertTrue(library.wornLipsticks(on: today).isEmpty)

        let names = Set(library.lipsticks.map(\.name))
        XCTAssertTrue(names.contains("Cellar Merlot"))
        XCTAssertTrue(names.contains("Noon Terracotta"))
        let coral = try XCTUnwrap(library.lipsticks.first { $0.name == "Lantern Coral" })
        XCTAssertEqual(coral.shade.hex, "E15A3C")
        XCTAssertEqual(coral.finish, .cream)
        XCTAssertEqual(coral.undertone, .warm)
        XCTAssertEqual(coral.occasions, [.date, .photos])
    }

    func testStarterDoesNotReplaceAnExistingDrawerOrAClearedOne() throws {
        var filled = WardrobeLibrary()
        _ = try filled.add(LipstickDraft(
            name: "Only Mine",
            finish: .gloss,
            undertone: .neutral,
            colorFamily: .pink,
            shade: try ShadeColor(hex: "E7B6C4"),
            ownership: .owned
        ))
        XCTAssertFalse(filled.installStarterIfNeeded(today: today))
        XCTAssertEqual(filled.lipsticks.map(\.name), ["Only Mine"])

        var cleared = WardrobeSnapshot.empty
        cleared.starterInstalled = true
        var library = WardrobeLibrary(snapshot: cleared)
        XCTAssertFalse(library.installStarterIfNeeded(today: today))
        XCTAssertTrue(library.lipsticks.isEmpty)
    }

    func testRoundTripAndMissingFile() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = JSONWardrobeStore(fileURL: directory.appendingPathComponent("drawer.json"))
        let missing = try store.load()
        XCTAssertEqual(missing, .empty)

        var library = WardrobeLibrary()
        _ = library.installStarterIfNeeded(today: today)
        let saved = try library.add(
            LipstickDraft(
                name: "Pocket Rose",
                brand: "North Satin",
                finish: .satin,
                undertone: .neutral,
                colorFamily: .rose,
                occasions: [.office],
                shade: try ShadeColor(hex: "B15C6C"),
                swatchFileName: "pocket.jpg",
                ownership: .owned
            ),
            id: UUID(uuidString: "22222222-2222-4222-8222-222222222222")!
        )
        _ = try library.markWorn(lipstickID: saved.id, on: today, id: UUID(uuidString: "33333333-3333-4333-8333-333333333333")!)
        try store.save(library.snapshot)

        let loaded = try store.load()
        XCTAssertEqual(loaded, library.snapshot)
        let restored = WardrobeLibrary(snapshot: loaded)
        XCTAssertEqual(restored.lipstick(id: saved.id)?.swatchFileName, "pocket.jpg")
        XCTAssertEqual(restored.wornLipsticks(on: today).map(\.name), ["Pocket Rose"])
    }

    func testCorruptAndUnknownVersionAreUnreadable() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("drawer.json")
        let store = JSONWardrobeStore(fileURL: url)
        try Data("not json".utf8).write(to: url)
        XCTAssertThrowsError(try store.load()) { error in
            XCTAssertEqual(error as? WardrobeStoreError, .unreadable)
        }

        let unknown = """
        {"formatVersion":9,"lipsticks":[],"starterInstalled":false,"wears":[]}
        """
        try Data(unknown.utf8).write(to: url)
        XCTAssertThrowsError(try store.load()) { error in
            XCTAssertEqual(error as? WardrobeStoreError, .unreadable)
        }
    }

    func testSaveCreatesMissingDirectory() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("nested")
        defer { try? FileManager.default.removeItem(at: directory.deletingLastPathComponent()) }
        let store = JSONWardrobeStore(fileURL: directory.appendingPathComponent("drawer.json"))
        try store.save(.empty)
        let loaded = try store.load()
        XCTAssertEqual(loaded, .empty)
    }
}
