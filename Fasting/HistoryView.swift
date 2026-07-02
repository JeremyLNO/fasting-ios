import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var languageRaw = "en"
    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }

    private var days: [(date: Date, record: FastRecord?)] { HistoryStore.recentDays(28) }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Palette.bgFastTop, Palette.bgFastBot],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        statsGrid
                        heatmapCard
                        if HistoryStore.totalCompleted == 0 {
                            Text(L.t("history_empty", lang))
                                .font(.footnote)
                                .foregroundStyle(Palette.sub)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                        }
                    }
                    .padding(22)
                }
            }
            .navigationTitle(L.t("history_title", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.t("set_close", lang)) { dismiss() }
                        .foregroundStyle(Palette.ink)
                }
            }
        }
    }

    private var statsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statCard(icon: "flame.fill", tint: Palette.peach,
                         label: L.t("history_streak", lang), value: "\(HistoryStore.currentStreak())")
                statCard(icon: "trophy.fill", tint: Palette.fastAccent,
                         label: L.t("history_best", lang), value: "\(HistoryStore.bestStreak())")
            }
            HStack(spacing: 12) {
                statCard(icon: "checkmark.seal.fill", tint: Palette.eatAccent,
                         label: L.t("history_total", lang), value: "\(HistoryStore.totalCompleted)")
                statCard(icon: "clock.fill", tint: Palette.water,
                         label: L.t("history_avg", lang), value: formatHM(TimeInterval(HistoryStore.averageMinutes * 60)))
            }
        }
    }

    private func statCard(icon: String, tint: Color, label: String, value: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(tint.opacity(0.16)).frame(width: 40, height: 40)
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(tint)
            }
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Palette.ink)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(0.5), lineWidth: 1))
    }

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.t("history_last", lang).uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.sub)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(days, id: \.date) { day in
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(day.record?.completed == true ? Palette.eatAccent : Palette.track)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18))
    }
}
