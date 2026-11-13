import Combine
import Foundation
import LookmiraCore

@MainActor
final class DiaryModel: ObservableObject {
    @Published private(set) var document: JournalDocument
    @Published var selectedDay: Date
    @Published var visibleMonth: Date
    @Published var banner: String?

    let calendar: Calendar
    private let store: JournalFileStore
    private let photos: PhotoArchive
    private let reminders: ReminderScheduler

    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        self.calendar = calendar

        let root = DiaryPaths.root()
        store = JournalFileStore(fileURL: root.appendingPathComponent("journal.json"))
        photos = PhotoArchive(folder: root.appendingPathComponent("Photos", isDirectory: true))
        reminders = ReminderScheduler()

        let now = Date()
        var loaded = JournalDocument(journal: LookJournal(), reminder: .off, didInstallSamples: true)
        var seeded = false
        do {
            let result = try store.loadOrSeed(now: now, calendar: calendar)
            loaded = result.document
            seeded = result.seeded
        } catch {
            banner = "The diary file could not be read."
        }
        if seeded {
            photos.installBundledSamples()
        }
        document = loaded
        let today = calendar.startOfDay(for: now)
        selectedDay = today
        visibleMonth = today
        reminders.reconcile(loaded.reminder)
    }

    func photoURL(_ name: String?) -> URL? {
        photos.url(for: name)
    }

    func importJPEG(_ data: Data) throws -> String {
        try photos.saveJPEG(data)
    }

    @discardableResult
    func add(_ draft: LookDraft) throws -> MakeupLook {
        var next = document
        let look = try next.journal.add(draft, now: Date(), calendar: calendar)
        try store.save(next)
        document = next
        return look
    }

    func update(_ id: UUID, with draft: LookDraft) throws {
        var next = document
        _ = try next.journal.update(id, with: draft, now: Date(), calendar: calendar)
        try store.save(next)
        document = next
    }

    func delete(_ id: UUID) throws {
        var next = document
        let removed = try next.journal.delete(id)
        try store.save(next)
        document = next
        if let name = removed.photoFileName, !document.journal.photoFileNamesInUse().contains(name) {
            photos.delete(name)
        }
    }

    func setFavorite(_ id: UUID, _ favorite: Bool) throws {
        var next = document
        _ = try next.journal.setFavorite(id, favorite, now: Date())
        try store.save(next)
        document = next
    }

    @discardableResult
    func recreate(_ id: UUID, on day: Date) throws -> MakeupLook {
        var next = document
        let look = try next.journal.recreate(id, on: day, now: Date(), calendar: calendar)
        try store.save(next)
        document = next
        selectedDay = calendar.startOfDay(for: day)
        visibleMonth = selectedDay
        banner = "Logged again on \(DiaryDates.dayTitle(selectedDay, calendar: calendar))."
        return look
    }

    func shiftMonth(by delta: Int) {
        guard let next = calendar.date(byAdding: .month, value: delta, to: visibleMonth) else { return }
        visibleMonth = next
        if !calendar.isDate(selectedDay, equalTo: next, toGranularity: .month) {
            selectedDay = calendar.date(from: calendar.dateComponents([.year, .month], from: next)) ?? next
        }
    }

    func select(day: Date) {
        selectedDay = calendar.startOfDay(for: day)
        visibleMonth = selectedDay
    }

    func setReminderEnabled(_ enabled: Bool) {
        var preference = document.reminder
        preference.isEnabled = enabled
        guard (try? preference.validated()) != nil else { return }
        if !enabled {
            document.reminder = preference
            persistReminder()
            reminders.reconcile(preference)
            return
        }
        reminders.requestAndEnable(preference) { [weak self] granted in
            guard let self else { return }
            if granted {
                self.document.reminder = preference
                self.persistReminder()
            } else {
                self.banner = "Notifications are turned off for Lookmira. You can allow them in Settings."
            }
        }
    }

    func setReminderTime(hour: Int, minute: Int) {
        var preference = document.reminder
        preference.hour = hour
        preference.minute = minute
        guard (try? preference.validated()) != nil else { return }
        document.reminder = preference
        persistReminder()
        if preference.isEnabled {
            reminders.reconcile(preference)
        }
    }

    private func persistReminder() {
        do {
            try store.save(document)
        } catch {
            banner = "The reminder could not be saved."
        }
    }
}

enum DiaryPaths {
    static func root() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let directory = base.appendingPathComponent("Lookmira", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
