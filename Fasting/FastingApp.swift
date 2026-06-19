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
    @StateObject private var live = LiveActivityManager()

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

                VStack(spacing: 22) {
                    header
                    ring(for: state)
                    stages(for: state)
                    stats(for: state)
                    liveButton(state)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
            }
        }
        .onAppear {
            live.refresh()
            if CommandLine.arguments.contains("-startLiveActivity") {
                let now = Date()
                let demo = FastingState(phase: .fasting, progress: 0.56,
                                        windowStart: now.addingTimeInterval(-9 * 3600),
                                        windowEnd: now.addingTimeInterval(7 * 3600),
                                        now: now)
                live.start(schedule: schedule, state: demo)
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
        .frame(width: 270, height: 270)
        .padding(.vertical, 2)
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

    private func liveButton(_ s: FastingState) -> some View {
        Button {
            if live.isActive {
                live.stop()
            } else {
                live.start(schedule: schedule, state: schedule.state(at: Date()))
            }
        } label: {
            Label(live.isActive ? "Arrêter le suivi en direct" : "Suivre dans la Dynamic Island",
                  systemImage: live.isActive ? "stop.circle.fill" : "bolt.badge.clock.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.ink)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.55), in: Capsule())
        }
    }
}

/// In-app preview of the home-screen widgets and the Live Activity, rendered from
/// the exact shared content. Shown via the -widgetGallery launch argument.
struct WidgetGalleryView: View {
    private var demoState: FastingState {
        let now = Date()
        return FastingState(phase: .fasting, progress: 0.56,
                            windowStart: now.addingTimeInterval(-9 * 3600),
                            windowEnd: now.addingTimeInterval(7 * 3600),
                            now: now)
    }

    private var liveData: LiveActivityData {
        let s = demoState
        return LiveActivityData(windowStart: s.windowStart, windowEnd: s.windowEnd,
                                isFasting: true, progress: s.progress,
                                startLabel: "20:00", endLabel: "12:00")
    }

    var body: some View {
        let s = demoState
        ScrollView {
            VStack(spacing: 24) {
                Text("Aperçu widgets & Dynamic Island")
                    .font(.headline)
                    .foregroundStyle(Palette.ink)

                sectionTitle("Widgets écran d'accueil")
                card(width: 158, height: 158) {
                    FastingWidgetContent(family: .systemSmall, state: s)
                }
                card(width: 338, height: 158) {
                    FastingWidgetContent(family: .systemMedium, state: s)
                }

                sectionTitle("Dynamic Island (compact)")
                islandCompact

                sectionTitle("Live Activity — écran verrouillé")
                LiveLockView(data: liveData)
                    .padding(16)
                    .frame(width: 360)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
        }
        .background(LinearGradient(colors: [Color(white: 0.94), Color(white: 0.85)],
                                   startPoint: .top, endPoint: .bottom).ignoresSafeArea())
    }

    private var islandCompact: some View {
        HStack {
            Text(liveData.stage.emoji)
            Spacer()
            liveRemaining(liveData)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 22)
        .frame(width: 240, height: 44)
        .background(Capsule().fill(.black))
    }

    private func sectionTitle(_ t: String) -> some View {
        Text(t.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(1)
            .foregroundStyle(Palette.subtle)
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
