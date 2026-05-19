import Foundation

/// Deterministic, on-device itinerary builder. v1 — no LLM. Picks places
/// that match the user's interests, distributes them across the available
/// days, and groups by area per day so people aren't crisscrossing the
/// island for dinner.
///
/// Roadmap (Insider+ v2): pipe interests + dates + saved favorites into
/// Claude via a backend Supabase Edge Function. The function signs the
/// request with a server-side API key; the client never sees the key.
/// Same `generate(...)` signature, swappable backend.
enum TripItineraryGenerator {

    struct Input {
        let plan: TripPlan
        let profile: UserProfile
        let allBusinesses: [Business]
        let favoriteIds: Set<String>
    }

    static let itemsPerDayTarget = 5

    /// Build a fresh schedule. Returns a date-key → [businessId] dict ready
    /// for `TripPlanStore.replaceSchedule(_:)`.
    static func generate(_ input: Input) -> [String: [String]] {
        let days = input.plan.days
        guard !days.isEmpty else { return [:] }

        let interests = input.profile.interests
        let totalWanted = days.count * itemsPerDayTarget

        // Candidate pool: ranked by relevance to the user. Favorites first,
        // then businesses matching interests, then quality.
        let candidates = rankCandidates(
            businesses: input.allBusinesses,
            interests: interests,
            favoriteIds: input.favoriteIds,
            limit: totalWanted * 2
        )

        guard !candidates.isEmpty else { return [:] }

        // Group candidates by area so we can keep each day geographically
        // coherent.
        let byArea: [String: [Business]] = Dictionary(grouping: candidates) { $0.area }
        let areas = byArea.keys.sorted { (byArea[$0]?.count ?? 0) > (byArea[$1]?.count ?? 0) }

        var schedule: [String: [String]] = [:]
        var areaIndex = 0
        var usedIds = Set<String>()

        for day in days {
            // Rotate through areas so each day gets a different vibe.
            let area = areas.isEmpty ? "west_bay" : areas[areaIndex % areas.count]
            areaIndex += 1

            let areaPool = (byArea[area] ?? []).filter { !usedIds.contains($0.id) }
            let crossAreaPool = candidates.filter { !usedIds.contains($0.id) }
            let pool = areaPool.isEmpty ? crossAreaPool : (areaPool + crossAreaPool.prefix(2))

            let picks = scheduleDay(from: pool, target: itemsPerDayTarget, isFirstDay: day.dayNumber == 1, isLastDay: day == days.last)
            schedule[day.dateKey] = picks.map(\.id)
            for p in picks { usedIds.insert(p.id) }
        }

        return schedule
    }

    // MARK: - Internals

    /// Rank candidates by interest match, favorite status, featured/insider
    /// flags, and rating.
    private static func rankCandidates(
        businesses: [Business],
        interests: Set<Interest>,
        favoriteIds: Set<String>,
        limit: Int
    ) -> [Business] {
        let scored: [(Business, Double)] = businesses.compactMap { b in
            guard b.isActive else { return nil }

            var score: Double = 0
            // Strongest signal: user already loves it.
            if favoriteIds.contains(b.id) { score += 100 }
            if b.isFeatured { score += 20 }
            if b.isInsiderPick { score += 15 }
            if b.isBestOf { score += 8 }
            if let rating = b.rating { score += rating * 2 }

            // Interest matching.
            let matchedInterests = interests.filter { interestMatches(b, $0) }.count
            score += Double(matchedInterests) * 10

            // Don't include places with no interest overlap unless they're
            // featured (e.g. essential beaches).
            if matchedInterests == 0 && !b.isFeatured && !b.isInsiderPick {
                return nil
            }

            return (b, score)
        }

        return scored
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }

    private static func interestMatches(_ business: Business, _ interest: Interest) -> Bool {
        let cat = business.category
        switch interest {
        case .eat:         return cat == "eat" || business.features.contains(where: { $0.localizedCaseInsensitiveContains("food") })
        case .drink:       return cat == "drink"
        case .dive:        return cat == "dive"
        case .snorkel:     return business.features.contains(where: { $0.localizedCaseInsensitiveContains("snorkel") }) || cat == "dive"
        case .beach:       return cat == "beaches" || business.features.contains(where: { $0.localizedCaseInsensitiveContains("beachfront") })
        case .nightlife:   return cat == "nightlife" || cat == "drink"
        case .family:      return business.features.contains(where: { $0.localizedCaseInsensitiveContains("family") }) || business.features.contains(where: { $0.localizedCaseInsensitiveContains("kid") })
        case .wellness:    return business.features.contains(where: { $0.localizedCaseInsensitiveContains("spa") }) || business.features.contains(where: { $0.localizedCaseInsensitiveContains("yoga") })
        case .photography: return business.features.contains(where: { $0.localizedCaseInsensitiveContains("view") }) || business.features.contains(where: { $0.localizedCaseInsensitiveContains("sunset") })
        case .history:     return business.features.contains(where: { $0.localizedCaseInsensitiveContains("history") }) || business.features.contains(where: { $0.localizedCaseInsensitiveContains("museum") })
        case .nature:      return cat == "tours" || business.features.contains(where: { $0.localizedCaseInsensitiveContains("nature") })
        case .shopping:    return cat == "shop"
        }
    }

    /// Pick a balanced ~5 items for one day from the candidate pool.
    /// Tries to surface food + an activity + a beach/view spot. First/last
    /// days are lighter.
    private static func scheduleDay(from pool: [Business], target: Int, isFirstDay: Bool, isLastDay: Bool) -> [Business] {
        guard !pool.isEmpty else { return [] }
        let count = (isFirstDay || isLastDay) ? max(2, target - 2) : target

        // Try to ensure mixed categories per day.
        var picks: [Business] = []
        var usedCategories: Set<String> = []

        // First pass: prefer one per top-level category.
        for biz in pool {
            if picks.count >= count { break }
            if !usedCategories.contains(biz.category) {
                picks.append(biz)
                usedCategories.insert(biz.category)
            }
        }

        // Second pass: fill remaining slots regardless of category overlap.
        for biz in pool where !picks.contains(where: { $0.id == biz.id }) {
            if picks.count >= count { break }
            picks.append(biz)
        }

        return picks
    }
}
