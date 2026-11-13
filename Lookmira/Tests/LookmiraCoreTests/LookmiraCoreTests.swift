import XCTest
@testable import LookmiraCore

final class LookDraftTests: XCTestCase {
    func testAcceptsACompleteDraftAndTrimsText() throws {
        let draft = LookDraft(
            title: "  Soft peach morning  ",
            wornOn: Date(timeIntervalSince1970: 1_700_000_000),
            styleTags: [.weekend, .natural, .natural],
            products: [UsedProduct(name: "  Peach coral satin  ", kind: .lipstick)],
            notes: "  Skin still looks like skin.  ",
            isFavorite: true,
            photoFileName: " sample-everyday.jpg "
        )
        let validated = try draft.validate()
        XCTAssertEqual(validated.title, "Soft peach morning")
        XCTAssertEqual(validated.styleTags, [.natural, .weekend])
        XCTAssertEqual(validated.products.first?.name, "Peach coral satin")
        XCTAssertEqual(validated.notes, "Skin still looks like skin.")
        XCTAssertEqual(validated.photoFileName, "sample-everyday.jpg")
        XCTAssertTrue(validated.isFavorite)
    }

    func testRejectsBlankTitle() {
        XCTAssertThrowsError(try LookDraft(title: "   ", styleTags: [.work]).validate()) { error in
            XCTAssertEqual(error as? LookDraftError, .titleEmpty)
        }
    }

    func testTitleLengthLimit() throws {
        let ok = LookDraft(title: String(repeating: "a", count: LookLimits.title), styleTags: [.work])
        XCTAssertEqual(try ok.validate().title.count, LookLimits.title)
        let tooLong = LookDraft(title: String(repeating: "a", count: LookLimits.title + 1), styleTags: [.work])
        XCTAssertThrowsError(try tooLong.validate()) { error in
            XCTAssertEqual(error as? LookDraftError, .titleTooLong(limit: LookLimits.title))
        }
    }

    func testRequiresAStyleTag() {
        XCTAssertThrowsError(try LookDraft(title: "Bare face").validate()) { error in
            XCTAssertEqual(error as? LookDraftError, .missingStyleTag)
        }
    }

    func testRejectsEmptyAndDuplicateProducts() {
        var empty = LookDraft(title: "Desk", styleTags: [.work], products: [UsedProduct(name: "  ", kind: .liner)])
        XCTAssertThrowsError(try empty.validate()) { error in
            XCTAssertEqual(error as? LookDraftError, .productNameEmpty(index: 0))
        }
        empty.products = [
            UsedProduct(name: "Berry silk", kind: .lipstick),
            UsedProduct(name: "berry silk", kind: .blush)
        ]
        XCTAssertThrowsError(try empty.validate()) { error in
            XCTAssertEqual(error as? LookDraftError, .duplicateProductName("berry silk"))
        }
    }

    func testProductNameAndCountLimits() {
        let longName = UsedProduct(name: String(repeating: "p", count: LookLimits.productName + 1), kind: .brow)
        let tooLong = LookDraft(title: "Brow day", styleTags: [.natural], products: [longName])
        XCTAssertThrowsError(try tooLong.validate()) { error in
            XCTAssertEqual(error as? LookDraftError, .productNameTooLong(index: 0, limit: LookLimits.productName))
        }
        let many = (0..<(LookLimits.products + 1)).map { UsedProduct(name: "Item \($0)", kind: .other) }
        let crowded = LookDraft(title: "Full kit", styleTags: [.party], products: many)
        XCTAssertThrowsError(try crowded.validate()) { error in
            XCTAssertEqual(error as? LookDraftError, .tooManyProducts(limit: LookLimits.products))
        }
    }

    func testNotesLimit() {
        let draft = LookDraft(
            title: "Notes",
            styleTags: [.evening],
            notes: String(repeating: "n", count: LookLimits.notes + 1)
        )
        XCTAssertThrowsError(try draft.validate()) { error in
            XCTAssertEqual(error as? LookDraftError, .notesTooLong(limit: LookLimits.notes))
        }
    }

