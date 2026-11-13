import Foundation
import LookmiraCore
import UserNotifications

struct ReminderScheduler {
    static let identifier = "lookmira.log-today"

    func reconcile(_ preference: ReminderPreference) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
        guard preference.isEnabled, (try? preference.validated()) != nil else { return }
        center.getNotificationSettings { settings in
            let allowed: Set<UNAuthorizationStatus> = [.authorized, .provisional, .ephemeral]
            guard allowed.contains(settings.authorizationStatus) else { return }
            self.schedule(preference, center: center)
        }
    }

    func requestAndEnable(_ preference: ReminderPreference, completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted {
                self.schedule(preference, center: .current())
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    private func schedule(_ preference: ReminderPreference, center: UNUserNotificationCenter) {
        let content = UNMutableNotificationContent()
        content.title = "Log today's look"
        content.body = "Add the photo and the products you used. It stays on this iPhone."
        var components = DateComponents()
        components.hour = preference.hour
        components.minute = preference.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger)
        center.add(request)
    }
}
