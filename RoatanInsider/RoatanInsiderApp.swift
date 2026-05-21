import SwiftUI
import Sentry

import SwiftData
import UIKit
import os

@main
struct RoatanInsiderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showLaunch = true
    @State private var profileStore = UserProfileStore()
    @State private var locationManager = LocationManager()
    @State private var purchaseManager = PurchaseManager()
    @State private var weatherService = WeatherService()
    @State private var recentlyViewed = RecentlyViewedStore()
    @State private var tripStore = TripPlanStore()
    @State private var reactions = ReactionsService()
    private let modelContainer: ModelContainer
    private let favoritesStore: FavoritesStore

    init() {
        SentrySDK.start { options in
            options.dsn = "https://2fae8a0d2affb47b0f9dfa47cf522505@o4511424942374912.ingest.us.sentry.io/4511424946503680"

            // Adds IP for users.
            // For more information, visit: https://docs.sentry.io/platforms/apple/data-management/data-collected/
            options.sendDefaultPii = true

            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0

            // Configure profiling. Visit https://docs.sentry.io/platforms/apple/profiling/ to learn more.
            options.configureProfiling = {
                $0.sessionSampleRate = 1.0 // We recommend adjusting this value in production.
                $0.lifecycle = .trace
            }

            // Uncomment the following lines to add more data to your events
            // options.attachScreenshot = true // This adds a screenshot to the error events
            // options.attachViewHierarchy = true // This adds the view hierarchy to the error events
            
            // Enable experimental logging features
            options.experimental.enableLogs = true
        }
        // Remove the next line after confirming that your Sentry integration is working.
        SentrySDK.capture(message: "This app uses Sentry! :)")

        // Schema V2 is CloudKit-compatible. The migration plan carries forward
        // any V1 favorites from existing installs without data loss.
        let schema = Schema(versionedSchema: FavoriteSchemaV2.self)

        // Try CloudKit first. If the iCloud entitlement is missing (e.g. the
        // user is signed out of iCloud, or this is a dev build without the
        // capability provisioned), SwiftData throws at container creation
        // and we fall through to a local-only store. The user never sees
        // a failure — favorites just don't sync.
        let cloudConfig = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic
        )
        let localConfig = ModelConfiguration(schema: schema)

        let container: ModelContainer
        if let cloudContainer = try? ModelContainer(
            for: schema,
            migrationPlan: FavoriteMigrationPlan.self,
            configurations: [cloudConfig]
        ) {
            AppLog.persistence.info("SwiftData store: CloudKit sync active.")
            container = cloudContainer
        } else if let localContainer = try? ModelContainer(
            for: schema,
            migrationPlan: FavoriteMigrationPlan.self,
            configurations: [localConfig]
        ) {
            AppLog.persistence.info("SwiftData store: local-only (no CloudKit entitlement).")
            container = localContainer
        } else {
            // Both persistent options exhausted — corruption or migration
            // failure. In-memory keeps the app running for the session;
            // favorites won't survive a relaunch but everything else works.
            AppLog.persistence.error("SwiftData persistent store failed — falling back to in-memory.")
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: schema, configurations: [memoryConfig])
        }
        self.modelContainer = container
        self.favoritesStore = FavoritesStore(modelContext: container.mainContext)

        // Wire analytics. Stays on LoggerBackend (console logging only) until
        // AppConstants.telemetryDeckAppID is set to a non-empty UUID, at
        // which point real events flow to the TelemetryDeck dashboard.
        if !AppConstants.telemetryDeckAppID.isEmpty {
            TelemetryDeckBackend.appID = AppConstants.telemetryDeckAppID
            Analytics.backend = TelemetryDeckBackend()
            AppLog.app.info("Analytics: TelemetryDeck backend active.")
        } else {
            AppLog.app.info("Analytics: LoggerBackend (TelemetryDeck app ID not set).")
        }
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
            .environment(profileStore)
            .environment(locationManager)
            .environment(purchaseManager)
            .environment(weatherService)
            .environment(recentlyViewed)
            .environment(tripStore)
            .environment(reactions)
        }
        .modelContainer(modelContainer)
    }
}