    func testPhotoFileNames() throws {
        let good = ["look.jpg", "look.jpeg", "look.PNG", "sample-everyday.jpg", "A1B2.jpg"]
        for name in good {
            let draft = LookDraft(title: "Photo", styleTags: [.natural], photoFileName: name)
            XCTAssertEqual(try draft.validate().photoFileName, name)
        }
        let blank = LookDraft(title: "Photo", styleTags: [.natural], photoFileName: "   ")
        XCTAssertNil(try blank.validate().photoFileName)
        let unsafe = ["../secret.jpg", "/tmp/a.jpg", "a.jpg.exe", ".jpg", "has space.jpg", "noext"]
        for name in unsafe {
            let draft = LookDraft(title: "Photo", styleTags: [.natural], photoFileName: name)
            XCTAssertThrowsError(try draft.validate(), "expected rejection for \(name)") { error in
                XCTAssertEqual(error as? LookDraftError, .unsafePhotoFileName)
            }
        }
    }

    func testAllowsALookWithNoProducts() throws {
        let validated = try LookDraft(title: "Just a photo", styleTags: [.weekend]).validate()
        XCTAssertTrue(validated.products.isEmpty)
    }
}

final class LookJournalTests: XCTestCase {
    var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = TestCalendar.make()
    }

    func testAddNormalizesTheDayAndKeepsTheIdentifier() throws {
        var journal = LookJournal()
        let id = UUID()
        let stamped = TestCalendar.date(2026, 11, 13, 18, 45, calendar)
        let now = TestCalendar.date(2026, 11, 13, 19, 0, calendar)
        let look = try journal.add(draft(title: "Soft peach morning", day: stamped), id: id, now: now, calendar: calendar)
        XCTAssertEqual(look.id, id)
        XCTAssertEqual(look.wornOn, TestCalendar.date(2026, 11, 13, 0, 0, calendar))
        XCTAssertEqual(look.createdAt, now)
        XCTAssertNil(look.recreatedFrom)
        XCTAssertEqual(journal.looks.count, 1)
    }

    func testUpdatePreservesIdentityAndCreatedAt() throws {
        var journal = LookJournal()
        let created = TestCalendar.date(2026, 11, 1, 8, 0, calendar)
        let added = try journal.add(draft(title: "Office berry"), id: SampleID.work, now: created, calendar: calendar)
        let editedAt = TestCalendar.date(2026, 11, 2, 9, 0, calendar)
        let updated = try journal.update(
            added.id,
            with: draft(title: "Office berry revised", tags: [.work, .natural], notes: "Quieter eyes."),
            now: editedAt,
            calendar: calendar
        )
        XCTAssertEqual(updated.id, added.id)
        XCTAssertEqual(updated.createdAt, created)
        XCTAssertEqual(updated.updatedAt, editedAt)
        XCTAssertEqual(updated.title, "Office berry revised")
        XCTAssertEqual(updated.styleTags, [.natural, .work])
        XCTAssertEqual(updated.notes, "Quieter eyes.")
    }

    func testMissingLookThrows() {
        var journal = LookJournal()
        XCTAssertThrowsError(try journal.update(UUID(), with: draft(title: "Gone"), now: Date(), calendar: calendar)) { error in
            XCTAssertEqual(error as? JournalError, .missingLook)
        }
        XCTAssertThrowsError(try journal.delete(UUID())) { error in
            XCTAssertEqual(error as? JournalError, .missingLook)
        }
        XCTAssertThrowsError(try journal.setFavorite(UUID(), true, now: Date())) { error in
            XCTAssertEqual(error as? JournalError, .missingLook)
        }
        XCTAssertThrowsError(try journal.recreate(UUID(), on: Date(), now: Date(), calendar: calendar)) { error in
            XCTAssertEqual(error as? JournalError, .missingLook)
        }
    }

    func testInvalidDraftIsWrapped() {
        var journal = LookJournal()
        XCTAssertThrowsError(try journal.add(LookDraft(title: " "), now: Date(), calendar: calendar)) { error in
            XCTAssertEqual(error as? JournalError, .invalid(.titleEmpty))
            XCTAssertEqual((error as? JournalError)?.message, LookDraftError.titleEmpty.message)
        }
    }

    func testDuplicateIdentifierIsRejected() throws {
        var journal = LookJournal()
        let id = UUID()
        _ = try journal.add(draft(title: "First"), id: id, now: Date(), calendar: calendar)
        XCTAssertThrowsError(try journal.add(draft(title: "Second"), id: id, now: Date(), calendar: calendar)) { error in
            XCTAssertEqual(error as? JournalError, .duplicateLook)
        }
    }

    func testDeleteRemovesTheLook() throws {
        var journal = LookJournal()
        let look = try journal.add(draft(title: "Office berry", photo: "sample-work.jpg"), now: Date(), calendar: calendar)
        let removed = try journal.delete(look.id)
        XCTAssertEqual(removed.id, look.id)
        XCTAssertTrue(journal.looks.isEmpty)
        XCTAssertFalse(journal.photoFileNamesInUse().contains("sample-work.jpg"))
    }

    func testFavoriteAndPhotoSharing() throws {
        var journal = LookJournal()
        let now = TestCalendar.date(2026, 11, 13, 12, 0, calendar)
        let original = try journal.add(
            draft(title: "Rose after dark", tags: [.evening], photo: "sample-evening.jpg"),
            now: now,
            calendar: calendar
        )
        let favored = try journal.setFavorite(original.id, true, now: now.addingTimeInterval(60))
        XCTAssertTrue(favored.isFavorite)
        XCTAssertEqual(favored.updatedAt, now.addingTimeInterval(60))
        XCTAssertEqual(journal.favorites().map(\.id), [original.id])

        let copy = try journal.recreate(original.id, on: TestCalendar.date(2026, 11, 20, 22, 0, calendar), now: now.addingTimeInterval(120), calendar: calendar)
        XCTAssertNotEqual(copy.id, original.id)
        XCTAssertEqual(copy.title, original.title)
        XCTAssertEqual(copy.styleTags, original.styleTags)
        XCTAssertEqual(copy.notes, original.notes)
        XCTAssertEqual(copy.photoFileName, original.photoFileName)
        XCTAssertFalse(copy.isFavorite)
        XCTAssertEqual(copy.recreatedFrom, original.id)
        XCTAssertEqual(copy.wornOn, TestCalendar.date(2026, 11, 20, 0, 0, calendar))
        XCTAssertEqual(Set(copy.products.map(\.name)), Set(original.products.map(\.name)))
        XCTAssertTrue(Set(copy.products.map(\.id)).isDisjoint(with: Set(original.products.map(\.id))))

        _ = try journal.delete(original.id)
        XCTAssertTrue(journal.photoFileNamesInUse().contains("sample-evening.jpg"))
        XCTAssertEqual(journal.favorites().count, 0)
    }

    func testRecentsFollowTheWornDay() throws {
        var journal = LookJournal()
        let older = try journal.add(
            draft(title: "Older", day: TestCalendar.date(2026, 10, 1, 0, 0, calendar)),
            now: TestCalendar.date(2026, 11, 12, 0, 0, calendar),
            calendar: calendar
        )
        let newer = try journal.add(
            draft(title: "Newer", day: TestCalendar.date(2026, 11, 13, 0, 0, calendar)),
            now: TestCalendar.date(2026, 11, 1, 0, 0, calendar),
            calendar: calendar
        )
        XCTAssertEqual(journal.recents(limit: 10).map(\.id), [newer.id, older.id])
        XCTAssertEqual(journal.recents(limit: 1).map(\.id), [newer.id])
        XCTAssertTrue(journal.recents(limit: 0).isEmpty)
        XCTAssertTrue(journal.recents(limit: -4).isEmpty)
    }

    func testLooksOnADayKeepCreationOrder() throws {
        var journal = LookJournal()
        let day = TestCalendar.date(2026, 11, 13, 15, 0, calendar)
        let first = try journal.add(draft(title: "Morning", day: day), now: day, calendar: calendar)
        let second = try journal.add(draft(title: "Evening", day: day.addingTimeInterval(3600)), now: day.addingTimeInterval(10), calendar: calendar)
        XCTAssertEqual(journal.looks(on: day, calendar: calendar).map(\.id), [first.id, second.id])
        XCTAssertTrue(journal.looks(on: day.addingTimeInterval(86_400), calendar: calendar).isEmpty)
    }

    func testProductSummary() {
        let look = MakeupLook(
            id: UUID(),
            title: "Kit",
            wornOn: Date(),
            styleTags: [.work],
            products: [
                UsedProduct(name: "Berry silk", kind: .lipstick),
                UsedProduct(name: "Taupe wash", kind: .eyeshadow),
                UsedProduct(name: "Soft blonde pencil", kind: .brow),
                UsedProduct(name: "Fine brown", kind: .liner)
            ],
            notes: "",
            isFavorite: false,
            photoFileName: nil,
            recreatedFrom: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertEqual(look.productSummary, "Berry silk, Taupe wash, Soft blonde pencil, +1")
        XCTAssertEqual(
            MakeupLook(
                id: UUID(), title: "Empty", wornOn: Date(), styleTags: [.natural], products: [],
                notes: "", isFavorite: false, photoFileName: nil, recreatedFrom: nil,
                createdAt: Date(), updatedAt: Date()
            ).productSummary,
            "No products listed"
        )
    }

    private func draft(
        title: String,
        tags: [StyleTag] = [.work],
        day: Date = Date(timeIntervalSince1970: 1_762_000_000),
        notes: String = "",
        photo: String? = nil
    ) -> LookDraft {
        LookDraft(
            title: title,
            wornOn: day,
            styleTags: tags,
            products: [UsedProduct(name: "Berry silk", kind: .lipstick)],
            notes: notes,
            photoFileName: photo
        )
    }
}

