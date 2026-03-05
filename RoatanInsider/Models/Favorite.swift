import Foundation
import SwiftData

@Model
final class Favorite {
    @Attribute(.unique) var businessId: String
    var dateAdded: Date

    init(businessId: String, dateAdded: Date = .now) {
        self.businessId = businessId
        self.dateAdded = dateAdded
    }
}
