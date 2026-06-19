import SwiftUI
import WidgetKit

@main
struct FastingApp: App {
    init() {
        _ = SharedStore.load() // ensure a default schedule exists on first launch
        // -skipNotifPrompt is only used for clean automated screenshots.
        if !CommandLine.arguments.contains("-skipNotifPrompt") {
            NotificationManager.shared.requestAuthorizationAndSchedule()
        }
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @State private var schedule = SharedStore.load()
    @State private var showSettings = false

    /// Optional fixed "now" for demo screenshots: -demoNow <unix-timestamp>.
    private var overrideNow: Date? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "-demoNow"), i + 1 < args.count,
              let t = TimeInterval(args[i + 1]) else { return nil }
        return Date(timeIntervalSince1970: t)
    }

    var body: some View {
        if CommandLine.arguments.contains("-widgetGallery") {
            WidgetGalleryView()
        } else {
            mainView
        }
    }

    private var mainView: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { context in
            let now = overrideNow ?? context.date
            let state = schedule.state(at: now)

            ZStack {
                LinearGradient(colors: Palette.bgColors(for: state.phase),
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    header
                    ring(for: state)
                    stages(for: state)
                    stats(for: state)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(schedule: $schedule)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Jeûne")
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .foregroundStyle(Palette.ink)
                Text("\(schedule.startLabel) → \(schedule.endLabel) · \(schedule.fastingHoursText)")
                    .font(.subheadline)
                    .foregroundStyle(Palette.subtle)
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundStyle(Palette.ink)
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(0.55), in: Circle())
            }
        }
    }

    private func ring(for s: FastingState) -> some View {
        ZStack {
            RingView(progress: s.progress, colors: Palette.ringColors(for: s.phase), lineWidth: 22)
            VStack(spacing: 6) {
                Text(s.isFasting ? "JEÛNE EN COURS" : "FENÊTRE ALIMENTAIRE")
                    .font(.caption2).fontWeight(.bold)
                    .tracking(1)
                    .foregroundStyle(Palette.subtle)
                Text(formatHMS(s.elapsed))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
                Text("\(Int((s.progress * 100).rounded())) %")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.subtle)
            }
            .padding(36)
        }
        .frame(width: 286, height: 286)
        .padding(.vertical, 4)
    }

    private func stages(for s: FastingState) -> some View {
        VStack(spacing: 8) {
            StageChip(stage: FastingStage.current(forHours: s.elapsedHours))
            if s.isFasting, let next = FastingStage.next(forHours: s.elapsedHours) {
                Text("Prochaine étape \(next.emoji) \(next.name) dans \(formatHM((next.threshold - s.elapsedHours) * 3600))")
                    .font(.caption)
                    .foregroundStyle(Palette.subtle)
                    .multilineTextAlignment(.center)
            } else {
                Text(FastingStage.current(forHours: s.elapsedHours).detail)
                    .font(.caption)
                    .foregroundStyle(Palette.subtle)
            }
        }
    }

    private func stats(for s: FastingState) -> some View {
        HStack(spacing: 12) {
            stat("Début", schedule.startLabel)
            stat(s.isFasting ? "Restant" : "Prochain jeûne", formatHM(s.remaining))
            stat("Fin", schedule.endLabel)
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.caption2)
                .foregroundStyle(Palette.subtle)
            Text(value)
                .font(.headline)
                .foregroundStyle(Palette.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.white.opacity(0.45), in: RoundedRectangle(cornerRadius: 18))
    }
}

/// In-app preview of the home-screen widgets, rendered from the exact shared
/// `FastingWidgetContent`. Shown via the -widgetGallery launch argument.
struct WidgetGalleryView: View {
    private var demoState: FastingState {
        let now = Date()
        return FastingState(phase: .fasting, progress: 0.56,
                            windowStart: now.addingTimeInterval(-9 * 3600),
                            windowEnd: now.addingTimeInterval(7 * 3600),
                            now: now)
    }

    var body: some View {
        let s = demoState
        ZStack {
            LinearGradient(colors: [Color(white: 0.94), Color(white: 0.86)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Aperçu widgets · écran d'accueil")
                    .font(.headline)
                    .foregroundStyle(Palette.ink)

                card(width: 158, height: 158) {
                    FastingWidgetContent(family: .systemSmall, state: s)
                }
                card(width: 338, height: 158) {
                    FastingWidgetContent(family: .systemMedium, state: s)
                }
            }
        }
    }

    private func card<V: View>(width: CGFloat, height: CGFloat, @ViewBuilder _ content: () -> V) -> some View {
        content()
            .frame(width: width, height: height)
            .background(
                LinearGradient(colors: Palette.bgColors(for: .fasting),
                               startPoint: .top, endPoint: .bottom)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    }
}
