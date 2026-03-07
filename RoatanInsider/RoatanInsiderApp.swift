import SwiftUI
import SwiftData

@main
struct RoatanInsiderApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showLaunch = true
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
