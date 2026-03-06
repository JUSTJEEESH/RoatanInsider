import SwiftUI
import MapKit

@Observable
final class MapViewModel {
    var selectedCategory: Category?
    var selectedBusiness: Business?
    var searchQuery = ""
    var isSearching = false
    var cameraPosition: MapCameraPosition = .region(roatanRegion)

    private static let roatanRegion = MKCoordinateRegion(
        center: AppConstants.roatanCenter,
        span: MKCoordinateSpan(
            latitudeDelta: AppConstants.roatanSpanLat,
            longitudeDelta: AppConstants.roatanSpanLon
        )
    )

    // MARK: - Filtered Businesses

    func filteredBusinesses(from businesses: [Business]) -> [Business] {
        let active = businesses.filter { $0.isActive }

        var results = active

        // Apply text search
        if !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            let query = searchQuery.lowercased()
            results = results.filter {
                $0.name.lowercased().contains(query) ||
                $0.description.lowercased().contains(query) ||
                $0.subcategory.lowercased().contains(query) ||
                $0.category.displayName.lowercased().contains(query) ||
                $0.area.displayName.lowercased().contains(query) ||
                $0.features.contains { $0.lowercased().contains(query) }
            }
        }

        // Apply category filter
        if let cat = selectedCategory {
            results = results.filter { $0.category == cat }
        }

        return results
    }

    // MARK: - Actions

    func selectCategory(_ category: Category?) {
        selectedCategory = category
        selectedBusiness = nil
    }

    func submitSearch() {
        selectedBusiness = nil
        // filteredBusinesses will handle the actual filtering
    }

    func clearSearch() {
        searchQuery = ""
        selectedBusiness = nil
    }

    func focusOnBusiness(_ business: Business) {
        selectedBusiness = business
        cameraPosition = .region(MKCoordinateRegion(
            center: business.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
}
