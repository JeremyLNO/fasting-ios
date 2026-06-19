import ActivityKit
import WidgetKit
import SwiftUI

private func data(_ context: ActivityViewContext<FastingActivityAttributes>) -> LiveActivityData {
    LiveActivityData(
        windowStart: context.state.windowStart,
        windowEnd: context.state.windowEnd,
        isFasting: context.state.isFasting,
        progress: context.state.progress,
        startLabel: context.attributes.startLabel,
        endLabel: context.attributes.endLabel)
}

struct FastingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FastingActivityAttributes.self) { context in
            // Lock Screen / banner
            LiveLockView(data: data(context))
                .padding(16)
                .activityBackgroundTint(Palette.bgTop.opacity(0.7))
                .activitySystemActionForegroundColor(Palette.ink)

        } dynamicIsland: { context in
            let d = data(context)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(d.isFasting ? "Jeûne" : "Repas")
                            .font(.caption).foregroundStyle(Palette.ink)
                    } icon: {
                        Text(d.stage.emoji)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    liveRemaining(d)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(Palette.ink)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        liveBar(d)
                        Text("\(d.stage.emoji) \(d.stage.name) · fin à \(d.endLabel)")
                            .font(.caption2)
                            .foregroundStyle(Palette.subtle)
                    }
                }
            } compactLeading: {
                Text(d.stage.emoji)
            } compactTrailing: {
                liveBar(d)
                    .frame(width: 46)
            } minimal: {
                Text(d.stage.emoji)
            }
            .keylineTint(d.ringColors.first ?? Palette.fastingA)
        }
    }
}
