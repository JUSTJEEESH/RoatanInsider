import SwiftUI

extension Color {
    // MARK: - Accent Colors (fixed, not adaptive)

    static let riPink = Color(hex: "E31B4E")
    static let riMint = Color(hex: "4ECDC4")
    static let riGoldStar = Color(hex: "F5A623")

    // MARK: - Adaptive Colors (respond to light/dark mode)

    /// Main background: white in light mode, charcoal in dark mode
    static let riWhite = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 45/255, green: 45/255, blue: 45/255, alpha: 1)   // #2D2D2D
            : .white
    })

    /// Card/surface background: off-white in light, slightly lighter charcoal in dark
    static let riOffWhite = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1)   // #383838
            : UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1) // #F8F8F8
    })

    /// Headlines/primary text: charcoal in light, white in dark
    static let riDark = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? .white
            : UIColor(red: 45/255, green: 45/255, blue: 45/255, alpha: 1)   // #2D2D2D
    })

    /// Tab bar background: stays near-black in both modes
    static let riNearBlack = Color(hex: "1A1A1A")

    /// Fixed charcoal — always #2D2D2D regardless of light/dark mode.
    /// Use for backgrounds that have white text on top (selected states, dark sections).
    static let riFixedDark = Color(hex: "2D2D2D")

    /// Secondary body text: medium gray, lighter in dark mode for readability
    static let riMediumGray = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1) // #AAAAAA
            : UIColor(red: 102/255, green: 102/255, blue: 102/255, alpha: 1) // #666666
    })

    /// Captions/metadata: light gray, adjusted for dark mode
    static let riLightGray = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 140/255, green: 140/255, blue: 140/255, alpha: 1) // #8C8C8C
            : UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1) // #999999
    })

    // MARK: - Hex Initializer

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
