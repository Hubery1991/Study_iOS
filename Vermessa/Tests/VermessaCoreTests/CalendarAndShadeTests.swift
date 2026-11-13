import XCTest
@testable import VermessaCore

final class CalendarAndShadeTests: XCTestCase {
    func testLeapDayAndYearBoundary() throws {
        let leapStart = CalendarDay(year: 2024, month: 2, day: 28)
        let leapEnd = CalendarDay(year: 2024, month: 3, day: 1)
        XCTAssertEqual(leapStart.daysUntil(leapEnd), 2)

        let commonStart = CalendarDay(year: 2025, month: 2, day: 28)
        let commonEnd = CalendarDay(year: 2025, month: 3, day: 1)
        XCTAssertEqual(commonStart.daysUntil(commonEnd), 1)

        let newYear = CalendarDay(year: 2026, month: 1, day: 1)
        XCTAssertEqual(CalendarDay(year: 2025, month: 12, day: 31).daysUntil(newYear), 1)
    }

    func testAddingDaysRoundTrips() throws {
        let day = try XCTUnwrap(CalendarDay(year: 2026, month: 11, day: 13).adding(days: -40))
        XCTAssertEqual(day, CalendarDay(year: 2026, month: 10, day: 4))
        let back = try XCTUnwrap(day.adding(days: 40))
        XCTAssertEqual(back, CalendarDay(year: 2026, month: 11, day: 13))
    }

    func testInvalidDayHasNoDistance() {
        let bogus = CalendarDay(year: 2026, month: 2, day: 31)
        XCTAssertNil(bogus.daysUntil(CalendarDay(year: 2026, month: 3, day: 1)))
        XCTAssertNil(bogus.utcNoon())
    }

    func testCapturingUsesTheProvidedCalendar() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 13, hour: 23)))
        XCTAssertEqual(CalendarDay.capturing(date, calendar: calendar), CalendarDay(year: 2026, month: 11, day: 13))
    }

    func testHexRoundTripAndRejection() throws {
        let shade = try ShadeColor(hex: "#6e2436")
        XCTAssertEqual(shade.hex, "6E2436")
        XCTAssertEqual(shade.red, 0x6E)
        XCTAssertEqual(shade.green, 0x24)
        XCTAssertEqual(shade.blue, 0x36)
        XCTAssertTrue(shade.prefersLightText)

        let nude = try ShadeColor(hex: "D0A088")
        XCTAssertFalse(nude.prefersLightText)

        XCTAssertThrowsError(try ShadeColor(hex: "GG0000")) { error in
            XCTAssertEqual(error as? WardrobeError, .invalidHex)
        }
        XCTAssertThrowsError(try ShadeColor(hex: "12345")) { error in
            XCTAssertEqual(error as? WardrobeError, .invalidHex)
        }
        XCTAssertThrowsError(try ShadeColor(red: 256, green: 0, blue: 0)) { error in
            XCTAssertEqual(error as? WardrobeError, .shadeOutOfRange)
        }
    }

    func testDayOrdering() {
        XCTAssertLessThan(CalendarDay(year: 2026, month: 1, day: 2), CalendarDay(year: 2026, month: 1, day: 10))
        XCTAssertEqual(CalendarDay(year: 2026, month: 5, day: 1).isoString, "2026-05-01")
    }
}
