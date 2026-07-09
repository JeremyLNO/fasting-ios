import Foundation
import UserNotifications

/// Schedules the two daily local notifications: fast start and fast end.
final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    func requestAuthorizationAndSchedule() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                self.reschedule(for: SharedStore.load())
            }
        }
    }

    func reschedule(for schedule: FastingSchedule) {
        let lang = AppLanguage.current
        center.removePendingNotificationRequests(withIdentifiers: ["fast.start", "fast.end"])

        add(id: "fast.start", hour: schedule.startHour, minute: schedule.startMinute,
            title: L.t("notif_start_title", lang),
            body: String(format: L.t("notif_start_body", lang), schedule.fastingHoursText))

        add(id: "fast.end", hour: schedule.endHour, minute: schedule.endMinute,
            title: L.t("notif_end_title", lang),
            body: L.t("notif_end_body", lang))

        print("[Notifications] scheduled: start \(schedule.startLabel), end \(schedule.endLabel)")
    }

    /// Cancels every pending notification (used for account deletion).
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    func rescheduleWater(enabled: Bool, goal: Int) {
        let ids = (0..<8).map { "water.reminder.\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        guard enabled else { return }

        let lang = AppLanguage.current
        let count = min(max(goal, 3), 8)
        let startHour = 9, endHour = 21
        let span = endHour - startHour
        for i in 0..<count {
            let hour = startHour + Int((Double(span) * Double(i) / Double(max(count - 1, 1))).rounded())
            add(id: "water.reminder.\(i)", hour: min(hour, 22), minute: 0,
                title: L.t("water_reminder_title", lang), body: L.t("water_reminder_body", lang))
        }
    }

    private func add(id: String, hour: Int, minute: Int, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
