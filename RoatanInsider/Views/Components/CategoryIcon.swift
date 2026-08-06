import SwiftUI

/// A category, as an icon over its name.
///
/// The icon used to sit inside a filled circle. That pattern — a glyph
/// centred in a tinted disc — is the most machine-made-looking thing in this
/// app, and a grid of ten of them reads as a component library rather than a
/// designed screen. The circle is gone; the icon stands on its own, which is
/// also what the palette rules ask for (categories are told apart by icon,
/// never by colour).
///
/// The tap target keeps the full former footprint even though nothing is
/// drawn there, so the grid is no harder to hit than it was.
struct CategoryIcon: View {
    let iconName: String
    let displayName: String
    var size: CGFloat = 48
    var lightText: Bool = false

    /// Convenience init from a CategoryInfo
    init(categoryInfo: CategoryInfo, size: CGFloat = 48, lightText: Bool = false) {
        self.iconName = categoryInfo.iconName
        self.displayName = categoryInfo.displayName
        self.size = size
        self.lightText = lightText
    }

    /// Convenience init from a Category enum (backward compat)
    init(category: Category, size: CGFloat = 48, lightText: Bool = false) {
        self.iconName = category.iconName
        self.displayName = category.displayName
        self.size = size
        self.lightText = lightText
    }

    /// Direct init with raw strings
    init(iconName: String, displayName: String, size: CGFloat = 48, lightText: Bool = false) {
        self.iconName = iconName
        self.displayName = displayName
        self.size = size
        self.lightText = lightText
    }

    var body: some View {
        VStack(spacing: AppConstants.Space.snug) {
            Image(systemName: iconName)
                .font(.system(size: size * 0.46, weight: .light))
                .foregroundStyle(lightText ? .white : Color.riDark)
                .frame(width: size, height: size)

            Text(displayName)
                .riType(.caption)
                .foregroundStyle(lightText ? Color.white.opacity(0.7) : Color.riMediumGray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(displayName)
    }
}
