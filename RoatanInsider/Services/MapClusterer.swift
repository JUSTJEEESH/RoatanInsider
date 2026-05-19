import Foundation
import MapKit

/// Grid-bucketed clustering for the Roatán map. SwiftUI's `Map(position:)`
/// + `Annotation` doesn't ship with MKClusterAnnotation-style clustering,
/// so we roll our own: project lat/lng onto a grid sized by the current
/// camera span and bucket businesses into cells.
///
/// At high zoom (small span) the grid cell size collapses below a pin's
/// hit-target and clusters degenerate into individual pins — exactly the
/// behaviour the user wants when zoomed all the way in.
///
/// Stable in the sense that the same input region + business list yields
/// the same clusters across renders, which keeps map annotations from
/// thrashing during pan.
enum MapClusterer {

    struct Pin: Identifiable, Hashable {
        let id: String
        let coordinate: CLLocationCoordinate2D
        let businesses: [Business]

        var count: Int { businesses.count }
        var isCluster: Bool { businesses.count > 1 }
        var representative: Business { businesses[0] }

        static func == (lhs: Pin, rhs: Pin) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    /// Build clusters for the visible camera span.
    /// - Parameters:
    ///   - businesses: input set (already filtered by category/active).
    ///   - span: current `MKCoordinateSpan` from the camera.
    ///   - minClusterCount: clusters of fewer than this many points are
    ///     split back into individual pins (prevents a "cluster of 2" when
    ///     the user has zoomed enough to see both).
    static func cluster(
        _ businesses: [Business],
        span: MKCoordinateSpan,
        minClusterCount: Int = 3
    ) -> [Pin] {
        guard !businesses.isEmpty else { return [] }

        // Cell size: a fraction of the visible span, capped so each cell
        // is roughly the size of one pin at the current zoom. Empirically
        // 1/8th of the visible span groups well across the island.
        let cellLat = max(0.0008, span.latitudeDelta / 8.0)
        let cellLon = max(0.0008, span.longitudeDelta / 8.0)

        // When zoomed in tight, skip clustering entirely.
        if span.latitudeDelta < 0.01 {
            return businesses.map { biz in
                Pin(id: biz.id, coordinate: biz.coordinate, businesses: [biz])
            }
        }

        var buckets: [String: [Business]] = [:]
        for biz in businesses {
            let row = Int((biz.latitude / cellLat).rounded(.down))
            let col = Int((biz.longitude / cellLon).rounded(.down))
            let key = "\(row)_\(col)"
            buckets[key, default: []].append(biz)
        }

        var pins: [Pin] = []
        for (key, members) in buckets {
            if members.count < minClusterCount {
                // Split back into individual pins.
                for biz in members {
                    pins.append(Pin(id: biz.id, coordinate: biz.coordinate, businesses: [biz]))
                }
            } else {
                // Place the cluster at the centroid of its members.
                let avgLat = members.map(\.latitude).reduce(0, +) / Double(members.count)
                let avgLon = members.map(\.longitude).reduce(0, +) / Double(members.count)
                pins.append(Pin(
                    id: "cluster_\(key)",
                    coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
                    businesses: members
                ))
            }
        }
        return pins
    }

    /// Returns a new camera region that zooms in on a cluster so the user
    /// taps once to "expand" it.
    static func zoomInRegion(for pin: Pin, currentSpan: MKCoordinateSpan) -> MKCoordinateRegion {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: max(0.005, currentSpan.latitudeDelta / 3),
            longitudeDelta: max(0.005, currentSpan.longitudeDelta / 3)
        )
        return MKCoordinateRegion(center: pin.coordinate, span: newSpan)
    }
}
