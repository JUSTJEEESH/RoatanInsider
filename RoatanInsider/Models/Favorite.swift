import Foundation
import SwiftData

// MARK: - Current Schema

enum FavoriteSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Favorite.self] }

    @Model
    final class Favorite {
        @Attribute(.unique) var businessId: String
        var dateAdded: Date

        init(businessId: String, dateAdded: Date = .now) {
            self.businessId = businessId
            self.dateAdded = dateAdded
        }
    }
}

// Type alias so existing code continues to work
typealias Favorite = FavoriteSchemaV1.Favorite

// MARK: - Migration Plan

enum FavoriteMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [FavoriteSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        // No migrations yet — will be added when schema changes
        []
    }
}
