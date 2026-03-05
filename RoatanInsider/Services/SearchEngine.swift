import Foundation
import CoreLocation

@Observable
final class SearchEngine {
    var searchText: String = ""
    var selectedCategories: Set<Category> = []
    var selectedAreas: Set<Area> = []
    var selectedPriceRanges: Set<Int> = []
    var selectedFeatures: Set<String> = []
    var showOpenNow: Bool = false
    var sortOption: SortOption = .featured

    enum SortOption: String, CaseIterable {
        case featured = "Featured"
        case nameAZ = "Name A-Z"
        case distance = "Distance"
    }

    var hasActiveFilters: Bool {
        !searchText.isEmpty ||
        !selectedCategories.isEmpty ||
        !selectedAreas.isEmpty ||
        !selectedPriceRanges.isEmpty ||
        !selectedFeatures.isEmpty ||
        showOpenNow
    }

    func clearFilters() {
        searchText = ""
        selectedCategories = []
        selectedAreas = []
        selectedPriceRanges = []
        selectedFeatures = []
        showOpenNow = false
        sortOption = .featured
    }

    func filter(_ businesses: [Business], userLocation: CLLocation? = nil) -> [Business] {
        var results = businesses.filter { $0.isActive }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            results = results.filter {
                $0.name.lowercased().contains(query) ||
                $0.description.lowercased().contains(query) ||
                $0.subcategory.lowercased().contains(query) ||
                $0.area.displayName.lowercased().contains(query) ||
                $0.features.contains { $0.lowercased().contains(query) }
            }
        }

        if !selectedCategories.isEmpty {
            results = results.filter { selectedCategories.contains($0.category) }
        }

        if !selectedAreas.isEmpty {
            results = results.filter { selectedAreas.contains($0.area) }
        }

        if !selectedPriceRanges.isEmpty {
            results = results.filter { selectedPriceRanges.contains($0.priceRange) }
        }

        if !selectedFeatures.isEmpty {
            results = results.filter { business in
                selectedFeatures.isSubset(of: Set(business.features))
            }
        }

        if showOpenNow {
            results = results.filter { $0.isOpenNow() }
        }

        switch sortOption {
        case .featured:
            results.sort { ($0.isFeatured ? 0 : 1) < ($1.isFeatured ? 0 : 1) }
        case .nameAZ:
            results.sort { $0.name < $1.name }
        case .distance:
            if let location = userLocation {
                results.sort {
                    let d0 = location.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude))
                    let d1 = location.distance(from: CLLocation(latitude: $1.latitude, longitude: $1.longitude))
                    return d0 < d1
                }
            }
        }

        return results
    }

    static func allFeatures(from businesses: [Business]) -> [String] {
        let allFeatures = businesses.flatMap { $0.features }
        let unique = Set(allFeatures)
        return unique.sorted()
    }
}