final class LibraryQueryTests: XCTestCase {
    func testSearchAndTagFilter() {
        let journal = SampleCatalog.document(now: TestCalendar.date(2026, 11, 13, 15, 0, TestCalendar.make()), calendar: TestCalendar.make()).journal
        XCTAssertEqual(journal.library(text: "   ", tag: nil).matchIDs, [SampleID.everyday, SampleID.work, SampleID.evening])
        XCTAssertEqual(journal.library(text: "BERRY", tag: nil).matchIDs, [SampleID.work])
        XCTAssertEqual(journal.library(text: "evening", tag: nil).matchIDs, [SampleID.evening])
        XCTAssertEqual(journal.library(text: "rose velvet", tag: .party).matchIDs, [SampleID.evening])
        XCTAssertEqual(journal.library(text: "fine brown", tag: nil).matchIDs, [SampleID.work])
        XCTAssertEqual(
            journal.library(text: "liner", tag: nil).matchIDs,
            [SampleID.everyday, SampleID.work, SampleID.evening],
            "Liner matches the product kind and the everyday note that mentions liner."
        )
        XCTAssertEqual(journal.library(text: "party berry", tag: nil), .noMatches)
        XCTAssertEqual(journal.library(text: "", tag: .weekend).matchIDs, [SampleID.everyday])
        XCTAssertEqual(LibraryQuery.state(allLooks: [], text: "rose", tag: nil), .emptyDiary)
    }
}

