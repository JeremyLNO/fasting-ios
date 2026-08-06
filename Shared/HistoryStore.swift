import Foundation

/// One fasting window, keyed by the calendar day its window started.
struct FastRecord: Codable {
    let targetMinutes: Int
    let completed: Bool
    /// How long the fast actually lasted. Optional so records written before this field existed
    /// still decode; for those, fall back to the target when completed (that's what they meant).
    let actualMinutes: Int?
    /// Exact clock times, present once the day has been edited by hand (or logged with them).
    /// Optional for the same backward-compatibility reason — older records only knew a duration.
    let startTime: Date?
    let endTime: Date?

    init(targetMinutes: Int, completed: Bool, actualMinutes: Int? = nil,
         startTime: Date? = nil, endTime: Date? = nil) {
        self.targetMinutes = targetMinutes
        self.completed = completed
        self.actualMinutes = actualMinutes
        self.startTime = startTime
        self.endTime = endTime
    }

    /// Best available real duration, in minutes — explicit times win when they're known.
    var effectiveMinutes: Int {
        if let start = startTime, let end = endTime, end > start {
            return Int(end.timeIntervalSince(start) / 60)
        }
        return actualMinutes ?? (completed ? targetMinutes : 0)
    }
}

/// How a given day turned out, for the "last 7 days" strip.
enum DayStatus {
    case full       // target reached
    case partial    // fasted, but stopped short
    case none       // nothing recorded
    case inProgress // today's fast is still running
}

/// One column of the "last 7 days" strip.
struct DayOutcome: Identifiable {
    let id = UUID()
    let date: Date
    let status: DayStatus
    /// Real hours fasted (or elapsed so far, for today).
    let hours: Double
    /// 0...1 against the day's target, for the ring.
    let progress: Double
    /// Exact times when they're known, so the day editor opens pre-filled with what's shown.
    var startTime: Date? = nil
    var endTime: Date? = nil

    var isToday: Bool { Calendar.current.isDateInToday(date) }

    /// "20h", "18h30" — compact, matching the strip's small rings.
    var hoursLabel: String {
        guard hours > 0 else { return "—" }
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return m == 0 ? "\(h)h" : "\(h)h\(String(format: "%02d", m))"
    }
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
    static func syncIfNeeded(schedule: FastingSchedule, installDate: Date,
                             override: ManualSession? = SharedStore.manualOverride(),
                             now: Date = Date()) -> Bool {
        // A fast stopped early skips the next scheduled window: it never ran, so reconstructing it
        // as a success would hand the user a fast they didn't do.
        let skipped = override?.skippedFastStart(for: schedule)
        var records = load()
        var changed = false
        for w in schedule.pastFastingWindows(before: now, limitDate: installDate) {
            let key = dayKey(w.start)
            if records[key] == nil {
                if let skipped, dayKey(skipped) == key {
                    records[key] = FastRecord(targetMinutes: schedule.fastingMinutes, completed: false,
                                              actualMinutes: 0)
                } else {
                    // Fully elapsed scheduled window → the real duration is the target.
                    records[key] = FastRecord(targetMinutes: schedule.fastingMinutes, completed: true,
                                              actualMinutes: schedule.fastingMinutes)
                }
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
        records[dayKey(day)] = FastRecord(targetMinutes: targetMinutes,
                                          completed: actualMinutes >= targetMinutes,
                                          actualMinutes: max(0, actualMinutes))
        save(records)
    }

    /// The record stored for a given day, if any — used to pre-fill the day editor.
    static func record(for day: Date) -> FastRecord? { load()[dayKey(day)] }

    /// Writes a hand-edited day. `completed` is derived from the edited times rather than trusted
    /// from the caller, so the strip, the streaks and the stats can't disagree with what's shown.
    static func setEntry(day: Date, start: Date, end: Date, targetMinutes: Int) {
        guard end > start else { return }
        let minutes = Int(end.timeIntervalSince(start) / 60)
        var records = load()
        records[dayKey(day)] = FastRecord(targetMinutes: targetMinutes,
                                          completed: minutes >= targetMinutes,
                                          actualMinutes: minutes,
                                          startTime: start, endTime: end)
        save(records)
    }

    /// Marks a day as "nothing fasted". Stored as an explicit zero rather than deleted: a deleted
    /// day whose scheduled window has already elapsed would simply be re-created by `syncIfNeeded`
    /// on the next launch, so clearing it would silently undo itself. A zero-minute record renders
    /// exactly like "no data" and survives the sync.
    static func clearEntry(day: Date, targetMinutes: Int) {
        var records = load()
        records[dayKey(day)] = FastRecord(targetMinutes: targetMinutes, completed: false, actualMinutes: 0)
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

    /// The last 7 calendar days (oldest first) as ready-to-render outcomes. `liveState` is the
    /// fast currently running, if any: its day has no record yet, so it's shown as in-progress
    /// with the time elapsed so far rather than as an empty day.
    static func last7Days(schedule: FastingSchedule, liveState: FastingState? = nil,
                          now: Date = Date(), calendar: Calendar = .current) -> [DayOutcome] {
        let records = load()
        let today = calendar.startOfDay(for: now)
        let target = max(1, schedule.fastingMinutes)

        return stride(from: 6, through: 0, by: -1).compactMap { offset -> DayOutcome? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }

            if let record = records[dayKey(date)] {
                let minutes = record.effectiveMinutes
                return DayOutcome(date: date,
                                  status: record.completed ? .full : (minutes > 0 ? .partial : .none),
                                  hours: Double(minutes) / 60,
                                  progress: min(1, Double(minutes) / Double(record.targetMinutes)),
                                  startTime: record.startTime, endTime: record.endTime)
            }

            // No record yet: if a fast is running and started on this day, show it live.
            if let s = liveState, s.isFasting,
               calendar.isDate(s.windowStart, inSameDayAs: date) {
                let minutes = Int(s.elapsed / 60)
                return DayOutcome(date: date, status: .inProgress,
                                  hours: Double(minutes) / 60,
                                  progress: min(1, Double(minutes) / Double(target)),
                                  startTime: s.windowStart, endTime: s.windowEnd)
            }

            return DayOutcome(date: date, status: .none, hours: 0, progress: 0)
        }
    }

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
