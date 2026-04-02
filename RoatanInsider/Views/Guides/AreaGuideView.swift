import SwiftUI
import MapKit

struct AreaGuideView: View {
    @Environment(DataManager.self) private var dataManager

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(dataManager.areaGuides) { guide in
                    NavigationLink {
                        AreaGuideDetailView(guide: guide)
                    } label: {
                        AreaCard(guide: guide)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(Color.riWhite)
        .navigationTitle("Area Guides")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct AreaCard: View {
    let guide: AreaGuide

    private var imageURL: URL? {
        URL(string: AppConstants.supabaseStorageBaseURL.replacingOccurrences(of: "business-photos/", with: "area-photos/") + guide.area + ".jpg")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                if let url = imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                .clipped()
                        default:
                            satelliteMap
                        }
                    }
                } else {
                    satelliteMap
                }

                Rectangle()
                    .fill(
                        .linearGradient(
                            colors: [.clear, .black.opacity(0.65)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )

                Text(guide.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(12)
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(guide.bestFor)
                .font(.riCaption(12))
                .foregroundStyle(Color.riLightGray)
                .lineLimit(2)
        }
    }

    private var satelliteMap: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: guide.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        ))) {}
        .mapStyle(.imagery)
        .disabled(true)
        .allowsHitTesting(false)
    }
}