final class MonthPageTests: XCTestCase {
    func testNovember2026SundayStart() {
        let calendar = TestCalendar.make(firstWeekday: 1)
        let day = TestCalendar.date(2026, 11, 13, 9, 0, calendar)
        let looks = [
            sampleLook(on: day, calendar: calendar),
            sampleLook(on: TestCalendar.date(2026, 10, 31, 12, 0, calendar), calendar: calendar)
        ]
        let page = DiaryDates.page(containing: day, looks: looks, calendar: calendar)
        XCTAssertEqual(page.title, "November 2026")
        XCTAssertEqual(page.weekdaySymbols, ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"])
        XCTAssertEqual(page.cells.count, 35)
        XCTAssertTrue(page.cells.allSatisfy(\.isInMonth) == false)
        XCTAssertEqual(page.cells.filter(\.isInMonth).count, 30)
        XCTAssertEqual(page.cells.first?.dayNumber, 1)
        XCTAssertTrue(page.cells.first?.isInMonth == true)
        let thirteenth = page.cells.first { $0.isInMonth && $0.dayNumber == 13 }
        XCTAssertEqual(thirteenth?.lookCount, 1)
        XCTAssertEqual(page.cells.filter { !$0.isInMonth }.map(\.lookCount), [0, 0, 0, 0, 0])
        XCTAssertEqual(DiaryDates.dayTitle(day, calendar: calendar), "Friday, November 13")
    }

    func testMondayStartShiftsLeadingDays() {
        let calendar = TestCalendar.make(firstWeekday: 2)
        let page = DiaryDates.page(
            containing: TestCalendar.date(2026, 11, 1, 0, 0, calendar),
            looks: [],
            calendar: calendar
        )
        XCTAssertEqual(page.weekdaySymbols.first, "Mon")
        XCTAssertEqual(page.cells.count, 42)
        XCTAssertEqual(page.cells.prefix(6).map(\.isInMonth), Array(repeating: false, count: 6))
        XCTAssertEqual(page.cells[6].dayNumber, 1)
        XCTAssertTrue(page.cells[6].isInMonth)
    }

    private func sampleLook(on day: Date, calendar: Calendar) -> MakeupLook {
        MakeupLook(
            id: UUID(),
            title: "Marked",
            wornOn: calendar.startOfDay(for: day),
            styleTags: [.natural],
            products: [],
            notes: "",
            isFavorite: false,
            photoFileName: nil,
            recreatedFrom: nil,
            createdAt: day,
            updatedAt: day
        )
    }
}

final class ReminderTests: XCTestCase {
    func testDefaultIsOff() {
        XCTAssertFalse(ReminderPreference.off.isEnabled)
        XCTAssertEqual(ReminderPreference.off.hour, 20)
        XCTAssertEqual(ReminderPreference.off.minute, 0)
        XCTAssertNil(ReminderPreference.off.nextFireDate(after: Date(), calendar: TestCalendar.make()))
    }

