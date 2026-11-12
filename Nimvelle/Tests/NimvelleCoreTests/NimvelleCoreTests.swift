import XCTest
@testable import NimvelleCore

final class NimvelleCoreTests: XCTestCase {
    private let calendar = DayCalendar.gregorian()

    private func day(_ year: Int, _ month: Int, _ day: Int) -> DayKey {
        DayKey(year: year, month: month, day: day)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var parts = DateComponents()
        parts.calendar = calendar
        parts.timeZone = calendar.timeZone
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = hour
        parts.minute = minute
        parts.second = 0
        return calendar.date(from: parts)!
    }

    func testDayKeyCrossesMonthAndAddsMonths() {
        let start = day(2026, 1, 31)
        XCTAssertEqual(start.adding(days: 1, calendar: calendar), day(2026, 2, 1))
        XCTAssertEqual(start.adding(months: 1, calendar: calendar), day(2026, 2, 28))
        XCTAssertEqual(day(2026, 1, 15).adding(months: 6, calendar: calendar), day(2026, 7, 15))
        XCTAssertEqual(day(2026, 3, 1).distance(to: day(2026, 3, 11), calendar: calendar), 10)
        XCTAssertEqual(day(2026, 3, 11).distance(to: day(2026, 3, 1), calendar: calendar), -10)
    }

    func testFreshnessWindowBoundaries() {
        let opened = day(2026, 1, 15)
        let expiry = day(2026, 7, 15)
        XCTAssertEqual(
            ShelfMath.freshness(openedOn: nil, paoMonths: 12, today: expiry, calendar: calendar),
            .sealed
        )
        XCTAssertEqual(
            ShelfMath.freshness(openedOn: opened, paoMonths: 0, today: expiry, calendar: calendar),
            .untracked
        )
        XCTAssertEqual(
            ShelfMath.freshness(openedOn: opened, paoMonths: -3, today: expiry, calendar: calendar),
            .untracked
        )
        XCTAssertEqual(
            ShelfMath.freshness(openedOn: opened, paoMonths: 6, today: day(2026, 6, 14), calendar: calendar),
            .good(daysLeft: 31)
        )
        XCTAssertEqual(
            ShelfMath.freshness(openedOn: opened, paoMonths: 6, today: day(2026, 6, 15), calendar: calendar),
            .soon(daysLeft: 30)
        )
        XCTAssertEqual(
            ShelfMath.freshness(openedOn: opened, paoMonths: 6, today: expiry, calendar: calendar),
            .soon(daysLeft: 0)
        )
        XCTAssertEqual(
            ShelfMath.freshness(openedOn: opened, paoMonths: 6, today: day(2026, 7, 16), calendar: calendar),
            .past(daysOver: 1)
        )
        XCTAssertEqual(ShelfMath.statusLine(.soon(daysLeft: 0)), "Open-jar window ends today")
        XCTAssertEqual(ShelfMath.statusLine(.soon(daysLeft: 1)), "1 day left in the open-jar window")
        XCTAssertEqual(ShelfMath.statusLine(.past(daysOver: 2)), "2 days past the open-jar window")
        XCTAssertEqual(ShelfMath.statusLine(.sealed), "Sealed")
    }

    func testCompletionIgnoresInactiveSteps() {
        let step = RoutineStep(id: UUID(), title: "Mask", kind: .mask, part: .evening, productID: nil, position: 0, isActive: false)
        let day = day(2026, 11, 11)
        XCTAssertEqual(RoutineMath.mark(on: day, steps: [step], checks: []), .none)
        let active = RoutineStep(id: UUID(), title: "Cleanse", kind: .cleanser, part: .morning, productID: nil, position: 0)
        XCTAssertEqual(RoutineMath.mark(on: day, steps: [active], checks: []), .none)
        let checks = [CheckIn(day: day, stepID: active.id)]
        XCTAssertEqual(RoutineMath.mark(on: day, steps: [active, step], checks: checks), .complete)
        let second = RoutineStep(id: UUID(), title: "Tone", kind: .toner, part: .morning, productID: nil, position: 1)
        XCTAssertEqual(RoutineMath.mark(on: day, steps: [active, second], checks: checks), .partial)
        XCTAssertEqual(RoutineMath.mark(on: day, steps: [active, second], checks: checks, part: .evening), .none)
    }

