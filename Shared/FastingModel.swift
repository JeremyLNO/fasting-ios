import Foundation

/// A simple daily fasting schedule defined by a start and end clock time.
/// A 20:00 → 12:00 schedule means a 16h fast (overnight) and an 8h eating window.
struct FastingSchedule: Codable, Equatable {
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int

    static let `default` = FastingSchedule(startHour: 20, startMinute: 0, endHour: 12, endMinute: 0)

    var startLabel: String { String(format: "%02d:%02d", startHour, startMinute) }
    var endLabel: String { String(format: "%02d:%02d", endHour, endMinute) }

    /// Duration of the fast in minutes, handling overnight windows. Equal times → 24h.
    var fastingMinutes: Int {
        let start = startHour * 60 + startMinute
        let end = endHour * 60 + endMinute
        var diff = end - start
        if diff <= 0 { diff += 24 * 60 }
        return diff
    }

    var fastingHoursText: String {
        let h = fastingMinutes / 60
        let m = fastingMinutes % 60
        return m == 0 ? "\(h)h" : "\(h)h\(String(format: "%02d", m))"
    }
}

enum FastingPhase { case fasting, eating }

/// A snapshot of where we are relative to the schedule at a given moment.
struct FastingState {
    let phase: FastingPhase
    let progress: Double      // 0...1 within the current window
    let windowStart: Date
    let windowEnd: Date
    let now: Date

    var elapsed: TimeInterval { max(0, now.timeIntervalSince(windowStart)) }
    var remaining: TimeInterval { max(0, windowEnd.timeIntervalSince(now)) }
    var elapsedHours: Double { elapsed / 3600 }
    var isFasting: Bool { phase == .fasting }
}

extension FastingSchedule {
    /// Computes the current fasting/eating state for `now`, handling overnight fasts.
    func state(at now: Date, calendar: Calendar = .current) -> FastingState {
        func clockDate(hour: Int, minute: Int, dayOffset: Int) -> Date {
            let base = calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        let durationSeconds = Double(fastingMinutes) * 60
        // Build fasting windows centred on today (yesterday / today / tomorrow starts).
        var windows: [(start: Date, end: Date)] = []
        for offset in [-1, 0, 1] {
            let start = clockDate(hour: startHour, minute: startMinute, dayOffset: offset)
            windows.append((start, start.addingTimeInterval(durationSeconds)))
        }

        // Inside a fasting window?
        if let w = windows.first(where: { now >= $0.start && now < $0.end }) {
            let total = w.end.timeIntervalSince(w.start)
            let p = total > 0 ? now.timeIntervalSince(w.start) / total : 0
            return FastingState(phase: .fasting, progress: min(max(p, 0), 1),
                                windowStart: w.start, windowEnd: w.end, now: now)
        }

        // Otherwise we're in the eating window between the previous fast end and the next fast start.
        let prevEnd = windows.map { $0.end }.filter { $0 <= now }.max() ?? windows[0].end
        let nextStart = windows.map { $0.start }.filter { $0 > now }.min() ?? windows[2].start
        let total = nextStart.timeIntervalSince(prevEnd)
        let p = total > 0 ? now.timeIntervalSince(prevEnd) / total : 0
        return FastingState(phase: .eating, progress: min(max(p, 0), 1),
                            windowStart: prevEnd, windowEnd: nextStart, now: now)
    }
}

/// Metabolic milestones reached as the fast progresses — the "état d'avancement".
struct FastingStage: Identifiable {
    let id = UUID()
    let threshold: Double   // elapsed fasting hours at which this stage begins
    let name: String
    let emoji: String
    let detail: String

    static let all: [FastingStage] = [
        .init(threshold: 0,  name: "Digestion",                emoji: "🍽️", detail: "Le corps digère le dernier repas"),
        .init(threshold: 4,  name: "Glycémie en baisse",       emoji: "📉", detail: "La glycémie redescend"),
        .init(threshold: 8,  name: "Réserves de glycogène",    emoji: "🔋", detail: "Le corps puise dans le glycogène"),
        .init(threshold: 12, name: "Combustion des graisses",  emoji: "🔥", detail: "Passage en mode lipolyse"),
        .init(threshold: 16, name: "Cétose",                   emoji: "🥑", detail: "Production de corps cétoniques"),
        .init(threshold: 18, name: "Autophagie",               emoji: "✨", detail: "Nettoyage cellulaire enclenché"),
        .init(threshold: 24, name: "Jeûne prolongé",           emoji: "🌟", detail: "Bénéfices renforcés")
    ]

    static func current(forHours hours: Double) -> FastingStage {
        all.last(where: { $0.threshold <= hours }) ?? all[0]
    }

    static func next(forHours hours: Double) -> FastingStage? {
        all.first(where: { $0.threshold > hours })
    }
}
