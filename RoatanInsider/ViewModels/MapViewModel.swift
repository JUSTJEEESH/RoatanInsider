import SwiftUI
import MapKit

@Observable
final class MapViewModel {
    var selectedCategory: Category?
    var selectedBusiness: Business?
    var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: AppConstants.roatanCenter,
            span: MKCoordinateSpan(
                latitudeDelta: AppConstants.roatanSpanLat,
                longitudeDelta: AppConstants.roatanSpanLon
            )
        )
    )

    func filteredBusinesses(from businesses: [Business]) -> [Business] {
        let active = businesses.filter { $0.isActive }
        if let cat = selectedCategory {
            return active.filter { $0.category == cat }
        }
        return active
    }
}
