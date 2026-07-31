import SwiftUI
import WidgetKit

@main
struct FastingApp: App {
    init() {
        if let i = CommandLine.arguments.firstIndex(of: "-demoLang"), i + 1 < CommandLine.arguments.count {
            UserDefaults.standard.set(CommandLine.arguments[i + 1], forKey: AppLanguage.storageKey)
        }
        if let i = CommandLine.arguments.firstIndex(of: "-demoInstallDaysAgo"), i + 1 < CommandLine.arguments.count,
           let days = Int(CommandLine.arguments[i + 1]) {
            let past = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            UserDefaults.standard.set(past, forKey: AppInstall.installKey)
        }
        AppInstall.ensureInstallDate()
        if let i = CommandLine.arguments.firstIndex(of: "-demoWater"), i + 1 < CommandLine.arguments.count,
           let n = Int(CommandLine.arguments[i + 1]) {
            SharedStore.setWaterGlasses(n)
        }
        if let i = CommandLine.arguments.firstIndex(of: "-demoManualFast"), i + 1 < CommandLine.arguments.count,
           let isFasting = Bool(CommandLine.arguments[i + 1]) {
            // Respect -demoNow so the override's anchor matches whatever "now" the demo renders.
            var demoNow = Date()
            if let j = CommandLine.arguments.firstIndex(of: "-demoNow"), j + 1 < CommandLine.arguments.count,
               let t = TimeInterval(CommandLine.arguments[j + 1]) {
                demoNow = Date(timeIntervalSince1970: t)
            }
            SharedStore.setManualOverride(ManualSession(isFasting: isFasting, start: demoNow))
        }
        if let i = CommandLine.arguments.firstIndex(of: "-demoInterruptDaysAgo"), i + 1 < CommandLine.arguments.count,
           let daysAgo = Int(CommandLine.arguments[i + 1]) {
            let day = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            let target = SharedStore.load().fastingMinutes
            HistoryStore.logInterruption(day: day, targetMinutes: target, actualMinutes: target / 2)
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

/// Fasting is a free app — first launch shows the Crazy Bee Labs commitment screen (why the app
/// is free, exactly once), then onboarding. Nothing else gates the app.
struct RootView: View {
    @AppStorage(CommitmentView.seenKey) private var hasSeenCommitment = false
    @AppStorage("onboarding.completed") private var onboardingDone = false
    @State private var schedule = SharedStore.load()

    var body: some View {
        let skipOnboarding = CommandLine.arguments.contains("-skipOnboarding")
        let forceCommitment = CommandLine.arguments.contains("-showCommitment")

        if forceCommitment || (!hasSeenCommitment && !skipOnboarding) {
            CommitmentView { hasSeenCommitment = true }
        } else if !onboardingDone && !skipOnboarding {
            OnboardingView(schedule: $schedule) {
                SharedStore.save(schedule)
                NotificationManager.shared.requestAuthorizationAndSchedule()
                onboardingDone = true
            }
        } else {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var schedule = SharedStore.load()
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showAccount = false
    @State private var glasses = SharedStore.waterGlasses()
    @State private var showEndFastConfirm = false
    @State private var toggleTrigger = false
    @StateObject private var live = LiveActivityManager()
    @StateObject private var auth = AuthManager()
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
        } else if CommandLine.arguments.contains("-liveActivityGallery") {
            LiveActivityGalleryView()
        } else {
            mainView
        }
    }

    private var mainView: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { context in
            let now = overrideNow ?? context.date
            let s = schedule.effectiveState(at: now, override: SharedStore.manualOverride())

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    header
                    heroRing(s)
                    toggleButton(s)
                    stageCard(s)
                    statsRow(s)
                    waterRow
                    WeekStrip(days: HistoryStore.last7Days(schedule: schedule, liveState: s, now: now),
                              lang: lang)
                    liveButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FastingBackground(phase: s.phase))
            // ActivityKit has no local-only way to schedule a future content update (that needs a
            // push server, which this app deliberately doesn't have) — so a Live Activity started
            // during, say, the eating window would otherwise sit frozen at 0:00 forever once that
            // window naturally elapses. Best-effort fix: whenever the app is open and re-evaluates
            // state (every second) and the phase actually flips, push a fresh update immediately.
            .onChange(of: s.isFasting) { _, _ in
                live.refreshIfActive(state: s)
            }
        }
        .onAppear {
            live.refresh()
            // Also correct any drift accumulated while the app was backgrounded/closed, in case a
            // transition was missed entirely (same reasoning as above).
            live.refreshIfActive(state: schedule.effectiveState(at: Date(), override: SharedStore.manualOverride()))
            glasses = SharedStore.waterGlasses()
            HistoryStore.syncIfNeeded(schedule: schedule, installDate: AppInstall.installDate)
            if CommandLine.arguments.contains("-openSettings") { showSettings = true }
            if CommandLine.arguments.contains("-openHistory") { showHistory = true }
            if CommandLine.arguments.contains("-openAccount") { showAccount = true }
            if CommandLine.arguments.contains("-startLiveActivity") {
                let now = Date()
                let demo = FastingState(phase: .fasting, progress: 0.56,
                                        windowStart: now.addingTimeInterval(-9 * 3600),
                                        windowEnd: now.addingTimeInterval(7 * 3600),
                                        now: now)
                live.start(state: demo)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(schedule: $schedule)
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
        }
        .sheet(isPresented: $showAccount) {
            NavigationStack { AccountView(auth: auth) }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                (Text("Fasting ").foregroundStyle(Palette.ink)
                 + Text(Image(systemName: "leaf.fill")).foregroundStyle(Palette.eatAccent)
                 + Text("\nmade easy").foregroundStyle(Palette.eatAccent))
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .lineSpacing(-2)
                Spacer()
                HStack(spacing: 10) {
                    Button { showHistory = true } label: { headerIcon("chart.bar.fill") }
                    Button { showSettings = true } label: { headerIcon("slider.horizontal.3") }
                }
            }

            // The configured schedule, as a chip — clearly separated from the live window times
            // shown in the stat cards below.
            HStack(spacing: 6) {
                Image(systemName: "clock").font(.caption)
                Text("\(schedule.startLabel) → \(schedule.endLabel) · \(schedule.fastingHoursText)")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
            }
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.white.opacity(0.75), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.7), lineWidth: 1))
        }
    }

    private func headerIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.title3)
            .foregroundStyle(Palette.ink)
            .frame(width: 48, height: 48)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
    }

    // MARK: Ring

    private func heroRing(_ s: FastingState) -> some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.55))
                .frame(width: 196, height: 196)
                .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1))
                .shadow(color: .black.opacity(0.05), radius: 12)

            GlowRing(progress: s.progress, colors: Palette.ring(s.phase), glow: Palette.glow(s.phase), lineWidth: 20)

            VStack(spacing: 5) {
                PhaseBadge(phase: s.phase)
                Text((s.isFasting ? L.t("phase_fasting", lang) : L.t("phase_eating", lang)).uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(Palette.sub)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(formatHMS(s.elapsed))
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                // Spell out what the big number is, then the counterpart — the old layout showed a
                // bare timer and a bare %, which read ambiguously.
                labelledDivider(L.t("ring_elapsed", lang))
                Text("\(Int((s.progress * 100).rounded()))%")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Palette.accent(s.phase))
                Text("\(L.t("ring_remaining", lang)) \(formatHMS(s.remaining))")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.sub)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 30)
        }
        .frame(width: 258, height: 258)
        .padding(.vertical, 2)
        .contentShape(Circle())
        .onTapGesture { toggleFasting(s) }
        .sensoryFeedback(.impact(weight: .medium), trigger: toggleTrigger)
        .confirmationDialog(L.t("end_fast_confirm_title", lang), isPresented: $showEndFastConfirm, titleVisibility: .visible) {
            Button(L.t("end_fast_confirm_action", lang), role: .destructive) {
                applyOverride(isFasting: false, currentState: s)
            }
            Button(L.t("set_close", lang), role: .cancel) {}
        } message: {
            Text(L.t("end_fast_confirm_body", lang))
        }
    }

    private func labelledDivider(_ text: String) -> some View {
        HStack(spacing: 8) {
            Rectangle().fill(Palette.sub.opacity(0.25)).frame(height: 1)
            Text(text).font(.caption2).foregroundStyle(Palette.sub).fixedSize()
            Rectangle().fill(Palette.sub.opacity(0.25)).frame(height: 1)
        }
        .frame(width: 150)
    }

    /// The main action, promoted from a faint hint to a real button — it's the one thing you can
    /// do from this screen, so it shouldn't look like a caption.
    private func toggleButton(_ s: FastingState) -> some View {
        Button { toggleFasting(s) } label: {
            HStack(spacing: 10) {
                Image(systemName: s.isFasting ? "moon.stars.fill" : "leaf.fill")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Palette.accent(s.phase))
                    .frame(width: 30, height: 30)
                    .background(.white, in: Circle())
                // Two lines allowed: the French/German labels are much longer than the English
                // one and were being truncated mid-word inside the pill.
                Text(s.isFasting ? L.t("tap_to_end", lang) : L.t("tap_to_start", lang))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                LinearGradient(colors: Palette.ring(s.phase).suffix(2),
                               startPoint: .leading, endPoint: .trailing),
                in: Capsule()
            )
            .shadow(color: Palette.glow(s.phase).opacity(0.35), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }

    private func toggleFasting(_ s: FastingState) {
        if s.isFasting {
            showEndFastConfirm = true
        } else {
            applyOverride(isFasting: true, currentState: s)
        }
    }

    private func applyOverride(isFasting: Bool, currentState: FastingState) {
        let now = overrideNow ?? Date()
        // Interrupting an in-progress fast: log it now, with the real elapsed time — this is the
        // only moment that's known, since the next session will overwrite the override entirely.
        if currentState.isFasting && !isFasting {
            HistoryStore.logInterruption(day: currentState.windowStart, targetMinutes: schedule.fastingMinutes,
                                         actualMinutes: Int(currentState.elapsed / 60))
        }
        let session = ManualSession(isFasting: isFasting, start: now)
        SharedStore.setManualOverride(session)
        toggleTrigger.toggle()
        live.refreshIfActive(state: schedule.effectiveState(at: now, override: session))
    }

    // MARK: Stage

    /// Metabolic stage as a proper row: name on top, explanation below, tappable to open History
    /// (where the stages are laid out in full).
    private func stageCard(_ s: FastingState) -> some View {
        let current = FastingStage.current(forHours: s.elapsedHours)
        let subtitle: String = {
            if s.isFasting, let next = FastingStage.next(forHours: s.elapsedHours) {
                return "\(L.t("next_stage", lang)) \(next.name(lang)) \(L.t("word_in", lang)) \(formatHM((next.threshold - s.elapsedHours) * 3600))"
            }
            return current.detail(lang)
        }()

        return Button { showHistory = true } label: {
            HStack(spacing: 12) {
                Text(current.emoji)
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(Palette.accent(s.phase).opacity(0.14), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(current.name(lang))
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Palette.sub)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Palette.sub)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(0.7), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: Stats

    /// START / REMAINING / END all describe the **window currently running**, not the configured
    /// schedule — after a manual start or interrupt the two differ, and mixing them (static ends
    /// next to a live countdown) made the row contradict itself and the Live Activity. The
    /// configured schedule still has its own place: the header line under the title.
    private func statsRow(_ s: FastingState) -> some View {
        HStack(spacing: 12) {
            StatCard(icon: "clock", tint: Palette.fastAccent, label: L.t("stat_start", lang),
                     value: clockLabel(s.windowStart))
            StatCard(icon: s.isFasting ? "hourglass" : "calendar",
                     tint: Palette.accent(s.phase),
                     label: s.isFasting ? L.t("stat_remaining", lang) : L.t("stat_next_fast", lang),
                     value: formatHM(s.remaining))
            StatCard(icon: "sunrise.fill", tint: Palette.peach, label: L.t("stat_end", lang),
                     value: clockLabel(s.windowEnd))
        }
    }

    // MARK: Live Activity button

    private var liveButton: some View {
        Button {
            if live.isActive {
                live.stop()
            } else {
                let now = overrideNow ?? Date()
                live.start(state: schedule.effectiveState(at: now, override: SharedStore.manualOverride()))
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

    /// Water on a single line — the glasses stay individually tappable, and a "+" adds the next
    /// one, so the common case (log one glass) is one tap without aiming.
    private var waterRow: some View {
        let goal = SharedStore.waterGoal
        let done = glasses >= goal
        return HStack(spacing: 10) {
            Image(systemName: done ? "checkmark.seal.fill" : "drop.fill")
                .font(.subheadline)
                .foregroundStyle(done ? Palette.eatAccent : Palette.water)
            Text(done ? L.t("water_done", lang) : L.t("water_title", lang))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(done ? Palette.eatAccent : Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(spacing: 5) {
                ForEach(0..<goal, id: \.self) { i in
                    Button { tapGlass(i) } label: { GlassIcon(filled: i < glasses, size: goal > 6 ? 16 : 20) }
                        .buttonStyle(.plain)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 4)

            Text("\(glasses * 200) / \(goal * 200) ml")
                .font(.caption2)
                .foregroundStyle(done ? Palette.eatAccent : Palette.sub)
                .lineLimit(1)
                .fixedSize()

            Button { tapGlass(min(glasses, goal - 1)) } label: {
                Image(systemName: "plus")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Palette.water)
                    .frame(width: 30, height: 30)
                    .background(Palette.water.opacity(0.14), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(done)
            .opacity(done ? 0.4 : 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(done ? Palette.eatAccent.opacity(0.5) : .white.opacity(0.7), lineWidth: 1))
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
                                isFasting: true, progress: s.progress)
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
                card(width: 338, height: 158) { FastingWidgetContent(family: .systemMedium, state: s, water: 3) }
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

                sectionTitle("Live Activity — CarPlay / Watch (small)")
                smallFamilyPreview
                    .frame(width: 280)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
        }
        .background(FastingBackground(phase: .fasting))
    }

    /// Mirrors FastingWidget/FastingLiveActivity.swift's SmallFamilyContent (CarPlay Dashboard /
    /// Apple Watch Smart Stack) using only Shared components, for in-app preview purposes.
    private var smallFamilyPreview: some View {
        let d = liveData
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(d.stage.emoji)
                Text(d.phaseTitle)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: 0)
            }
            liveRemaining(d)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Palette.ink)
                .monospacedDigit()
            liveBar(d)
        }
        .padding(12)
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

/// Focused, no-scroll-needed preview of just the Live Activity presentations (Lock Screen +
/// CarPlay/Watch "small" family), for verification. Shown via -liveActivityGallery.
/// Uses a demo eating-window state whose windowEnd deliberately differs from the schedule's
/// static clock labels, to make the END-label fix visually obvious.
struct LiveActivityGalleryView: View {
    private var liveData: LiveActivityData {
        let now = Date()
        return LiveActivityData(windowStart: now.addingTimeInterval(-3 * 3600),
                                windowEnd: now.addingTimeInterval(2 * 3600 + 37 * 60),
                                isFasting: false, progress: 0.55)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Live Activity — Lock Screen").font(.caption.weight(.bold)).foregroundStyle(Palette.sub)
            LiveLockView(data: liveData)
                .padding(16)
                .frame(width: 360)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            Text("Live Activity — CarPlay / Watch (small)").font(.caption.weight(.bold)).foregroundStyle(Palette.sub)
            smallFamilyPreview
                .frame(width: 280)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FastingBackground(phase: .eating))
    }

    private var smallFamilyPreview: some View {
        let d = liveData
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(d.stage.emoji)
                Text(d.phaseTitle)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: 0)
            }
            liveRemaining(d)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Palette.ink)
                .monospacedDigit()
            liveBar(d)
        }
        .padding(12)
    }
}
