import Combine
import Foundation

@MainActor
final class RoutineStore: ObservableObject {
    @Published private(set) var studio: Studio
    @Published private(set) var notificationsAllowed = false
    @Published var notificationMessage: String?

    let calendar: Calendar
    private let fileURL: URL
    private let persists: Bool

    init() {
        let calendar = Calendar.current
        self.calendar = calendar
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let folder = support.appendingPathComponent("Nimvelle", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent("studio.json")
        persists = true
        if let data = try? Data(contentsOf: fileURL), let loaded = try? StudioArchive.studio(from: data) {
            studio = loaded
        } else if !FileManager.default.fileExists(atPath: fileURL.path) {
            studio = SampleStudio.make(today: DayKey.from(Date(), calendar: calendar), calendar: calendar)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            if let data = try? StudioArchive.data(from: studio) {
                try? data.write(to: fileURL, options: .atomic)
            }
        } else {
            studio = Studio()
        }
    }

    init(preview studio: Studio, calendar: Calendar = DayCalendar.gregorian()) {
        self.studio = studio
        self.calendar = calendar
        self.fileURL = URL(fileURLWithPath: "/tmp/nimvelle-preview.json")
        self.persists = false
    }

    var today: DayKey { DayKey.from(Date(), calendar: calendar) }

    func toggle(day: DayKey, stepID: UUID) {
        guard day <= today else { return }
        studio = studio.toggling(day: day, stepID: stepID)
        Haptics.tap(studio.hapticsEnabled)
        commit()
    }

    func markRemaining(day: DayKey, part: DayPart) {
        guard day <= today else { return }
        studio = studio.markingRemaining(day: day, part: part)
        Haptics.success(studio.hapticsEnabled)
        commit()
    }

    func save(note: SkinNote) {
        studio = studio.saving(note: note)
        Haptics.success(studio.hapticsEnabled)
        commit()
    }

    func deleteNote(id: UUID) {
        studio = studio.deletingNote(id: id)
        commit()
    }

    func save(product: Product) {
        if studio.products.contains(where: { $0.id == product.id }) {
            studio = studio.replacing(product: product)
        } else {
            studio = studio.adding(product: product)
        }
        Haptics.success(studio.hapticsEnabled)
        commit()
    }

    func deleteProduct(id: UUID) {
        studio = studio.deletingProduct(id: id)
        commit()
    }

    func save(step: RoutineStep) {
        if studio.steps.contains(where: { $0.id == step.id }) {
            studio = studio.replacing(step: step)
        } else {
            studio = studio.adding(step: step)
        }
        Haptics.success(studio.hapticsEnabled)
        commit()
    }

    func deleteStep(id: UUID) {
        studio = studio.deletingStep(id: id)
        commit()
    }

    func addPhoto(fileName: String, day: DayKey) {
        let photo = ProgressPhoto(id: UUID(), day: day, fileName: fileName, isSample: false)
        studio = studio.adding(photo: photo)
        Haptics.success(studio.hapticsEnabled)
        commit()
    }

    func deletePhoto(_ photo: ProgressPhoto) {
        PhotoFiles.remove(fileName: photo.fileName)
        studio = studio.deletingPhoto(id: photo.id)
        commit()
    }

    func removeSample() {
        let names = studio.photos.filter(\.isSample).map(\.fileName)
        studio = studio.removingSample()
        names.forEach(PhotoFiles.remove(fileName:))
        Haptics.success(studio.hapticsEnabled)
        commit()
    }

    func setHaptics(_ enabled: Bool) {
        studio.hapticsEnabled = enabled
        commit(schedule: false)
    }

    func setReminderClock(part: DayPart, hour: Int, minute: Int) {
        switch part {
        case .morning:
            studio.reminders.morningHour = hour
            studio.reminders.morningMinute = minute
        case .evening:
            studio.reminders.eveningHour = hour
            studio.reminders.eveningMinute = minute
        }
        commit()
    }

    func setReminderEnabled(part: DayPart, enabled: Bool) {
        Task { await applyReminder(part: part, enabled: enabled) }
    }

    func refreshReminders() {
        Task { await reschedule() }
    }

    private func applyReminder(part: DayPart, enabled: Bool) async {
        if enabled {
            let allowed = await ReminderClient.requestAccess()
            notificationsAllowed = allowed
            if !allowed {
                notificationMessage = "Notifications are off for Nimvelle. You can allow them in Settings, then turn this reminder on."
                switch part {
                case .morning: studio.reminders.morningEnabled = false
                case .evening: studio.reminders.eveningEnabled = false
                }
                commit()
                return
            }
        }
        switch part {
        case .morning: studio.reminders.morningEnabled = enabled
        case .evening: studio.reminders.eveningEnabled = enabled
        }
        notificationMessage = nil
        commit()
    }

    private func commit(schedule: Bool = true) {
        guard persists else { return }
        if let data = try? StudioArchive.data(from: studio) {
            try? data.write(to: fileURL, options: .atomic)
        }
        if schedule {
            Task { await reschedule() }
        }
    }

    private func reschedule() async {
        let allowed = await ReminderClient.isAuthorized()
        notificationsAllowed = allowed
        let morning = RoutineMath.mark(on: today, steps: studio.steps, checks: studio.checks, part: .morning) == .complete
        let evening = RoutineMath.mark(on: today, steps: studio.steps, checks: studio.checks, part: .evening) == .complete
        let drafts = ReminderPlanner.plan(
            settings: studio.reminders,
            now: Date(),
            morningComplete: morning,
            eveningComplete: evening,
            morningSteps: RoutineMath.activeSteps(studio.steps, part: .morning).count,
            eveningSteps: RoutineMath.activeSteps(studio.steps, part: .evening).count,
            calendar: calendar
        )
        await ReminderClient.apply(allowed ? drafts : [])
    }
}
