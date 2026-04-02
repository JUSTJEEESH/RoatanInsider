import Foundation
import CoreLocation

@Observable
final class SearchEngine {
    var searchText: String = ""
    var selectedCategories: Set<Category> = []
    var selectedAreas: Set<String> = []
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
            results = results.filter { biz in
                biz.name.lowercased().contains(query) ||
                biz.description.lowercased().contains(query) ||
                biz.allCategories.contains { $0.subcategory.lowercased().contains(query) } ||
                biz.allAreaStrings.contains { $0.replacingOccurrences(of: "_", with: " ").lowercased().contains(query) } ||
                biz.features.contains { $0.lowercased().contains(query) }
            }
        }

        if !selectedCategories.isEmpty {
            results = results.filter { biz in
                selectedCategories.contains { biz.hasCategory($0) }
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

    static func allFeatures(from businesses: [Business]) -> [String] {
        let allFeatures = businesses.flatMap { $0.features }
        let unique = Set(allFeatures)
        return unique.sorted()
    }
}
