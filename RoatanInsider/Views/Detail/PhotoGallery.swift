import SwiftUI

struct PhotoGallery: View {
    let images: [String]
    @State private var currentIndex = 0

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(images.enumerated()), id: \.offset) { index, imageName in
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: images.count > 1 ? .always : .never))
        .frame(height: 320)
    }
}
