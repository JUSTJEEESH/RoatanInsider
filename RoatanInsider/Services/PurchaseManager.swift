import Foundation
import StoreKit

/// Centralised subscription state and StoreKit 2 plumbing for Insider+.
///
/// Business model (Aug 2026):
///   - Free tier:        everything except the AI itinerary builder —
///                       directory, map, search, events, ships in port,
///                       favorites (CloudKit-synced), Live Activity, alerts,
///                       currency/tip, guides.
///   - Insider+:         $2.99/month or $14.99/year. Gates the AI itinerary
///                       builder today; future member features (offline maps,
///                       partner discounts) land behind it as they actually
///                       ship. The paywall may only claim what exists.
///
/// Grandfather guarantee:
///   Users who originally bought the app at $4.99 get Insider+ for free,
///   forever, automatically. This is detected via StoreKit 2's
///   `AppTransaction.shared.originalAppVersion`: any device whose first
///   purchase preceded `freemiumReleaseBuild` is silently entitled with no
///   "restore purchases" tap required, no servers, no manual flags. New
///   installs after the freemium release see the paywall.
///
/// To roll out:
///   1. Configure the two in-app purchase products in App Store Connect using
///      the IDs below.
///   2. `freemiumReleaseBuild` is the CFBundleVersion of the build where
///      Insider+ ships — 100, matching CURRENT_PROJECT_VERSION. DO NOT bump
///      it for patch releases; it is the single switch defining the
///      grandfather cohort and should never move. Every later build must be
///      numbered above it.
///
/// YOU CANNOT TEST THIS IN SANDBOX OR TESTFLIGHT. For sandbox accounts
/// `AppTransaction.originalAppVersion` reports a fixed "1.0" regardless of
/// purchase history, so every tester looks grandfathered and the paywall
/// never appears. That is not a passing test — it is the API declining to
/// answer. The first honest check is a real App Store build.
@Observable
final class PurchaseManager {
    // MARK: - Configuration

    static let monthlyProductID = "com.roataninsider.app.insiderplus.monthly"
    static let yearlyProductID  = "com.roataninsider.app.insiderplus.yearly"
    static let allProductIDs = [yearlyProductID, monthlyProductID]

    /// The BUILD NUMBER (CFBundleVersion) of the first freemium release.
    /// Anyone whose original purchase predates it is a founding member and
    /// gets Insider+ for life. Never move this.
    ///
    /// It is a build number, not "2.0", and that distinction is the whole
    /// point. On iOS, `AppTransaction.originalAppVersion` returns
    /// CFBundleVersion — the build number — NOT the marketing version.
    /// (macOS is the platform that returns the short version string.) This
    /// constant used to be "2.0.0", compared numerically against a build
    /// number, and "2" sorts before "2.0.0" because the digit runs tie and
    /// the shorter string wins. Every new customer would have been silently
    /// grandfathered and nobody would ever have reported it.
    ///
    /// 100 rather than 2 on purpose. Versions 1.0 through 1.6 all shipped as
    /// build 1, and a new marketing version makes build 1 available again —
    /// so shipping 2.0 as build 1 would have handed every new customer the
    /// founding-member entitlement. Starting at 100 puts a gap between the
    /// old numbering and the new that a slip cannot close.
    static let freemiumReleaseBuild = "100"

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
                // `originalAppVersion` is the CFBundleVersion at the time of
                // the customer's FIRST purchase — build "1" for everyone who
                // bought any version from 1.0 through 1.6.
                let original = appTransaction.originalAppVersion
                let cutoff = Self.freemiumReleaseBuild
                // Numeric compare so "99" < "100" rather than sorting as text.
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
