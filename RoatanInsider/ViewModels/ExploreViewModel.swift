import Foundation

@Observable
final class ExploreViewModel {
    var searchEngine = SearchEngine()
    var showingFilters = false

    func filteredBusinesses(from businesses: [Business]) -> [Business] {
        searchEngine.filter(businesses)
    }
}
