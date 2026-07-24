import ActivityKit
import Foundation

/// Attributes describing a live fasting session, shared between the app (which
/// starts/stops the activity) and the widget extension (which renders it on the
/// Lock Screen and in the Dynamic Island). Everything the UI needs (including the
/// current window's start/end) lives in `ContentState`, since it changes over time —
/// there's no static data left to capture once at activity-start time.
struct FastingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var windowStart: Date
        var windowEnd: Date
        var isFasting: Bool
        var progress: Double
    }
}
