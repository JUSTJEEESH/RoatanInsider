import SwiftUI

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
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(lightText ? Color.white.opacity(0.1) : Color.riOffWhite)
                    .frame(width: size, height: size)

                Image(systemName: iconName)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundStyle(lightText ? .white : Color.riDark)
            }

            Text(displayName)
                .font(.riCaption(12))
                .foregroundStyle(lightText ? Color.riOffWhite : Color.riMediumGray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}
