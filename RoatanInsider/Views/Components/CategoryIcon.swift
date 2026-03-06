import SwiftUI

struct CategoryIcon: View {
    let category: Category
    var size: CGFloat = 48
    var lightText: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.riOffWhite)
                    .frame(width: size, height: size)

                Image(systemName: category.iconName)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundStyle(Color.riDark)
            }

            Text(category.displayName)
                .font(.riCaption(12))
                .foregroundStyle(lightText ? Color.riOffWhite : Color.riMediumGray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}
