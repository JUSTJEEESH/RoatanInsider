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
    /// USD per person in a shared taxi.
    let colectivoUSD: Double?
    /// USD for the whole car.
    let privateUSD: Double?
    /// Anything that changes the number — "after dark", "per car up to 4".
    let note: String?

    var routeLabel: String { "\(from) → \(to)" }

    var hasAnyFare: Bool { colectivoUSD != nil || privateUSD != nil }

    static func formatted(_ amount: Double) -> String {
        amount == amount.rounded()
            ? "$\(Int(amount))"
            : String(format: "$%.2f", amount)
    }
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
