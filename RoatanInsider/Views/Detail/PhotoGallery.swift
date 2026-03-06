import SwiftUI

struct PhotoGallery: View {
    let images: [String]
    let category: Category
    @State private var currentIndex = 0

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(images.enumerated()), id: \.offset) { index, imageName in
                let hasImage = UIImage(named: imageName) != nil

                if hasImage {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                        .tag(index)
                } else {
                    ZStack {
                        category.placeholderColor

                        VStack(spacing: 12) {
                            Image(systemName: category.iconName)
                                .font(.system(size: 48, weight: .medium))
                                .foregroundStyle(Color.riMint)

                            Text(category.displayName.uppercased())
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.riMint.opacity(0.7))
                                .tracking(2)
                        }
                    }
                    .tag(index)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: images.count > 1 ? .always : .never))
        .frame(height: 320)
    }
}
