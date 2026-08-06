import Foundation
import Observation

/// Loads the bundled cruise ship arrival schedule and answers the
/// daily-utility question every user type cares about: who's in port
/// today, and how busy will the western beaches be? Future phases will
/// swap the bundled file for a live source (cruisecal.com scrape or a
/// maintained Supabase table).
@Observable
final class CruiseArrivalsService {
    private(set) var arrivals: [CruiseArrival] = []

    init() {
        load()
        Task { await refreshFromRemoteIfNeeded() }
    }

    /// Test seam — builds with a known schedule and performs no disk or
    /// network I/O, so freshness logic can be tested against fixed dates.
    init(arrivals: [CruiseArrival]) {
        self.arrivals = arrivals
    }

    private func load() {
        if let data: [CruiseArrival] = RemoteDataService.loadCachedOrBundled(
            filename: "cruise_arrivals.json",
            bundleName: "cruise_arrivals",
            type: [CruiseArrival].self
        ) {
            arrivals = data
        }
    }

    /// Pulls a fresh copy from Supabase Storage if our cache is >6h old.
    /// The Edge Function `scrape-cruise-arrivals` regenerates the file
    /// nightly from cruisetimetables.com.
    func refreshFromRemoteIfNeeded() async {
        if let fresh: [CruiseArrival] = await RemoteDataService.fetchLatest(
            filename: "cruise_arrivals.json",
            type: [CruiseArrival].self
        ) {
            await MainActor.run { self.arrivals = fresh }
        }
    }

    /// True when the loaded schedule can actually speak to today — its
    /// horizon reaches today or later. When the scraper has been failing
    /// long enough that every row is in the past, this goes false and the
    /// UI must NOT claim "no ships in port" (stale data saying "quiet day"
    /// while three ships are docked is worse than showing nothing).
    var hasCurrentData: Bool {
        guard let latest = arrivals.map(\.date).max() else { return false }
        return latest >= Self.dateString(daysFromNow: 0)
    }

    func arrivalsToday() -> [CruiseArrival] {
        arrivals.filter { $0.isToday }.sorted { $0.arrivalTime < $1.arrivalTime }
    }

    func arrivalsTomorrow() -> [CruiseArrival] {
        let tomorrow = Self.dateString(daysFromNow: 1)
        return arrivals
            .filter { $0.date == tomorrow }
            .sorted { $0.arrivalTime < $1.arrivalTime }
    }

    func upcomingArrivals(days: Int = 7) -> [CruiseArrival] {
        let today = Self.dateString(daysFromNow: 0)
        let horizon = Self.dateString(daysFromNow: days)
        return arrivals
            .filter { $0.date >= today && $0.date <= horizon }
            .sorted { ($0.date, $0.arrivalTime) < ($1.date, $1.arrivalTime) }
    }

    func totalPassengersToday() -> Int {
        arrivalsToday().reduce(0) { $0 + $1.passengerCount }
    }

    func totalPassengersTomorrow() -> Int {
        arrivalsTomorrow().reduce(0) { $0 + $1.passengerCount }
    }

    private static func dateString(daysFromNow days: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: -6 * 3600)
        return formatter.string(from: date)
    }
}
