import Foundation
import CoreLocation

/// A named dive site on Roatán's reef.
///
/// The app has eleven dive shops and, until now, no sites — which is the
/// wrong way round for an island whose main draw is the Mesoamerican
/// Barrier Reef. Divers arrive knowing the names of places they want to go
/// and choose an operator second; a directory that lists only operators
/// answers the easier question.
///
/// Everything except `name`, `area` and `coordinate` is optional on purpose.
/// Depth and difficulty are safety information, not marketing copy: a site
/// with no depth recorded shows no depth, and one with no level shows no
/// level, rather than inheriting a plausible default. Nothing here is
/// inferred from anything else.
struct DiveSite: Identifiable, Codable, Hashable {
    let id: String
    let slug: String
    let name: String
    /// Which stretch of coast, matching the app's `Area` ids where possible.
    let area: String
    let latitude: Double
    let longitude: Double

    let kind: DiveSiteKind?
    let level: DiveLevel?
    /// Shallowest and deepest points in metres.
    let minDepthMeters: Double?
    let maxDepthMeters: Double?
    /// True when you can swim to it from shore.
    let shoreAccessible: Bool?
    /// What you're likely to see. Two or three sentences, in Josh's voice.
    let summary: String?
    /// The one thing a local would tell you before you got in.
    let insiderTip: String?
    /// Free-form marine life notes: "eagle rays", "seahorses on the wall".
    let marineLife: [String]
    /// Slugs of dive shops in `businesses.json` that run this site.
    let operatorSlugs: [String]
    let isActive: Bool

    private enum CodingKeys: String, CodingKey {
        case id, slug, name, area, latitude, longitude, kind, level
        case minDepthMeters, maxDepthMeters, shoreAccessible
        case summary, insiderTip, marineLife, operatorSlugs, active
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        slug = try c.decode(String.self, forKey: .slug)
        name = try c.decode(String.self, forKey: .name)
        area = try c.decode(String.self, forKey: .area)
        latitude = try c.decode(Double.self, forKey: .latitude)
        longitude = try c.decode(Double.self, forKey: .longitude)
        kind = try? c.decodeIfPresent(DiveSiteKind.self, forKey: .kind)
        level = try? c.decodeIfPresent(DiveLevel.self, forKey: .level)
        minDepthMeters = try? c.decodeIfPresent(Double.self, forKey: .minDepthMeters)
        maxDepthMeters = try? c.decodeIfPresent(Double.self, forKey: .maxDepthMeters)
        shoreAccessible = try? c.decodeIfPresent(Bool.self, forKey: .shoreAccessible)
        summary = try? c.decodeIfPresent(String.self, forKey: .summary)
        insiderTip = try? c.decodeIfPresent(String.self, forKey: .insiderTip)
        marineLife = (try? c.decodeIfPresent([String].self, forKey: .marineLife)) as? [String] ?? []
        operatorSlugs = (try? c.decodeIfPresent([String].self, forKey: .operatorSlugs)) as? [String] ?? []
        isActive = (try? c.decodeIfPresent(Bool.self, forKey: .active)) as? Bool ?? true
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var areaDisplayName: String {
        Area(rawValue: area)?.displayName
            ?? area.replacingOccurrences(of: "_", with: " ").capitalized
    }

    /// "12–30 m", "to 30 m", or nothing at all when no depth is recorded.
    /// Never guesses a floor of zero.
    func depthLabel(useMetric: Bool) -> String? {
        func value(_ metres: Double) -> String {
            useMetric
                ? "\(Int(metres.rounded()))"
                : "\(Int((metres * 3.28084).rounded()))"
        }
        let unit = useMetric ? "m" : "ft"
        switch (minDepthMeters, maxDepthMeters) {
        case let (min?, max?): return "\(value(min))–\(value(max)) \(unit)"
        case let (nil, max?):  return "to \(value(max)) \(unit)"
        case let (min?, nil):  return "from \(value(min)) \(unit)"
        default:               return nil
        }
    }

    /// The short line under the name: type, level, depth, shore access —
    /// whichever of those we actually know.
    func subtitle(useMetric: Bool) -> String {
        var parts: [String] = [areaDisplayName]
        if let kind { parts.append(kind.displayName) }
        if let depth = depthLabel(useMetric: useMetric) { parts.append(depth) }
        if shoreAccessible == true { parts.append("Shore dive") }
        return parts.joined(separator: " · ")
    }
}

enum DiveSiteKind: String, Codable, CaseIterable, Identifiable {
    case wall, wreck, reef, channel, pinnacle, swimThrough = "swim_through"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wall:        return "Wall"
        case .wreck:       return "Wreck"
        case .reef:        return "Reef"
        case .channel:     return "Channel"
        case .pinnacle:    return "Pinnacle"
        case .swimThrough: return "Swim-through"
        }
    }

    var iconName: String {
        switch self {
        case .wall:        return "square.3.layers.3d.top.filled"
        case .wreck:       return "ferry"
        case .reef:        return "water.waves"
        case .channel:     return "arrow.left.and.right"
        case .pinnacle:    return "triangle"
        case .swimThrough: return "arrow.up.forward.and.arrow.down.backward"
        }
    }
}

enum DiveLevel: String, Codable, CaseIterable, Identifiable {
    case openWater = "open_water"
    case advanced
    case technical

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openWater: return "Open Water"
        case .advanced:  return "Advanced"
        case .technical: return "Technical"
        }
    }

    /// Plain language, because "Advanced" means different things to
    /// different agencies and a visitor booking a boat needs the practical
    /// version.
    var explanation: String {
        switch self {
        case .openWater: return "Fine on an Open Water certification."
        case .advanced:  return "Depth or current puts this past a basic certification."
        case .technical: return "Beyond recreational limits — specialist training and gear."
        }
    }
}
