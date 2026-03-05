import SwiftUI

extension Font {
    // Display/Headlines — SF Pro Display, 700-800, 28-36pt, tight tracking
    static func riDisplay(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    static func riHeadline(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    // Body — SF Pro Text, 400, 16pt
    static let riBody: Font = .system(size: 16, weight: .regular, design: .default)

    // Captions/Metadata — SF Pro Text, 400, 13-14pt
    static func riCaption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    // Button Labels — SF Pro Text, 600, 16pt
    static let riButton: Font = .system(size: 16, weight: .semibold, design: .default)

    // Tab Labels — SF Pro Text, 500, 10pt
    static let riTab: Font = .system(size: 10, weight: .medium, design: .default)
}

extension View {
    func riDisplayStyle(_ size: CGFloat = 34) -> some View {
        self
            .font(.riDisplay(size))
            .tracking(-0.8)
    }

    func riHeadlineStyle(_ size: CGFloat = 28) -> some View {
        self
            .font(.riHeadline(size))
            .tracking(-0.5)
    }
}
