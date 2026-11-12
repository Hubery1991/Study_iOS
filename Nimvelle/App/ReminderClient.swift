import Foundation
import UserNotifications

enum ReminderClient {
    static func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    static func requestAccess() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .denied, .ephemeral:
            return false
        @unknown default:
            return false
        }
    }

    static func apply(_ drafts: [ReminderDraft]) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let stale = pending.map(\.identifier).filter { identifier in
            identifier.hasPrefix(ReminderPlanner.morningPrefix) || identifier.hasPrefix(ReminderPlanner.eveningPrefix)
        }
        center.removePendingNotificationRequests(withIdentifiers: stale)
        for draft in drafts {
            let content = UNMutableNotificationContent()
            content.title = draft.title
            content.body = draft.body
            content.sound = .default
            var parts = DateComponents()
            parts.year = draft.fireDay.year
            parts.month = draft.fireDay.month
            parts.day = draft.fireDay.day
            parts.hour = draft.hour
            parts.minute = draft.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            let request = UNNotificationRequest(identifier: draft.identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }
}
