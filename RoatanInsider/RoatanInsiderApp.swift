import SwiftUI
import SwiftData
import UIKit
import Sentry
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
    @State private var trending = TrendingReactionsService()
    @State private var arrival = ArrivalDetector()
    private let modelContainer: ModelContainer
    private let favoritesStore: FavoritesStore

    init() {
        // Sentry: crashes + performance + profiling. Guarded so the app
        // gracefully degrades if the DSN constant is ever cleared (e.g.
        // for a build that intentionally doesn't report to Sentry).
        //
        // Sample rates: 100% in DEBUG so we can see everything while
        // developing; 20% in RELEASE to keep production transaction
        // volume + cost reasonable. Crashes are sent 100% regardless of
        // the traces rate — that's a separate sampler controlled by the
        // SDK internals.
        if !AppConstants.sentryDSN.isEmpty {
            SentrySDK.start { options in
                options.dsn = AppConstants.sentryDSN
                options.sendDefaultPii = true
                #if DEBUG
                options.environment = "debug"
                options.tracesSampleRate = 1.0
                options.configureProfiling = {
                    $0.sessionSampleRate = 1.0
                    $0.lifecycle = .trace
                }
                #else
                options.environment = "release"
                options.tracesSampleRate = 0.2
                options.configureProfiling = {
                    $0.sessionSampleRate = 0.2
                    $0.lifecycle = .trace
                }
                #endif
                options.attachScreenshot = true
                options.attachViewHierarchy = true
                options.experimental.enableLogs = true
            }
            AppLog.app.info("Sentry: crash reporting + perf active.")
        }

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
            .environment(trending)
            .environment(arrival)
        }
        .modelContainer(modelContainer)
    }
}
