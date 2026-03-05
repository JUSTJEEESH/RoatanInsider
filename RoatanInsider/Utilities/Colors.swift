import SwiftUI

extension Color {
    // Primary Accent
    static let riPink = Color(hex: "E31B4E")

    // Secondary Accent
    static let riMint = Color(hex: "4ECDC4")

    // Neutrals
    static let riDark = Color(hex: "2D2D2D")
    static let riNearBlack = Color(hex: "1A1A1A")
    static let riWhite = Color.white
    static let riOffWhite = Color(hex: "F8F8F8")
    static let riLightGray = Color(hex: "999999")
    static let riMediumGray = Color(hex: "666666")

    // Special
    static let riGoldStar = Color(hex: "F5A623")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
