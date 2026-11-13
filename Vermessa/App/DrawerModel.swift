import Combine
import Foundation
import VermessaCore

@MainActor
final class DrawerModel: ObservableObject {
    @Published private(set) var library: WardrobeLibrary
    @Published var alertMessage: String?

    let photos: PhotoCabinet
    private let store: JSONWardrobeStore
    private var allowPersist = true

    init() {
        let root = DrawerModel.storageRoot()
        let store = JSONWardrobeStore(fileURL: root.appendingPathComponent("drawer.json"))
        self.store = store
        self.photos = PhotoCabinet(directory: root.appendingPathComponent("photos", isDirectory: true))
        do {
            var loaded = WardrobeLibrary(snapshot: try store.load())
            if let today = CalendarDay.capturing(Date(), calendar: .current),
               loaded.installStarterIfNeeded(today: today) {
                try store.save(loaded.snapshot)
            }
            library = loaded
        } catch {
            library = WardrobeLibrary()
            allowPersist = false
            alertMessage = WardrobeStoreError.unreadable.message
        }
    }

    var today: CalendarDay {
        CalendarDay.capturing(Date(), calendar: .current) ?? CalendarDay(year: 2026, month: 1, day: 1)
    }

    func owned(matching filter: WardrobeFilter) -> [Lipstick] {
        var narrowed = filter
        narrowed.ownership = .owned
        return library.filtered(narrowed)
    }

    func wishlist(matching text: String) -> [Lipstick] {
        library.filtered(WardrobeFilter(text: text, ownership: .wishlist))
    }

    @discardableResult
    func add(_ draft: LipstickDraft, photoData: Data?) -> Lipstick? {
        do {
            var lipstick = try library.add(draft)
            if let photoData {
                let fileName = "\(lipstick.id.uuidString).jpg"
                try photos.writeJPEG(photoData, fileName: fileName)
                lipstick.swatchFileName = fileName
                try library.update(lipstick)
            }
            persist()
            return library.lipstick(id: lipstick.id)
        } catch let error as WardrobeError {
            alertMessage = error.message
        } catch let error as PhotoCabinetError {
            alertMessage = error.message
            persist()
        } catch {
            alertMessage = WardrobeStoreError.unwritable.message
        }
        return library.lipsticks.last
    }

    func save(_ lipstick: Lipstick, photoData: Data?, removePhoto: Bool) {
        do {
            var next = lipstick
            if removePhoto {
                photos.delete(lipstick.swatchFileName)
                next.swatchFileName = nil
            }
            if let photoData {
                let fileName = "\(lipstick.id.uuidString).jpg"
                try photos.writeJPEG(photoData, fileName: fileName)
                if lipstick.swatchFileName != fileName {
                    photos.delete(lipstick.swatchFileName)
                }
                next.swatchFileName = fileName
            }
            try library.update(next)
            persist()
        } catch let error as WardrobeError {
            alertMessage = error.message
        } catch let error as PhotoCabinetError {
            alertMessage = error.message
        } catch {
            alertMessage = WardrobeStoreError.unwritable.message
        }
    }

    func delete(id: UUID) {
        let fileName = library.lipstick(id: id)?.swatchFileName
        do {
            try library.delete(id: id)
            photos.delete(fileName)
            persist()
        } catch let error as WardrobeError {
            alertMessage = error.message
        }
    }

    func setOwnership(id: UUID, to ownership: Ownership) {
        do {
            try library.setOwnership(id: id, to: ownership)
            persist()
        } catch let error as WardrobeError {
            alertMessage = error.message
        }
    }

    func logWorn(id: UUID) {
        do {
            _ = try library.markWorn(lipstickID: id, on: today)
            persist()
        } catch let error as WardrobeError {
            alertMessage = error.message
        }
    }

    func clearWorn(id: UUID, on day: CalendarDay) {
        if library.clearWorn(lipstickID: id, on: day) {
            persist()
        }
    }

    func isWornToday(_ id: UUID) -> Bool {
        library.wornLipsticks(on: today).contains { $0.id == id }
    }

    private func persist() {
        guard allowPersist else { return }
        do {
            try store.save(library.snapshot)
        } catch {
            alertMessage = WardrobeStoreError.unwritable.message
        }
    }

    private static func storageRoot() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let root = base.appendingPathComponent("Vermessa", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
}
