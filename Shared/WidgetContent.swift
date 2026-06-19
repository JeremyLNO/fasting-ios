import SwiftUI
import WidgetKit

/// The visual content of the widget, shared so it can be rendered both inside the
/// WidgetKit extension and in an in-app preview. The caller supplies the background.
struct FastingWidgetContent: View {
    let family: WidgetFamily
    let state: FastingState

    var body: some View {
        switch family {
        case .accessoryCircular: accessory
        case .systemMedium:      medium
        case .systemLarge:       large
        default:                 small
        }
    }

    /// Live-updating elapsed (fasting) or countdown (eating), no timeline reloads needed.
    private var live: some View {
        Group {
            if state.isFasting {
                Text(state.windowStart, style: .timer)
            } else {
                Text(state.windowEnd, style: .timer)
            }
        }
        .monospacedDigit()
    }

    private var small: some View {
        ZStack {
            RingView(progress: state.progress, colors: Palette.ringColors(for: state.phase), lineWidth: 11)
            VStack(spacing: 2) {
                Text(FastingStage.current(forHours: state.elapsedHours).emoji)
                    .font(.title3)
                live
                    .font(.system(.callout, design: .rounded).weight(.bold))
                    .foregroundStyle(Palette.ink)
                Text(state.isFasting ? L.t("phase_fasting") : L.t("phase_eating"))
                    .font(.caption2)
                    .foregroundStyle(Palette.subtle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .padding(6)
    }

    private var medium: some View {
        HStack(spacing: 16) {
            ZStack {
                RingView(progress: state.progress, colors: Palette.ringColors(for: state.phase), lineWidth: 11)
                Text("\(Int((state.progress * 100).rounded()))%")
                    .font(.system(.callout, design: .rounded).weight(.bold))
                    .foregroundStyle(Palette.ink)
            }
            .frame(width: 92, height: 92)

            VStack(alignment: .leading, spacing: 6) {
                Text(state.isFasting ? L.t("phase_fasting") : L.t("phase_eating"))
                    .font(.headline)
                    .foregroundStyle(Palette.ink)
                live
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(Palette.ink)
                StageChip(emoji: FastingStage.current(forHours: state.elapsedHours).emoji,
                          name: FastingStage.current(forHours: state.elapsedHours).name(), compact: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
    }

    private var large: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: state.isFasting ? "moon.stars.fill" : "leaf.fill")
                    .font(.subheadline)
                    .foregroundStyle(Palette.accent(state.phase))
                Text(state.isFasting ? L.t("phase_fasting") : L.t("phase_eating"))
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text("\(Int((state.progress * 100).rounded()))%")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(Palette.accent(state.phase))
            }

            ZStack {
                RingView(progress: state.progress, colors: Palette.ringColors(for: state.phase), lineWidth: 16)
                VStack(spacing: 2) {
                    Text(FastingStage.current(forHours: state.elapsedHours).emoji)
                        .font(.title2)
                    live
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                }
            }
            .frame(maxHeight: .infinity)

            StageChip(emoji: FastingStage.current(forHours: state.elapsedHours).emoji,
                      name: FastingStage.current(forHours: state.elapsedHours).name())

            HStack(spacing: 6) {
                Image(systemName: "flag.checkered")
                    .font(.caption2).foregroundStyle(Palette.sub)
                Text(state.isFasting ? L.t("stat_end") : L.t("stat_next_fast"))
                    .font(.caption).foregroundStyle(Palette.sub)
                Spacer()
                Text(state.windowEnd, format: .dateTime.hour().minute())
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Palette.ink)
            }
        }
        .padding(16)
    }

    private var accessory: some View {
        Gauge(value: state.progress) {
            Text(state.isFasting ? "J" : "R")
        } currentValueLabel: {
            Text("\(Int((state.progress * 100).rounded()))")
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}
