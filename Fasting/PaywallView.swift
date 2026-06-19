import SwiftUI

struct PaywallView: View {
    @ObservedObject var store: StoreManager
    var lang: AppLanguage
    var trialActive: Bool = false
    var daysRemaining: Int = 0
    var onContinue: (() -> Void)? = nil

    var body: some View {
        ZStack {
            FastingBackground(phase: .fasting)

            VStack(spacing: 16) {
                Spacer(minLength: 0)

                Text("🌙").font(.system(size: 52))
                Text(L.t("pay_title", lang))
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Text(headline)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Palette.accent(.fasting))
                    .multilineTextAlignment(.center)
                Text(L.t("pay_subtitle", lang))
                    .font(.subheadline)
                    .foregroundStyle(Palette.sub)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                VStack(alignment: .leading, spacing: 12) {
                    feature(L.t("pay_feature_1", lang))
                    feature(L.t("pay_feature_2", lang))
                    feature(L.t("pay_feature_3", lang))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.5), lineWidth: 1))

                Spacer(minLength: 0)

                Button { Task { await store.purchase() } } label: {
                    VStack(spacing: 2) {
                        Text(L.t("pay_subscribe", lang))
                            .font(.system(.headline, design: .rounded).weight(.bold))
                        Text(String(format: L.t("pay_per_year", lang), store.priceText))
                            .font(.subheadline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [Palette.fastingA, Palette.fastingB],
                                       startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                }
                .disabled(store.purchasing)

                if trialActive, let onContinue {
                    Button(L.t("pay_continue", lang)) { onContinue() }
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Palette.ink)
                }

                Button(L.t("pay_restore", lang)) { Task { await store.restore() } }
                    .font(.footnote)
                    .foregroundStyle(Palette.sub)

                Text(L.t("pay_terms", lang))
                    .font(.caption2)
                    .foregroundStyle(Palette.sub)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
    }

    private var headline: String {
        if trialActive {
            return daysRemaining <= 1
                ? L.t("pay_one_day_left", lang)
                : String(format: L.t("pay_days_left", lang), daysRemaining)
        }
        return L.t("pay_trial_ended", lang)
    }

    private func feature(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.fastAccent)
            Text(text).font(.subheadline).foregroundStyle(Palette.ink)
            Spacer(minLength: 0)
        }
    }
}
