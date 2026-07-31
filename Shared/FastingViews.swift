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

private let clockFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    return f
}()

/// Wall-clock label ("HH:mm") for a moment in time. Used for the *current* window's start/end,
/// which can differ from the configured schedule after a manual start/interrupt — never format
/// `schedule.startLabel`/`endLabel` into those slots or they'll go stale.
func clockLabel(_ date: Date) -> String { clockFormatter.string(from: date) }

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

/// The hero progress ring: a glossy multi-stop gradient arc over a track, with tick marks and a
/// bright head at the leading edge. The gradient is mapped across the *swept* portion only, so the
/// colour ramp reads the same whether the arc covers 10% or 90%.
struct GlowRing: View {
    var progress: Double
    var colors: [Color]
    var glow: Color
    var lineWidth: CGFloat = 24

    var body: some View {
        let raw = min(max(progress, 0), 1)
        // Below ~0.5% the rounded line cap would still paint a full dot on the track, which reads
        // as a stray bead rather than "just started" — so draw nothing at all there.
        let visible = raw > 0.005
        let p = max(0.0001, raw)
        // Squeeze the stops into the swept arc, then pad with the last colour so the remainder of
        // the circle doesn't wrap the ramp back around to the first colour.
        let stops: [Gradient.Stop] = colors.enumerated().map { i, c in
            .init(color: c, location: Double(i) / Double(max(colors.count - 1, 1)) * p)
        } + [.init(color: colors.last ?? glow, location: 1)]
        let gradient = AngularGradient(gradient: Gradient(stops: stops), center: .center,
                                       startAngle: .degrees(-90), endAngle: .degrees(270))

        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let radius = (side - lineWidth) / 2
            let angle = Angle.degrees(-90 + 360 * p)

            ZStack {
                Ticks(count: 60)
                    .stroke(Palette.sub.opacity(0.22), lineWidth: 1)
                    .padding(lineWidth + 8)

                Circle()
                    .stroke(Palette.track, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                if visible {
                    Circle()
                        .trim(from: 0, to: p)
                        .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .blur(radius: 13)
                        .opacity(0.85)

                    Circle()
                        .trim(from: 0, to: p)
                        .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .shadow(color: glow.opacity(0.5), radius: 6)

                    // Glossy sheen along the top of the stroke, for the 3D look.
                    Circle()
                        .trim(from: 0, to: p)
                        .stroke(.white.opacity(0.28), style: StrokeStyle(lineWidth: lineWidth * 0.30, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .offset(y: -lineWidth * 0.22)
                        .blur(radius: 2)
                        .mask(Circle().trim(from: 0, to: p)
                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                            .rotationEffect(.degrees(-90)))

                    // Bright head at the leading edge.
                    Circle()
                        .fill(.white)
                        .frame(width: lineWidth * 0.26, height: lineWidth * 0.26)
                        .shadow(color: .white.opacity(0.9), radius: 4)
                        .offset(x: radius * cos(angle.radians), y: radius * sin(angle.radians))
                }
            }
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Last 7 days

/// Seven small rings summarising the week: green when the target was reached, amber when the fast
/// was cut short, hollow when nothing was recorded. Today's running fast shows as a dashed ring.
struct WeekStrip: View {
    let days: [DayOutcome]
    var lang: AppLanguage = .current

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEE")
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(L.t("week_title", lang).uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(0.5)
                    .foregroundStyle(Palette.ink)
                Spacer()
                legendDot(Palette.eatAccent, L.t("week_full", lang))
                legendDot(Palette.amber, L.t("week_partial", lang))
            }

            HStack(spacing: 6) {
                ForEach(days) { day in
                    dayColumn(day)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.5), lineWidth: 1))
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.caption2).foregroundStyle(Palette.sub)
        }
    }

    private func dayColumn(_ day: DayOutcome) -> some View {
        let tint = color(for: day.status)
        return VStack(spacing: 6) {
            Text(day.isToday ? L.t("week_today", lang)
                             : Self.weekdayFormatter.string(from: day.date).uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(day.isToday ? Palette.eatAccent : Palette.sub)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            ZStack {
                Circle().stroke(Palette.track, lineWidth: 3)
                Circle()
                    .trim(from: 0, to: max(0.001, day.progress))
                    .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round,
                                                     dash: day.status == .inProgress ? [2.5, 2.5] : []))
                    .rotationEffect(.degrees(-90))
                Text(day.status == .inProgress ? day.hoursLabel + "+" : day.hoursLabel)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(day.status == .none ? Palette.sub.opacity(0.5) : Palette.ink)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(2)
            }
            .frame(height: 42)

            Image(systemName: icon(for: day.status))
                .font(.system(size: 11))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(day.isToday ? Palette.eatAccent.opacity(0.08) : .white.opacity(0.35),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func color(for status: DayStatus) -> Color {
        switch status {
        case .full, .inProgress: return Palette.eatAccent
        case .partial:           return Palette.amber
        case .none:              return Palette.sub.opacity(0.3)
        }
    }

    private func icon(for status: DayStatus) -> String {
        switch status {
        case .full:       return "trophy.fill"
        case .partial:    return "star.fill"
        case .inProgress: return "star"
        case .none:       return "minus"
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
/// Label on top, then the value as the dominant element, then the icon — the value is what you
/// actually read, so it gets the visual weight rather than a big decorative icon badge.
struct StatCard: View {
    let icon: String
    let tint: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.3)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(0.7), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
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