    func testStreakTreatsTodayAsStillOpen() {
        let today = day(2026, 11, 11)
        let step = RoutineStep(id: UUID(), title: "Cleanse", kind: .cleanser, part: .morning, productID: nil, position: 0)
        var checks: [CheckIn] = []
        for offset in -5 ... -1 {
            checks.append(CheckIn(day: today.adding(days: offset, calendar: calendar), stepID: step.id))
        }
        XCTAssertEqual(RoutineMath.currentStreak(today: today, steps: [step], checks: checks, calendar: calendar), 5)
        checks.append(CheckIn(day: today, stepID: step.id))
        XCTAssertEqual(RoutineMath.currentStreak(today: today, steps: [step], checks: checks, calendar: calendar), 6)
        let gap = checks.filter { $0.day != today.adding(days: -2, calendar: calendar) }
        XCTAssertEqual(RoutineMath.currentStreak(today: today, steps: [step], checks: gap, calendar: calendar), 2)
        XCTAssertEqual(RoutineMath.currentStreak(today: today, steps: [], checks: checks, calendar: calendar), 0)
    }

    func testLongestStreakStopsAtAGap() {
        let step = RoutineStep(id: UUID(), title: "Cleanse", kind: .cleanser, part: .morning, productID: nil, position: 0)
        var checks: [CheckIn] = []
        for offset in [1, 2, 3, 5, 6] {
            checks.append(CheckIn(day: day(2026, 11, offset), stepID: step.id))
        }
        XCTAssertEqual(RoutineMath.longestStreak(steps: [step], checks: checks, calendar: calendar), 3)
        XCTAssertEqual(RoutineMath.longestStreak(steps: [step], checks: [], calendar: calendar), 0)
    }

    func testNovember2026Grid() {
        let sunday = MonthGrid.weeks(year: 2026, month: 11, calendar: calendar)
        XCTAssertEqual(sunday.count, 5)
        XCTAssertEqual(sunday[0][0].day, day(2026, 11, 1))
        XCTAssertTrue(sunday[0][0].inMonth)
        XCTAssertEqual(sunday[4][1].day, day(2026, 11, 30))
        XCTAssertFalse(sunday[4][2].inMonth)
        XCTAssertEqual(sunday[4][2].day, day(2026, 12, 1))
        XCTAssertEqual(MonthGrid.weekdayLabels(calendar: calendar).count, 7)

        let monday = DayCalendar.gregorian(firstWeekday: 2)
        let weeks = MonthGrid.weeks(year: 2026, month: 11, calendar: monday)
        XCTAssertEqual(weeks[0][0].day, day(2026, 10, 26))
        XCTAssertFalse(weeks[0][0].inMonth)
        XCTAssertEqual(weeks[0][6].day, day(2026, 11, 1))
        XCTAssertTrue(weeks[0][6].inMonth)
    }

    func testTrendWindowAveragesAndClamps() {
        let today = day(2026, 11, 11)
        let wild = SkinNote(id: UUID(), day: today, dryness: 9, breakouts: 8, mood: 0, sleep: -4, text: "x")
        XCTAssertEqual(wild.dryness, 5)
        XCTAssertEqual(wild.breakouts, 3)
        XCTAssertEqual(wild.mood, 1)
        XCTAssertEqual(wild.sleep, 1)
        var decoded = wild
        decoded.dryness = 9
        decoded.breakouts = 0
        let summary = NoteTrends.summary(notes: [decoded], today: today, window: 7, calendar: calendar)
        XCTAssertEqual(summary.points.count, 7)
        XCTAssertEqual(summary.points.last?.day, today)
        XCTAssertEqual(summary.points.last?.dryness, 5)
        XCTAssertEqual(summary.notedDays, 1)
        XCTAssertEqual(summary.drynessAverage, 5)
        XCTAssertEqual(summary.breakoutDays, 0)
        XCTAssertNil(summary.points.first?.mood)
    }

