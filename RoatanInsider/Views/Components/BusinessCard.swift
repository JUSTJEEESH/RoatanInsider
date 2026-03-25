import SwiftUI
import CoreLocation

struct BusinessCard: View {
    let business: Business
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(LocationManager.self) private var locationManager
    @Environment(UnitPreference.self) private var unitPreference

    var body: some View {
        NavigationLink(value: business) {
            VStack(alignment: .leading, spacing: 0) {
                // Photo
                ZStack(alignment: .topTrailing) {
                    GeometryReader { geo in
                        BusinessImageView(business: business, aspectRatio: 16/9)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                    .aspectRatio(16/9, contentMode: .fit)
                    .clipped()

                    FavoriteButton(businessId: business.id)
                        .padding(12)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(business.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.riDark)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if let rating = business.rating {
                            RatingView(rating: rating, size: 12)
                        }
                        Text(business.area.displayName)
                        Text("·")
                        Text(business.priceLabel)

                        if let distance = distanceText {
                            Text("·")
                            Text(distance)
                        }
                    }
                    .font(.riCaption(14))
                    .foregroundStyle(Color.riLightGray)
                    .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .background(Color.riOffWhite)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(business.name), \(business.category.displayName) in \(business.area.displayName), \(business.priceLabel)")
    }

    private var distanceText: String? {
        guard let userLocation = locationManager.userLocation else { return nil }
        let businessLocation = CLLocation(latitude: business.latitude, longitude: business.longitude)
        let meters = userLocation.distance(from: businessLocation)
        return UnitPreference.formatDistance(meters: meters, useMetric: unitPreference.useMetric)
    }
}

// Compact card for horizontal scrolling
struct BusinessCardCompact: View {
    let business: Business
    var darkStyle: Bool = false
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(LocationManager.self) private var locationManager
    @Environment(UnitPreference.self) private var unitPreference

    var body: some View {
        NavigationLink(value: business) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    BusinessImageView(business: business, aspectRatio: 4/3)
                        .frame(width: 260, height: 180)
                        .clipped()

                    FavoriteButton(businessId: business.id)
                        .padding(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(business.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(darkStyle ? .white : Color.riDark)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if let rating = business.rating {
                            RatingView(rating: rating, size: 11)
                        }
                        Text(business.area.displayName)
                        Text("·")
                        Text(business.priceLabel)

                        if let distance = distanceText {
                            Text("·")
                            Text(distance)
                        }
                    }
                    .font(.riCaption(13))
                    .foregroundStyle(Color.riLightGray)
                    .lineLimit(1)
                }
                .padding(10)
            }
            .frame(width: 260)
            .background(darkStyle ? Color.riFixedDark : Color.riOffWhite)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(business.name), \(business.area.displayName), \(business.priceLabel)")
    }

    private var distanceText: String? {
        guard let userLocation = locationManager.userLocation else { return nil }
        let businessLocation = CLLocation(latitude: business.latitude, longitude: business.longitude)
        let meters = userLocation.distance(from: businessLocation)
        return UnitPreference.formatDistance(meters: meters, useMetric: unitPreference.useMetric)
    }
}

// Grid card for 2-column explore layout
struct BusinessCardGrid: View {
    let business: Business
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(LocationManager.self) private var locationManager
    @Environment(UnitPreference.self) private var unitPreference

    var body: some View {
        NavigationLink(value: business) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    GeometryReader { geo in
                        BusinessImageView(business: business, aspectRatio: 4/3)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                    .aspectRatio(4/3, contentMode: .fit)
                    .clipped()

                    FavoriteButton(businessId: business.id)
                        .padding(8)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(business.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.riDark)
                        .lineLimit(1)

                    HStack(spacing: 3) {
                        if let rating = business.rating {
                            RatingView(rating: rating, size: 10)
                        }
                        Text(business.area.displayName)
                        Text("·")
                        Text(business.priceLabel)

                        if let distance = distanceText {
                            Text("·")
                            Text(distance)
                        }
                    }
                    .font(.riCaption(12))
                    .foregroundStyle(Color.riLightGray)
                    .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }
            .background(Color.riOffWhite)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(business.name), \(business.area.displayName)")
    }

    private var distanceText: String? {
        guard let userLocation = locationManager.userLocation else { return nil }
        let businessLocation = CLLocation(latitude: business.latitude, longitude: business.longitude)
        let meters = userLocation.distance(from: businessLocation)
        return UnitPreference.formatDistance(meters: meters, useMetric: unitPreference.useMetric)
    }
}
