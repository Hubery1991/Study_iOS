import XCTest
@testable import QuillisseCore

final class QuillisseCoreTests: XCTestCase {
    private let calendar = CivilDate.utc()
    private let today = DayStamp(year: 2026, month: 11, day: 11)

    func testSeedCoversEveryCategory() {
        let categories = Set(SeedCloset.garments.map(\.category))
        XCTAssertEqual(categories, Set(GarmentCategory.allCases))
        XCTAssertEqual(SeedCloset.garments.count, 20)
        let tokens = SeedCloset.garments.map(\.imageToken)
        XCTAssertEqual(Set(tokens).count, tokens.count)
        XCTAssertTrue(SeedCloset.garments.allSatisfy(\.isSample))
        XCTAssertEqual(Set(SeedCloset.garments.map(\.id)).count, 20)
    }

    func testDayDistanceCrossesAMonth() {
        let start = DayStamp(year: 2026, month: 10, day: 30)
        XCTAssertEqual(start.distance(to: today, calendar: calendar), 12)
        XCTAssertEqual(today.addingDays(-12, calendar: calendar), start)
        XCTAssertEqual(today.addingDays(0, calendar: calendar), today)
    }

    func testSeasonsAndTemperatureBands() {
        XCTAssertEqual(Season.from(month: 4), .spring)
        XCTAssertEqual(Season.from(month: 7), .summer)
        XCTAssertEqual(Season.from(month: 11), .autumn)
        XCTAssertEqual(Season.from(month: 1), .winter)
        XCTAssertEqual(today.season, .autumn)
        XCTAssertEqual(WeatherBand.band(celsius: 30), .hot)
        XCTAssertEqual(WeatherBand.band(celsius: 21), .warm)
        XCTAssertEqual(WeatherBand.band(celsius: 18), .mild)
        XCTAssertEqual(WeatherBand.band(celsius: 7), .cool)
        XCTAssertEqual(WeatherBand.band(celsius: 6.9), .cold)
        XCTAssertEqual(LayerNeed.forWeather(WeatherChoice(band: .mild, isRaining: true)), .required)
        XCTAssertEqual(LayerNeed.forWeather(WeatherChoice(band: .hot)), .avoid)
        XCTAssertEqual(LayerNeed.forWeather(WeatherChoice(band: .wet)), .required)
    }

    func testNovemberGridStartsOnSunday() {
        let cells = MonthGrid.cells(year: 2026, month: 11, calendar: calendar)
        XCTAssertEqual(cells.count % 7, 0)
        XCTAssertEqual(cells.compactMap { $0 }.count, 30)
        XCTAssertEqual(cells.first, .some(DayStamp(year: 2026, month: 11, day: 1)))
        XCTAssertTrue(MonthGrid.cells(year: 2026, month: 13, calendar: calendar).isEmpty)
    }

    func testColorHarmonyPrefersOneAccent() {
        let neutral = ColorHarmony.score(of: [.ivory, .camel, .black, .gold])
        let oneAccent = ColorHarmony.score(of: [.ivory, .coral, .camel])
        let clash = ColorHarmony.score(of: [.olive, .coral, .lavender])
        XCTAssertEqual(neutral, 12)
        XCTAssertEqual(oneAccent, 14)
        XCTAssertGreaterThan(oneAccent, clash)
        XCTAssertTrue(ColorHarmony.related(.coral, .blush))
        XCTAssertFalse(ColorHarmony.related(.olive, .coral))
    }

    func testWorkSuggestionSkipsShortsAndARecentRepeat() {
        let document = ClosetDocument.fresh(on: today, calendar: calendar)
        let looks = document.suggestions(on: today, occasion: .work, calendar: calendar)
        let top = try! XCTUnwrap(looks.first)
        XCTAssertFalse(top.pieces.contains { $0.id == SeedCloset.oliveShorts })
        XCTAssertNotEqual(top.signature, OutfitEngine.signature(for: SeedCloset.workLookIDs))
        XCTAssertTrue(top.pieces.contains { $0.category == .shoes })
        XCTAssertTrue(top.reasons.contains { $0.contains("Not worn") })
        let names = top.pieces.map(\.name).joined(separator: ", ")
        XCTAssertFalse(names.isEmpty)
    }

