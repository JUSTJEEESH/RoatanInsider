import SwiftUI

/// Drop-in replacement for AsyncImage that goes through `ImageCache`.
///
/// Loaded images are persisted on disk so they survive app launches, fly offline,
/// and avoid duplicate decodes when the same business photo appears in multiple
/// home sections.
struct CachedRemoteImage<Placeholder: View>: View {
    let url: URL?
    let contentMode: ContentMode
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: UIImage?

    init(
        url: URL?,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await load()
        }
    }

    private func load() async {
        guard let url else {
            image = nil
            return
        }
        let loaded = await ImageCache.shared.image(for: url)
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.18)) {
                self.image = loaded
            }
        }
    }
}
