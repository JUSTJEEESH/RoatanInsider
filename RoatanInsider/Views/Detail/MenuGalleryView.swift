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
                            ZoomableImage(source: source)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: displaySources.count > 1 ? .always : .never))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
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

// MARK: - Zoomable Image using ScrollView (native iOS feel)

struct ZoomableImage: View {
    let source: MenuImageSource

    var body: some View {
        switch source {
        case .local(let name):
            if let uiImage = UIImage(named: name) {
                ZoomableScrollView {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
        case .remote(let urlString):
            if let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        ZoomableScrollView {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
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

// MARK: - Native ScrollView-based zoom (smooth, iOS-native feel)

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    let content: () -> Content

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear

        let hostingController = UIHostingController(rootView: content())
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            hostingController.view.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
        ])

        context.coordinator.hostingView = hostingController.view

        // Double-tap to zoom
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingView: UIView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let hostingView else { return }
            let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
            let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
            hostingView.frame.origin = CGPoint(x: offsetX, y: offsetY)
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }
            if scrollView.zoomScale > 1.0 {
                scrollView.setZoomScale(1.0, animated: true)
            } else {
                let point = gesture.location(in: scrollView)
                let zoomRect = CGRect(
                    x: point.x - 75,
                    y: point.y - 75,
                    width: 150,
                    height: 150
                )
                scrollView.zoom(to: zoomRect, animated: true)
            }
        }
    }
}

enum MenuImageSource {
    case local(String)
    case remote(String)
}
