import SwiftUI

// MARK: - Type scale
//
// Six steps. Nothing else. Before this existed the app used 23 distinct
// font sizes — 11, 12, 13, 14, 15 and 16pt all coexisting — which is why
// nothing on screen had visual rank: the eye can't tell what matters when
// six near-identical sizes sit next to each other.
//
// The jumps here are deliberately decisive. 13, 15 and 17pt are gone.
// If a design seems to need a size between two steps, it almost always
// needs a different weight or more space instead.
//
// Usage: `.riType(.title)` sets size, weight and tracking together, so
// headline tracking can't drift from one screen to the next.

enum RIType {
    case display   // 34/800 — screen titles, once per screen
    case title     // 24/700 — section headers
    case heading   // 18/600 — card titles, row leads
    case body      // 16/400 — running copy
    case caption   // 14/400 — metadata, supporting detail
    case label     // 12/600 — uppercase kickers, tags

    var size: CGFloat {
        switch self {
        case .display: return 34
        case .title:   return 24
        case .heading: return 18
        case .body:    return 16
        case .caption: return 14
        case .label:   return 12
        }
    }

    var weight: Font.Weight {
        switch self {
        case .display: return .heavy
        case .title:   return .bold
        case .heading: return .semibold
        case .body:    return .regular
        case .caption: return .regular
        case .label:   return .semibold
        }
    }

    /// Tight on display sizes, open on labels — the standard optical
    /// correction. Body and caption stay at the system default.
    var tracking: CGFloat {
        switch self {
        case .display: return -0.8
        case .title:   return -0.5
        case .heading: return -0.2
        case .body, .caption: return 0
        case .label:   return 1.2
        }
    }
}

extension View {
    /// The only way new code should set type. Applies size, weight and
    /// tracking as a unit.
    func riType(_ step: RIType) -> some View {
        font(.system(size: step.size, weight: step.weight))
            .tracking(step.tracking)
    }
}

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
