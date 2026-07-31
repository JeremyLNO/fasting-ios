import SwiftUI

/// Plain data the Live Activity / Dynamic Island views render from (no ActivityKit
/// dependency, so the same views can be reused in an in-app preview).
struct LiveActivityData {
    let windowStart: Date
    let windowEnd: Date
    let isFasting: Bool
    let progress: Double

    var phaseTitle: String { isFasting ? L.t("phase_fasting") : L.t("phase_eating") }
    var ringColors: [Color] { Palette.ringColors(for: isFasting ? .fasting : .eating) }
    var stage: FastingStage {
        FastingStage.current(forHours: max(0, Date().timeIntervalSince(windowStart)) / 3600)
    }
    /// The *current* window's end, formatted — not a static label, so it's always correct whether
    /// we're fasting or eating (fixes "END" showing the wrong, frozen clock time after a transition).
    var endTimeLabel: String { clockLabel(windowEnd) }
}

/// Live, self-ticking remaining-time text (no activity updates required).
func liveRemaining(_ data: LiveActivityData) -> some View {
    Text(timerInterval: data.windowStart...data.windowEnd, countsDown: true)
        .monospacedDigit()
}

/// Auto-filling progress bar driven purely by the time interval.
func liveBar(_ data: LiveActivityData) -> some View {
    ProgressView(timerInterval: data.windowStart...data.windowEnd, countsDown: false) {
        EmptyView()
    } currentValueLabel: {
        EmptyView()
    }
    .tint(data.ringColors.first ?? Palette.fastingA)
}

/// Lock Screen / banner presentation of the Live Activity.
struct LiveLockView: View {
    let data: LiveActivityData

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RingView(progress: data.progress, colors: data.ringColors, lineWidth: 8)
                Text(data.stage.emoji).font(.title3)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(data.phaseTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                liveRemaining(data)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(Palette.ink)
                liveBar(data)
            }

            Spacer(minLength: 6)

            VStack(spacing: 2) {
                Text(L.t("la_end").uppercased()).font(.caption2).foregroundStyle(Palette.subtle)
                Text(data.endTimeLabel).font(.headline).foregroundStyle(Palette.ink)
            }
        }
    }
}
