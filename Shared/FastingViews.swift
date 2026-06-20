import SwiftUI

// MARK: - Formatting

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

// MARK: - Decorative background

/// Soft pastel gradient with blurred colour blobs and sparkles, tinted by phase.
struct FastingBackground: View {
    let phase: FastingPhase

    private let sparkles: [(x: CGFloat, y: CGFloat, size: CGFloat, op: Double)] = [
        (-130, -190, 9, 0.85), (140, -130, 7, 0.7), (125, 250, 8, 0.6),
        (-150, 120, 6, 0.55), (60, -250, 11, 0.5), (-70, 330, 7, 0.5), (165, 60, 6, 0.5)
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: Palette.bg(phase), startPoint: .top, endPoint: .bottom)

            Circle().fill(blobA).frame(width: 360, height: 360).blur(radius: 70)
                .offset(x: -150, y: 360)
            Circle().fill(blobB).frame(width: 320, height: 320).blur(radius: 80)
                .offset(x: 160, y: 410)
            Capsule().fill(.white.opacity(0.30)).frame(width: 540, height: 130).blur(radius: 45)
                .rotationEffect(.degrees(-18)).offset(x: -30, y: 300)

            ForEach(sparkles.indices, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: sparkles[i].size))
                    .foregroundStyle(.white.opacity(sparkles[i].op))
                    .offset(x: sparkles[i].x, y: sparkles[i].y)
            }
        }
        // Pin to the proposed (screen) size so the off-canvas blobs don't widen the layout.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea()
    }

    private var blobA: Color { phase == .fasting ? Palette.fastingB.opacity(0.55) : Palette.eatingA.opacity(0.5) }
    private var blobB: Color { phase == .fasting ? Palette.fastingA.opacity(0.55) : Palette.peach.opacity(0.40) }
}

// MARK: - Ring

/// Tick marks evenly spaced around a circle.
struct Ticks: Shape {
    var count: Int
    var lengthRatio: CGFloat = 0.045

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        for i in 0..<count {
            let angle = CGFloat(i) / CGFloat(count) * 2 * .pi
            let outer = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            let inner = CGPoint(x: center.x + cos(angle) * (radius - radius * lengthRatio),
                                y: center.y + sin(angle) * (radius - radius * lengthRatio))
            path.move(to: inner)
            path.addLine(to: outer)
        }
        return path
    }
}

/// The hero progress ring: glowing multi-stop gradient arc over a track, with tick marks.
struct GlowRing: View {
    var progress: Double
    var colors: [Color]
    var glow: Color
    var lineWidth: CGFloat = 24

    var body: some View {
        let p = max(0.0001, min(progress, 1))
        let gradient = AngularGradient(gradient: Gradient(colors: colors), center: .center)
        ZStack {
            Ticks(count: 60)
                .stroke(Palette.sub.opacity(0.22), lineWidth: 1)
                .padding(lineWidth + 8)

            Circle()
                .stroke(Palette.track, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            Circle()
                .trim(from: 0, to: p)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .blur(radius: 13)
                .opacity(0.9)

            Circle()
                .trim(from: 0, to: p)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: glow.opacity(0.55), radius: 6)
        }
    }
}

/// Simpler ring (no heavy glow) for the widgets and Live Activity.
struct RingView: View {
    var progress: Double
    var colors: [Color]
    var lineWidth: CGFloat = 20

    var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.track, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(
                    AngularGradient(gradient: Gradient(colors: colors + [colors.first ?? .white]), center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Reusable glass components

// MARK: - Water

/// Tapered drinking-glass shape.
struct WaterGlassShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.16, y: h * 0.04))
        p.addLine(to: CGPoint(x: w * 0.84, y: h * 0.04))
        p.addLine(to: CGPoint(x: w * 0.70, y: h * 0.96))
        p.addLine(to: CGPoint(x: w * 0.30, y: h * 0.96))
        p.closeSubpath()
        return p
    }
}

/// A single glass — empty outline or filled with water.
struct GlassIcon: View {
    var filled: Bool
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            WaterGlassShape()
                .fill(filled
                      ? LinearGradient(colors: [Palette.waterLight, Palette.water], startPoint: .top, endPoint: .bottom)
                      : LinearGradient(colors: [.white.opacity(0.45), .white.opacity(0.45)], startPoint: .top, endPoint: .bottom))
            WaterGlassShape()
                .stroke(filled ? Palette.water : Palette.sub.opacity(0.45), lineWidth: 1.5)
        }
        .frame(width: size, height: size * 1.18)
    }
}

