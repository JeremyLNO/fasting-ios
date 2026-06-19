import SwiftUI

/// Plain data the Live Activity / Dynamic Island views render from (no ActivityKit
/// dependency, so the same views can be reused in an in-app preview).
struct LiveActivityData {
    let windowStart: Date
    let windowEnd: Date
    let isFasting: Bool
    let progress: Double
    let startLabel: String
    let endLabel: String

    var phaseTitle: String { isFasting ? "Jeûne en cours" : "Fenêtre alimentaire" }
    var ringColors: [Color] { Palette.ringColors(for: isFasting ? .fasting : .eating) }
    var stage: FastingStage {
        FastingStage.current(forHours: max(0, Date().timeIntervalSince(windowStart)) / 3600)
    }
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
                Text("FIN").font(.caption2).foregroundStyle(Palette.subtle)
                Text(data.endLabel).font(.headline).foregroundStyle(Palette.ink)
            }
        }
    }
}
