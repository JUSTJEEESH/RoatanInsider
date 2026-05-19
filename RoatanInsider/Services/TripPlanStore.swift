import Foundation
import Observation

/// Persisted Trip Plan store. Holds at most one active plan keyed on the
/// user's current trip dates from UserProfile. Resets the plan when those
/// dates change.
@Observable
final class TripPlanStore {
    private static let key = "ri.tripPlan.v1"

    private(set) var plan: TripPlan?

    init() {
        load()
    }

    // MARK: - Lifecycle

    /// Sync the plan to the user's current arrival/departure dates. Creates
    /// an empty plan if none exists, replaces the plan if dates changed.
    /// Preserves itemsByDate entries that still fall inside the new range.
    func sync(with profile: UserProfile) {
        guard let arrival = profile.arrivalDate, let departure = profile.departureDate else {
            plan = nil
            persist()
            return
        }

        if let existing = plan, existing.arrivalDate == arrival, existing.departureDate == departure {
            return
        }

        var preserved: [String: [String]] = [:]
        if let existing = plan {
            let validKeys = Set(makeDateKeys(from: arrival, to: departure))
            for (key, ids) in existing.itemsByDate where validKeys.contains(key) {
                preserved[key] = ids
            }
        }

        plan = TripPlan(
            arrivalDate: arrival,
            departureDate: departure,
            itemsByDate: preserved,
            lastGenerated: nil
        )
        persist()
    }

    // MARK: - Mutations

    func addItem(_ businessId: String, to dateKey: String) {
        guard plan != nil else { return }
        var items = plan!.itemsByDate[dateKey] ?? []
        guard !items.contains(businessId) else { return }
        items.append(businessId)
        plan!.itemsByDate[dateKey] = items
        persist()
    }

    func removeItem(_ businessId: String, from dateKey: String) {
        guard plan != nil else { return }
        plan!.itemsByDate[dateKey] = (plan!.itemsByDate[dateKey] ?? []).filter { $0 != businessId }
        if plan!.itemsByDate[dateKey]?.isEmpty == true {
            plan!.itemsByDate.removeValue(forKey: dateKey)
        }
        persist()
    }

    func setItems(_ ids: [String], for dateKey: String) {
        guard plan != nil else { return }
        plan!.itemsByDate[dateKey] = ids
        persist()
    }

    /// Replace the entire schedule (used by the itinerary generator).
    func replaceSchedule(_ schedule: [String: [String]]) {
        guard plan != nil else { return }
        plan!.itemsByDate = schedule
        plan!.lastGenerated = .now
        persist()
    }

    func clear() {
        guard plan != nil else { return }
        plan!.itemsByDate = [:]
        plan!.lastGenerated = nil
        persist()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.key),
              let decoded = try? JSONDecoder().decode(TripPlan.self, from: data) else { return }
        plan = decoded
    }

    private func persist() {
        if let plan {
            if let data = try? JSONEncoder().encode(plan) {
                UserDefaults.standard.set(data, forKey: Self.key)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: Self.key)
        }
    }

    private func makeDateKeys(from start: Date, to end: Date) -> [String] {
        var result: [String] = []
        let cal = Calendar.current
        var cursor = cal.startOfDay(for: start)
        let endDay = cal.startOfDay(for: end)
        while cursor <= endDay {
            result.append(TripPlan.dateKey(for: cursor))
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }
}
