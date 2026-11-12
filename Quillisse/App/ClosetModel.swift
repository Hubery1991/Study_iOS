import Foundation
import UIKit

@MainActor
final class ClosetModel: ObservableObject {
    @Published private(set) var document: ClosetDocument
    @Published var occasion: Occasion = .work
    @Published var suggestionIndex = 0
    @Published var weatherStatus = ""

    private let fileURL: URL
    private let calendar: Calendar
    private let weatherClient = DeviceWeather()

    init(document: ClosetDocument? = nil, fileURL: URL? = nil, calendar: Calendar = .current) {
        self.calendar = calendar
        let url = fileURL ?? Self.defaultURL()
        self.fileURL = url
        if let document {
            self.document = document
        } else if let loaded = ClosetArchive.load(from: url) {
            self.document = loaded
        } else {
            let day = DayStamp.from(Date(), calendar: calendar)
            let fresh = ClosetDocument.fresh(on: day, calendar: calendar)
            self.document = fresh
            try? ClosetArchive.save(fresh, to: url)
        }
    }

    var today: DayStamp {
        DayStamp.from(Date(), calendar: calendar)
    }

    var suggestions: [SuggestedLook] {
        document.suggestions(on: today, occasion: occasion, calendar: calendar)
    }

    var currentSuggestion: SuggestedLook? {
        let looks = suggestions
        guard !looks.isEmpty else { return nil }
        let index = min(suggestionIndex, looks.count - 1)
        return looks[index]
    }

    func setOccasion(_ occasion: Occasion) {
        self.occasion = occasion
        suggestionIndex = 0
        Haptics.tap(document.preferences.hapticsEnabled)
    }

    func showAnother() {
        let count = suggestions.count
        guard count > 1 else { return }
        suggestionIndex = (suggestionIndex + 1) % count
        Haptics.tap(document.preferences.hapticsEnabled)
    }

    func wear(pieces: [Garment], occasion: Occasion, lookID: UUID? = nil) {
        _ = document.logWear(
            day: today,
            pieceIDs: pieces.map(\.id),
            occasion: occasion,
            lookID: lookID
        )
        persist()
        Haptics.success(document.preferences.hapticsEnabled)
    }

    func clearToday() {
        document.clearWear(on: today)
        persist()
    }

    func clearWear(on day: DayStamp) {
        document.clearWear(on: day)
        persist()
    }

    @discardableResult
    func addPhoto(_ image: UIImage) -> UUID? {
        guard let token = PhotoStore.save(image) else { return nil }
        let garment = Garment(
            id: UUID(),
            name: "New piece",
            category: .top,
            colors: [.ivory],
            seasons: [.allSeason],
            formality: .casual,
            weight: .light,
            imageToken: token,
            isFavorite: false,
            isSample: false,
            createdAt: Date(),
            note: ""
        )
        document.upsert(garment)
        persist()
        return garment.id
    }

    func save(_ garment: Garment) {
        var copy = garment
        copy.name = ClosetText.name(garment.name, fallback: garment.category.displayName)
        document.upsert(copy)
        persist()
    }

    func deleteGarment(_ id: UUID) {
        if let token = document.garment(id)?.imageToken {
            PhotoStore.delete(token: token)
        }
        document.removeGarment(id: id)
        persist()
    }

    func toggleFavorite(garment id: UUID) {
        document.toggleFavorite(garment: id)
        persist()
        Haptics.tap(document.preferences.hapticsEnabled)
    }

    func saveLook(name: String, pieces: [Garment], occasion: Occasion?, handbuilt: Bool, favorite: Bool) {
        let look = SavedLook(
            name: name.isEmpty ? OutfitEngine.title(for: pieces) : name,
            pieceIDs: pieces.map(\.id),
            occasion: occasion,
            isFavorite: favorite,
            handbuilt: handbuilt,
            createdAt: Date()
        )
        document.saveLook(look)
        persist()
    }

    func toggleFavorite(look: SuggestedLook) {
        let ids = look.pieces.map(\.id)
        let signature = OutfitEngine.signature(for: ids)
        if let existing = document.looks.first(where: { OutfitEngine.signature(for: $0.pieceIDs) == signature }) {
            document.toggleFavorite(look: existing.id)
        } else {
            document.saveLook(SavedLook(
                name: look.title,
                pieceIDs: ids,
                occasion: occasion,
                isFavorite: true,
                handbuilt: false
            ))
        }
        persist()
        Haptics.tap(document.preferences.hapticsEnabled)
    }

    func isFavorite(_ look: SuggestedLook) -> Bool {
        let signature = look.signature
        return document.looks.contains {
            $0.isFavorite && OutfitEngine.signature(for: $0.pieceIDs) == signature
        }
    }

    func removeLook(_ id: UUID) {
        document.removeLook(id: id)
        persist()
    }

    func dismissSampleNote() {
        document.preferences.hasDismissedSampleNote = true
        persist()
    }

    func removeSamplePieces() {
        let tokens = document.garments.filter(\.isSample).map(\.imageToken)
        document.removeSamplePieces()
        for token in tokens {
            PhotoStore.delete(token: token)
        }
        persist()
    }

    func updatePreferences(_ body: (inout ClosetPreferences) -> Void) {
        body(&document.preferences)
        document.preferences.repeatWindowDays = document.preferences.clampedWindow
        persist()
    }

    func setManualBand(_ band: WeatherBand) {
        document.preferences.weather.band = band
        document.preferences.weatherIsFromDevice = false
        document.preferences.useAppleWeather = false
        document.preferences.weatherNote = ""
        weatherStatus = "Using the weather you chose. No location is involved."
        persist()
    }

    func setRaining(_ raining: Bool) {
        document.preferences.weather.isRaining = raining
        document.preferences.weatherIsFromDevice = false
        document.preferences.useAppleWeather = false
        persist()
    }

    func setSeason(_ season: Season?) {
        document.preferences.seasonOverride = season
        persist()
    }

    func refreshAppleWeather() async {
        do {
            let reading = try await weatherClient.reading()
            let band = WeatherBand.band(celsius: reading.celsius)
            document.preferences.weather = WeatherChoice(band: band, isRaining: reading.isRaining)
            document.preferences.useAppleWeather = true
            document.preferences.weatherIsFromDevice = true
            document.preferences.weatherNote = reading.summary
            weatherStatus = "Using Apple Weather, \(reading.summary). Your location is not saved."
            persist()
        } catch DeviceWeatherError.denied {
            document.preferences.useAppleWeather = false
            document.preferences.weatherIsFromDevice = false
            weatherStatus = "Location is off. Choose the weather here. The closet still works."
            persist()
        } catch {
            document.preferences.useAppleWeather = false
            document.preferences.weatherIsFromDevice = false
            weatherStatus = "Apple Weather could not be reached. The choice below is what today will use."
            persist()
        }
    }

    func stopAppleWeather() {
        document.preferences.useAppleWeather = false
        document.preferences.weatherIsFromDevice = false
        document.preferences.weatherNote = ""
        weatherStatus = "Using the weather you chose."
        persist()
    }

    private func persist() {
        try? ClosetArchive.save(document, to: fileURL)
    }

    private static func defaultURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("Quillisse", isDirectory: true)
            .appendingPathComponent("closet.json")
    }
}
