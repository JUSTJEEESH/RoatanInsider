import Foundation

/// Calls the `generate-itinerary` Supabase Edge Function — which calls
/// Claude Sonnet 4.6 server-side — to produce a day-by-day schedule that's
/// genuinely smart, not just rule-based.
///
/// The client never sees an Anthropic API key. The edge function holds it.
/// All the client sends is a ranked candidate pool + the user's interests
/// and dates. The edge function returns:
///   - `schedule`: dateKey → [businessId] (only IDs from the candidate set)
///   - `rationale`: a short blurb shown under the itinerary
///
/// Failure modes (all silently fall back to the local heuristic generator
/// in the caller — never block the user):
///   - No Supabase anon key configured → skip remote, generate locally
///   - Network error or 5xx → skip remote, generate locally
///   - Malformed response → skip remote, generate locally
enum RemoteItineraryService {

    struct Output {
        let schedule: [String: [String]]
        let rationale: String?
    }

    enum RemoteError: Error {
        case notConfigured
        case network(Error)
        case httpStatus(Int, body: String)
        case malformed
        case empty
    }

    /// Build the schedule via Claude. Throws on any failure so the caller
    /// can fall back to the on-device heuristic.
    static func generate(_ input: TripItineraryGenerator.Input) async throws -> Output {
        guard !AppConstants.supabaseAnonKey.isEmpty else {
            throw RemoteError.notConfigured
        }
        guard let url = URL(string: AppConstants.generateItineraryURL) else {
            throw RemoteError.notConfigured
        }

        // Candidate pre-filter: ask the local heuristic for its top-ranked
        // businesses for this user, then send only those to Claude. Keeps
        // the prompt small (each candidate is ~80 tokens) and tells Claude
        // what we already know is high-quality. Capped at 40 for the same
        // reason — past that, candidates are increasingly noisy.
        let candidates = TripItineraryGenerator.rankedCandidates(
            for: input,
            limit: 40
        )
        guard !candidates.isEmpty else { throw RemoteError.empty }

        let body = makeRequestBody(input: input, candidates: candidates)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConstants.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(AppConstants.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw RemoteError.network(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw RemoteError.malformed
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw RemoteError.httpStatus(http.statusCode, body: body)
        }

        struct RemoteResponse: Decodable {
            let schedule: [String: [String]]
            let rationale: String?
        }
        let decoded: RemoteResponse
        do {
            decoded = try JSONDecoder().decode(RemoteResponse.self, from: data)
        } catch {
            throw RemoteError.malformed
        }

        // Final safety check: every returned ID must be in our candidate set.
        // The edge function already filters, but defense in depth is cheap.
        let validIds = Set(candidates.map(\.id))
        var cleaned: [String: [String]] = [:]
        var seen = Set<String>()
        for day in input.plan.days {
            let ids = (decoded.schedule[day.dateKey] ?? []).filter { id in
                guard validIds.contains(id), !seen.contains(id) else { return false }
                seen.insert(id)
                return true
            }
            cleaned[day.dateKey] = ids
        }

        // If Claude returned an empty schedule for every day, treat that as
        // a soft failure — the caller will fall back to the local generator.
        let totalItems = cleaned.values.map(\.count).reduce(0, +)
        guard totalItems > 0 else { throw RemoteError.empty }

        return Output(
            schedule: cleaned,
            rationale: decoded.rationale?.isEmpty == false ? decoded.rationale : nil
        )
    }

    // MARK: - Body builder

    private static func makeRequestBody(
        input: TripItineraryGenerator.Input,
        candidates: [Business]
    ) -> [String: Any] {
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE"
        weekdayFormatter.locale = Locale(identifier: "en_US_POSIX")

        let days = input.plan.days.map { day in
            [
                "dayNumber": day.dayNumber,
                "dateKey": day.dateKey,
                "weekday": weekdayFormatter.string(from: day.date)
            ] as [String: Any]
        }

        let candidatePayload = candidates.map { biz -> [String: Any] in
            var dict: [String: Any] = [
                "id": biz.id,
                "name": biz.name,
                "category": biz.category,
                "area": biz.area,
                "features": Array(biz.features.prefix(6)),
                "priceRange": biz.priceRange,
                "isFavorite": input.favoriteIds.contains(biz.id),
                "isInsiderPick": biz.isInsiderPick
            ]
            if let rating = biz.rating { dict["rating"] = rating }
            return dict
        }

        return [
            "travelerType": input.profile.travelerType?.rawValue ?? "vacationer",
            "interests": input.profile.interests.map(\.rawValue).sorted(),
            "itemsPerDay": TripItineraryGenerator.itemsPerDayTarget,
            "days": days,
            "candidates": candidatePayload
        ]
    }
}
