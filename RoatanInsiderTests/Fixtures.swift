import Foundation
@testable import RoatanInsider

/// Test fixtures built by decoding JSON rather than by calling memberwise
/// initialisers.
///
/// Two reasons. The models define `init(from:)` in the type body, which
/// suppresses the synthesised memberwise init — so JSON is the only way in
/// without adding init boilerplate to production code purely for tests. And
/// decoding here means every fixture also exercises the real decoder, so a
/// schema drift between the app and the scrapers fails a test instead of
/// failing on a user's phone.

extension Business {
    /// `hours` takes "HH:mm-HH:mm" per weekday, or an explicit nil for a day
    /// the place is shut. An empty dictionary means hours are unknown, which
    /// is a third state the app treats differently from either.
    static func fixture(
        slug: String,
        name: String? = nil,
        insiderTip: String? = "Ask for the corner table.",
        category: String = "eat",
        area: String = "west_end",
        latitude: Double = 16.2985,
        longitude: Double = -86.6110,
        isInsiderPick: Bool = true,
        status: String = "active",
        features: [String] = [],
        hours: [String: String?] = [:],
        happyHour: HappyHour? = nil
    ) -> Business {
        let tipField = insiderTip.map { "\"insiderTip\": \(quoted($0))," } ?? ""
        let hoursField = hours.map { day, window -> String in
            guard let window, let dash = window.firstIndex(of: "-") else {
                return "\(quoted(day)): null"
            }
            let open = String(window[window.startIndex..<dash])
            let close = String(window[window.index(after: dash)...])
            return "\(quoted(day)): {\"open\": \(quoted(open)), \"close\": \(quoted(close))}"
        }.joined(separator: ",")
        let happyHourField = happyHour.map { hh in
            let note = hh.note.map { "\"note\": \(quoted($0))," } ?? ""
            return """
            "happyHour": {"days": \(jsonArray(hh.days)), \(note)"start": \(quoted(hh.start)), "end": \(quoted(hh.end))},
            """
        } ?? ""
        let json = """
        {
          "id": "\(slug)-id",
          "slug": "\(slug)",
          "name": \(quoted(name ?? slug.replacingOccurrences(of: "-", with: " ").capitalized)),
          "description": "A place on Roatán used in tests.",
          \(tipField)
          \(happyHourField)
          "category": "\(category)",
          "subcategory": "Test",
          "area": "\(area)",
          "latitude": \(latitude),
          "longitude": \(longitude),
          "addressDescription": "On the main road",
          "priceRange": 2,
          "hours": {\(hoursField)},
          "features": \(jsonArray(features)),
          "images": ["business_placeholder"],
          "isVerified": true,
          "isFeatured": false,
          "isInsiderPick": \(isInsiderPick),
          "isBestOf": false,
          "status": "\(status)"
        }
        """
        return decode(Business.self, from: json)
    }
}

extension Event {
    static func fixture(
        id: String = "test-event",
        venue: String = "Sundowners",
        area: String = "West End",
        performer: String = "The Londoners",
        day: Weekday? = .wednesday,
        date: Date? = nil,
        startTime: String = "17:00",
        endTime: String? = nil,
        genre: String? = nil,
        category: EventCategory = .liveMusic,
        cruiseShipDayOnly: Bool = false,
        featured: Bool = false
    ) -> Event {
        var fields: [String] = [
            "\"id\": \(quoted(id))",
            "\"venue\": \(quoted(venue))",
            "\"area\": \(quoted(area))",
            "\"category\": \(quoted(category.rawValue))",
            "\"performer\": \(quoted(performer))",
            "\"startTime\": \(quoted(startTime))",
            "\"recurring\": \(date == nil)",
            "\"featured\": \(featured)",
            "\"active\": true",
        ]
        if let day { fields.append("\"day\": \(quoted(day.rawValue))") }
        if let date { fields.append("\"date\": \(quoted(isoDay(date)))") }
        if let endTime { fields.append("\"endTime\": \(quoted(endTime))") }
        if let genre { fields.append("\"genre\": \(quoted(genre))") }
        if cruiseShipDayOnly { fields.append("\"cruiseShipDayOnly\": true") }
        return decode(Event.self, from: "{\(fields.joined(separator: ","))}")
    }
}

extension CruiseArrival {
    static func fixture(
        date: String,
        shipName: String = "Test Ship",
        cruiseLine: String = "Test Line",
        port: String = "Port of Roatán",
        arrivalTime: String = "08:00",
        departureTime: String = "17:00",
        passengerCount: Int = 3000
    ) -> CruiseArrival {
        let json = """
        {
          "id": "\(date)-\(shipName.lowercased().replacingOccurrences(of: " ", with: "-"))",
          "shipName": \(quoted(shipName)),
          "cruiseLine": \(quoted(cruiseLine)),
          "port": \(quoted(port)),
          "date": "\(date)",
          "arrivalTime": "\(arrivalTime)",
          "departureTime": "\(departureTime)",
          "passengerCount": \(passengerCount)
        }
        """
        return decode(CruiseArrival.self, from: json)
    }
}

// MARK: - Helpers

private func decode<T: Decodable>(_ type: T.Type, from json: String) -> T {
    do {
        return try JSONDecoder().decode(type, from: Data(json.utf8))
    } catch {
        fatalError("Fixture for \(type) failed to decode — the model's schema changed: \(error)\n\(json)")
    }
}

private func quoted(_ s: String) -> String {
    let escaped = s
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
    return "\"\(escaped)\""
}

private func jsonArray(_ items: [String]) -> String {
    "[" + items.map(quoted).joined(separator: ",") + "]"
}

private func isoDay(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(identifier: "America/Tegucigalpa")
    return f.string(from: date)
}
