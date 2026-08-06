import Foundation
import Observation
import CoreLocation

/// Loads the dive site list and answers the questions a diver asks: what's
/// near me, what can I do on my certification, what can I reach from shore,
/// and who runs it.
///
/// Remote-first like everything else — the Edge pipeline can publish
/// `dive_sites.json` to the `app-data` bucket and the bundled copy is the
/// offline fallback. The file ships empty, and an empty list means the whole
/// feature hides rather than showing a bare screen.
@Observable
final class DiveSitesService {
    private(set) var sites: [DiveSite] = []
    private(set) var lastRefreshed: Date?

    /// Sites are editorial content that changes rarely, so this is far
    /// slacker than the events throttle.
    private static let refreshInterval: TimeInterval = 24 * 3600

    init() {
        load()
        Task { await refreshFromRemoteIfNeeded() }
    }

    /// Test seam: an explicit list, no disk and no network.
    init(sites: [DiveSite]) {
        self.sites = sites.filter(\.isActive)
    }

    private func load() {
        if let file: DiveSiteFile = RemoteDataService.loadCachedOrBundled(
            filename: "dive_sites.json", bundleName: "dive_sites", type: DiveSiteFile.self
        ) {
            sites = file.sites.filter(\.isActive)
        }
    }

    func refreshFromRemoteIfNeeded() async {
        if let fresh: DiveSiteFile = await RemoteDataService.fetchLatest(
            filename: "dive_sites.json",
            maxAge: Self.refreshInterval,
            type: DiveSiteFile.self
        ) {
            await MainActor.run {
                self.sites = fresh.sites.filter(\.isActive)
                self.lastRefreshed = .now
            }
        }
    }

    /// Nothing to show means the tab, the map layer and the shop links all
    /// disappear — no empty states advertising a feature with no content.
    var hasSites: Bool { !sites.isEmpty }

    // MARK: - Queries

    func sites(in area: String) -> [DiveSite] {
        sites.filter { $0.area == area }
    }

    func site(slug: String) -> DiveSite? {
        sites.first { $0.slug == slug }
    }

    /// Sites a given dive shop runs, by slug.
    func sites(runBy businessSlug: String) -> [DiveSite] {
        sites.filter { $0.operatorSlugs.contains(businessSlug) }
    }

    /// Shops that run a given site, resolved against the directory.
    func operators(for site: DiveSite, in businesses: [Business]) -> [Business] {
        let bySlug = Dictionary(businesses.map { ($0.slug, $0) }, uniquingKeysWith: { first, _ in first })
        return site.operatorSlugs.compactMap { bySlug[$0] }.filter(\.isActive)
    }

    /// Filtered and sorted for the list screen. Distance sorting only when
    /// we actually have a location; otherwise alphabetical, which is at
    /// least predictable.
    func filtered(
        kind: DiveSiteKind? = nil,
        level: DiveLevel? = nil,
        shoreOnly: Bool = false,
        near location: CLLocation? = nil
    ) -> [DiveSite] {
        var result = sites
        if let kind { result = result.filter { $0.kind == kind } }
        if let level { result = result.filter { $0.level == level } }
        if shoreOnly { result = result.filter { $0.shoreAccessible == true } }

        guard let location else {
            return result.sorted { $0.name < $1.name }
        }
        return result.sorted {
            location.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude))
                < location.distance(from: CLLocation(latitude: $1.latitude, longitude: $1.longitude))
        }
    }

    /// Only the kinds and levels actually present, so no filter chip ever
    /// returns nothing.
    var availableKinds: [DiveSiteKind] {
        let present = Set(sites.compactMap(\.kind))
        return DiveSiteKind.allCases.filter { present.contains($0) }
    }

    var availableLevels: [DiveLevel] {
        let present = Set(sites.compactMap(\.level))
        return DiveLevel.allCases.filter { present.contains($0) }
    }

    var hasShoreDives: Bool { sites.contains { $0.shoreAccessible == true } }
}

/// The file wrapper. `_README` and `_example` in the JSON are ignored by the
/// decoder, which is what lets the shipped file document itself.
struct DiveSiteFile: Decodable {
    let sites: [DiveSite]
}
