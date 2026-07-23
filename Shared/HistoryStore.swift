import Foundation

/// One fasting window, keyed by the calendar day its window started.
struct FastRecord: Codable {
    let targetMinutes: Int
    let completed: Bool
}

/// Tracks daily fasting history so streaks and stats can be shown. There is no explicit
/// start/stop action in this app — a fast counts as completed once its scheduled window has
/// fully elapsed. History only ever grows from the install date onward (never fabricated).
enum HistoryStore {
    private static let recordsKey = "history.records.v1"
    private static var defaults: UserDefaults { UserDefaults(suiteName: SharedStore.appGroup) ?? .standard }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()

    private static func dayKey(_ date: Date) -> String { dayFormatter.string(from: date) }

    private static func load() -> [String: FastRecord] {
        guard let data = defaults.data(forKey: recordsKey),
              let dict = try? JSONDecoder().decode([String: FastRecord].self, from: data) else { return [:] }
        return dict
    }

    private static func save(_ dict: [String: FastRecord]) {
        if let data = try? JSONEncoder().encode(dict) {
            defaults.set(data, forKey: recordsKey)
        }
    }

    /// Call on launch/foreground: logs any fasting windows that fully elapsed since install
    /// and aren't recorded yet. Never overwrites a day that already has a record — in particular,
    /// a real interruption logged by `logInterruption` always wins over this reconstruction.
    @discardableResult
    static func syncIfNeeded(schedule: FastingSchedule, installDate: Date, now: Date = Date()) -> Bool {
        var records = load()
        var changed = false
        for w in schedule.pastFastingWindows(before: now, limitDate: installDate) {
            let key = dayKey(w.start)
            if records[key] == nil {
                records[key] = FastRecord(targetMinutes: schedule.fastingMinutes, completed: true)
                changed = true
            }
        }
        if changed { save(records) }
        return changed
    }

    /// Logs a fasting session that was manually ended before its target duration — called at the
    /// exact moment of interruption, since that's the only time the real elapsed duration is known
    /// (once overwritten by the next session, it can no longer be reconstructed from the schedule).
    static func logInterruption(day: Date, targetMinutes: Int, actualMinutes: Int) {
        var records = load()
        records[dayKey(day)] = FastRecord(targetMinutes: targetMinutes, completed: actualMinutes >= targetMinutes)
        save(records)
    }

    static func currentStreak(now: Date = Date(), calendar: Calendar = .current) -> Int {
        let records = load()
        guard !records.isEmpty else { return 0 }
        let today = calendar.startOfDay(for: now)

        // Anchor on the most recent completed day within the last 3 calendar days — the fast
        // that started "yesterday" may still be in progress (it ends later today), so the most
        // recently *completed* one can be a couple of days back.
        var cursor: Date?
        for offset in 0...2 {
            let candidate = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            if records[dayKey(candidate)]?.completed == true { cursor = candidate; break }
        }
        guard var day = cursor else { return 0 }

        var streak = 0
        while let record = records[dayKey(day)], record.completed {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    static func bestStreak(calendar: Calendar = .current) -> Int {
        let records = load()
        guard !records.isEmpty else { return 0 }
        var best = 0, current = 0
        var previousDate: Date?
        for key in records.keys.sorted() {
            guard records[key]?.completed == true, let date = dayFormatter.date(from: key) else {
                current = 0; previousDate = nil; continue
            }
            if let prev = previousDate,
               let nextDay = calendar.date(byAdding: .day, value: 1, to: prev),
               calendar.isDate(nextDay, inSameDayAs: date) {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            previousDate = date
        }
        return best
    }

    static var totalCompleted: Int { load().values.filter { $0.completed }.count }

    static var averageMinutes: Int {
        let completed = load().values.filter { $0.completed }.map { $0.targetMinutes }
        guard !completed.isEmpty else { return 0 }
        return completed.reduce(0, +) / completed.count
    }

    /// Erases all recorded fasting history (used for account deletion).
    static func wipe() { defaults.removeObject(forKey: recordsKey) }

    /// Last `days` calendar days (oldest first), with their record if any — for a simple heatmap.
    static func recentDays(_ days: Int, now: Date = Date(), calendar: Calendar = .current) -> [(date: Date, record: FastRecord?)] {
        let records = load()
        var result: [(Date, FastRecord?)] = []
        let today = calendar.startOfDay(for: now)
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            result.append((date, records[dayKey(date)]))
        }
        return result
    }
}
