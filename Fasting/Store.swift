import Foundation
import StoreKit

/// 7-day free trial counted from the first launch (stored locally).
enum Trial {
    static let installKey = "trial.installDate"
    static let trialDays = 7

    static func ensureInstallDate() {
        if UserDefaults.standard.object(forKey: installKey) == nil {
            UserDefaults.standard.set(Date(), forKey: installKey)
        }
    }

    static var installDate: Date {
        UserDefaults.standard.object(forKey: installKey) as? Date ?? Date()
    }

    static var daysRemaining: Int {
        // -forceExpired simulates an ended trial (for testing the paywall).
        if CommandLine.arguments.contains("-forceExpired") { return 0 }
        let elapsed = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        return max(0, trialDays - elapsed)
    }

    static var isActive: Bool { daysRemaining > 0 }
}

/// StoreKit 2 wrapper for the yearly "Fasting Pro" subscription.
@MainActor
final class StoreManager: ObservableObject {
    static let productID = "com.lno.fasting.pro.yearly"

    @Published var product: Product?
    @Published var isSubscribed = false
    @Published var purchasing = false

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                    await self?.refresh()
                }
            }
        }
        Task { await load(); await refresh() }
    }

    deinit { updatesTask?.cancel() }

    var priceText: String { product?.displayPrice ?? "$9.99" }

    func load() async {
        product = try? await Product.products(for: [Self.productID]).first
    }

    func refresh() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                active = true
            }
        }
        isSubscribed = active
    }

    func purchase() async {
        guard let product else { return }
        purchasing = true
        defer { purchasing = false }
        if let result = try? await product.purchase(),
           case .success(let verification) = result,
           case .verified(let transaction) = verification {
            await transaction.finish()
            await refresh()
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh()
    }
}