    func testHotWeekendLeavesTheCoatOff() {
        var document = ClosetDocument.fresh(on: today, calendar: calendar)
        document.preferences.weather = WeatherChoice(band: .hot)
        document.preferences.seasonOverride = .summer
        let day = DayStamp(year: 2026, month: 7, day: 4)
        let looks = document.suggestions(on: day, occasion: .weekend, calendar: calendar)
        let top = try! XCTUnwrap(looks.first)
        XCTAssertFalse(top.pieces.contains { $0.weight == .heavy })
        XCTAssertTrue(top.pieces.contains { $0.id == SeedCloset.oliveShorts || $0.id == SeedCloset.lightJeans })
        XCTAssertFalse(top.pieces.contains { $0.category == .outerwear && $0.weight == .heavy })
    }

    func testFormalSummerChoosesTheDress() {
        var document = ClosetDocument.fresh(on: today, calendar: calendar)
        document.preferences.weather = WeatherChoice(band: .warm)
        document.preferences.seasonOverride = .summer
        let day = DayStamp(year: 2026, month: 6, day: 20)
        let looks = document.suggestions(on: day, occasion: .formal, calendar: calendar)
        let top = try! XCTUnwrap(looks.first)
        XCTAssertTrue(top.pieces.contains { $0.id == SeedCloset.coralDress })
        XCTAssertTrue(top.pieces.contains { $0.category == .shoes })
    }

    func testColdWeatherIncludesTheCoat() {
        var document = ClosetDocument.fresh(on: today, calendar: calendar)
        document.preferences.weather = WeatherChoice(band: .cold)
        document.preferences.seasonOverride = .winter
        let day = DayStamp(year: 2027, month: 1, day: 8)
        let looks = document.suggestions(on: day, occasion: .work, calendar: calendar)
        let top = try! XCTUnwrap(looks.first)
        XCTAssertTrue(top.pieces.contains { $0.id == SeedCloset.camelCoat })
    }

    func testRepeatPenaltyThenRelease() {
        let garments = SeedCloset.garments
        let worn = garments.filter { SeedCloset.workLookIDs.contains($0.id) }
        let fresh = garments.filter {
            [SeedCloset.navyKnit, SeedCloset.charcoalTrousers, SeedCloset.blackBlazer, SeedCloset.blackLoafers].contains($0.id)
        }
        let wears = SeedCloset.sampleWears(around: today, calendar: calendar)
        let query = SuggestQuery(
            occasion: .work,
            weather: WeatherChoice(band: .mild),
            season: .autumn,
            day: today,
            repeatWindowDays: 7
        )
        let repeated = OutfitEngine.score(pieces: worn, wears: wears, query: query, calendar: calendar)
        let alternative = OutfitEngine.score(pieces: fresh, wears: wears, query: query, calendar: calendar)
        XCTAssertLessThan(repeated.score, alternative.score)
        XCTAssertTrue(repeated.reasons.contains { $0.contains("Worn") })

        let later = DayStamp(year: 2026, month: 11, day: 25)
        let laterQuery = SuggestQuery(
            occasion: .work,
            weather: WeatherChoice(band: .mild),
            season: .autumn,
            day: later,
            repeatWindowDays: 7
        )
        let released = OutfitEngine.score(pieces: worn, wears: wears, query: laterQuery, calendar: calendar)
        XCTAssertTrue(released.reasons.contains { $0.contains("Not worn") })
        XCTAssertGreaterThan(released.score, repeated.score)
    }

    func testSameDayWearIsNotAPastRepeat() {
        let pieces = SeedCloset.garments.filter { SeedCloset.casualLookIDs.contains($0.id) }
        let wear = WearEntry(day: today, pieceIDs: SeedCloset.casualLookIDs, occasion: .casual)
        let query = SuggestQuery(
            occasion: .casual,
            weather: WeatherChoice(band: .mild),
            season: .autumn,
            day: today,
            repeatWindowDays: 7
        )
        let scored = OutfitEngine.score(pieces: pieces, wears: [wear], query: query, calendar: calendar)
        XCTAssertFalse(scored.reasons.contains { $0.contains("Worn") && $0.contains("ago") })
    }

