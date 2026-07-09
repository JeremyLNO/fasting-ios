import SwiftUI
import AuthenticationServices

struct AccountView: View {
    @ObservedObject var auth: AuthManager
    @AppStorage(AppLanguage.storageKey) private var languageRaw = "en"
    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }

    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.bgFastTop, Palette.bgFastBot],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if auth.isSignedIn {
                        signedInCard
                        manageAppleIdLink
                        signOutButton
                        deleteAccountButton
                    } else {
                        signInCard
                    }
                }
                .padding(22)
            }
        }
        .navigationTitle(L.t("account_title", lang))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(L.t("account_delete_confirm_title", lang), isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button(L.t("account_delete_confirm_action", lang), role: .destructive) {
                auth.deleteAccount()
                dismiss()
            }
            Button(L.t("set_close", lang), role: .cancel) {}
        } message: {
            Text(L.t("account_delete_confirm_body", lang))
        }
    }

    private var signInCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 44))
                .foregroundStyle(Palette.fastAccent)
            Text(L.t("account_signin_title", lang))
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Palette.ink)
            Text(L.t("account_signin_subtitle", lang))
                .font(.subheadline)
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let authorization): auth.handle(authorization)
                case .failure(let error): print("[Auth] Sign in with Apple failed: \(error)")
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.top, 6)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18))
    }

    private var signedInCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(Palette.eatAccent)
            VStack(alignment: .leading, spacing: 2) {
                Text(auth.displayName ?? L.t("account_signed_in_as", lang))
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(Palette.ink)
                if auth.displayName != nil {
                    Text(L.t("account_signed_in_as", lang))
                        .font(.caption)
                        .foregroundStyle(Palette.sub)
                }
            }
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18))
    }

    private var manageAppleIdLink: some View {
        Link(destination: URL(string: "https://appleid.apple.com/account/manage")!) {
            HStack(spacing: 6) {
                Image(systemName: "key.fill")
                Text(L.t("account_manage_apple_id", lang))
                Spacer()
                Image(systemName: "arrow.up.right")
            }
            .font(.system(.subheadline, design: .rounded).weight(.medium))
            .foregroundStyle(Palette.fastAccent)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var signOutButton: some View {
        Button { auth.signOut() } label: {
            Text(L.t("account_sign_out", lang))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var deleteAccountButton: some View {
        VStack(spacing: 8) {
            Button(role: .destructive) { showDeleteConfirm = true } label: {
                Text(L.t("account_delete", lang))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 16))
            }
            Text(L.t("account_delete_note", lang))
                .font(.caption2)
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 6)
    }
}
