import SwiftUI

struct MenuGalleryView: View {
    let businessName: String
    let menuImages: [String]
    let slug: String
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if displaySources.isEmpty {
                    emptyState
                } else {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(displaySources.enumerated()), id: \.offset) { index, source in
                            ZoomableMenuImage(source: source)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: displaySources.count > 1 ? .always : .never))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Menu")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        if displaySources.count > 1 {
                            Text("\(currentIndex + 1) of \(displaySources.count)")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private var displaySources: [MenuImageSource] {
        let localImages = menuImages.compactMap { name -> MenuImageSource? in
            guard UIImage(named: name) != nil else { return nil }
            return .local(name)
        }

        if !localImages.isEmpty {
            return localImages
        }

        if !slug.isEmpty && !menuImages.isEmpty {
            return menuImages.map { name in
                let hasExtension = name.contains(".")
                let url = AppConstants.supabaseStorageBaseURL + (hasExtension ? name : name + ".jpg")
                return .remote(url)
            }
        }

        return []
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "menucard")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.white.opacity(0.3))
            Text("No menu available")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

// MARK: - Zoomable Menu Image

struct ZoomableMenuImage: View {
    let source: MenuImageSource
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            menuContent
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in
                            let newScale = lastScale * value.magnification
                            scale = min(max(newScale, 1.0), 5.0)
                        }
                        .onEnded { _ in
                            lastScale = scale
                            if scale <= 1.0 {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1.0 {
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if scale > 1.0 {
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2.5
                            lastScale = 2.5
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    @ViewBuilder
    private var menuContent: some View {
        switch source {
        case .local(let name):
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 8)
        case .remote(let urlString):
            if let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal, 8)
                    case .failure:
                        menuPlaceholder
                    case .empty:
                        ProgressView()
                            .tint(Color.riMint)
                    @unknown default:
                        menuPlaceholder
                    }
                }
            } else {
                menuPlaceholder
            }
        }
    }

    private var menuPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "menucard")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.white.opacity(0.3))
            Text("Menu image unavailable")
                .font(.riCaption(14))
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}

enum MenuImageSource {
    case local(String)
    case remote(String)
}
