import Foundation

/// Tracks the first-launch date, used to bound how far back History reconstructs streaks.
/// Fasting is a free app (no trial, no paywall) — this has nothing to do with monetization.
enum AppInstall {
    static let installKey = "app.installDate"

    static func ensureInstallDate() {
        if UserDefaults.standard.object(forKey: installKey) == nil {
            UserDefaults.standard.set(Date(), forKey: installKey)
        }
    }

    static var installDate: Date {
        UserDefaults.standard.object(forKey: installKey) as? Date ?? Date()
    }
}
