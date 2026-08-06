import SwiftUI
import MapKit

/// The map's state.
///
/// It used to show Apple Maps results whenever it could reach the network,
/// and the app's own 94 places only when offline — so the guide's curation,
/// the entire reason this app exists, appeared exclusively when the phone
/// had no signal. Tapping "Eat" ran an Apple Maps search for "restaurants"
/// rather than filtering the twenty-three places written up in the guide,
/// and with no search running at all the map rendered nothing.
///
/// Now the directory is the map, always. Apple's results are a supplement
/// for one specific case — a text search that finds nothing in the guide,
/// like a pharmacy — and they're drawn differently and labelled so nobody
/// mistakes them for a recommendation.
@Observable
final class MapViewModel {
    enum Layer: String, CaseIterable, Identifiable {
        case places, diveSites
        var id: String { rawValue }
        var title: String { self == .places ? "Places" : "Dive sites" }
    }

    var layer: Layer = .places
    var selectedCategory: String?
    var selectedBusiness: Business?
    var selectedDiveSite: DiveSite?
    var selectedMapItem: MKMapItem?
    var searchQuery = ""
    var searchResults: [MKMapItem] = []
    var isSearching = false
    var cameraPosition: MapCameraPosition = .region(roatanRegion)
    var visibleSpan: MKCoordinateSpan = roatanRegion.span
    var visibleRegion: MKCoordinateRegion = roatanRegion

    private var currentSearchTask: Task<Void, Never>?

    static let roatanRegion = MKCoordinateRegion(
        center: AppConstants.roatanCenter,
        span: MKCoordinateSpan(
            latitudeDelta: AppConstants.roatanSpanLat,
            longitudeDelta: AppConstants.roatanSpanLon
        )
    )

    var hasQuery: Bool {
        !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func zoom(to region: MKCoordinateRegion) {
        cameraPosition = .region(region)
    }

    func clearSelection() {
        selectedBusiness = nil
        selectedDiveSite = nil
        selectedMapItem = nil
    }

    // MARK: - The directory, which is the point

    /// Category filter and text search both run against the guide. Nothing
    /// here touches the network.
    func filteredBusinesses(from businesses: [Business]) -> [Business] {
        var result = businesses.filter { $0.isActive }
        if let catId = selectedCategory {
            result = result.filter { $0.hasCategory(catId) }
        }
        let query = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter { $0.searchHaystack.contains(query) }
        }
        return result
    }

    func filteredDiveSites(from sites: [DiveSite]) -> [DiveSite] {
        let query = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return sites }
        return sites.filter {
            $0.name.lowercased().contains(query) || $0.areaDisplayName.lowercased().contains(query)
        }
    }

    /// How many of the given coordinates are inside the current viewport.
    /// Drives the "N places in view" button, which is how someone pans to
    /// French Harbour and gets a list of what's actually there.
    func countInView<T>(_ items: [T], coordinate: (T) -> CLLocationCoordinate2D) -> Int {
        items.reduce(into: 0) { total, item in
            if Self.region(visibleRegion, contains: coordinate(item)) { total += 1 }
        }
    }

    func itemsInView<T>(_ items: [T], coordinate: (T) -> CLLocationCoordinate2D) -> [T] {
        items.filter { Self.region(visibleRegion, contains: coordinate($0)) }
    }

    private static func region(_ region: MKCoordinateRegion, contains point: CLLocationCoordinate2D) -> Bool {
        let latDelta = abs(point.latitude - region.center.latitude)
        let lonDelta = abs(point.longitude - region.center.longitude)
        return latDelta <= region.span.latitudeDelta / 2
            && lonDelta <= region.span.longitudeDelta / 2
    }

    // MARK: - Category selection

    /// Filters the guide. It used to fire an Apple Maps search instead,
    /// which is how "Eat" came to mean "whatever Apple thinks is a
    /// restaurant near here".
    func selectCategory(_ categoryId: String?) {
        selectedCategory = selectedCategory == categoryId ? nil : categoryId
        clearSelection()
        clearSearchResults()
    }

    // MARK: - Text search

    /// Searches the guide immediately. Apple is consulted only if the guide
    /// has nothing — someone looking for a pharmacy or a bank deserves an
    /// answer, it just isn't a recommendation.
    func submitSearch(directoryMatches: Int) {
        clearSelection()
        guard hasQuery else {
            clearSearch()
            return
        }
        guard directoryMatches == 0 else {
            clearSearchResults()
            return
        }
        search(for: searchQuery)
    }

    func clearSearch() {
        currentSearchTask?.cancel()
        searchResults = []
        searchQuery = ""
        isSearching = false
        clearSelection()
        selectedCategory = nil
    }

    private func clearSearchResults() {
        currentSearchTask?.cancel()
        searchResults = []
        isSearching = false
        selectedMapItem = nil
    }

    private func search(for query: String) {
        isSearching = true
        currentSearchTask?.cancel()
        currentSearchTask = Task {
            let results = await performSearch(query: query)
            if Task.isCancelled { return }
            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }

    private func performSearch(query: String) async -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = Self.roatanRegion

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            return response.mapItems
        } catch {
            return []
        }
    }
}
