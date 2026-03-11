import SwiftUI
import MapKit

struct AreaGuideView: View {
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Area.allCases) { area in
                    NavigationLink {
                        AreaGuideDetailView(area: area)
                    } label: {
                        AreaCard(area: area)
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
    let area: Area

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                // Satellite map of the area
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: area.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                ))) {}
                .mapStyle(.imagery)
                .disabled(true)
                .allowsHitTesting(false)

                // Dark scrim for text readability
                Rectangle()
                    .fill(
                        .linearGradient(
                            colors: [.clear, .black.opacity(0.65)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )

                Text(area.displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(12)
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(area.bestFor)
                .font(.riCaption(12))
                .foregroundStyle(Color.riLightGray)
                .lineLimit(2)
        }
    }
}
