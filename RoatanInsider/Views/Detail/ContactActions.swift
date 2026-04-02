import SwiftUI
import MapKit

struct ContactActions: View {
    let business: Business
    @State private var showingMenu = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
            if let menuImages = business.menuImages, !menuImages.isEmpty {
                contactButton(icon: "menucard", label: "Menu") {
                    showingMenu = true
                }
            }

            if let whatsapp = business.whatsapp {
                contactButton(icon: "message", label: "WhatsApp") {
                    let cleaned = whatsapp.replacingOccurrences(of: "+", with: "")
                        .replacingOccurrences(of: " ", with: "")
                        .replacingOccurrences(of: "-", with: "")
                    if let url = URL(string: "https://wa.me/\(cleaned)") {
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

            if let website = business.website {
                contactButton(icon: "safari", label: "Website") {
                    if let url = URL(string: website) {
                        UIApplication.shared.open(url)
                    }
                }
            }

            if let facebook = business.facebook {
                contactButton(icon: "hand.thumbsup", label: "Facebook") {
                    if let url = URL(string: facebook) {
                        UIApplication.shared.open(url)
                    }
                }
            }

            if let instagram = business.instagram {
                contactButton(icon: "camera", label: "Instagram") {
                    if let url = URL(string: instagram) {
                        UIApplication.shared.open(url)
                    }
                }
            }

        }
        }
        .fullScreenCover(isPresented: $showingMenu) {
            MenuGalleryView(
                businessName: business.name,
                menuImages: business.menuImages ?? [],
                slug: business.slug
            )
        }
    }

    private func contactButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact()
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.riDark)

                Text(label)
                    .font(.riCaption(11))
                    .foregroundStyle(Color.riMediumGray)
            }
            .frame(width: 64)
            .frame(height: AppConstants.minTapTarget)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
