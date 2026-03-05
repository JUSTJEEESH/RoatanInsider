import SwiftUI
import MapKit

struct MiniMapView: View {
    let coordinate: CLLocationCoordinate2D
    let name: String

    var body: some View {
        Map {
            Marker(name, coordinate: coordinate)
                .tint(.riPink)
        }
        .mapStyle(.standard)
        .disabled(true)
        .allowsHitTesting(false)
    }
}
