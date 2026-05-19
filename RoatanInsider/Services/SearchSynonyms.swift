import Foundation

/// Curated synonym map for Roatán-specific search. When the user types one term,
/// we silently expand the query to include the others so a "scuba" search still
/// finds dive shops, "ceviche" finds seafood spots, "spanish" finds language
/// resources, and a misspelled "snorkle" matches "snorkel".
///
/// Keys are normalised lowercase tokens. Order doesn't matter; matching is
/// symmetric: if "scuba" expands to "dive", searching "dive" will also expand
/// to "scuba" via the inverse table built at init.
enum SearchSynonyms {

    /// Tokens that should imply the same search intent.
    /// Add liberally — false positives are cheap; missing a match is expensive.
    private static let groups: [[String]] = [
        // Diving / snorkeling
        ["dive", "diving", "scuba", "padi", "ssi", "wreck"],
        ["snorkel", "snorkeling", "snorkle", "snorkling", "reef"],
        ["dive shop", "scuba shop", "dive school"],

        // Food
        ["baleada", "baleadas", "honduran food", "honduran"],
        ["seafood", "fish", "lobster", "shrimp", "ceviche", "catch of the day"],
        ["bbq", "barbeque", "barbecue", "grill", "grilled"],
        ["coffee", "cafe", "café", "espresso", "breakfast"],
        ["vegan", "vegetarian", "plant based", "plant-based"],
        ["pizza", "pizzeria", "italian"],
        ["burger", "burgers", "hamburger"],
        ["taco", "tacos", "mexican"],

        // Drinks
        ["bar", "bars", "drinks", "cocktail", "cocktails", "happy hour"],
        ["beer", "cerveza", "craft beer", "salva vida", "imperial"],
        ["wine", "vino"],
        ["smoothie", "juice", "fresh juice", "licuado"],

        // Beaches / water
        ["beach", "beaches", "playa", "sand"],
        ["sunset", "sundowner", "sundowners", "golden hour"],
        ["swim", "swimming", "water"],
        ["paddleboard", "sup", "paddle board", "stand up paddle"],
        ["kayak", "kayaking"],
        ["surf", "surfing", "waves"],
        ["fishing", "deep sea", "sport fishing", "fish charter"],

        // Tours / activities
        ["tour", "tours", "excursion", "excursions", "activity", "activities"],
        ["zipline", "zip line", "canopy", "adventure"],
        ["horseback", "horse riding", "horses"],
        ["yoga", "wellness", "meditation", "retreat"],
        ["spa", "massage", "wellness"],
        ["jungle", "rainforest", "nature", "iguana", "monkey"],

        // Shopping / services
        ["shopping", "shop", "boutique", "store", "souvenir", "souvenirs", "gift", "gifts"],
        ["grocery", "groceries", "supermarket", "eldon", "eldons"],
        ["pharmacy", "drugstore", "farmacia", "medicine"],
        ["atm", "bank", "cash", "money"],
        ["laundry", "wash", "lavanderia"],

        // Lodging
        ["hotel", "stay", "lodging", "accommodation"],
        ["airbnb", "rental", "apartment", "condo", "villa"],
        ["resort", "all inclusive", "all-inclusive"],

        // Transport
        ["taxi", "cab", "ride", "uber"],
        ["rental", "car rental", "car hire", "scooter", "moped", "atv"],
        ["water taxi", "ferry", "boat shuttle"],

        // Geo / context
        ["west bay", "westbay", "west-bay"],
        ["west end", "westend", "west-end"],
        ["coxen hole", "coxen", "coxen-hole"],
        ["french harbour", "french harbor", "frenchharbor", "frenchharbour"],
        ["sandy bay", "sandybay"],

        // Language / culture
        ["spanish", "español", "espanol", "language", "phrases", "translate"],
        ["english", "ingles"],

        // Family / accessibility
        ["family", "kids", "kid friendly", "kid-friendly", "children"],
        ["accessible", "wheelchair", "disabled"],
        ["pet", "dog", "pets", "dog friendly", "dog-friendly"],

        // Money / planning
        ["currency", "exchange", "convert", "lempira", "lempiras", "hnl", "dollar", "usd"],
        ["tip", "tipping", "gratuity"],
    ]

    /// Pre-computed: token -> set of equivalent tokens (including itself).
    private static let index: [String: Set<String>] = {
        var map: [String: Set<String>] = [:]
        for group in groups {
            let set = Set(group.map { $0.normalisedForSearch })
            for term in set {
                map[term, default: []].formUnion(set)
            }
        }
        return map
    }()

    /// Expand a user query into a normalised set of search tokens.
    ///
    /// For "scuba shops in West Bay" returns the original tokens plus their
    /// synonyms. Falls back to just the normalised input if no synonyms match.
    static func expand(_ query: String) -> [String] {
        let normalised = query.normalisedForSearch
        guard !normalised.isEmpty else { return [] }

        var tokens = Set<String>()
        tokens.insert(normalised)

        // Try the full string first (handles multi-word synonyms like "happy hour").
        if let synonyms = index[normalised] {
            tokens.formUnion(synonyms)
        }

        // Then per-word.
        for word in normalised.split(separator: " ") {
            let key = String(word)
            tokens.insert(key)
            if let synonyms = index[key] {
                tokens.formUnion(synonyms)
            }
        }

        return Array(tokens)
    }
}

extension String {
    /// Lowercase + diacritic-folded. "Mañana" -> "manana", "Café" -> "cafe".
    /// Use this everywhere user input or business text is compared.
    var normalisedForSearch: String {
        self
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
