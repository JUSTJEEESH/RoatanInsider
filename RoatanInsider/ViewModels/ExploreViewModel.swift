import Foundation
import CoreLocation

@Observable
final class ExploreViewModel {
    var searchEngine = SearchEngine()
    var showingFilters = false

    /// `userLocation` has to be threaded through for the distance sort to do
    /// anything. It wasn't, so selecting "Distance" left the list exactly as
    /// it found it — the sort was dead code twice over, since no UI offered
    /// the choice either.
    func filteredBusinesses(
        from businesses: [Business],
        userLocation: CLLocation? = nil
    ) -> [Business] {
        searchEngine.filter(businesses, userLocation: userLocation)
    }
}
