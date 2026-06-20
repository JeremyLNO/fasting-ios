import SwiftUI
import WidgetKit

@main
struct FastingApp: App {
    init() {
        if let i = CommandLine.arguments.firstIndex(of: "-demoLang"), i + 1 < CommandLine.arguments.count {
            UserDefaults.standard.set(CommandLine.arguments[i + 1], forKey: AppLanguage.storageKey)
        }
        Trial.ensureInstallDate()
        if let i = CommandLine.arguments.firstIndex(of: "-demoWater"), i + 1 < CommandLine.arguments.count,
           let n = Int(CommandLine.arguments[i + 1]) {
            SharedStore.setWaterGlasses(n)
        }
        _ = SharedStore.load() // ensure a default schedule exists on first launch
        if !CommandLine.arguments.contains("-skipNotifPrompt") {
            NotificationManager.shared.requestAuthorizationAndSchedule()
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
    }
}

/// Gates the app behind the 7-day free trial / Fasting Pro subscription.
struct RootView: View {
    @StateObject private var store = StoreManager()
    @AppStorage(AppLanguage.storageKey) private var languageRaw = "en"
    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }

    var body: some View {
        let forced = CommandLine.arguments.contains("-showPaywall")
        if !forced && (store.isSubscribed || Trial.isActive) {
            ContentView(store: store)
        } else {
            PaywallView(store: store, lang: lang)
        }
    }
}

struct ContentView: View {
    let store: StoreManager
    @State private var schedule = SharedStore.load()
    @State private var showSettings = false
    @State private var glasses = SharedStore.waterGlasses()
    @StateObject private var live = LiveActivityManager()
    @AppStorage(AppLanguage.storageKey) private var languageRaw = "en"
    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }

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

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    heroRing(s)
                    stageSection(s)
                    statsRow(s)
                    waterTracker
                    liveButton
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FastingBackground(phase: s.phase))
        }
        .onAppear {
            live.refresh()
            glasses = SharedStore.waterGlasses()
            if CommandLine.arguments.contains("-openSettings") { showSettings = true }
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
            SettingsView(schedule: $schedule, store: store)
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
                Text((s.isFasting ? L.t("phase_fasting", lang) : L.t("phase_eating", lang)).uppercased())
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
            let current = FastingStage.current(forHours: s.elapsedHours)
            StageChip(emoji: current.emoji, name: current.name(lang))
            if s.isFasting, let next = FastingStage.next(forHours: s.elapsedHours) {
                Text("\(L.t("next_stage", lang)) \(next.emoji) \(next.name(lang)) \(L.t("word_in", lang)) \(formatHM((next.threshold - s.elapsedHours) * 3600))")
                    .font(.caption)
                    .foregroundStyle(Palette.sub)
                    .multilineTextAlignment(.center)
            } else {
                Text(current.detail(lang))
                    .font(.caption)
                    .foregroundStyle(Palette.sub)
            }
        }
    }

    // MARK: Stats

    private func statsRow(_ s: FastingState) -> some View {
        HStack(spacing: 12) {
            StatCard(icon: "clock", tint: Palette.fastAccent, label: L.t("stat_start", lang), value: schedule.startLabel)
            StatCard(icon: s.isFasting ? "hourglass" : "calendar",
                     tint: Palette.accent(s.phase),
                     label: s.isFasting ? L.t("stat_remaining", lang) : L.t("stat_next_fast", lang),
                     value: formatHM(s.remaining))
            StatCard(icon: "sunrise.fill", tint: Palette.peach, label: L.t("stat_end", lang), value: schedule.endLabel)
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
            Label(live.isActive ? L.t("btn_stop", lang) : L.t("btn_track", lang),
                  systemImage: live.isActive ? "stop.circle.fill" : "bolt.fill")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Palette.ink)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.5), lineWidth: 1))
        }
        .padding(.top, 2)
    }

    private var waterTracker: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "drop.fill").font(.subheadline).foregroundStyle(Palette.water)
                Text(L.t("water_title", lang))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text("\(glasses * 200) ml / 1 L")
                    .font(.caption).foregroundStyle(Palette.sub)
            }
            HStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { i in
                    Button { tapGlass(i) } label: { GlassIcon(filled: i < glasses, size: 34) }
                        .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.5), lineWidth: 1))
    }

    private func tapGlass(_ i: Int) {
        let newValue = (glasses == i + 1) ? i : i + 1
        glasses = newValue
        SharedStore.setWaterGlasses(newValue)
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
                card(width: 338, height: 354) { FastingWidgetContent(family: .systemLarge, state: s, water: 3) }

                sectionTitle("Widget eau")
                waterWidgetCard

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

    private var waterWidgetCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "drop.fill").foregroundStyle(Palette.water)
                Text(L.t("water_title"))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Palette.ink)
            }
            WaterGlassesRow(count: 3, size: 20, spacing: 5)
            Text("600 ml / 1 L").font(.caption2).foregroundStyle(Palette.subtle)
        }
        .frame(width: 158, height: 158)
        .background(LinearGradient(colors: [Color(red: 0.90, green: 0.96, blue: 1.0), Color(red: 0.83, green: 0.92, blue: 1.0)],
                                   startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
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
