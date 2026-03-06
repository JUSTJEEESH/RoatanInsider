import SwiftUI
import MapKit

struct MapPopupCard: View {
    let business: Business
    let onDismiss: () -> Void

    var body: some View {
        NavigationLink(value: business) {
            HStack(spacing: 12) {
                BusinessImageView(business: business, aspectRatio: 1)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(business.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.riDark)
                        .lineLimit(1)

                    Text(business.category.displayName)
                        .font(.riCaption(13))
                        .foregroundStyle(Color.riLightGray)

                    HStack(spacing: 4) {
                        Text(business.area.displayName)
                        Text("·")
                        Text(business.priceLabel)
                    }
                    .font(.riCaption(13))
                    .foregroundStyle(Color.riLightGray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.riLightGray)
            }
            .padding(12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.riDark)
                    .lineLimit(1)

                if let address = mapItem.placemark.title {
                    Text(address)
                        .font(.riCaption(13))
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