    func testReminderRules() {
        let settings = ReminderSettings(
            morningEnabled: true,
            morningHour: 8,
            morningMinute: 0,
            eveningEnabled: true,
            eveningHour: 21,
            eveningMinute: 30
        )
        let now = date(2026, 11, 11, 7, 15)
        let open = ReminderPlanner.plan(
            settings: settings,
            now: now,
            morningComplete: false,
            eveningComplete: false,
            morningSteps: 5,
            eveningSteps: 3,
            calendar: calendar,
            horizonDays: 3
        )
        XCTAssertEqual(open.count, 6)
        XCTAssertEqual(open.filter { $0.identifier.hasPrefix(ReminderPlanner.morningPrefix) }.map(\.fireDay), [
            day(2026, 11, 11), day(2026, 11, 12), day(2026, 11, 13),
        ])
        let done = ReminderPlanner.plan(
            settings: settings,
            now: now,
            morningComplete: true,
            eveningComplete: false,
            morningSteps: 5,
            eveningSteps: 3,
            calendar: calendar,
            horizonDays: 2
        )
        XCTAssertEqual(done.first { $0.title == "Morning routine" }?.fireDay, day(2026, 11, 12))
        let later = date(2026, 11, 11, 8, 0)
        let passed = ReminderPlanner.plan(
            settings: settings,
            now: later,
            morningComplete: false,
            eveningComplete: true,
            morningSteps: 1,
            eveningSteps: 1,
            calendar: calendar,
            horizonDays: 1
        )
        XCTAssertEqual(passed.map(\.fireDay), [day(2026, 11, 12), day(2026, 11, 12)])
        var invalid = settings
        invalid.eveningMinute = 60
        invalid.morningEnabled = false
        let dropped = ReminderPlanner.plan(
            settings: invalid,
            now: now,
            morningComplete: false,
            eveningComplete: false,
            morningSteps: 2,
            eveningSteps: 2,
            calendar: calendar,
            horizonDays: 4
        )
        XCTAssertTrue(dropped.isEmpty)
        let noSteps = ReminderPlanner.plan(
            settings: settings,
            now: now,
            morningComplete: false,
            eveningComplete: false,
            morningSteps: 0,
            eveningSteps: 2,
            calendar: calendar,
            horizonDays: 2
        )
        XCTAssertTrue(noSteps.allSatisfy { $0.identifier.hasPrefix(ReminderPlanner.eveningPrefix) })
        let banned = ["diagnos", "treat", "cure", "medical", "clinical"]
        for draft in open {
            let text = (draft.title + " " + draft.body).lowercased()
            XCTAssertTrue(banned.allSatisfy { !text.contains($0) })
            XCTAssertFalse(draft.body.isEmpty)
        }
    }

    func testSampleStudioStory() {
        let today = day(2026, 11, 11)
        let studio = SampleStudio.make(today: today, calendar: calendar)
        XCTAssertEqual(RoutineMath.activeSteps(studio.steps, part: .morning).count, 5)
        XCTAssertEqual(RoutineMath.activeSteps(studio.steps, part: .evening).count, 3)
        XCTAssertEqual(RoutineMath.checkedCount(on: today, steps: studio.steps, checks: studio.checks, part: .morning).done, 3)
        XCTAssertEqual(RoutineMath.mark(on: today, steps: studio.steps, checks: studio.checks, part: .evening), .none)
        XCTAssertEqual(RoutineMath.currentStreak(today: today, steps: studio.steps, checks: studio.checks, calendar: calendar), 5)
        XCTAssertGreaterThan(RoutineMath.longestStreak(steps: studio.steps, checks: studio.checks, calendar: calendar), 5)
        let veil = studio.products.first { $0.name == "Veil Cream" }!
        XCTAssertEqual(veil.freshness(today: today, calendar: calendar), .soon(daysLeft: 10))
        let night = studio.products.first { $0.name == "Night Repair Cream" }!
        XCTAssertEqual(night.freshness(today: today, calendar: calendar), .past(daysOver: 40))
        XCTAssertEqual(studio.attentionSummary(today: today, calendar: calendar), "1 jar is past its open-jar window, and 1 is close.")
        XCTAssertTrue(studio.products.allSatisfy(\.isSample))
        XCTAssertTrue(studio.steps.allSatisfy { $0.productID != nil })
        let trend = NoteTrends.summary(notes: studio.notes, today: today, window: 14, calendar: calendar)
        XCTAssertEqual(trend.points.count, 14)
        XCTAssertEqual(trend.notedDays, 9)
        XCTAssertEqual(trend.breakoutDays, 2)
        XCTAssertEqual(trend.drynessAverage ?? 0, 23.0 / 9.0, accuracy: 0.001)
        XCTAssertEqual(trend.moodAverage ?? 0, 37.0 / 9.0, accuracy: 0.001)
        XCTAssertEqual(trend.sleepAverage ?? 0, 33.0 / 9.0, accuracy: 0.001)
        XCTAssertFalse(studio.reminders.morningEnabled)
        XCTAssertFalse(studio.reminders.eveningEnabled)
    }

