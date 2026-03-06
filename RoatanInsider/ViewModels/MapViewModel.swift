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

    private static let roatanRegion = MKCoordinateRegion(
        center: AppConstants.roatanCenter,
        span: MKCoordinateSpan(
            latitudeDelta: AppConstants.roatanSpanLat,
            longitudeDelta: AppConstants.roatanSpanLon
        )
    )

    var isShowingAppleResults: Bool {
        !searchResults.isEmpty
    }

    // MARK: - Fallback: our bundled pins

    func filteredBusinesses(from businesses: [Business]) -> [Business] {
        let active = businesses.filter { $0.isActive }
        if let cat = selectedCategory {
            return active.filter { $0.category == cat }
        }
        return active
    }

    // MARK: - Apple Maps Search

    func selectCategory(_ category: Category?) {
        selectedCategory = category
        selectedMapItem = nil
        selectedBusiness = nil

        if let category {
            searchWithCategory(category)
        } else {
            clearSearch()
        }
    }

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
    }

    func searchForBusiness(_ business: Business) {
        selectedBusiness = business
        selectedMapItem = nil
        search(for: business.name) { [weak self] results in
            guard let self else { return }
            if let match = results.first {
                self.selectedMapItem = match
                if let coord = match.placemark.location?.coordinate {
                    self.cameraPosition = .region(MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            } else {
                // Fallback to our bundled coordinates
                self.cameraPosition = .region(MKCoordinateRegion(
                    center: business.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
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

    private func search(for query: String, completion: (([MKMapItem]) -> Void)? = nil) {
        isSearching = true
        currentSearchTask?.cancel()
        currentSearchTask = Task {
            let results = await performSearch(query: query + " Roatán")
            if Task.isCancelled { return }
            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
                completion?(results)
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
