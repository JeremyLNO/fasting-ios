import SwiftUI

/// First-launch wizard: language -> fasting schedule -> free commitment -> notifications.
struct OnboardingView: View {
    @Binding var schedule: FastingSchedule
    var onFinish: () -> Void

    @AppStorage(AppLanguage.storageKey) private var languageRaw = "en"
    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }

    @State private var step: Int = {
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "-onboardingStep"), i + 1 < args.count, let s = Int(args[i + 1]) {
            return s
        }
        return 0
    }()
    @State private var selectedPresetLabel = "16:8"
    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 10)
            Group {
                switch step {
                case 0: welcomePage
                case 1: schedulePage
                case 2: freeCommitmentPage
                default: notifPage
                }
            }
            Spacer(minLength: 10)
            dots
            actionButton
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FastingBackground(phase: .fasting))
    }

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i == step ? Palette.fastAccent : Palette.sub.opacity(0.3))
                    .frame(width: i == step ? 22 : 8, height: 8)
            }
        }
    }

    private var actionButton: some View {
        Button {
            if step < totalSteps - 1 {
                step += 1
            } else {
                let hours = FastingPreset.all.first(where: { $0.label == selectedPresetLabel })?.fastingHours ?? schedule.fastingMinutes / 60
                let c = Calendar.current
                let startH = schedule.startHour, startM = schedule.startMinute
                if let start = c.date(bySettingHour: startH, minute: startM, second: 0, of: Date()),
                   let end = c.date(byAdding: .hour, value: hours, to: start) {
                    schedule = FastingSchedule(startHour: startH, startMinute: startM,
                                               endHour: c.component(.hour, from: end),
                                               endMinute: c.component(.minute, from: end))
                }
                onFinish()
            }
        } label: {
            Text(step < totalSteps - 1 ? L.t("onb_continue", lang) : L.t("onb_get_started", lang))
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [Palette.fastingA, Palette.fastingB],
                                   startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 18)
                )
        }
    }

    // MARK: Page 0 — Welcome + language

    private var welcomePage: some View {
        VStack(spacing: 22) {
            Text("🌙").font(.system(size: 56))
            Text(L.t("onb_welcome_title", lang))
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Text(L.t("onb_welcome_subtitle", lang))
                .font(.subheadline)
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            VStack(alignment: .leading, spacing: 6) {
                Text(L.t("onb_language_title", lang).uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.sub)
                    .padding(.bottom, 2)
                ForEach(AppLanguage.allCases) { l in
                    Button { languageRaw = l.rawValue } label: {
                        HStack(spacing: 12) {
                            FlagView(lang: l)
                            Text(l.name).font(.system(.body, design: .rounded)).foregroundStyle(Palette.ink)
                            Spacer()
                            Image(systemName: l == lang ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(l == lang ? Palette.fastAccent : Palette.sub.opacity(0.35))
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    // MARK: Page 1 — Schedule presets

    private var schedulePage: some View {
        VStack(spacing: 18) {
            Text("⏱️").font(.system(size: 48))
            Text(L.t("onb_schedule_title", lang))
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Text(L.t("onb_schedule_subtitle", lang))
                .font(.subheadline)
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            VStack(spacing: 10) {
                ForEach(FastingPreset.all) { preset in
                    Button { selectedPresetLabel = preset.label } label: {
                        HStack {
                            Text(preset.label)
                                .font(.system(.headline, design: .rounded))
                                .foregroundStyle(Palette.ink)
                            Spacer()
                            if selectedPresetLabel == preset.label {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.fastAccent)
                            }
                        }
                        .padding(16)
                        .background(.white.opacity(selectedPresetLabel == preset.label ? 0.85 : 0.5),
                                    in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Page 2 — Free, thanks to Crazy Bee Labs

    private var freeCommitmentPage: some View {
        VStack(spacing: 22) {
            Text("🐝").font(.system(size: 56))
            Text(L.t("onb_free_title", lang))
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Text(L.t("onb_free_subtitle", lang))
                .font(.subheadline)
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(Palette.eatAccent)
                Text(L.t("onb_free_feature", lang))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.leading)
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    // MARK: Page 3 — Notifications

    private var notifPage: some View {
        VStack(spacing: 18) {
            Text("🔔").font(.system(size: 48))
            Text(L.t("onb_notif_title", lang))
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Text(L.t("onb_notif_subtitle", lang))
                .font(.subheadline)
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
    }
}
