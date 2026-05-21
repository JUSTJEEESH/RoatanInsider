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

    func arrivalsToday() -> [CruiseArrival] {
        arrivals.filter { $0.isToday }.sorted { $0.arrivalTime < $1.arrivalTime }
    }

    func upcomingArrivals(days: Int = 7) -> [CruiseArrival] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: -6 * 3600)
        let today = formatter.string(from: .now)
        guard let horizon = Calendar.current.date(byAdding: .day, value: days, to: .now) else {
            return []
        }
        let horizonStr = formatter.string(from: horizon)
        return arrivals
            .filter { $0.date >= today && $0.date <= horizonStr }
            .sorted { ($0.date, $0.arrivalTime) < ($1.date, $1.arrivalTime) }
    }

    func totalPassengersToday() -> Int {
        arrivalsToday().reduce(0) { $0 + $1.passengerCount }
    }
}
