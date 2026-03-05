import SwiftUI
import MapKit

struct AreaGuideDetailView: View {
    let area: Area
    @Environment(DataManager.self) private var dataManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Area map
                Map {
                    Marker(area.displayName, coordinate: area.coordinate)
                        .tint(.riPink)
                }
                .mapStyle(.standard)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .disabled(true)

                // Description
                Text(area.description)
                    .font(.riBody)
                    .foregroundStyle(Color.riMediumGray)
                    .lineSpacing(4)

                // Best For
                VStack(alignment: .leading, spacing: 8) {
                    Text("Best For")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.riDark)

                    Text(area.bestFor)
                        .font(.riBody)
                        .foregroundStyle(Color.riMediumGray)
                }

                // Top picks from this area
                let areaBusinesses = dataManager.businesses(for: area)
                if !areaBusinesses.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Top Picks")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.riDark)

                        ForEach(areaBusinesses.prefix(5)) { business in
                            NavigationLink(value: business) {
                                HStack(spacing: 12) {
                                    Image(business.images.first ?? "business_placeholder")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(business.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(Color.riDark)

                                        Text(business.category.displayName)
                                            .font(.riCaption(13))
                                            .foregroundStyle(Color.riLightGray)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Color.riLightGray)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color.riWhite)
        .navigationTitle(area.displayName)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: Business.self) { business in
            BusinessDetailView(business: business)
        }
    }
}
