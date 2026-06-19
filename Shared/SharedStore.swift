import Foundation
import WidgetKit

/// Persists the schedule in an App Group so the app and the widget read the same data.
enum SharedStore {
    static let appGroup = "group.company.lno.fasting"
    private static let key = "fasting.schedule.v1"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static func load() -> FastingSchedule {
        guard let data = defaults.data(forKey: key),
              let schedule = try? JSONDecoder().decode(FastingSchedule.self, from: data) else {
            return .default
        }
        return schedule
    }

    static func save(_ schedule: FastingSchedule) {
        if let data = try? JSONEncoder().encode(schedule) {
            defaults.set(data, forKey: key)
        }
        // Tell the system to refresh the home-screen widget with the new schedule.
        WidgetCenter.shared.reloadAllTimelines()
    }
}
