import Foundation
import CoreLocation

enum Area: String, Codable, CaseIterable, Identifiable {
    case westBay = "west_bay"
    case westEnd = "west_end"
    case sandyBay = "sandy_bay"
    case coxenHole = "coxen_hole"
    case flowersBay = "flowers_bay"
    case frenchHarbour = "french_harbour"
    case oakRidge = "oak_ridge"
    case puntaGorda = "punta_gorda"
    case portRoyal = "port_royal"
    case campBay = "camp_bay"
    case dixonCove = "dixon_cove"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .westBay: return "West Bay"
        case .westEnd: return "West End"
        case .sandyBay: return "Sandy Bay"
        case .coxenHole: return "Coxen Hole"
        case .flowersBay: return "Flowers Bay"
        case .frenchHarbour: return "French Harbour"
        case .oakRidge: return "Oak Ridge"
        case .puntaGorda: return "Punta Gorda"
        case .portRoyal: return "Port Royal"
        case .campBay: return "Camp Bay"
        case .dixonCove: return "Dixon Cove"
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .westBay: return CLLocationCoordinate2D(latitude: 16.2940, longitude: -86.6180)
        case .westEnd: return CLLocationCoordinate2D(latitude: 16.2985, longitude: -86.6110)
        case .sandyBay: return CLLocationCoordinate2D(latitude: 16.3150, longitude: -86.5850)
        case .coxenHole: return CLLocationCoordinate2D(latitude: 16.3040, longitude: -86.5560)
        case .flowersBay: return CLLocationCoordinate2D(latitude: 16.3200, longitude: -86.5400)
        case .frenchHarbour: return CLLocationCoordinate2D(latitude: 16.3350, longitude: -86.4600)
        case .oakRidge: return CLLocationCoordinate2D(latitude: 16.3670, longitude: -86.3690)
        case .puntaGorda: return CLLocationCoordinate2D(latitude: 16.3730, longitude: -86.3420)
        case .portRoyal: return CLLocationCoordinate2D(latitude: 16.4050, longitude: -86.3200)
        case .campBay: return CLLocationCoordinate2D(latitude: 16.4200, longitude: -86.2900)
        case .dixonCove: return CLLocationCoordinate2D(latitude: 16.3100, longitude: -86.5700)
        }
    }

    var description: String {
        switch self {
        case .westBay: return "Roatán's most famous beach — powdery white sand, turquoise water, and the island's best resorts and restaurants."
        case .westEnd: return "The bohemian heart of Roatán. Dive shops, bars, live music, and the island's best sunsets."
        case .sandyBay: return "A quiet residential stretch between West Bay and Coxen Hole with a few hidden gems."
        case .coxenHole: return "The island's capital and commercial hub. Cruise port, markets, banks, and local life."
        case .flowersBay: return "A peaceful local community east of Coxen Hole with authentic Honduran culture."
        case .frenchHarbour: return "The island's business center — seafood processing, marinas, and great local restaurants."
        case .oakRidge: return "A charming fishing village built on stilts over the water. Authentic and off the beaten path."
        case .puntaGorda: return "The oldest Garifuna community on Roatán — rich culture, traditional food, and warm hospitality."
        case .portRoyal: return "Remote and wild — the far eastern tip with pristine reefs and virtually no tourists."
        case .campBay: return "Secluded beach paradise on the eastern end. Worth the drive for solitude seekers."
        case .dixonCove: return "A small community between Sandy Bay and Coxen Hole, home to the Mahogany Bay cruise port."
        }
    }

    var bestFor: String {
        switch self {
        case .westBay: return "Beach lovers, families, luxury travelers"
        case .westEnd: return "Divers, backpackers, nightlife, budget travelers"
        case .sandyBay: return "Quiet stays, snorkeling, nature lovers"
        case .coxenHole: return "Errands, local markets, cruise passengers"
        case .flowersBay: return "Local culture, quiet exploration"
        case .frenchHarbour: return "Seafood, shopping, boating"
        case .oakRidge: return "Authentic experiences, boat tours, fishing"
        case .puntaGorda: return "Cultural immersion, Garifuna heritage"
        case .portRoyal: return "Adventure seekers, advanced divers"
        case .campBay: return "Solitude, remote beaches, nature"
        case .dixonCove: return "Cruise passengers, quick stops, local shopping"
        }
    }
}
