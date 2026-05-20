import Foundation
import Observation
import UIKit

/// Reactions store. Local-first by design — every reaction lives in
/// UserDefaults so the feature works fully offline and on cold install
/// without a backend. When a Supabase anon key is configured (see
/// `AppConstants.supabaseAnonKey`), local changes also sync to a
/// `business_reactions` table and aggregate counts are fetched per business.
///
/// Three reaction kinds — `.heart`, `.fire`, `.thumbs`. Each user can tap
/// any combination on any business (they're not mutually exclusive). Counts
/// shown on the detail page are global aggregates pulled from Supabase
/// when available, falling back to the user's own count otherwise.
@Observable
final class ReactionsService {

    enum Reaction: String, CaseIterable, Codable, Identifiable {
        case heart, fire, thumbs

        var id: String { rawValue }

        var symbol: String {
            switch self {
            case .heart:  return "heart.fill"
            case .fire:   return "flame.fill"
            case .thumbs: return "hand.thumbsup.fill"
            }
        }

        var tint: String {
            switch self {
            case .heart:  return "pink"
            case .fire:   return "orange"
            case .thumbs: return "mint"
            }
        }
    }

    /// Aggregate counts for a single business, indexed by reaction.
    struct Counts: Codable, Hashable {
        var heart: Int = 0
        var fire: Int = 0
        var thumbs: Int = 0

        func value(for reaction: Reaction) -> Int {
            switch reaction {
            case .heart:  return heart
            case .fire:   return fire
            case .thumbs: return thumbs
            }
        }
    }

    // MARK: - Observable state

    /// User's own reactions per businessId. Read this for "is the heart filled?".
    private(set) var myReactions: [String: Set<Reaction>] = [:]
    /// Aggregate counts per businessId, populated when the backend is reachable.
    private(set) var counts: [String: Counts] = [:]

    // MARK: - Internals

    private static let myReactionsKey = "ri.reactions.mine.v1"
    private static let countsCacheKey = "ri.reactions.counts.v1"
    private let deviceID: String
    private var inflightFetches: Set<String> = []

    // MARK: - Lifecycle

    init() {
        self.deviceID = Self.stableDeviceID()
        loadFromDisk()
        print("[ReactionsService] anon key configured: \(!AppConstants.supabaseAnonKey.isEmpty)")
    }

    // MARK: - Public API

    func reactions(for businessId: String) -> Set<Reaction> {
        myReactions[businessId] ?? []
    }

    func count(for businessId: String, reaction: Reaction) -> Int {
        // Prefer backend aggregate; if missing, fall back to "1 if I reacted else 0".
        if let counts = counts[businessId] {
            return counts.value(for: reaction)
        }
        return reactions(for: businessId).contains(reaction) ? 1 : 0
    }

    /// Toggle a reaction. Updates local state immediately (optimistic UI),
    /// persists to disk, and fires a best-effort sync to Supabase. Sync
    /// failures don't roll back — the user's reaction stays locally.
    func toggle(_ reaction: Reaction, on businessId: String) {
        var current = myReactions[businessId] ?? []
        let nowOn: Bool
        if current.contains(reaction) {
            current.remove(reaction)
            nowOn = false
        } else {
            current.insert(reaction)
            nowOn = true
        }
        myReactions[businessId] = current.isEmpty ? nil : current

        // Optimistic local count update so the UI feels live.
        var c = counts[businessId] ?? Counts()
        switch reaction {
        case .heart:  c.heart  = max(0, c.heart  + (nowOn ? 1 : -1))
        case .fire:   c.fire   = max(0, c.fire   + (nowOn ? 1 : -1))
        case .thumbs: c.thumbs = max(0, c.thumbs + (nowOn ? 1 : -1))
        }
        counts[businessId] = c

        persistMyReactions()
        persistCounts()

        Analytics.track(.businessFavorited(id: businessId, isFavorite: nowOn))

        Task { await syncToBackend(businessId: businessId) }
    }

    /// Fetch aggregate counts for one business. Called from BusinessDetailView
    /// on appear so the counts a user sees are global, not just theirs.
    /// No-ops when no anon key is configured.
    func refreshCounts(for businessId: String) {
        guard !AppConstants.supabaseAnonKey.isEmpty else { return }
        guard !inflightFetches.contains(businessId) else { return }
        inflightFetches.insert(businessId)
        Task {
            defer {
                Task { @MainActor in self.inflightFetches.remove(businessId) }
            }
            await fetchCounts(for: businessId)
        }
    }

