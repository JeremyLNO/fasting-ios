import SwiftUI

struct SettingsView: View {
    @Binding var schedule: FastingSchedule
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var languageRaw = "en"
    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }

    @State private var start = Date()
    @State private var end = Date()
    @State private var waterGoal = SharedStore.waterGoal
    @AppStorage("water.reminders.enabled") private var waterRemindersEnabled = false
    @StateObject private var auth = AuthManager()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Palette.bgFastTop, Palette.bgFastBot],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        presetsCard
                        timeCard(L.t("set_fast_start", lang), "🌙", $start)
                        timeCard(L.t("set_fast_end", lang), "☀️", $end)
                        summary
                        waterSettingsCard
                        languageCard
                        accountCard
                        freeAppCard
                        Button(action: save) {
                            Text(L.t("set_save", lang))
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
                        .padding(.top, 4)

                        Link(destination: URL(string: "https://crazybeelabs.com/support/")!) {
                            HStack(spacing: 6) {
                                Image(systemName: "lifepreserver")
                                Text(L.t("support", lang))
                            }
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundStyle(Palette.fastAccent)
                        }
                        .padding(.top, 8)

                        Link(destination: URL(string: "https://www.crazybeelabs.com/privacy-policy/")!) {
                            HStack(spacing: 6) {
                                Image(systemName: "hand.raised.fill")
                                Text(L.t("privacy_policy", lang))
                            }
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundStyle(Palette.fastAccent)
                        }

                        Link(destination: URL(string: "https://crazybeelabs.com/")!) {
                            Image("CrazyBeeLabs")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 30)
                                .opacity(0.95)
                                .padding(.top, 10)
                                .padding(.bottom, 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(22)
                }
            }
            .navigationTitle(L.t("set_title", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.t("set_close", lang)) { dismiss() }
                        .foregroundStyle(Palette.ink)
                }
            }
        }
        .onAppear(perform: load)
    }

    private var presetsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L.t("set_presets", lang).uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.sub)
            HStack(spacing: 8) {
                ForEach(FastingPreset.all) { preset in
                    Button {
                        end = Calendar.current.date(byAdding: .hour, value: preset.fastingHours, to: start) ?? end
                    } label: {
                        Text(preset.label)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(Palette.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18))
    }

    private var waterSettingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L.t("water_title", lang).uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.sub)

            Stepper(value: $waterGoal, in: 3...8) {
                HStack(spacing: 6) {
                    Image(systemName: "drop.fill").foregroundStyle(Palette.water)
                    Text(L.t("water_goal_label", lang)).foregroundStyle(Palette.ink)
                    Spacer()
                    Text(String(format: L.t("water_goal_glasses", lang), waterGoal))
                        .foregroundStyle(Palette.sub)
                }
            }
            .onChange(of: waterGoal) { _, newValue in
                SharedStore.setWaterGoal(newValue)
                if waterRemindersEnabled {
                    NotificationManager.shared.rescheduleWater(enabled: true, goal: newValue)
                }
            }

            Toggle(isOn: $waterRemindersEnabled) {
                HStack(spacing: 6) {
                    Image(systemName: "bell.fill").foregroundStyle(Palette.water)
                    Text(L.t("water_reminders_label", lang)).foregroundStyle(Palette.ink)
                }
            }
            .tint(Palette.water)
            .onChange(of: waterRemindersEnabled) { _, enabled in
                NotificationManager.shared.rescheduleWater(enabled: enabled, goal: waterGoal)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18))
    }

    private func timeCard(_ title: String, _ emoji: String, _ value: Binding<Date>) -> some View {
        HStack {
            Text(emoji).font(.title2)
            Text(title).font(.system(.headline, design: .rounded)).foregroundStyle(Palette.ink)
            Spacer()
            DatePicker("", selection: value, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
        .padding(18)
        .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18))
    }

    private var summary: some View {
        let temp = scheduleFromPickers()
        let eating = 24 * 60 - temp.fastingMinutes
        let eatingText = eating % 60 == 0 ? "\(eating / 60)h" : "\(eating / 60)h\(String(format: "%02d", eating % 60))"
        return Text("\(temp.fastingHoursText) \(L.t("set_word_fasting", lang)) · \(eatingText) \(L.t("set_word_eating", lang))")
            .font(.subheadline)
            .foregroundStyle(Palette.sub)
    }

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L.t("set_language", lang).uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.sub)
                .padding(.bottom, 4)

            ForEach(AppLanguage.allCases) { l in
                Button {
                    languageRaw = l.rawValue
                    NotificationManager.shared.reschedule(for: schedule)
                } label: {
                    HStack(spacing: 12) {
                        FlagView(lang: l)
                        Text(l.name)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Palette.ink)
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
        .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18))
    }

    private var accountCard: some View {
        NavigationLink {
            AccountView(auth: auth)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Palette.fastAccent)
                Text(L.t("account_title", lang))
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Spacer()
                if auth.isSignedIn {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Palette.eatAccent)
                }
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(Palette.sub)
            }
        }
        .padding(18)
        .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18))
    }

    private var freeAppCard: some View {
        HStack(spacing: 12) {
            Text("🐝").font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(L.t("free_badge_title", lang))
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Text(L.t("free_badge_subtitle", lang))
                    .font(.caption)
                    .foregroundStyle(Palette.sub)
            }
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18))
    }

    private func scheduleFromPickers() -> FastingSchedule {
        let c = Calendar.current
        return FastingSchedule(
            startHour: c.component(.hour, from: start),
            startMinute: c.component(.minute, from: start),
            endHour: c.component(.hour, from: end),
            endMinute: c.component(.minute, from: end)
        )
    }

    private func load() {
        let c = Calendar.current
        start = c.date(bySettingHour: schedule.startHour, minute: schedule.startMinute, second: 0, of: Date()) ?? Date()
        end = c.date(bySettingHour: schedule.endHour, minute: schedule.endMinute, second: 0, of: Date()) ?? Date()
    }

    private func save() {
        schedule = scheduleFromPickers()
        SharedStore.save(schedule)
        NotificationManager.shared.reschedule(for: schedule)
        dismiss()
    }
}
