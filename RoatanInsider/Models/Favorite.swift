import Foundation
import SwiftData

// MARK: - V1 — original local-only schema
//
// Held a `@Attribute(.unique)` constraint on businessId and non-optional
// properties. Both are incompatible with CloudKit (CloudKit doesn't enforce
// uniqueness across devices and SwiftData+CloudKit requires every property
// to be optional OR have a default). V1 survives as the migration source so
// existing on-device favorites carry forward intact.

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

// MARK: - V2 — CloudKit-compatible
//
// Drops `.unique` (uniqueness is now enforced in `FavoritesStore` via the
// in-memory Set; CloudKit can't promise it across devices anyway). Both
// properties get defaults so SwiftData+CloudKit's required-or-default
// invariant is satisfied. Property names stay identical so call sites
// don't need to change.

enum FavoriteSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [Favorite.self] }

    @Model
    final class Favorite {
        // SwiftData's @Model macro can't resolve `.now` at expansion time
        // (it sees `.now` as `Any?` with no member), so defaults must be
        // fully-qualified expressions. `Date()` gives us the same effective
        // result (current time on first insert).
        var businessId: String = ""
        var dateAdded: Date = Date()

        init(businessId: String, dateAdded: Date = .now) {
            self.businessId = businessId
            self.dateAdded = dateAdded
        }
    }
}

// Type alias points at the current schema. Call sites use `Favorite`
// transparently — no churn at the use site when we bump versions again.
typealias Favorite = FavoriteSchemaV2.Favorite

// MARK: - Migration Plan

enum FavoriteMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [FavoriteSchemaV1.self, FavoriteSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [
            // V1 → V2: lightweight. Same property names and types; we're only
            // relaxing the unique constraint and adding default values, both
            // of which Core Data handles automatically without a custom
            // willMigrate/didMigrate.
            .lightweight(fromVersion: FavoriteSchemaV1.self, toVersion: FavoriteSchemaV2.self)
        ]
    }
}

