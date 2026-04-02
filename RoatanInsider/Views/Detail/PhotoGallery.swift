import SwiftUI

struct PhotoGallery: View {
    let images: [String]
    let categoryIconName: String
    let categoryDisplayName: String
    var slug: String = ""
    @State private var currentIndex = 0

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(displayImages.enumerated()), id: \.offset) { index, imageSource in
                imageView(for: imageSource)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: displayImages.count > 1 ? .always : .never))
        .frame(height: 320)
    }

    /// Determines what images to show: local assets, or Supabase URLs via slug
    private var displayImages: [ImageSource] {
        // Check if any local assets exist
        let localImages = images.compactMap { name -> ImageSource? in
            guard UIImage(named: name) != nil else { return nil }
            return .local(name)
        }

        if !localImages.isEmpty {
            return localImages
        }

        // Fall back to Supabase URL using slug
        if !slug.isEmpty {
            return [.remote(AppConstants.supabaseStorageBaseURL + slug + ".jpg")]
        }

        return [.placeholder]
    }

    @ViewBuilder
    private func imageView(for source: ImageSource) -> some View {
        switch source {
        case .local(let name):
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        case .remote(let urlString):
            if let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                    case .failure:
                        placeholderView
                    case .empty:
                        placeholderView
                            .overlay {
                                ProgressView()
                                    .tint(Color.riMint)
                            }
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        case .placeholder:
            placeholderView
        }
    }

    private var placeholderView: some View {
        ZStack {
            Color.riMint.opacity(0.15)

            VStack(spacing: 12) {
                Image(systemName: categoryIconName)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(Color.riMint)

                Text(categoryDisplayName.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.riMint.opacity(0.7))
                    .tracking(2)
            }
        }
    }
}

private enum ImageSource {
    case local(String)
    case remote(String)
    case placeholder
}
