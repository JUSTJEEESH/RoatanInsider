import Foundation

/// A single cruise ship arrival in one of Roatán's two ports. Bundled
/// at launch from `cruise_arrivals.json`; the JSON cadence is one
/// row per ship per day. A day with two ships gets two rows.
///
/// `passengerCount` is the double-occupancy capacity published by the
/// cruise line — the actual number aboard varies, but the published
/// figure is the practical "how busy will the island be" signal.
struct CruiseArrival: Identifiable, Codable, Hashable {
    let id: String
    let shipName: String
    let cruiseLine: String?
    let port: String          // "Mahogany Bay" or "Port of Roatán"
    let date: String          // ISO "YYYY-MM-DD"
    let arrivalTime: String   // 24hr "HH:mm"
    let departureTime: String // 24hr "HH:mm"
    let passengerCount: Int
    let notes: String?

    /// Display-friendly passenger count, rounded to the nearest 500.
    /// Exact ship capacity is misleading anyway — not everyone disembarks.
    var displayPassengerCount: Int {
        Self.roundedToNearest500(passengerCount)
    }

    static func roundedToNearest500(_ n: Int) -> Int {
        Int((Double(n) / 500.0).rounded()) * 500
    }

    /// Today's calendar date matches this row's date string.
    var isToday: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: -6 * 3600)
        return formatter.string(from: .now) == date
    }

    /// "8:00 AM – 5:00 PM" for display.
    var hoursLabel: String {
        "\(displayTime(arrivalTime)) – \(displayTime(departureTime))"
    }

    var departureLabel: String { displayTime(departureTime) }

    private func displayTime(_ raw: String) -> String {
        let parts = raw.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else {
            return raw
        }
        let suffix = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return minute == 0
            ? "\(displayHour):00 \(suffix)"
            : "\(displayHour):\(String(format: "%02d", minute)) \(suffix)"
    }
}
