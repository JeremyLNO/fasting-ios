import ActivityKit
import Foundation

/// Starts, stops and tracks the fasting Live Activity (Dynamic Island + Lock Screen).
@MainActor
final class LiveActivityManager: ObservableObject {
    @Published var isActive = false

    var available: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    func refresh() {
        isActive = !Activity<FastingActivityAttributes>.activities.isEmpty
    }

    func start(schedule: FastingSchedule, state: FastingState) {
        guard available else { return }
        // Avoid duplicates.
        if !Activity<FastingActivityAttributes>.activities.isEmpty { return }

        let attributes = FastingActivityAttributes(startLabel: schedule.startLabel,
                                                   endLabel: schedule.endLabel)
        let content = ActivityContent(
            state: FastingActivityAttributes.ContentState(
                windowStart: state.windowStart,
                windowEnd: state.windowEnd,
                isFasting: state.isFasting,
                progress: state.progress),
            staleDate: state.windowEnd)

        do {
            _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
            isActive = true
        } catch {
            print("[LiveActivity] start error: \(error)")
        }
    }

    func stop() {
        Task {
            for activity in Activity<FastingActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            isActive = false
        }
    }
}