    func testRainPrefersALayer() {
        let tee = garment(SeedCloset.whiteTee)
        let trousers = garment(SeedCloset.camelTrousers)
        let loafers = garment(SeedCloset.blackLoafers)
        let coat = garment(SeedCloset.camelCoat)
        let query = SuggestQuery(
            occasion: .work,
            weather: WeatherChoice(band: .mild, isRaining: true),
            season: .autumn,
            day: today
        )
        let withCoat = OutfitEngine.score(pieces: [tee, trousers, loafers, coat], wears: [], query: query, calendar: calendar)
        let bare = OutfitEngine.score(pieces: [tee, trousers, loafers], wears: [], query: query, calendar: calendar)
        XCTAssertGreaterThan(withCoat.score, bare.score)
    }

    func testBuilderIssues() {
        let dressAndTop = LookSlots(top: SeedCloset.ivoryBlouse, dress: SeedCloset.coralDress, shoes: SeedCloset.nudeHeels)
        let issues = OutfitEngine.issues(for: dressAndTop)
        XCTAssertTrue(issues.contains(.dressWithTop))
        XCTAssertTrue(issues.contains { $0.isBlocking })

        let complete = LookSlots(
            top: SeedCloset.ivoryBlouse,
            bottom: SeedCloset.camelTrousers,
            shoes: SeedCloset.blackLoafers
        )
        XCTAssertFalse(OutfitEngine.issues(for: complete).contains { $0.isBlocking })

        let noShoes = LookSlots(top: SeedCloset.whiteTee, bottom: SeedCloset.lightJeans)
        let warnings = OutfitEngine.issues(for: noShoes)
        XCTAssertEqual(warnings, [.missingShoes])
        XCTAssertFalse(warnings[0].isBlocking)

        XCTAssertEqual(OutfitEngine.issues(for: .empty), [.empty])
        let half = LookSlots(top: SeedCloset.whiteTee)
        XCTAssertTrue(OutfitEngine.issues(for: half).contains(.missingBottom))
    }

    func testSignatureIgnoresOrder() {
        let forward = OutfitEngine.signature(for: [SeedCloset.ivoryBlouse, SeedCloset.camelTrousers])
        let backward = OutfitEngine.signature(for: [SeedCloset.camelTrousers, SeedCloset.ivoryBlouse])
        XCTAssertEqual(forward, backward)
        XCTAssertEqual(OutfitEngine.title(for: [
            garment(SeedCloset.camelTrousers),
            garment(SeedCloset.ivoryBlouse)
        ]), "Ivory blouse and Camel trousers")
    }

    func testEmptyClosetSuggestsNothing() {
        let looks = OutfitEngine.suggestions(
            garments: [],
            wears: [],
            query: SuggestQuery(occasion: .work, weather: WeatherChoice(band: .mild), season: .autumn, day: today),
            calendar: calendar
        )
        XCTAssertTrue(looks.isEmpty)
    }

