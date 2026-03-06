import Foundation

@Observable
final class UnitPreference {
    var useMetric: Bool {
        didSet {
            UserDefaults.standard.set(useMetric, forKey: "useMetricUnits")
        }
    }

    init() {
        self.useMetric = UserDefaults.standard.bool(forKey: "useMetricUnits")
    }

    static func formatDistance(meters: Double, useMetric: Bool) -> String {
        if useMetric {
            if meters < 1000 {
                return "\(Int(meters))m"
            } else {
                return String(format: "%.1fkm", meters / 1000)
            }
        } else {
            let miles = meters / 1609.34
            if miles < 0.1 {
                let feet = Int(meters * 3.28084)
                return "\(feet)ft"
            } else {
                return String(format: "%.1fmi", miles)
            }
        }
    }
}
