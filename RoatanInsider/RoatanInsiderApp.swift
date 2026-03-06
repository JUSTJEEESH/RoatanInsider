import SwiftUI
import SwiftData

@main
struct RoatanInsiderApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    private let modelContainer: ModelContainer
    private let favoritesStore: FavoritesStore

    init() {
        let schema = Schema(versionedSchema: FavoriteSchemaV1.self)
        let config = ModelConfiguration(schema: schema)
        let container = try! ModelContainer(
            for: schema,
            migrationPlan: FavoriteMigrationPlan.self,
            configurations: [config]
        )
        self.modelContainer = container
        self.favoritesStore = FavoritesStore(modelContext: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView(favoritesStore: favoritesStore)
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .modelContainer(modelContainer)
    }
}
