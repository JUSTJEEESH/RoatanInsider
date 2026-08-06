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
    case figure    // 44/700 — a single number that IS the screen (converters)
    case display   // 34/800 — screen titles, once per screen
    case title     // 24/700 — section headers
    case heading   // 18/600 — card titles, row leads
    case body      // 16/400 — running copy
    case caption   // 14/400 — metadata, supporting detail
    case label     // 12/600 — uppercase kickers, tags
    case micro     // 11/700 — status badges: LIVE NOW, DON'T MISS

    var size: CGFloat {
        switch self {
        case .figure:  return 44
        case .display: return 34
        case .title:   return 24
        case .heading: return 18
        case .body:    return 16
        case .caption: return 14
        case .label:   return 12
        case .micro:   return 11
        }
    }

    var weight: Font.Weight {
        switch self {
        case .figure:  return .bold
        case .display: return .heavy
        case .title:   return .bold
        case .heading: return .semibold
        case .body:    return .regular
        case .caption: return .regular
        case .label:   return .semibold
        case .micro:   return .bold
        }
    }

    /// Tight on display sizes, open on labels — the standard optical
    /// correction. Body and caption stay at the system default.
    var tracking: CGFloat {
        switch self {
        case .figure:  return -1.0
        case .display: return -0.8
        case .title:   return -0.5
        case .heading: return -0.2
        case .body, .caption: return 0
        case .label:   return 1.2
        case .micro:   return 1.0
        }
    }
}

extension View {
    /// The only way new code should set type. Applies size, weight and
    /// tracking as a unit.
    ///
    /// `weight` overrides the step's default — the escape hatch the scale
    /// is designed around. A card title in a narrow grid column needs to be
    /// smaller AND heavier than running copy; the answer is `.body` at
    /// `.semibold`, not a new 15pt size. Size discipline is what makes the
    /// screen feel drawn; weight is free.
    func riType(_ step: RIType, weight: Font.Weight? = nil) -> some View {
        font(.system(size: step.size, weight: weight ?? step.weight))
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
