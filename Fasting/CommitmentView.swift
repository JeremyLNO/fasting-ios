import SwiftUI

/// One-time "why Fasting made easy is free" screen, shown before onboarding on the very first
/// launch ever (see `RootView`, gated on `CommitmentView.seenKey`) and never again automatically.
/// Mirrors the same screen in the other free Crazy Bee Labs health apps (cf. Respire), and is kept
/// standalone — taking a plain `onContinue` closure — so Settings can present it again as a sheet
/// without duplicating any layout.
struct CommitmentView: View {
    /// `UserDefaults`/`@AppStorage` key remembering this screen has already been shown once.
    static let seenKey = "commitment.seen"

    /// Crazy Bee Labs' public site — the same destination for every entry point (first launch
    /// here, and the Settings row).
    static let commitmentURL = URL(string: "https://www.crazybeelabs.com/")!

    var onContinue: () -> Void

    @AppStorage(AppLanguage.storageKey) private var languageRaw = "en"
    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(Palette.fastAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                        .accessibilityHidden(true)

                    Text(L.t("commit_title", lang))
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    card {
                        Text(L.t("commit_why_title", lang))
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Palette.ink)
                        Text(L.t("commit_why_body", lang))
                            .font(.subheadline)
                            .foregroundStyle(Palette.sub)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(L.t("commit_why_body2", lang))
                            .font(.subheadline)
                            .foregroundStyle(Palette.sub)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    card {
                        Text(L.t("commit_cbl_title", lang))
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Palette.ink)
                        Text(L.t("commit_cbl_body", lang))
                            .font(.subheadline)
                            .foregroundStyle(Palette.sub)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    commitmentFooter
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
                .padding(24)
            }

            Button(action: onContinue) {
                Text(L.t("onb_continue", lang))
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
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FastingBackground(phase: .fasting))
    }

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) { content() }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.5), lineWidth: 1))
    }

    private var commitmentFooter: some View {
        Link(destination: CommitmentView.commitmentURL) {
            VStack(spacing: 6) {
                Image("CrazyBeeLabs")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(height: 30)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1))
                Text(L.t("commit_link", lang))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.fastAccent)
                    .underline()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(L.t("commit_link", lang)), Crazy Bee Labs")
    }
}
