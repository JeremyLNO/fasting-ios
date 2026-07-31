import SwiftUI

/// Edits one day's fast: when it started and when it ended. Reached by tapping a day in the
/// "last 7 days" strip. Whatever is saved becomes the truth for that day — the strip, the streaks
/// and the stats all recompute from it (`HistoryStore.setEntry` derives "completed" itself, so the
/// numbers can't drift from what's shown here).
struct DayEditorView: View {
    let day: Date
    let schedule: FastingSchedule
    /// Pre-filled from what the strip already knows, when the day has times on record.
    var initialStart: Date?
    var initialEnd: Date?
    var onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var languageRaw = "en"
    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }

    @State private var start = Date()
    @State private var end = Date()

    private var minutes: Int { max(0, Int(end.timeIntervalSince(start) / 60)) }
    private var isValid: Bool { end > start }
    private var reachesGoal: Bool { minutes >= schedule.fastingMinutes }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Palette.bgFastTop, Palette.bgFastBot],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        Text(Self.dayFormatter.string(from: day).capitalized)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Palette.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        card {
                            timeRow(L.t("edit_day_start", lang), "moon.stars.fill", Palette.fastAccent, $start)
                            Divider().opacity(0.4)
                            timeRow(L.t("edit_day_end", lang), "sunrise.fill", Palette.peach, $end)
                        }

                        summary

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
                        .disabled(!isValid)
                        .opacity(isValid ? 1 : 0.5)

                        Button(role: .destructive) {
                            HistoryStore.clearEntry(day: day, targetMinutes: schedule.fastingMinutes)
                            onSaved()
                            dismiss()
                        } label: {
                            Text(L.t("edit_day_clear", lang))
                                .font(.footnote.weight(.medium))
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 2)
                    }
                    .padding(22)
                }
            }
            .navigationTitle(L.t("edit_day_title", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.t("set_close", lang)) { dismiss() }.foregroundStyle(Palette.ink)
                }
            }
        }
        .onAppear(perform: load)
    }

    private var summary: some View {
        VStack(spacing: 6) {
            if isValid {
                HStack(spacing: 8) {
                    Image(systemName: reachesGoal ? "trophy.fill" : "star.fill")
                        .foregroundStyle(reachesGoal ? Palette.eatAccent : Palette.amber)
                    Text("\(L.t("edit_day_duration", lang)) \(formatHM(TimeInterval(minutes * 60)))")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Palette.ink)
                }
                Text(String(format: L.t("edit_day_goal", lang), schedule.fastingHoursText))
                    .font(.caption)
                    .foregroundStyle(Palette.sub)
            } else {
                Text(L.t("edit_day_invalid", lang))
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private func timeRow(_ title: String, _ icon: String, _ tint: Color, _ value: Binding<Date>) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(tint).frame(width: 24)
            Text(title).font(.system(.subheadline, design: .rounded)).foregroundStyle(Palette.ink)
            Spacer()
            // Date *and* time: an overnight fast ends on the following day, so the day must be
            // editable too or a 20 h fast could never be expressed.
            DatePicker("", selection: value, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 12) { content() }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 18))
    }

    private func load() {
        let c = Calendar.current
        if let s = initialStart, let e = initialEnd {
            start = s; end = e
            return
        }
        // No explicit times on record: start from the scheduled start for that day…
        let base = c.date(bySettingHour: schedule.startHour, minute: schedule.startMinute, second: 0, of: day) ?? day
        start = base
        // …but keep the duration that was actually logged. A day interrupted at 10 h must open on
        // 10 h, not on the 20 h goal, or opening the editor would silently rewrite the history.
        let logged = HistoryStore.record(for: day)?.effectiveMinutes ?? 0
        let minutes = logged > 0 ? logged : schedule.fastingMinutes
        end = base.addingTimeInterval(Double(minutes) * 60)
    }

    private func save() {
        guard isValid else { return }
        // Key the record on the day the fast *started*, matching how history is stored elsewhere.
        HistoryStore.setEntry(day: start, start: start, end: end, targetMinutes: schedule.fastingMinutes)
        onSaved()
        dismiss()
    }
}