    func testPersistenceRoundTripAndWearReplace() throws {
        var document = ClosetDocument.fresh(on: today, calendar: calendar)
        XCTAssertTrue(document.toggleFavorite(garment: SeedCloset.goldHoops))
        XCTAssertEqual(document.garment(SeedCloset.goldHoops)?.isFavorite, true)
        let look = SavedLook(
            name: "  Desk   day  ",
            pieceIDs: SeedCloset.workLookIDs,
            occasion: .work,
            handbuilt: true,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        document.saveLook(look)
        XCTAssertEqual(document.looks.first?.name, "Desk day")
        XCTAssertTrue(document.toggleFavorite(look: look.id))
        XCTAssertEqual(document.looks.first?.isFavorite, true)

        let logged = document.logWear(day: today, pieceIDs: SeedCloset.weekendLookIDs, occasion: .weekend)
        XCTAssertEqual(logged?.pieceIDs.count, 4)
        let replaced = document.logWear(day: today, pieceIDs: SeedCloset.workLookIDs + [SeedCloset.workLookIDs[0]], occasion: .work)
        XCTAssertEqual(document.wears.filter { $0.day == today }.count, 1)
        XCTAssertEqual(replaced?.id, logged?.id)
        XCTAssertEqual(Set(replaced?.pieceIDs ?? []), Set(SeedCloset.workLookIDs))

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("quillisse-\(UUID().uuidString).json")
        try ClosetArchive.save(document, to: url)
        let loaded = try XCTUnwrap(ClosetArchive.load(from: url))
        XCTAssertEqual(loaded, document)
        XCTAssertThrowsError(try ClosetArchive.decode(Data("nope".utf8)))
    }

    func testRemoveGarmentAndSampleCloset() {
        var document = ClosetDocument.fresh(on: today, calendar: calendar)
        document.saveLook(SavedLook(name: "Work", pieceIDs: SeedCloset.workLookIDs, occasion: .work))
        XCTAssertTrue(document.removeGarment(id: SeedCloset.goldHoops))
        XCTAssertFalse(document.looks[0].pieceIDs.contains(SeedCloset.goldHoops))
        XCTAssertNil(document.logWear(day: today, pieceIDs: [SeedCloset.goldHoops], occasion: .work))
        document.removeSamplePieces()
        XCTAssertTrue(document.garments.isEmpty)
        XCTAssertTrue(document.wears.isEmpty)
        XCTAssertTrue(document.looks.isEmpty)
    }

    func testNamesAndWindowClamp() {
        XCTAssertEqual(ClosetText.name("   ", fallback: "Piece"), "Piece")
        XCTAssertEqual(ClosetText.name("  Navy   knit ", fallback: "Piece"), "Navy knit")
        let long = String(repeating: "a", count: 80)
        XCTAssertEqual(ClosetText.name(long, fallback: "Piece").count, ClosetText.maxNameLength)
        var preferences = ClosetPreferences(repeatWindowDays: 1)
        XCTAssertEqual(preferences.clampedWindow, 3)
        preferences.repeatWindowDays = 40
        XCTAssertEqual(preferences.clampedWindow, 21)
        XCTAssertEqual(preferences.season(on: today), .autumn)
        preferences.seasonOverride = .summer
        XCTAssertEqual(preferences.season(on: today), .summer)
        XCTAssertEqual(WeatherChoice(band: .cool, isRaining: true).label, "Cool, rain")
    }

    func testSlotsRoundTripCategoryOrder() {
        let pieces = [
            garment(SeedCloset.blackLoafers),
            garment(SeedCloset.ivoryBlouse),
            garment(SeedCloset.camelTrousers)
        ]
        let slots = LookSlots.from(pieces: pieces)
        XCTAssertEqual(slots.top, SeedCloset.ivoryBlouse)
        XCTAssertEqual(slots.bottom, SeedCloset.camelTrousers)
        XCTAssertEqual(slots.shoes, SeedCloset.blackLoafers)
        let resolved = OutfitEngine.pieces(in: slots, garments: SeedCloset.garments)
        XCTAssertEqual(resolved.map(\.category), [.top, .bottom, .shoes])
    }

    func testFavoriteBoostDoesNotOverrideHeat() {
        var coat = garment(SeedCloset.camelCoat)
        coat.isFavorite = true
        let tee = garment(SeedCloset.whiteTee)
        let shorts = garment(SeedCloset.oliveShorts)
        let sneakers = garment(SeedCloset.whiteSneakers)
        let query = SuggestQuery(
            occasion: .weekend,
            weather: WeatherChoice(band: .hot),
            season: .summer,
            day: DayStamp(year: 2026, month: 7, day: 4)
        )
        let heavy = OutfitEngine.score(pieces: [tee, shorts, sneakers, coat], wears: [], query: query, calendar: calendar)
        let light = OutfitEngine.score(pieces: [tee, shorts, sneakers], wears: [], query: query, calendar: calendar)
        XCTAssertGreaterThan(light.score, heavy.score)
    }

    func testSampleJournalDays() {
        let wears = SeedCloset.sampleWears(around: today, calendar: calendar)
        XCTAssertEqual(wears.map(\.day.day), [10, 8, 5, 2])
        XCTAssertEqual(wears.map(\.occasion), [.casual, .weekend, .work, .date])
    }

    private func garment(_ id: UUID) -> Garment {
        SeedCloset.garments.first { $0.id == id }!
    }
}