    /// Pre-fetch counts for several businesses in one round-trip.
    /// Useful for list views that show small reaction badges.
    func refreshCounts(for businessIds: [String]) {
        guard !AppConstants.supabaseAnonKey.isEmpty, !businessIds.isEmpty else { return }
        Task { await fetchBatchCounts(for: businessIds) }
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: Self.myReactionsKey),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            myReactions = decoded.compactMapValues { strings in
                let set = Set(strings.compactMap { Reaction(rawValue: $0) })
                return set.isEmpty ? nil : set
            }
        }
        if let data = defaults.data(forKey: Self.countsCacheKey),
           let decoded = try? JSONDecoder().decode([String: Counts].self, from: data) {
            counts = decoded
        }
    }

    private func persistMyReactions() {
        let serializable = myReactions.mapValues { Array($0.map(\.rawValue)) }
        if let data = try? JSONEncoder().encode(serializable) {
            UserDefaults.standard.set(data, forKey: Self.myReactionsKey)
        }
    }

    private func persistCounts() {
        if let data = try? JSONEncoder().encode(counts) {
            UserDefaults.standard.set(data, forKey: Self.countsCacheKey)
        }
    }

    // MARK: - Networking

    /// Stable per-install token. Reset on reinstall, which matches what we
    /// want — a fresh install is a fresh "voter."
    private static func stableDeviceID() -> String {
        let stored = UserDefaults.standard.string(forKey: "ri.reactions.deviceId")
        if let stored, !stored.isEmpty { return stored }
        let new = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(new, forKey: "ri.reactions.deviceId")
        return new
    }

    private func syncToBackend(businessId: String) async {
        guard !AppConstants.supabaseAnonKey.isEmpty else { return }
        let reactions = (myReactions[businessId] ?? []).map(\.rawValue).sorted()

        guard let url = URL(string: "\(AppConstants.supabaseRESTBaseURL)/rpc/set_reactions") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConstants.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(AppConstants.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "p_business_id": businessId,
            "p_device_id": deviceID,
            "p_reactions": reactions
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                AppLog.network.debug("Reaction sync status \(http.statusCode, privacy: .public) for \(businessId, privacy: .public)")
                return
            }
            // After a successful sync, pull the latest aggregate so the user
            // sees the bumped count from the server, not just the optimistic one.
            await fetchCounts(for: businessId)
        } catch {
            AppLog.network.debug("Reaction sync failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func fetchCounts(for businessId: String) async {
        guard let url = URL(string: "\(AppConstants.supabaseRESTBaseURL)/business_reaction_counts?business_id=eq.\(businessId)&select=*") else { return }
        var request = URLRequest(url: url)
        request.setValue(AppConstants.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(AppConstants.supabaseAnonKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
            let rows = try JSONDecoder().decode([RemoteCountsRow].self, from: data)
            await MainActor.run {
                if let row = rows.first {
                    self.counts[businessId] = Counts(
                        heart: row.heart_count ?? 0,
                        fire: row.fire_count ?? 0,
                        thumbs: row.thumbs_count ?? 0
                    )
                    self.persistCounts()
                }
            }
        } catch {
            AppLog.network.debug("Fetch counts failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func fetchBatchCounts(for businessIds: [String]) async {
        let idList = businessIds.joined(separator: ",")
        guard let url = URL(string: "\(AppConstants.supabaseRESTBaseURL)/business_reaction_counts?business_id=in.(\(idList))&select=*") else { return }
        var request = URLRequest(url: url)
        request.setValue(AppConstants.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(AppConstants.supabaseAnonKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
            let rows = try JSONDecoder().decode([RemoteCountsRow].self, from: data)
            await MainActor.run {
                for row in rows {
                    self.counts[row.business_id] = Counts(
                        heart: row.heart_count ?? 0,
                        fire: row.fire_count ?? 0,
                        thumbs: row.thumbs_count ?? 0
                    )
                }
                self.persistCounts()
            }
        } catch {
            AppLog.network.debug("Fetch batch counts failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private struct RemoteCountsRow: Decodable {
        let business_id: String
        let heart_count: Int?
        let fire_count: Int?
        let thumbs_count: Int?
    }
}
