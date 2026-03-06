import SwiftUI

/// Displays a business photo or a styled category-aware placeholder when no image exists.
struct BusinessImageView: View {
    let business: Business
    var aspectRatio: CGFloat = 16/9
    var contentMode: ContentMode = .fill

    var body: some View {
        let imageName = business.images.first ?? "business_placeholder"
        let hasImage = UIImage(named: imageName) != nil

        if hasImage {
            Image(imageName)
                .resizable()
                .aspectRatio(aspectRatio, contentMode: contentMode)
                .clipped()
        } else {
            categoryPlaceholder
        }
    }

    private var categoryPlaceholder: some View {
        ZStack {
            business.category.placeholderColor

            VStack(spacing: 10) {
                Image(systemName: business.category.iconName)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(Color.riMint)

                Text(business.category.displayName.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.riMint.opacity(0.7))
                    .tracking(1.5)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }
}

/// Standalone placeholder for non-business contexts (hero, etc.)
struct PlaceholderImageView: View {
    var icon: String = "photo"
    var label: String = ""

    var body: some View {
        ZStack {
            Color.riDark

            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))

                if !label.isEmpty {
                    Text(label.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                        .tracking(1.5)
                }
            }
        }
    }
}