/// A non-interactive row of glasses (used in the widgets).
struct WaterGlassesRow: View {
    var count: Int
    var total: Int = 5
    var size: CGFloat = 32
    var spacing: CGFloat = 12

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<total, id: \.self) { i in
                GlassIcon(filled: i < count, size: size)
            }
        }
    }
}

/// Phase emblem shown in the centre of the ring (moon for fasting, leaf for eating).
struct PhaseBadge: View {
    let phase: FastingPhase
    var body: some View {
        let symbol = phase == .fasting ? "moon.stars.fill" : "leaf.fill"
        let tint = Palette.accent(phase)
        ZStack {
            Circle().fill(tint.opacity(0.16)).frame(width: 46, height: 46)
            Image(systemName: symbol).font(.system(size: 18, weight: .medium)).foregroundStyle(tint)
        }
    }
}

/// Thin divider with a centred sparkle.
struct SparkleDivider: View {
    var tint: Color
    var body: some View {
        HStack(spacing: 8) {
            line
            Image(systemName: "sparkle").font(.caption2).foregroundStyle(tint)
            line
        }
        .frame(width: 116)
    }
    private var line: some View { Rectangle().fill(Palette.sub.opacity(0.30)).frame(height: 1) }
}

/// A frosted-glass stat card with an icon badge, label and value.
struct StatCard: View {
    let icon: String
    let tint: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle().fill(.white.opacity(0.7)).frame(width: 38, height: 38)
                Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(tint)
            }
            Text(label.uppercased()).font(.caption2).foregroundStyle(Palette.sub)
            Text(value).font(.system(.headline, design: .rounded)).foregroundStyle(Palette.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.5), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

/// Small drawn flag — robust everywhere (regional-indicator flag emoji don't always
/// render, e.g. on the iOS Simulator).
struct FlagView: View {
    let lang: AppLanguage
    private let w: CGFloat = 28
    private let h: CGFloat = 20

    private let blue = Color(red: 0.0, green: 0.13, blue: 0.55)
    private let red = Color(red: 0.79, green: 0.07, blue: 0.18)
    private let gold = Color(red: 1.0, green: 0.79, blue: 0.0)

    var body: some View {
        content
            .frame(width: w, height: h)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(.black.opacity(0.12), lineWidth: 0.5))
    }

    @ViewBuilder private var content: some View {
        switch lang {
        case .fr:
            HStack(spacing: 0) { blue; Color.white; red }
        case .de:
            VStack(spacing: 0) { Color.black; red; gold }
        case .es:
            VStack(spacing: 0) {
                red.frame(height: h * 0.25)
                gold.frame(height: h * 0.50)
                red.frame(height: h * 0.25)
            }
        case .en:
            unionJack
        }
    }

    private var unionJack: some View {
        GeometryReader { geo in
            let ww = geo.size.width
            let hh = geo.size.height
            ZStack {
                blue
                diagonals.stroke(Color.white, lineWidth: hh * 0.30)
                diagonals.stroke(red, lineWidth: hh * 0.14)
                Rectangle().fill(Color.white).frame(width: ww * 0.34)
                Rectangle().fill(Color.white).frame(height: hh * 0.34)
                Rectangle().fill(red).frame(width: ww * 0.20)
                Rectangle().fill(red).frame(height: hh * 0.20)
            }
            .compositingGroup()
        }
    }

    private var diagonals: Path {
        Path { p in
            p.move(to: .zero); p.addLine(to: CGPoint(x: w, y: h))
            p.move(to: CGPoint(x: w, y: 0)); p.addLine(to: CGPoint(x: 0, y: h))
        }
    }
}

/// Pill showing the current metabolic stage.
struct StageChip: View {
    let emoji: String
    let name: String
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 7) {
            Text(emoji)
            Text(name)
                .font(compact ? .caption2 : .system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, compact ? 8 : 16)
        .padding(.vertical, compact ? 4 : 9)
        .background {
            if compact {
                Capsule().fill(.white.opacity(0.6))
            } else {
                Capsule().fill(.ultraThinMaterial)
                    .overlay(Capsule().stroke(.white.opacity(0.5), lineWidth: 1))
            }
        }
    }
}
