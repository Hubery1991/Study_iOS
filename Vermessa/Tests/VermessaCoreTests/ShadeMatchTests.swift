import XCTest
@testable import VermessaCore

final class ShadeMatchTests: XCTestCase {
    private let today = CalendarDay(year: 2026, month: 11, day: 13)

    func testOccasionPoints() {
        XCTAssertEqual(ShadeMatch.occasionPoints(tags: [.evening], requested: nil), 16)
        XCTAssertEqual(ShadeMatch.occasionPoints(tags: [.evening, .date], requested: .evening), 40)
        XCTAssertEqual(ShadeMatch.occasionPoints(tags: [], requested: .office), 10)
        XCTAssertEqual(ShadeMatch.occasionPoints(tags: [.brunch], requested: .evening), 0)
    }

    func testUndertoneMatrix() {
        XCTAssertEqual(ShadeMatch.undertonePoints(shade: .warm, requested: nil), 12)
        XCTAssertEqual(ShadeMatch.undertonePoints(shade: .warm, requested: .warm), 30)
        XCTAssertEqual(ShadeMatch.undertonePoints(shade: .neutral, requested: .warm), 14)
        XCTAssertEqual(ShadeMatch.undertonePoints(shade: .cool, requested: .neutral), 10)
        XCTAssertEqual(ShadeMatch.undertonePoints(shade: .warm, requested: .cool), 0)
        XCTAssertEqual(ShadeMatch.undertonePoints(shade: .cool, requested: .warm), 0)
    }

    func testRecencyBuckets() {
        let expected: [(Int?, Int)] = [
            (nil, 26),
            (0, 0),
            (-3, 0),
            (1, 4),
            (2, 8),
            (3, 8),
            (4, 14),
            (6, 14),
            (7, 20),
            (13, 20),
            (14, 26),
            (29, 26),
            (30, 30),
            (100, 30)
        ]
        for (days, points) in expected {
            XCTAssertEqual(ShadeMatch.recencyPoints(daysSinceWorn: days), points, "days \(String(describing: days))")
        }
    }

    func testReasonCopy() {
        XCTAssertEqual(ShadeMatch.occasionReason(tags: [.date], requested: .date), "Fits date")
        XCTAssertEqual(ShadeMatch.occasionReason(tags: [], requested: .office), "Occasion not set")
        XCTAssertEqual(ShadeMatch.undertoneReason(shade: .neutral, requested: .warm), "Neutral can bridge warm")
        XCTAssertEqual(ShadeMatch.undertoneReason(shade: .cool, requested: .warm), "Opposite undertone")
        XCTAssertEqual(ShadeMatch.recencyReason(daysSinceWorn: nil), "Not worn yet")
        XCTAssertEqual(ShadeMatch.recencyReason(daysSinceWorn: 1), "Worn yesterday")
        XCTAssertEqual(ShadeMatch.recencyReason(daysSinceWorn: 16), "Quiet for 16 days")
    }

    func testDateNightWarmRankingUsesOwnCollectionOnly() throws {
        var library = WardrobeLibrary()
        XCTAssertTrue(library.installStarterIfNeeded(today: today))
        let picks = library.recommendations(
            RecommendationQuery(occasion: .date, undertone: .warm, day: today, limit: 8)
        )
        XCTAssertEqual(picks.map(\.lipstick.name), [
            "Lantern Coral",
            "Glass Cherry",
            "Cellar Merlot",
            "Dusty Blush",
            "Bare Apricot",
            "Ink Plum",
            "Mauve Hour",
            "Quiet Rose"
        ])
        XCTAssertEqual(picks[0].score.total, 96)
        XCTAssertEqual(picks[0].score.reasons, ["Fits date", "Matches warm", "Quiet for 16 days"])
        XCTAssertFalse(picks.contains { $0.lipstick.ownership == .wishlist })
        XCTAssertFalse(picks.map(\.lipstick.name).contains("Winter Currant"))
        XCTAssertFalse(picks.map(\.lipstick.name).contains("Noon Terracotta"))
    }

    func testLongQuietEveningShadeOutranksANeverWornMatch() throws {
        var library = WardrobeLibrary()
        _ = library.installStarterIfNeeded(today: today)
        let picks = library.recommendations(
            RecommendationQuery(occasion: .evening, undertone: .cool, day: today, limit: 3)
        )
        XCTAssertEqual(picks.map(\.lipstick.name), ["Ink Plum", "Cellar Merlot", "Mauve Hour"])
        XCTAssertEqual(picks[0].score.total, 100)
        XCTAssertEqual(picks[0].score.daysSinceWorn, 40)
        XCTAssertEqual(picks[0].score.recencyPoints, 30)
        XCTAssertEqual(picks[1].score.daysSinceWorn, nil)
        XCTAssertEqual(picks[1].score.recencyPoints, 26)
        XCTAssertEqual(picks[1].score.reasons[2], "Not worn yet")
    }

    func testLimitAndNameTieBreak() throws {
        var library = WardrobeLibrary()
        let shade = try ShadeColor(hex: "112233")
        let older = try library.add(LipstickDraft(name: "Beta", finish: .matte, undertone: .warm, colorFamily: .red, shade: shade, ownership: .owned))
        _ = try library.add(LipstickDraft(name: "Alpha", finish: .matte, undertone: .warm, colorFamily: .red, shade: shade, ownership: .owned))
        _ = try library.markWorn(lipstickID: older.id, on: today)
        let picks = library.recommendations(RecommendationQuery(occasion: .office, undertone: .warm, day: today, limit: 1))
        XCTAssertEqual(picks.count, 1)
        // Both miss the office tag. Alpha was never worn, so it outranks Beta worn today.
        XCTAssertEqual(picks[0].lipstick.name, "Alpha")

        let all = library.recommendations(RecommendationQuery(day: today, limit: 0))
        XCTAssertTrue(all.isEmpty)

        let negative = library.recommendations(RecommendationQuery(day: today, limit: -4))
        XCTAssertTrue(negative.isEmpty)
    }

    func testSameScoreSortsByName() throws {
        var library = WardrobeLibrary()
        let shade = try ShadeColor(hex: "445566")
        _ = try library.add(LipstickDraft(name: "Zest", finish: .gloss, undertone: .neutral, colorFamily: .pink, occasions: [.brunch], shade: shade, ownership: .owned))
        _ = try library.add(LipstickDraft(name: "Amber", finish: .gloss, undertone: .neutral, colorFamily: .pink, occasions: [.brunch], shade: shade, ownership: .owned))
        let picks = library.recommendations(RecommendationQuery(occasion: .brunch, undertone: .neutral, day: today, limit: 5))
        XCTAssertEqual(picks.map(\.score.total), [picks[0].score.total, picks[0].score.total])
        XCTAssertEqual(picks.map(\.lipstick.name), ["Amber", "Zest"])
    }
}
