import Foundation
import StoreKit

/// Centralised subscription state and StoreKit 2 plumbing for Insider+.
///
/// Business model (May 2026 onward):
///   - Free tier:        directory, map, search, favorites, currency/tip,
///                       basic guides.
///   - Insider+:         $2.99/month or $14.99/year. AI itinerary, cruise Live
///                       Activity, offline map tiles, "Right Now" feed, sunset
///                       and happy-hour notifications, cloud-sync favorites,
///                       Insider Pass discounts.
///
/// Grandfather guarantee:
///   Users who originally bought the app at $4.99 get Insider+ for free,
///   forever, automatically. This is detected via StoreKit 2's
///   `AppTransaction.shared.originalAppVersion`: any device whose first
///   purchase preceded `freemiumReleaseAppVersion` is silently entitled with no
///   "restore purchases" tap required, no servers, no manual flags. New
///   installs after the freemium release see the paywall.
///
/// To roll out:
///   1. Configure the two in-app purchase products in App Store Connect using
///      the IDs below.
///   2. Set `freemiumReleaseAppVersion` to the CFBundleShortVersionString of
///      the build where Insider+ ships (e.g. "2.0.0"). DO NOT bump this for
///      patch releases — it's the single switch that defines the grandfather
///      cohort and should never move.
///   3. Update binary version once and never again.
@Observable
final class PurchaseManager {
    // MARK: - Configuration

    static let monthlyProductID = "com.roataninsider.app.insiderplus.monthly"
    static let yearlyProductID  = "com.roataninsider.app.insiderplus.yearly"
    static let allProductIDs = [yearlyProductID, monthlyProductID]

    /// Any user whose original app purchase version is earlier than this is
    /// grandfathered into Insider+ for life. Bump only when you intentionally
    /// want to close the grandfather window — typically never.
    static let freemiumReleaseAppVersion = "2.0.0"

    // MARK: - Observable state

    /// True when the user has any path to Insider+ — paid sub OR grandfathered.
    var hasPremium: Bool { isGrandfathered || !activeSubscriptionIDs.isEmpty }

    private(set) var products: [Product] = []
    private(set) var activeSubscriptionIDs: Set<String> = []
    private(set) var isGrandfathered: Bool = false
    private(set) var isLoading: Bool = false
    private(set) var lastError: String?

    private var updatesTask: Task<Void, Never>?

    // MARK: - Lifecycle

    init() {
        updatesTask = listenForTransactionUpdates()
        Task { await refresh() }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Public API

    /// Re-syncs grandfather status, products, and active entitlements.
    /// Called on init, after a successful purchase, after Restore, and
    /// on ScenePhase becoming active.
    @MainActor
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        await evaluateGrandfather()
        await fetchProducts()
        await refreshEntitlements()
    }

    /// Begins a purchase flow for the given product. Returns `true` when
    /// the purchase verified successfully, `false` if the user cancelled
    /// or the purchase is pending parental approval.
    @MainActor
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                    return true
                }
                lastError = "Purchase could not be verified."
                return false
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            AppLog.purchase.error("Purchase failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Restore previous purchases (Apple requires a Restore button on every
    /// paid app).
    @MainActor
    func restore() async {
        do {
            try await AppStore.sync()
            await refresh()
        } catch {
            lastError = error.localizedDescription
            AppLog.purchase.error("Restore failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Internals

    @MainActor
    private func fetchProducts() async {
        do {
            let fetched = try await Product.products(for: Self.allProductIDs)
            // Sort yearly first (best value), monthly second.
            products = fetched.sorted { lhs, _ in lhs.id == Self.yearlyProductID }
        } catch {
            AppLog.purchase.warning("Product fetch failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func refreshEntitlements() async {
        var ids: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.revocationDate == nil {
                ids.insert(t.productID)
            }
        }
        activeSubscriptionIDs = ids
    }

    @MainActor
    private func evaluateGrandfather() async {
        do {
            let verification = try await AppTransaction.shared
            if case .verified(let appTransaction) = verification {
                let original = appTransaction.originalAppVersion
                let cutoff = Self.freemiumReleaseAppVersion
                // Numeric compare: "1.5.0" < "2.0.0" -> .orderedAscending.
                let comparison = original.compare(cutoff, options: .numeric)
                isGrandfathered = (comparison == .orderedAscending)
                if isGrandfathered {
                    AppLog.purchase.notice("Grandfathered user: originalAppVersion=\(original, privacy: .public) cutoff=\(cutoff, privacy: .public)")
                }
            }
        } catch {
            // AppTransaction.shared can fail in Simulator or for sandbox users
            // without a real App Store receipt. We default to NOT grandfathered
            // in that case — the only impact is the user might need to use
            // Restore once.
            AppLog.purchase.debug("AppTransaction unavailable: \(error.localizedDescription)")
            isGrandfathered = false
        }
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let t) = result {
                    await t.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }

    // MARK: - Display helpers

    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyProductID } }
    var yearlyProduct: Product? { products.first { $0.id == Self.yearlyProductID } }

    /// Approximate dollars saved if billed monthly vs yearly. Computed from
    /// live App Store prices, no hardcoded math.
    var yearlySavingsLabel: String? {
        guard let monthly = monthlyProduct, let yearly = yearlyProduct else { return nil }
        let yearlyAtMonthly = monthly.price * 12
        guard yearlyAtMonthly > yearly.price else { return nil }
        let saved = yearlyAtMonthly - yearly.price
        let formatter = yearly.priceFormatStyle
        return "Save \(saved.formatted(formatter))"
    }
}
