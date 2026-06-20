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

    // MARK: Water (1 L = 5 glasses, resets each day)

    static let waterGoal = 5
    private static let waterCountKey = "water.count.v1"
    private static let waterDateKey = "water.date.v1"

    static func waterGlasses(asOf now: Date = Date()) -> Int {
        guard let saved = defaults.object(forKey: waterDateKey) as? Date,
              Calendar.current.isDate(saved, inSameDayAs: now) else { return 0 }
        return min(defaults.integer(forKey: waterCountKey), waterGoal)
    }

    static func setWaterGlasses(_ count: Int, asOf now: Date = Date()) {
        defaults.set(min(max(count, 0), waterGoal), forKey: waterCountKey)
        defaults.set(now, forKey: waterDateKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
