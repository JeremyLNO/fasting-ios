import SwiftUI

/// Corrects the start time of the window currently running — reached by tapping the START card.
/// Saving writes a `ManualSession` anchored at the chosen moment, so the elapsed time, the
/// percentage and the END card all recompute from it (and the widgets/Live Activity follow,
/// since the session lives in the App Group).
struct StartEditorView: View {
    let schedule: FastingSchedule
    let state: FastingState
    var onSaved: (ManualSession) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var languageRaw = "en"
    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }

    @State private var start = Date()

    /// A window can't start in the future — that would show a negative elapsed time.
    private var isValid: Bool { start <= Date() }

    private var targetMinutes: Int {
        state.isFasting ? schedule.fastingMinutes : (24 * 60 - schedule.fastingMinutes)
    }
    private var projectedEnd: Date { start.addingTimeInterval(Double(targetMinutes) * 60) }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: Palette.bg(state.phase), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    Text(state.isFasting ? L.t("edit_start_fasting", lang) : L.t("edit_start_eating", lang))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Palette.sub)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    DatePicker("", selection: $start, in: ...Date(),
                               displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding(.horizontal, 8)
                        .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18))

                    if isValid {
                        VStack(spacing: 4) {
                            Text(formatHMS(max(0, Date().timeIntervalSince(start))))
                                .font(.system(size: 30, weight: .heavy, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Palette.ink)
                            Text(L.t("ring_elapsed", lang))
                                .font(.caption).foregroundStyle(Palette.sub)
                            Text(String(format: L.t("edit_ends_at", lang), clockLabel(projectedEnd)))
                                .font(.footnote)
                                .foregroundStyle(Palette.accent(state.phase))
                                .padding(.top, 2)
                        }
                    } else {
                        Text(L.t("edit_start_future", lang))
                            .font(.caption).foregroundStyle(.red)
                    }

                    Spacer()

                    Button(action: save) {
                        Text(L.t("set_save", lang))
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: Palette.ring(state.phase).suffix(2),
                                               startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 18)
                            )
                    }
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.5)
                }
                .padding(22)
            }
            .navigationTitle(L.t("edit_start_title", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.t("set_close", lang)) { dismiss() }.foregroundStyle(Palette.ink)
                }
            }
        }
        .onAppear { start = state.windowStart }
    }

    private func save() {
        guard isValid else { return }
        onSaved(ManualSession(isFasting: state.isFasting, start: start))
        dismiss()
    }
}
