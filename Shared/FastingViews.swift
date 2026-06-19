import SwiftUI

func formatHMS(_ t: TimeInterval) -> String {
    let total = max(0, Int(t))
    return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
}

func formatHM(_ t: TimeInterval) -> String {
    let total = max(0, Int(t))
    let h = total / 3600
    let m = (total % 3600) / 60
    return h > 0 ? "\(h)h\(String(format: "%02d", m))" : "\(m) min"
}

/// Pastel circular progress ring, reused by the app screen and the widget.
struct RingView: View {
    var progress: Double
    var colors: [Color]
    var lineWidth: CGFloat = 20

    var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.ringTrack, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(
                    AngularGradient(gradient: Gradient(colors: colors + [colors.first ?? .white]),
                                    center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

/// Small pill showing the current metabolic stage.
struct StageChip: View {
    let stage: FastingStage
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Text(stage.emoji)
            Text(stage.name)
                .font(compact ? .caption2 : .subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, compact ? 8 : 14)
        .padding(.vertical, compact ? 4 : 8)
        .background(.white.opacity(0.6), in: Capsule())
    }
}
