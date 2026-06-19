import SwiftUI
import WidgetKit

@main
struct FastingApp: App {
    init() {
        _ = SharedStore.load() // ensure a default schedule exists on first launch
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
            let s = schedule.state(at: now)

            VStack(spacing: 18) {
                header
                heroRing(s)
                stageSection(s)
                statsRow(s)
                liveButton
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FastingBackground(phase: s.phase))
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

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Fasting")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Text("\(schedule.startLabel) → \(schedule.endLabel) · \(schedule.fastingHoursText)")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Palette.sub)
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .foregroundStyle(Palette.ink)
                    .frame(width: 48, height: 48)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
            }
        }
    }

    // MARK: Ring

    private func heroRing(_ s: FastingState) -> some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.5))
                .frame(width: 224, height: 224)
                .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1))
                .shadow(color: .black.opacity(0.05), radius: 12)

            GlowRing(progress: s.progress, colors: Palette.ring(s.phase), glow: Palette.glow(s.phase), lineWidth: 24)

            VStack(spacing: 7) {
                PhaseBadge(phase: s.phase)
                Text(s.isFasting ? "JEÛNE EN COURS" : "FENÊTRE ALIMENTAIRE")
                    .font(.caption2.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(Palette.sub)
                Text(formatHMS(s.elapsed))
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
                SparkleDivider(tint: Palette.accent(s.phase))
                Text("\(Int((s.progress * 100).rounded())) %")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(Palette.accent(s.phase))
            }
            .padding(.horizontal, 30)
        }
        .frame(width: 298, height: 298)
        .padding(.vertical, 4)
    }

    // MARK: Stage

    private func stageSection(_ s: FastingState) -> some View {
        VStack(spacing: 8) {
            StageChip(stage: FastingStage.current(forHours: s.elapsedHours))
            if s.isFasting, let next = FastingStage.next(forHours: s.elapsedHours) {
                Text("Prochaine étape \(next.emoji) \(next.name) dans \(formatHM((next.threshold - s.elapsedHours) * 3600))")
                    .font(.caption)
                    .foregroundStyle(Palette.sub)
                    .multilineTextAlignment(.center)
            } else {
                Text(FastingStage.current(forHours: s.elapsedHours).detail)
                    .font(.caption)
                    .foregroundStyle(Palette.sub)
            }
        }
    }

    // MARK: Stats

    private func statsRow(_ s: FastingState) -> some View {
        HStack(spacing: 12) {
            StatCard(icon: "clock", tint: Palette.fastAccent, label: "Début", value: schedule.startLabel)
            StatCard(icon: s.isFasting ? "hourglass" : "calendar",
                     tint: Palette.accent(s.phase),
                     label: s.isFasting ? "Restant" : "Prochain jeûne",
                     value: formatHM(s.remaining))
            StatCard(icon: "sunrise.fill", tint: Palette.peach, label: "Fin", value: schedule.endLabel)
        }
    }

    // MARK: Live Activity button

    private var liveButton: some View {
        Button {
            if live.isActive {
                live.stop()
            } else {
                live.start(schedule: schedule, state: schedule.state(at: Date()))
            }
        } label: {
            Label(live.isActive ? "Arrêter le suivi en direct" : "Suivre dans la Dynamic Island",
                  systemImage: live.isActive ? "stop.circle.fill" : "bolt.badge.clock.fill")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Palette.ink)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.5), lineWidth: 1))
        }
        .padding(.top, 2)
    }
}

/// In-app preview of the widgets and the Live Activity, rendered from the exact
/// shared content. Shown via the -widgetGallery launch argument.
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Text("Aperçu widgets & Dynamic Island")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Palette.ink)

                sectionTitle("Widgets écran d'accueil")
                card(width: 158, height: 158) { FastingWidgetContent(family: .systemSmall, state: s) }
                card(width: 338, height: 158) { FastingWidgetContent(family: .systemMedium, state: s) }

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
        .background(FastingBackground(phase: .fasting))
    }

    private var islandCompact: some View {
        HStack {
            Text(liveData.stage.emoji)
            Spacer()
            liveRemaining(liveData).font(.caption.weight(.bold)).foregroundStyle(.white)
        }
        .padding(.horizontal, 22)
        .frame(width: 240, height: 44)
        .background(Capsule().fill(.black))
    }

    private func sectionTitle(_ t: String) -> some View {
        Text(t.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(1)
            .foregroundStyle(Palette.sub)
    }

    private func card<V: View>(width: CGFloat, height: CGFloat, @ViewBuilder _ content: () -> V) -> some View {
        content()
            .frame(width: width, height: height)
            .background(LinearGradient(colors: Palette.bgColors(for: .fasting), startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    }
}
