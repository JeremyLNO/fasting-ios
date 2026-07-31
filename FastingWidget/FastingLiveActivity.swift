import ActivityKit
import WidgetKit
import SwiftUI

private func data(_ context: ActivityViewContext<FastingActivityAttributes>) -> LiveActivityData {
    LiveActivityData(
        windowStart: context.state.windowStart,
        windowEnd: context.state.windowEnd,
        isFasting: context.state.isFasting,
        progress: context.state.progress)
}

/// Lock Screen / banner content ("medium" family — the default/full-size presentation).
private func lockContent(_ context: ActivityViewContext<FastingActivityAttributes>) -> some View {
    LiveLockView(data: data(context))
        .padding(16)
        .activityBackgroundTint(Palette.bgTop.opacity(0.7))
        .activitySystemActionForegroundColor(Palette.ink)
}

/// Compact content for the "small" activity family — CarPlay Dashboard and the Apple Watch Smart
/// Stack. Space is tight, so unlike the compact Dynamic Island pill (icon + bare bar only), this
/// still spells out the phase and the remaining/elapsed time as text.
private struct SmallFamilyContent: View {
    let data: LiveActivityData

    var body: some View {
        // Layout lives in Shared/LiveActivityViews.swift so the in-app gallery previews the exact
        // same card. Dark tint + light text: see LiveSmallView.
        LiveSmallView(data: data)
            .activityBackgroundTint(Palette.ink)
            .activitySystemActionForegroundColor(.white)
    }
}

private struct FamilyAwareContent: View {
    @Environment(\.activityFamily) private var activityFamily
    let context: ActivityViewContext<FastingActivityAttributes>

    var body: some View {
        switch activityFamily {
        case .small:
            SmallFamilyContent(data: data(context))
        default:
            lockContent(context)
        }
    }
}

struct FastingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FastingActivityAttributes.self) { context in
            FamilyAwareContent(context: context)
        } dynamicIsland: { context in
            let d = data(context)
            return DynamicIsland {
                // The expanded island is drawn on pure black: same reason as LiveSmallView, the
                // app's dark-navy ink is unreadable there, so everything here is light-on-dark.
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(d.isFasting ? L.t("phase_fasting") : L.t("phase_eating"))
                            .font(.caption).foregroundStyle(.white.opacity(0.85))
                    } icon: {
                        Text(d.stage.emoji)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    liveRemaining(d)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        liveBar(d, onDark: true)
                        Text("\(d.stage.emoji) \(d.stage.name()) · \(L.t("la_ends_at")) \(d.endTimeLabel)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
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
        .supplementalActivityFamilies([.small])
    }
}