    func testMutationsArchiveAndSampleRemoval() {
        let today = day(2026, 11, 11)
        var studio = SampleStudio.make(today: today, calendar: calendar)
        let morning = RoutineMath.activeSteps(studio.steps, part: .morning)[0]
        studio = studio.toggling(day: today, stepID: morning.id)
        XCTAssertFalse(studio.isChecked(day: today, stepID: morning.id))
        studio = studio.toggling(day: today, stepID: morning.id)
        XCTAssertTrue(studio.isChecked(day: today, stepID: morning.id))
        studio = studio.markingRemaining(day: today, part: .morning)
        XCTAssertEqual(RoutineMath.mark(on: today, steps: studio.steps, checks: studio.checks, part: .morning), .complete)

        let ownProduct = Product(
            id: UUID(),
            name: "My Balm",
            brand: "Home",
            kind: .lipCare,
            openedOn: nil,
            paoMonths: 12,
            fill: .full
        )
        studio = studio.adding(product: ownProduct)
        let ownStep = RoutineStep(id: UUID(), title: "Lips", kind: .lipCare, part: .evening, productID: ownProduct.id, position: 0)
        studio = studio.adding(step: ownStep)
        XCTAssertEqual(studio.steps.first { $0.id == ownStep.id }?.position, 3)
        studio = studio.toggling(day: today, stepID: ownStep.id)
        let edited = SkinNote(id: UUID(), day: today.adding(days: -1, calendar: calendar), dryness: 5, breakouts: 0, mood: 2, sleep: 2, text: "Rewritten")
        studio = studio.saving(note: edited)
        XCTAssertEqual(studio.notes.filter { $0.day == edited.day }.count, 1)
        XCTAssertEqual(studio.notes.first { $0.day == edited.day }?.text, "Rewritten")
        XCTAssertTrue(studio.notes.first { $0.day == edited.day }?.isSample == true)

        let data = try! StudioArchive.data(from: studio)
        let restored = try! StudioArchive.studio(from: data)
        XCTAssertEqual(restored, studio)

        let cleared = restored.removingSample()
        XCTAssertEqual(cleared.products.map(\.name), ["My Balm"])
        XCTAssertEqual(cleared.steps.map(\.title), ["Lips"])
        XCTAssertTrue(cleared.notes.isEmpty)
        XCTAssertEqual(cleared.checks.map(\.stepID), [ownStep.id])
        XCTAssertFalse(cleared.hasSample)
        XCTAssertEqual(cleared.products[0].freshness(today: today, calendar: calendar), .sealed)

        let unlinked = cleared.deletingProduct(id: ownProduct.id)
        XCTAssertNil(unlinked.steps[0].productID)
        let gone = unlinked.deletingStep(id: ownStep.id)
        XCTAssertTrue(gone.steps.isEmpty)
        XCTAssertTrue(gone.checks.isEmpty)
    }

    func testAttentionPluralsAndFillOrder() {
        let today = day(2026, 11, 1)
        func jar(_ name: String, freshnessDays: Int) -> Product {
            let expiry = today.adding(days: freshnessDays, calendar: calendar)
            return Product(
                id: UUID(),
                name: name,
                brand: "Test",
                kind: .moisturizer,
                openedOn: expiry.adding(months: -12, calendar: calendar),
                paoMonths: 12,
                fill: .half
            )
        }
        var studio = Studio(products: [jar("A", freshnessDays: -2), jar("B", freshnessDays: -3), jar("C", freshnessDays: 4)])
        XCTAssertEqual(
            studio.attentionSummary(today: today, calendar: calendar),
            "2 jars are past their open-jar window, and 1 is close."
        )
        studio.products = [jar("A", freshnessDays: 4), jar("B", freshnessDays: 9)]
        XCTAssertEqual(
            studio.attentionSummary(today: today, calendar: calendar),
            "2 jars are close to the end of their open-jar window."
        )
        XCTAssertEqual(FillLevel.threeQuarters.fraction, 0.75)
        XCTAssertEqual(FillLevel.empty.fraction, 0)
        XCTAssertEqual(StepKind.sunscreen.title, "Sunscreen")
        XCTAssertEqual(DayPart.evening.title, "Evening")
    }
}
