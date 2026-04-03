import SwiftUI
import MapKit

struct AreaGuideDetailView: View {
    let guide: AreaGuide
    @Environment(DataManager.self) private var dataManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Area hero image or map fallback
                let imageURL = URL(string: AppConstants.supabaseStorageBaseURL.replacingOccurrences(of: "business-photos/", with: "area-photos/") + guide.area + ".jpg")

                if let url = imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        default:
                            areaMap
                        }
                    }
                } else {
                    areaMap
                }

                // Description
                Text(guide.descriptionText)
                    .font(.riBody)
                    .foregroundStyle(Color.riMediumGray)
                    .lineSpacing(4)

                if !guide.overview.isEmpty && guide.overview != guide.descriptionText {
                    Text(guide.overview)
                        .font(.riBody)
                        .foregroundStyle(Color.riMediumGray)
                        .lineSpacing(4)
                }

                // Best For
                if !guide.bestFor.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Best For")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.riDark)

                        Text(guide.bestFor)
                            .font(.riBody)
                            .foregroundStyle(Color.riMediumGray)
                    }
                }

                // Vibe
                if !guide.vibe.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vibe")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.riDark)

                        Text(guide.vibe)
                            .font(.riBody)
                            .foregroundStyle(Color.riMediumGray)
                    }
                }

                // Getting There
                if !guide.gettingThere.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Getting There")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.riDark)

                        Text(guide.gettingThere)
                            .font(.riBody)
                            .foregroundStyle(Color.riMediumGray)
                    }
                }

                // Top picks from this area
                let areaBusinesses = dataManager.businesses(forAreaId: guide.area)
                if !areaBusinesses.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Top Picks")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.riDark)

                        ForEach(areaBusinesses.prefix(5)) { business in
                            NavigationLink(value: business) {
                                HStack(spacing: 12) {
                                    BusinessImageView(business: business)
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(business.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(Color.riDark)

                                        Text(business.categoryDisplayName)
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
        .navigationTitle(guide.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private var areaMap: some View {
        Map {
            Marker(guide.name, coordinate: guide.coordinate)
                .tint(Color.riPink)
        }
        .mapStyle(.standard)
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .disabled(true)
    }
}
