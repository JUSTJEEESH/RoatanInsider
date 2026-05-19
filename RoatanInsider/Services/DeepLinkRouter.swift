import Foundation
import SwiftUI

/// Centralised URL → in-app destination resolver.
///
/// Handles both Universal Links (`https://roataninsider.com/b/<slug>`) and
/// the custom scheme (`roataninsider://business/<slug>`). The custom scheme
/// is testable today via Simulator (`xcrun simctl openurl booted ...`) without
/// any server setup, while Universal Links require the AASA file on the web
/// origin and the Associated Domains entitlement on the iOS target.
///
/// Adding a new route type is two steps:
///   1. Add a case to `Route`.
///   2. Add a matcher to `parse(url:)`.
///   3. Add a handler in `ContentView`'s `.onChange(of: router.pendingRoute)`.
@Observable
final class DeepLinkRouter {
    enum Route: Equatable {
        case business(slug: String)
        case category(id: String)
        case area(id: String)
        case collection(id: String)
        case openTab(index: Int)
    }

    var pendingRoute: Route?

    func consume() -> Route? {
        defer { pendingRoute = nil }
        return pendingRoute
    }

    func handle(_ url: URL) {
        guard let route = Self.parse(url: url) else {
            AppLog.app.warning("Unhandled deep link: \(url.absoluteString, privacy: .public)")
            return
        }
        AppLog.app.notice("Deep link: \(url.absoluteString, privacy: .public)")
        pendingRoute = route
    }

    static func parse(url: URL) -> Route? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let comp = components else { return nil }

        let scheme = comp.scheme?.lowercased() ?? ""
        let host = comp.host?.lowercased() ?? ""
        // First non-empty path segment — handles both
        // `/b/<slug>` (universal link, host = roataninsider.com)
        // and `business/<slug>` (custom scheme, host = "business")
        let pathSegments = comp.path
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)

        // Custom scheme: roataninsider://<host>/<rest>
        if scheme == "roataninsider" {
            switch host {
            case "business", "b":
                if let slug = pathSegments.first { return .business(slug: slug) }
            case "category", "c":
                if let id = pathSegments.first { return .category(id: id) }
            case "area", "a":
                if let id = pathSegments.first { return .area(id: id) }
            case "collection":
                if let id = pathSegments.first { return .collection(id: id) }
            case "tab":
                if let idStr = pathSegments.first, let idx = Int(idStr) { return .openTab(index: idx) }
            default:
                break
            }
        }

        // Universal links: https://roataninsider.com/<root>/<rest>
        if scheme == "https" || scheme == "http" {
            guard let root = pathSegments.first else { return nil }
            let rest = Array(pathSegments.dropFirst())
            switch root {
            case "b", "business":
                if let slug = rest.first { return .business(slug: slug) }
            case "c", "category":
                if let id = rest.first { return .category(id: id) }
            case "a", "area":
                if let id = rest.first { return .area(id: id) }
            case "collection":
                if let id = rest.first { return .collection(id: id) }
            default:
                break
            }
        }

        return nil
    }
}
