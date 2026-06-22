import SwiftUI

struct SettingsView: View {
    @Binding var schedule: FastingSchedule
    @ObservedObject var store: StoreManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var languageRaw = "en"
    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }

    @State private var start = Date()
    @State private var end = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Palette.bgFastTop, Palette.bgFastBot],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        timeCard(L.t("set_fast_start", lang), "🌙", $start)
                        timeCard(L.t("set_fast_end", lang), "☀️", $end)
                        summary
                        languageCard
                        subscriptionCard
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

    private var subscriptionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L.t("set_plan", lang).uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.sub)

            HStack(spacing: 12) {
                Image(systemName: store.isSubscribed ? "crown.fill" : "gift.fill")
                    .font(.title3)
                    .foregroundStyle(store.isSubscribed ? Palette.peach : Palette.fastAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(planTitle)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(Palette.ink)
                    Text(planSubtitle)
                        .font(.caption)
                        .foregroundStyle(Palette.sub)
                }
                Spacer()
                if store.isSubscribed {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Palette.eatAccent)
                }
            }

            if !store.isSubscribed {
                Button { Task { await store.purchase() } } label: {
                    Text("\(L.t("pay_subscribe", lang)) · \(String(format: L.t("pay_per_year", lang), store.priceText))")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            LinearGradient(colors: [Palette.fastingA, Palette.fastingB],
                                           startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                }
                .disabled(store.purchasing)

                Button(L.t("pay_restore", lang)) { Task { await store.restore() } }
                    .font(.footnote)
                    .foregroundStyle(Palette.sub)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18))
    }

    private var planTitle: String {
        store.isSubscribed ? L.t("pay_title", lang) : L.t("plan_free", lang)
    }

    private var planSubtitle: String {
        if store.isSubscribed { return L.t("plan_active", lang) }
        let days = Trial.daysRemaining
        if days <= 0 { return L.t("pay_trial_ended", lang) }
        return days <= 1 ? L.t("pay_one_day_left", lang) : String(format: L.t("pay_days_left", lang), days)
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
