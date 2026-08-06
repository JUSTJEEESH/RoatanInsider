import SwiftUI
import MapKit

struct AreaGuideDetailView: View {
    let guide: AreaGuide
    @Environment(DataManager.self) private var dataManager
    @State private var selectedBusiness: Business?

    private var imageURL: URL? {
        URL(string: AppConstants.supabaseStorageBaseURL.replacingOccurrences(of: "business-photos/", with: "area-photos/") + guide.area + ".jpg")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Area hero image
                CachedRemoteImage(url: imageURL, contentMode: .fill) {
                    heroPlaceholder
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Description
                Text(guide.descriptionText)
                    .riType(.body)
                    .foregroundStyle(Color.riMediumGray)
                    .lineSpacing(4)

                if !guide.overview.isEmpty && guide.overview != guide.descriptionText {
                    Text(guide.overview)
                        .riType(.body)
                        .foregroundStyle(Color.riMediumGray)
                        .lineSpacing(4)
                }

                // Best For
                if !guide.bestFor.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Best For")
                            .riType(.body, weight: .semibold)
                            .foregroundStyle(Color.riDark)

                        Text(guide.bestFor)
                            .riType(.body)
                            .foregroundStyle(Color.riMediumGray)
                    }
                }

                // Vibe
                if !guide.vibe.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vibe")
                            .riType(.body, weight: .semibold)
                            .foregroundStyle(Color.riDark)

                        Text(guide.vibe)
                            .riType(.body)
                            .foregroundStyle(Color.riMediumGray)
                    }
                }

                // Getting There
                if !guide.gettingThere.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Getting There")
                            .riType(.body, weight: .semibold)
                            .foregroundStyle(Color.riDark)

                        Text(guide.gettingThere)
                            .riType(.body)
                            .foregroundStyle(Color.riMediumGray)
                    }
                }

                // Top picks from this area
                let areaBusinesses = dataManager.businesses(forAreaId: guide.area)
                if !areaBusinesses.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Top Picks")
                            .riType(.heading, weight: .bold)
                            .foregroundStyle(Color.riDark)

                        ForEach(areaBusinesses.prefix(5)) { business in
                            Button {
                                selectedBusiness = business
                            } label: {
                                HStack(spacing: 12) {
                                    BusinessImageView(business: business)
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(business.name)
                                            .riType(.body, weight: .semibold)
                                            .foregroundStyle(Color.riDark)

                                        Text(business.categoryDisplayName)
                                            .riType(.caption)
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
        .navigationDestination(item: $selectedBusiness) { business in
            BusinessDetailView(business: business)
        }
    }

    private var heroPlaceholder: some View {
        ZStack {
            Color.riMint.opacity(0.15)

            VStack(spacing: 12) {
                Image(systemName: "photo")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(Color.riMint.opacity(0.5))

                Text(guide.name)
                    .riType(.caption, weight: .semibold)
                    .foregroundStyle(Color.riMint.opacity(0.7))
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
