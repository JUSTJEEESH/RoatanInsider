import SwiftUI
import SwiftData
import os

@main
struct RoatanInsiderApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showLaunch = true
    private let modelContainer: ModelContainer
    private let favoritesStore: FavoritesStore

    init() {
        let schema = Schema(versionedSchema: FavoriteSchemaV1.self)
        let persistentConfig = ModelConfiguration(schema: schema)
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: schema,
                migrationPlan: FavoriteMigrationPlan.self,
                configurations: [persistentConfig]
            )
        } catch {
            // Persistent store unrecoverable (corrupt / migration failure).
            // Fall back to in-memory so the app still runs; favorites won't
            // persist across launches but the user can still use everything.
            AppLog.persistence.error("SwiftData store failed (\(error.localizedDescription)) — falling back to in-memory.")
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try! ModelContainer(
                for: schema,
                configurations: [memoryConfig]
            )
        }
        self.modelContainer = container
        self.favoritesStore = FavoritesStore(modelContext: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    ContentView(favoritesStore: favoritesStore)
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }

                if showLaunch {
                    AnimatedLaunchView {
                        showLaunch = false
                    }
                    .zIndex(1)
                }
            }
        }
        .modelContainer(modelContainer)
    }
}
