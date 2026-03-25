import SwiftUI

/// Displays a business photo from Supabase storage, local asset catalog, or a styled category-aware placeholder.
/// Returns a resizable, scaledToFill image. The CALLER is responsible for framing and clipping.
struct BusinessImageView: View {
    let business: Business
    var aspectRatio: CGFloat = 16/9

    var body: some View {
        let imageName = business.images.first ?? ""
        let hasLocalImage = UIImage(named: imageName) != nil

        if hasLocalImage {
            Image(imageName)
                .resizable()
                .scaledToFill()
        } else if let url = supabaseURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    categoryPlaceholder
                case .empty:
                    categoryPlaceholder
                        .overlay {
                            ProgressView()
                                .tint(Color.riMint)
                        }
                @unknown default:
                    categoryPlaceholder
                }
            }
        } else {
            categoryPlaceholder
        }
    }

    private var supabaseURL: URL? {
        let slug = business.slug
        guard !slug.isEmpty else { return nil }
        return URL(string: AppConstants.supabaseStorageBaseURL + slug + ".jpg")
    }

    private var categoryPlaceholder: some View {
        business.category.placeholderColor
            .overlay {
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
