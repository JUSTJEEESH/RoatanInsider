import Foundation
import CoreLocation

@Observable
final class SearchEngine {
    var searchText: String = ""
    var selectedCategories: Set<String> = []
    var selectedAreas: Set<String> = []
    var selectedPriceRanges: Set<Int> = []
    var selectedFeatures: Set<String> = []
    var showOpenNow: Bool = false
    var sortOption: SortOption = .featured

    /// Sort choices. `distance` needs a user location; `requiresLocation`
    /// lets the UI hide it rather than offering a control that silently does
    /// nothing — which is exactly what it did before, since nothing ever
    /// passed a location in and no UI ever offered the choice.
    enum SortOption: String, CaseIterable, Identifiable {
        case featured = "Best first"
        case distance = "Nearest"
        case nameAZ = "A–Z"

        var id: String { rawValue }

        var requiresLocation: Bool { self == .distance }

        var symbol: String {
            switch self {
            case .featured: return "sparkles"
            case .distance: return "location"
            case .nameAZ:   return "textformat.abc"
            }
        }
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
            let tokens = SearchSynonyms.expand(searchText)
            if !tokens.isEmpty {
                results = results.filter { biz in
                    let haystack = biz.searchHaystack
                    return tokens.contains { token in haystack.contains(token) }
                }
            }
        }

        if !selectedCategories.isEmpty {
            results = results.filter { biz in
                selectedCategories.contains { catId in biz.hasCategory(catId) }
            }
        }

        if !selectedAreas.isEmpty {
            results = results.filter { biz in
                selectedAreas.contains { biz.isInArea($0) }
            }
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
            results.sort { lhs, rhs in
                let lhsTier = lhs.isFeatured ? 0 : (lhs.isInsiderPick ? 1 : 2)
                let rhsTier = rhs.isFeatured ? 0 : (rhs.isInsiderPick ? 1 : 2)
                if lhsTier != rhsTier { return lhsTier < rhsTier }
                let lhsRating = lhs.rating ?? 0
                let rhsRating = rhs.rating ?? 0
                if lhsRating != rhsRating { return lhsRating > rhsRating }
                let lhsReviews = lhs.reviewCount ?? 0
                let rhsReviews = rhs.reviewCount ?? 0
                return lhsReviews > rhsReviews
            }
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

    /// Feature tags worth offering as a filter, commonest first.
    ///
    /// The vocabulary has 123 distinct tags and 57 of them apply to exactly
    /// one business. A filter that returns a single result isn't a filter,
    /// it's a dead end — and a list of 123 chips is unscannable, so the rare
    /// ones were crowding out the useful ones. Tags below the threshold
    /// still show on the business page; they just aren't offered as a way to
    /// narrow a list.
    static func allFeatures(from businesses: [Business], minimumCoverage: Int = 4) -> [String] {
        var counts: [String: Int] = [:]
        for business in businesses where business.isActive {
            for feature in Set(business.features) {
                counts[feature, default: 0] += 1
            }
        }
        return counts
            .filter { $0.value >= minimumCoverage }
            .sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
            .map(\.key)
    }
}
