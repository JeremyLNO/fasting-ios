import Foundation
import AuthenticationServices
import ActivityKit

/// A lightweight, backend-less "account" built on Sign in with Apple. Fasting has no server —
/// the only purpose of signing in is to give the user a real identity so Settings can offer a
/// proper account (and account deletion), per App Store review guideline 5.1.1(v). There is no
/// app-specific password: "reset password" is delegated entirely to the user's Apple ID.
@MainActor
final class AuthManager: ObservableObject {
    @Published var isSignedIn: Bool
    @Published var displayName: String?

    private static let userIdKey = "auth.appleUserId"
    private static let nameKey = "auth.displayName"

    init() {
        isSignedIn = UserDefaults.standard.string(forKey: Self.userIdKey) != nil
        displayName = UserDefaults.standard.string(forKey: Self.nameKey)
        Task { await self.refreshCredentialState() }
    }

    /// Detects if the user revoked "Sign in with Apple" for this app from their Apple ID settings.
    func refreshCredentialState() async {
        guard let userId = UserDefaults.standard.string(forKey: Self.userIdKey) else { return }
        let state = try? await ASAuthorizationAppleIDProvider().credentialState(forUserID: userId)
        if state == .revoked || state == .notFound {
            signOut()
        }
    }

    func handle(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        UserDefaults.standard.set(credential.user, forKey: Self.userIdKey)
        // Apple only provides the name on the very first authorization ever — persist it now.
        if let name = credential.fullName, name.givenName != nil || name.familyName != nil {
            let formatted = PersonNameComponentsFormatter().string(from: name)
            if !formatted.isEmpty {
                UserDefaults.standard.set(formatted, forKey: Self.nameKey)
                displayName = formatted
            }
        }
        isSignedIn = true
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: Self.userIdKey)
        UserDefaults.standard.removeObject(forKey: Self.nameKey)
        isSignedIn = false
        displayName = nil
    }

    /// Erases everything Fasting stores locally — nothing here is legally required to keep.
    func deleteAccount() {
        SharedStore.wipeScheduleAndWater()
        HistoryStore.wipe()
        UserDefaults.standard.removeObject(forKey: AppLanguage.storageKey)
        UserDefaults.standard.removeObject(forKey: "water.reminders.enabled")
        UserDefaults.standard.removeObject(forKey: "onboarding.completed")
        NotificationManager.shared.cancelAll()
        Task {
            for activity in Activity<FastingActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        signOut()
    }
}
