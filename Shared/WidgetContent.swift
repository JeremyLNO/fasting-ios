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
                Text(state.isFasting ? "jeûne" : "repas")
                    .font(.caption2)
                    .foregroundStyle(Palette.subtle)
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
                Text(state.isFasting ? "Jeûne en cours" : "Fenêtre alimentaire")
                    .font(.headline)
                    .foregroundStyle(Palette.ink)
                live
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(Palette.ink)
                StageChip(stage: FastingStage.current(forHours: state.elapsedHours), compact: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
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
