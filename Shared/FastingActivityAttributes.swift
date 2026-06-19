import ActivityKit
import Foundation

/// Attributes describing a live fasting session, shared between the app (which
/// starts/stops the activity) and the widget extension (which renders it on the
/// Lock Screen and in the Dynamic Island).
struct FastingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var windowStart: Date
        var windowEnd: Date
        var isFasting: Bool
        var progress: Double
    }

    // Static data that doesn't change for the life of the activity.
    var startLabel: String
    var endLabel: String
}
