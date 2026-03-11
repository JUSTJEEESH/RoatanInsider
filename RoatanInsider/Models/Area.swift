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
    case palmettoBay = "palmetto_bay"
    case miltonBight = "milton_bight"
    case johnsonBight = "johnson_bight"

    var id: String { rawValue }

    var imageName: String { "area_\(rawValue)" }

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
        case .palmettoBay: return "Palmetto Bay"
        case .miltonBight: return "Milton Bight"
        case .johnsonBight: return "Johnson Bight"
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .westBay: return CLLocationCoordinate2D(latitude: 16.2750, longitude: -86.5990)
        case .westEnd: return CLLocationCoordinate2D(latitude: 16.3040, longitude: -86.5935)
        case .sandyBay: return CLLocationCoordinate2D(latitude: 16.3280, longitude: -86.5680)
        case .coxenHole: return CLLocationCoordinate2D(latitude: 16.3170, longitude: -86.5370)
        case .flowersBay: return CLLocationCoordinate2D(latitude: 16.3000, longitude: -86.5450)
        case .frenchHarbour: return CLLocationCoordinate2D(latitude: 16.3380, longitude: -86.4650)
        case .oakRidge: return CLLocationCoordinate2D(latitude: 16.3700, longitude: -86.3650)
        case .puntaGorda: return CLLocationCoordinate2D(latitude: 16.3833, longitude: -86.3000)
        case .portRoyal: return CLLocationCoordinate2D(latitude: 16.4050, longitude: -86.3200)
        case .campBay: return CLLocationCoordinate2D(latitude: 16.4290, longitude: -86.2970)
        case .dixonCove: return CLLocationCoordinate2D(latitude: 16.3248, longitude: -86.4959)
        case .palmettoBay: return CLLocationCoordinate2D(latitude: 16.3350, longitude: -86.5100)
        case .miltonBight: return CLLocationCoordinate2D(latitude: 16.3725, longitude: -86.4325)
        case .johnsonBight: return CLLocationCoordinate2D(latitude: 16.3950, longitude: -86.4350)
        }
    }

    var description: String {
        switch self {
        case .westBay: return "Roatán's most famous beach — powdery white sand, turquoise water, and the island's best resorts and restaurants."
        case .westEnd: return "The bohemian heart of Roatán. Dive shops, bars, live music, and the island's best sunsets."
        case .sandyBay: return "A quiet residential stretch between West End and Coxen Hole with marine research and nature."
        case .coxenHole: return "The island's capital and commercial hub. Cruise port, markets, banks, and local life."
        case .flowersBay: return "A peaceful local community south of Coxen Hole with authentic Honduran culture."
        case .frenchHarbour: return "The island's business center — seafood processing, marinas, and great local restaurants."
        case .oakRidge: return "A charming fishing village built on stilts over the water. Authentic and off the beaten path."
        case .puntaGorda: return "The oldest Garifuna community on Roatán — rich culture, traditional food, and warm hospitality."
        case .portRoyal: return "Remote and wild — the far eastern tip with pristine reefs and virtually no tourists."
        case .campBay: return "Secluded beach paradise on the eastern end. Worth the drive for solitude seekers."
        case .dixonCove: return "Home to the Mahogany Bay cruise port, the ferry terminal, and duty-free shopping."
        case .palmettoBay: return "A growing community between Sandy Bay and French Harbour with craft breweries and local businesses."
        case .miltonBight: return "A quiet stretch on the north shore between French Harbour and Oak Ridge with secluded dive resorts."
        case .johnsonBight: return "A remote area on the eastern end with quiet beaches and the island's best-kept-secret beach clubs."
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
        case .dixonCove: return "Cruise passengers, ferry, duty-free shopping"
        case .palmettoBay: return "Craft beer, local dining, quiet stays"
        case .miltonBight: return "Secluded diving, eco-resorts, nature"
        case .johnsonBight: return "Remote beaches, beach clubs, day trips"
        }
    }
}
