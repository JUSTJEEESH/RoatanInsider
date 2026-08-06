import Foundation

/// A published taxi fare between two points on Roatán.
///
/// This exists because "How do taxis work? Will I get ripped off?" is one of
/// the fifteen questions in Ask a Local, and prose is the wrong shape for
/// the answer. Nobody reads a paragraph standing at the roadside with a
/// driver waiting. A number is checkable in four seconds, which is roughly
/// how long that negotiation lasts.
///
/// Two fares per route, because Roatán has two systems and confusing them is
/// how visitors overpay: a *colectivo* is a shared taxi charging per person
/// along a fixed run, and a *private* (or "tourist") taxi is the whole car.
/// A driver quoting the private rate for what is really a colectivo seat is
/// the single most common way someone gets caught out here.
///
/// Either fare may be absent. A route with neither never renders — the app
/// would rather say nothing than guess, because a wrong number here costs
/// someone money and makes the app the liar.
struct TaxiFare: Identifiable, Codable, Hashable {
    let id: String
    let from: String
    let to: String
    /// USD per person in a shared taxi. The low end when a range is given.
    let colectivoUSD: Double?
    /// The top of the shared range, when the fare is quoted as one. Nil
    /// means the fare really is a single number, not that we rounded.
    let colectivoMaxUSD: Double?
    /// USD for the whole car. The low end when a range is given.
    let privateUSD: Double?
    let privateMaxUSD: Double?
    /// Anything that changes the number — "after dark", "per car up to 4".
    let note: String?

    private enum CodingKeys: String, CodingKey {
        case id, from, to, colectivoUSD, colectivoMaxUSD, privateUSD, privateMaxUSD, note
    }

    // Hand-written because the range fields were added after the file
    // shipped, and a synthesised decoder throws on a key that simply isn't
    // in an older copy rather than falling back to the property default.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        from = try c.decode(String.self, forKey: .from)
        to = try c.decode(String.self, forKey: .to)
        colectivoUSD = try? c.decodeIfPresent(Double.self, forKey: .colectivoUSD)
        colectivoMaxUSD = try? c.decodeIfPresent(Double.self, forKey: .colectivoMaxUSD)
        privateUSD = try? c.decodeIfPresent(Double.self, forKey: .privateUSD)
        privateMaxUSD = try? c.decodeIfPresent(Double.self, forKey: .privateMaxUSD)
        note = try? c.decodeIfPresent(String.self, forKey: .note)
    }

    var routeLabel: String { "\(from) → \(to)" }

    var hasAnyFare: Bool { colectivoUSD != nil || privateUSD != nil }

    static func formatted(_ amount: Double) -> String {
        amount == amount.rounded()
            ? "$\(Int(amount))"
            : String(format: "$%.2f", amount)
    }

    /// "$8" or "$8–12". Roatán fares are negotiated inside a band rather
    /// than fixed, so a single number would be a more precise claim than
    /// anyone can actually make — and precision is what a reader trusts.
    static func formattedRange(_ low: Double?, _ high: Double?) -> String? {
        guard let low else { return nil }
        guard let high, high > low else { return formatted(low) }
        let top = high == high.rounded() ? "\(Int(high))" : String(format: "%.2f", high)
        return "\(formatted(low))–\(top)"
    }

    var colectivoLabel: String? { Self.formattedRange(colectivoUSD, colectivoMaxUSD) }
    var privateLabel: String? { Self.formattedRange(privateUSD, privateMaxUSD) }
}

/// The fare card as published, plus the rules that apply to all of it.
struct TaxiFareGuide: Codable {
    /// Where these came from, shown to the reader. Fares change; naming the
    /// source is what lets someone judge how much to trust the number.
    let source: String
    let sourceURL: String?
    /// When the numbers were last checked, "yyyy-MM-dd".
    let updated: String
    /// Practical rules — agree before you get in, small bills, night rates.
    let rules: [String]
    let fares: [TaxiFare]

    /// Only routes we actually hold a fare for. An empty guide renders
    /// nothing at all rather than an empty table.
    var publishedFares: [TaxiFare] { fares.filter(\.hasAnyFare) }

    var updatedDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "America/Tegucigalpa")
        return formatter.date(from: updated)
    }

    /// Fares go out of date. Past this, the screen says so rather than
    /// presenting a two-year-old number as today's.
    var isStale: Bool {
        guard let updatedDate else { return true }
        return Date().timeIntervalSince(updatedDate) > 365 * 24 * 3600
    }

    static let empty = TaxiFareGuide(
        source: "", sourceURL: nil, updated: "", rules: [], fares: []
    )
}
