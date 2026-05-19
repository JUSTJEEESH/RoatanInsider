import Foundation

/// Lightweight analytics façade. Today it routes events to `os.Logger` so they
/// appear in Console.app under the "analytics" category. Tomorrow swap the
/// `backend` to TelemetryDeck, PostHog, or your own Supabase ingest — every
/// call site stays the same.
///
/// The point of shipping this NOW (with no real backend) is to put call sites
/// in place across the app so we never have to retrofit "where do we track
/// X?" — every screen view, business open, search, favorite, and paywall
/// event already fires.
///
/// Privacy: events never carry PII. Business IDs and area/category IDs are
/// non-identifying public catalogue keys.
enum Analytics {
    enum Event {
        case appLaunched
        case onboardingStarted
        case onboardingCompleted(travelerType: String?)
        case onboardingSkipped(at: String)

        case tabSelected(name: String)
        case homeSectionViewed(name: String)
        case businessOpened(id: String, source: String)
        case businessShared(id: String)
        case businessFavorited(id: String, isFavorite: Bool)

        case searchSubmitted(query: String, resultCount: Int)
        case searchNoResults(query: String)
        case filterApplied(kind: String, value: String)

        case mapPinTapped(id: String)
        case mapCategoryFiltered(category: String)

        case cruiseModeOpened(port: String?)
        case cruiseBusinessTapped(id: String, canVisit: Bool)

        case paywallShown(source: String)
        case paywallProductSelected(productId: String)
        case paywallPurchaseSucceeded(productId: String)
        case paywallPurchaseFailed(reason: String)
        case paywallRestoreInvoked
        case paywallDismissed(source: String)

        case deepLinkOpened(route: String)
        case weatherRefreshed
        case dataManifestChecked(updates: Int)

        case toolUsed(name: String)
    }

    static var backend: AnalyticsBackend = LoggerBackend()

    static func track(_ event: Event) {
        backend.send(name: event.name, properties: event.properties)
    }

    static func identify(properties: [String: String]) {
        backend.identify(properties: properties)
    }
}

protocol AnalyticsBackend {
    func send(name: String, properties: [String: String])
    func identify(properties: [String: String])
}

/// Default backend — writes events to `os.Logger`. Swap for a real one later
/// without changing a single call site.
struct LoggerBackend: AnalyticsBackend {
    func send(name: String, properties: [String: String]) {
        let propsString = properties.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
        AppLog.app.notice("[analytics] \(name, privacy: .public) \(propsString, privacy: .public)")
    }

    func identify(properties: [String: String]) {
        let propsString = properties.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
        AppLog.app.notice("[analytics] identify \(propsString, privacy: .public)")
    }
}

extension Analytics.Event {
    var name: String {
        switch self {
        case .appLaunched: return "app_launched"
        case .onboardingStarted: return "onboarding_started"
        case .onboardingCompleted: return "onboarding_completed"
        case .onboardingSkipped: return "onboarding_skipped"
        case .tabSelected: return "tab_selected"
        case .homeSectionViewed: return "home_section_viewed"
        case .businessOpened: return "business_opened"
        case .businessShared: return "business_shared"
        case .businessFavorited: return "business_favorited"
        case .searchSubmitted: return "search_submitted"
        case .searchNoResults: return "search_no_results"
        case .filterApplied: return "filter_applied"
        case .mapPinTapped: return "map_pin_tapped"
        case .mapCategoryFiltered: return "map_category_filtered"
        case .cruiseModeOpened: return "cruise_mode_opened"
        case .cruiseBusinessTapped: return "cruise_business_tapped"
        case .paywallShown: return "paywall_shown"
        case .paywallProductSelected: return "paywall_product_selected"
        case .paywallPurchaseSucceeded: return "paywall_purchase_succeeded"
        case .paywallPurchaseFailed: return "paywall_purchase_failed"
        case .paywallRestoreInvoked: return "paywall_restore_invoked"
        case .paywallDismissed: return "paywall_dismissed"
        case .deepLinkOpened: return "deep_link_opened"
        case .weatherRefreshed: return "weather_refreshed"
        case .dataManifestChecked: return "data_manifest_checked"
        case .toolUsed: return "tool_used"
        }
    }

    var properties: [String: String] {
        switch self {
        case .appLaunched: return [:]
        case .onboardingStarted: return [:]
        case .onboardingCompleted(let type): return ["traveler_type": type ?? "unknown"]
        case .onboardingSkipped(let step): return ["step": step]
        case .tabSelected(let name): return ["tab": name]
        case .homeSectionViewed(let name): return ["section": name]
        case .businessOpened(let id, let source): return ["id": id, "source": source]
        case .businessShared(let id): return ["id": id]
        case .businessFavorited(let id, let isFav): return ["id": id, "favorited": isFav ? "1" : "0"]
        case .searchSubmitted(let q, let n): return ["query_len": "\(q.count)", "result_count": "\(n)"]
        case .searchNoResults(let q): return ["query_len": "\(q.count)"]
        case .filterApplied(let kind, let value): return ["kind": kind, "value": value]
        case .mapPinTapped(let id): return ["id": id]
        case .mapCategoryFiltered(let category): return ["category": category]
        case .cruiseModeOpened(let port): return ["port": port ?? "default"]
        case .cruiseBusinessTapped(let id, let canVisit): return ["id": id, "can_visit": canVisit ? "1" : "0"]
        case .paywallShown(let source): return ["source": source]
        case .paywallProductSelected(let id): return ["product_id": id]
        case .paywallPurchaseSucceeded(let id): return ["product_id": id]
        case .paywallPurchaseFailed(let reason): return ["reason": reason]
        case .paywallRestoreInvoked: return [:]
        case .paywallDismissed(let source): return ["source": source]
        case .deepLinkOpened(let route): return ["route": route]
        case .weatherRefreshed: return [:]
        case .dataManifestChecked(let n): return ["updates": "\(n)"]
        case .toolUsed(let name): return ["tool": name]
        }
    }
}
