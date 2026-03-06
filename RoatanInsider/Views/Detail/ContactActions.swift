import SwiftUI

struct ContactActions: View {
    let business: Business

    var body: some View {
        HStack(spacing: 0) {
            if let phone = business.phone {
                contactButton(icon: "phone", label: "Call") {
                    if let url = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                        UIApplication.shared.open(url)
                    }
                }
            }

            if let whatsapp = business.whatsapp {
                contactButton(icon: "message", label: "WhatsApp") {
                    if let url = URL(string: "https://wa.me/\(whatsapp.replacingOccurrences(of: "+", with: ""))") {
                        UIApplication.shared.open(url)
                    }
                }
            }

            if let website = business.website {
                contactButton(icon: "safari", label: "Website") {
                    if let url = URL(string: website) {
                        UIApplication.shared.open(url)
                    }
                }
            }

            contactButton(icon: "arrow.triangle.turn.up.right.diamond", label: "Directions") {
                let coordinate = business.coordinate
                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                mapItem.name = business.name
                mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
            }
        }
    }

    private func contactButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.riDark)

                Text(label)
                    .font(.riCaption(11))
                    .foregroundStyle(Color.riMediumGray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppConstants.minTapTarget)
        }
        .buttonStyle(.plain)
    }
}

import MapKit
