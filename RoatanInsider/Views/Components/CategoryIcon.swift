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
/// Removing the circle left its footprint behind: a 22pt glyph was still
/// centred in a 48pt box, so there were roughly 13pt of dead space under it
/// before the 12pt stack spacing even began. Twenty-five points from glyph
/// to label, against thirty-three between rows — near enough the same gap
/// that each label read as floating between two icons rather than belonging
/// to one, and the small glyphs left the columns looking airy and loose.
///
/// The box is now cut to the glyph, the glyph is larger and no longer
/// hairline-weight, and the label sits just under it. Icon and name read as
/// one object; the row spacing in the grid does the separating.
///
/// The whole stack is the tap target and clears 44pt comfortably.
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
        VStack(spacing: AppConstants.Space.hair) {
            Image(systemName: iconName)
                .font(.system(size: size * 0.55, weight: .regular))
                .foregroundStyle(lightText ? .white : Color.riDark)
                .frame(width: size, height: size * 0.58)

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