    func testNextFireDate() throws {
        let calendar = TestCalendar.make()
        let now = TestCalendar.date(2026, 11, 13, 15, 0, calendar)
        let later = ReminderPreference(isEnabled: true, hour: 20, minute: 0)
        XCTAssertEqual(later.nextFireDate(after: now, calendar: calendar), TestCalendar.date(2026, 11, 13, 20, 0, calendar))
        let passed = ReminderPreference(isEnabled: true, hour: 9, minute: 30)
        XCTAssertEqual(passed.nextFireDate(after: now, calendar: calendar), TestCalendar.date(2026, 11, 14, 9, 30, calendar))
        let exact = ReminderPreference(isEnabled: true, hour: 15, minute: 0)
        XCTAssertEqual(exact.nextFireDate(after: now, calendar: calendar), TestCalendar.date(2026, 11, 14, 15, 0, calendar))
        XCTAssertThrowsError(try ReminderPreference(isEnabled: true, hour: 24, minute: 0).validated()) { error in
            XCTAssertEqual(error as? ReminderError, .hourOutOfRange)
        }
        XCTAssertThrowsError(try ReminderPreference(isEnabled: false, hour: 8, minute: 60).validated()) { error in
            XCTAssertEqual(error as? ReminderError, .minuteOutOfRange)
        }
        XCTAssertNil(ReminderPreference(isEnabled: true, hour: 24, minute: 0).nextFireDate(after: now, calendar: calendar))
    }
}

final class StorageTests: XCTestCase {
    func testRoundTripAndSeedRules() throws {
        let calendar = TestCalendar.make()
        let now = TestCalendar.date(2026, 11, 13, 15, 30, calendar)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = JournalFileStore(fileURL: folder.appendingPathComponent("journal.json"))
        XCTAssertNil(try store.load())

        let first = try store.loadOrSeed(now: now, calendar: calendar)
        XCTAssertTrue(first.seeded)
        XCTAssertTrue(first.document.didInstallSamples)
        XCTAssertEqual(first.document.reminder, .off)
        XCTAssertEqual(Set(first.document.journal.looks.map(\.title)), ["Soft peach morning", "Office berry", "Rose after dark"])

        let second = try store.loadOrSeed(now: now.addingTimeInterval(5_000), calendar: calendar)
        XCTAssertFalse(second.seeded)
        XCTAssertEqual(second.document, first.document)

        var emptied = second.document
        emptied.journal = LookJournal()
        try store.save(emptied)
        let third = try store.loadOrSeed(now: now, calendar: calendar)
        XCTAssertFalse(third.seeded)
        XCTAssertTrue(third.document.journal.looks.isEmpty)
        XCTAssertTrue(third.document.didInstallSamples)

        try Data("{}".utf8).write(to: store.fileURL)
        XCTAssertThrowsError(try store.load()) { error in
            XCTAssertEqual(error as? JournalStoreError, .unreadable)
        }
        XCTAssertThrowsError(try store.loadOrSeed(now: now, calendar: calendar))
    }

