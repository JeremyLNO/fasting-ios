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
        center.removePendingNotificationRequests(withIdentifiers: ["fast.start", "fast.end"])

        add(id: "fast.start", hour: schedule.startHour, minute: schedule.startMinute,
            title: "Jeûne démarré 🌙",
            body: "Ton jeûne de \(schedule.fastingHoursText) commence maintenant. Courage !")

        add(id: "fast.end", hour: schedule.endHour, minute: schedule.endMinute,
            title: "Jeûne terminé ✅",
            body: "Bravo ! Tu peux ouvrir ta fenêtre alimentaire.")

        print("[Notifications] Programmées : début \(schedule.startLabel), fin \(schedule.endLabel)")
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
