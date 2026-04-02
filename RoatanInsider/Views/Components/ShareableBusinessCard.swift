import SwiftUI

/// A styled card view used to render a shareable image of a business via ImageRenderer.
struct ShareableBusinessCard: View {
    let business: Business

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category placeholder as hero
            ZStack(alignment: .bottomLeading) {
                business.category.placeholderColor
                    .overlay {
                        Image(systemName: business.category.iconName)
                            .font(.system(size: 60, weight: .ultraLight))
                            .foregroundStyle(Color.riMint.opacity(0.3))
                    }

                // Dark gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

                // Business name on image
                Text(business.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(16)
            }
            .frame(height: 200)
            .clipped()

            // Info section
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: business.category.iconName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.riMint)

                    Text(business.category.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.riMediumGray)

                    Text("·")
                        .foregroundStyle(Color.riLightGray)

                    Text(business.areaDisplayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.riMediumGray)

                    Text("·")
                        .foregroundStyle(Color.riLightGray)

                    Text(business.priceLabel)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.riMediumGray)
                }

                if let tip = business.insiderTip {
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.riMint)
                            .frame(width: 3)

                        Text(tip)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.riMediumGray)
                            .italic()
                            .lineLimit(2)
                            .padding(.leading, 10)
                    }
                }

                // App branding
                HStack(spacing: 6) {
                    Image(systemName: "palm.tree")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.riPink)

                    Text("Roatán Insider")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.riDark)

                    Spacer()

                    Text("Explore the island like a local.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.riLightGray)
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .frame(width: 360)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Share Helper

enum ShareHelper {
    @MainActor
    static func shareImage(for business: Business) -> UIImage? {
        let renderer = ImageRenderer(content: ShareableBusinessCard(business: business))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}
