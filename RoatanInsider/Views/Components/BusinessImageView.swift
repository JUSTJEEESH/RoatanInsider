import SwiftUI

/// Displays a business photo from Supabase storage, local asset catalog, or a styled category-aware placeholder.
///
/// The image fills all available space using aspect-fill and clips overflow.
/// Callers control the size via `.aspectRatio()` or `.frame()` modifiers:
///   - `.aspectRatio(16/9, contentMode: .fit)` for flexible-width containers
///   - `.frame(width: 260, height: 180)` for fixed-size containers
struct BusinessImageView: View {
    let business: Business
    var aspectRatio: CGFloat = 16/9

    var body: some View {
        let imageName = business.images.first ?? ""
        let hasLocalImage = UIImage(named: imageName) != nil

        if hasLocalImage {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
        } else if let url = supabaseURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipped()
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
        Color.riMint.opacity(0.15)
            .overlay {
                VStack(spacing: 10) {
                    Image(systemName: business.categoryIconName)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(Color.riMint)

                    Text(business.categoryDisplayName.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.riMint.opacity(0.7))
                        .tracking(1.5)
                }
            }
            .aspectRatio(aspectRatio, contentMode: .fill)
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