    func testSampleContent() {
        let calendar = TestCalendar.make()
        let now = TestCalendar.date(2026, 11, 13, 15, 30, calendar)
        let document = SampleCatalog.document(now: now, calendar: calendar)
        let everyday = document.journal.look(SampleID.everyday)
        let work = document.journal.look(SampleID.work)
        let evening = document.journal.look(SampleID.evening)
        XCTAssertEqual(everyday?.photoFileName, SamplePhoto.everyday)
        XCTAssertEqual(work?.photoFileName, SamplePhoto.work)
        XCTAssertEqual(evening?.photoFileName, SamplePhoto.evening)
        XCTAssertEqual(everyday?.styleTags, [.natural, .weekend])
        XCTAssertEqual(work?.styleTags, [.work])
        XCTAssertEqual(evening?.styleTags, [.evening, .party])
        XCTAssertEqual(everyday?.wornOn, TestCalendar.date(2026, 11, 13, 0, 0, calendar))
        XCTAssertEqual(work?.wornOn, TestCalendar.date(2026, 11, 10, 0, 0, calendar))
        XCTAssertEqual(evening?.wornOn, TestCalendar.date(2026, 11, 7, 0, 0, calendar))
        XCTAssertEqual(evening?.isFavorite, true)
        XCTAssertEqual(everyday?.isFavorite, false)
        XCTAssertEqual(document.journal.favorites().map(\.id), [SampleID.evening])
        XCTAssertEqual(work?.products.map(\.kind), [.lipstick, .eyeshadow, .brow, .foundation, .liner])
        XCTAssertEqual(SamplePhoto.fileNames.count, 3)
    }
}

private extension LibraryState {
    var matchIDs: [UUID] {
        if case .matches(let looks) = self { return looks.map(\.id) }
        return []
    }
}

enum TestCalendar {
    static func make(firstWeekday: Int = 1) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: 0))!
    }
}
