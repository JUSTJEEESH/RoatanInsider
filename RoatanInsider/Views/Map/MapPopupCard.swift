import SwiftUI
import MapKit
import CoreLocation

/// The card that slides up when you tap a guide pin.
///
/// Now carries how far away it is and a Directions button, which is the
/// whole point of tapping a pin on a map — you already know roughly where it
/// is, you want to know whether to walk and how to get there. Previously it
/// closed no loop at all: you could read the name and then had to leave for
/// the detail page to do anything.
struct MapPopupCard: View {
    let business: Business
    var userLocation: CLLocation?
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: AppConstants.Space.snug) {
            NavigationLink(value: business) {
                HStack(spacing: AppConstants.Space.snug) {
                    BusinessImageView(business: business, aspectRatio: 1)
                        .frame(width: 68, height: 68)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.small, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(business.name)
                            .riType(.body, weight: .semibold)
                            .foregroundStyle(Color.riDark)
                            .lineLimit(1)

                        HStack(spacing: 5) {
                            Text(business.categoryDisplayName)
                            OpenStatusBadge(business: business)
                        }
                        .riType(.caption)
                        .foregroundStyle(Color.riMediumGray)
                        .lineLimit(1)

                        Text(travelLine)
                            .riType(.caption)
                            .foregroundStyle(Color.riLightGray)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                Haptics.impact()
                openDirections()
            } label: {
                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.riPink)
                    .frame(width: AppConstants.minTapTarget, height: AppConstants.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Directions to \(business.name)")
        }
        .padding(AppConstants.Space.snug)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.card, style: .continuous))
    }

    /// Area and price always; how far only when we know where you are and
    /// it's far enough to matter.
    private var travelLine: String {
        var parts = [business.areaDisplayName, business.priceLabel]
        if let travel = TravelEstimate.label(to: business, from: userLocation) {
            parts.append(travel)
        }
        return parts.joined(separator: " · ")
    }

    private func openDirections() {
        let placemark = MKPlacemark(coordinate: business.coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = business.name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}


// MARK: - Apple Maps Result Popup

struct MapItemPopupCard: View {
    let mapItem: MKMapItem
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.riPink.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.riPink)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(mapItem.name ?? "Unknown")
                    .riType(.body, weight: .semibold)
                    .foregroundStyle(Color.riDark)
                    .lineLimit(1)

                if let address = mapItem.placemark.title {
                    Text(address)
                        .riType(.caption)
                        .foregroundStyle(Color.riLightGray)
                        .lineLimit(2)
                }
            }

            Spacer()

            VStack(spacing: 8) {
                if mapItem.phoneNumber != nil {
                    Button {
                        callBusiness()
                    } label: {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.riMint)
                    }
                }

                Button {
                    openInMaps()
                } label: {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.riPink)
                }
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func callBusiness() {
        guard let phone = mapItem.phoneNumber,
              let url = URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "+" })") else { return }
        UIApplication.shared.open(url)
    }

    private func openInMaps() {
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
