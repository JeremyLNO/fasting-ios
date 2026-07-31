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

    /// How many days of one-by-one notifications are scheduled when a manual session forces us to
    /// skip an occurrence. 14 days × 2 = 28 pending requests, well under iOS' 64-request limit even
    /// with the water reminders. Beyond that horizon the app has to be opened again — acceptable,
    /// since the plain repeating triggers come back as soon as the session is over.
    private static let horizonDays = 14

    private var horizonIdentifiers: [String] {
        (0..<Self.horizonDays).flatMap { ["fast.start.\($0)", "fast.end.\($0)"] }
    }

    func reschedule(for schedule: FastingSchedule,
                    override: ManualSession? = SharedStore.manualOverride(),
                    now: Date = Date(),
                    calendar: Calendar = .current) {
        let lang = AppLanguage.current
        center.removePendingNotificationRequests(
            withIdentifiers: ["fast.start", "fast.end"] + horizonIdentifiers)

        let startTitle = L.t("notif_start_title", lang)
        let startBody = String(format: L.t("notif_start_body", lang), schedule.fastingHoursText)
        let endTitle = L.t("notif_end_title", lang)
        let endBody = L.t("notif_end_body", lang)

        // No manual session running: plain daily repeating triggers, which keep firing even if the
        // app is never reopened.
        guard let override, override.end(for: schedule) > now else {
            add(id: "fast.start", hour: schedule.startHour, minute: schedule.startMinute,
                title: startTitle, body: startBody)
            add(id: "fast.end", hour: schedule.endHour, minute: schedule.endMinute,
                title: endTitle, body: endBody)
            print("[Notifications] scheduled: start \(schedule.startLabel), end \(schedule.endLabel)")
            return
        }

        // A manual session is running: announcing "your fast starts now" at the usual hour would
        // contradict the app, which has been counting that fast for a while already (same for the
        // end notification during a manual eating window). A repeating trigger can't skip a single
        // occurrence, so the next `horizonDays` are scheduled individually instead, minus whatever
        // falls inside the session. The repeating pair is restored by the next `reschedule`, once
        // the session has run out.
        var muted = 0
        for (index, date) in occurrences(hour: schedule.startHour, minute: schedule.startMinute,
                                         after: now, calendar: calendar).enumerated() {
            guard !override.covers(date, schedule: schedule) else { muted += 1; continue }
            add(id: "fast.start.\(index)", at: date, title: startTitle, body: startBody, calendar: calendar)
        }
        for (index, date) in occurrences(hour: schedule.endHour, minute: schedule.endMinute,
                                         after: now, calendar: calendar).enumerated() {
            guard !override.covers(date, schedule: schedule) else { muted += 1; continue }
            add(id: "fast.end.\(index)", at: date, title: endTitle, body: endBody, calendar: calendar)
        }
        print("[Notifications] manual session running until \(override.end(for: schedule)): "
              + "\(Self.horizonDays) days scheduled, \(muted) occurrence(s) muted")
    }

    /// The next `horizonDays` occurrences of a daily hour:minute, strictly after `now`.
    private func occurrences(hour: Int, minute: Int, after now: Date, calendar: Calendar) -> [Date] {
        let today = calendar.startOfDay(for: now)
        return (0...Self.horizonDays).compactMap { offset -> Date? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  date > now else { return nil }
            return date
        }
        .prefix(Self.horizonDays)
        .map { $0 }
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
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        add(id: id, components: components, repeats: true, title: title, body: body)
    }

    /// One-shot variant, for a single dated occurrence.
    private func add(id: String, at date: Date, title: String, body: String, calendar: Calendar) {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        add(id: id, components: components, repeats: false, title: title, body: body)
    }

    private func add(id: String, components: DateComponents, repeats: Bool, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
