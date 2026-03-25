import SwiftUI
import MapKit

@Observable
final class MapViewModel {
    var selectedCategory: Category?
    var selectedBusiness: Business?
    var selectedMapItem: MKMapItem?
    var searchQuery = ""
    var searchResults: [MKMapItem] = []
    var isSearching = false
    var cameraPosition: MapCameraPosition = .region(roatanRegion)

    private var currentSearchTask: Task<Void, Never>?

    static let roatanRegion = MKCoordinateRegion(
        center: AppConstants.roatanCenter,
        span: MKCoordinateSpan(
            latitudeDelta: AppConstants.roatanSpanLat,
            longitudeDelta: AppConstants.roatanSpanLon
        )
    )

    var isShowingAppleResults: Bool {
        !searchResults.isEmpty
    }

    // MARK: - Offline fallback: bundled pins

    func filteredBusinesses(from businesses: [Business]) -> [Business] {
        let active = businesses.filter { $0.isActive }
        if let cat = selectedCategory {
            return active.filter { $0.hasCategory(cat) }
        }
        return active
    }

    // MARK: - Category selection

    func selectCategory(_ category: Category?) {
        selectedCategory = category
        selectedMapItem = nil
        selectedBusiness = nil

        if let category {
            searchWithCategory(category)
        } else {
            clearSearchResults()
        }
    }

    // MARK: - Text search

    func submitSearch() {
        selectedMapItem = nil
        selectedBusiness = nil
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            clearSearch()
            return
        }
        search(for: searchQuery)
    }

    func clearSearch() {
        currentSearchTask?.cancel()
        searchResults = []
        searchQuery = ""
        isSearching = false
        selectedMapItem = nil
        selectedCategory = nil
    }

    private func clearSearchResults() {
        currentSearchTask?.cancel()
        searchResults = []
        isSearching = false
        selectedMapItem = nil
    }

    // MARK: - Apple Maps search

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

    private func searchWithCategory(_ category: Category) {
        let terms = category.mapSearchTerms
        isSearching = true
        searchResults = []

        currentSearchTask?.cancel()
        currentSearchTask = Task {
            var allResults: [MKMapItem] = []
            for term in terms {
                if Task.isCancelled { return }
                let results = await performSearch(query: term)
                allResults.append(contentsOf: results)
            }
            if Task.isCancelled { return }
            var seen = Set<String>()
            let unique = allResults.filter { item in
                let name = item.name ?? ""
                if seen.contains(name) { return false }
                seen.insert(name)
                return true
            }
            await MainActor.run {
                self.searchResults = unique
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
