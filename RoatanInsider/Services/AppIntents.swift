import Foundation
import AppIntents

/// App Intents surface for Roatán Insider — exposes the business catalogue
/// to Spotlight system search, Shortcuts, and Siri without the user opening
/// the app. "Hey Siri, show me dive shops in West End" works once this ships.
///
/// `BusinessAppEntity` is the App Intents-facing wrapper around `Business`.
/// `BusinessEntityQuery` powers the picker UI in Shortcuts and the prefix
/// search Spotlight uses.
/// `OpenBusinessIntent` is the action a tap on a Spotlight result performs —
/// it routes through the existing DeepLinkRouter so the same code path the
/// share-link sheet uses also handles system search results.

// MARK: - Business entity

struct BusinessAppEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Place on Roatán"

    static var defaultQuery = BusinessEntityQuery()

    var id: String
    var name: String
    var subtitle: String
    var slug: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(subtitle)")
    }
}

struct BusinessEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [BusinessAppEntity] {
        let businesses = await AppIntentDataBridge.shared.allBusinesses
        return identifiers.compactMap { id in
            businesses.first(where: { $0.id == id }).map { Self.entity(from: $0) }
        }
    }

    func suggestedEntities() async throws -> [BusinessAppEntity] {
        // Surface featured + insider picks first in Shortcuts pickers.
        let businesses = await AppIntentDataBridge.shared.allBusinesses
            .filter { $0.isActive && ($0.isFeatured || $0.isInsiderPick) }
            .prefix(20)
        return businesses.map { Self.entity(from: $0) }
    }

    static func entity(from business: Business) -> BusinessAppEntity {
        BusinessAppEntity(
            id: business.id,
            name: business.name,
            subtitle: "\(business.categoryDisplayName) · \(business.areaDisplayName)",
            slug: business.slug
        )
    }
}

extension BusinessEntityQuery: EntityStringQuery {
    func entities(matching string: String) async throws -> [BusinessAppEntity] {
        let businesses = await AppIntentDataBridge.shared.allBusinesses
        let tokens = SearchSynonyms.expand(string)
        guard !tokens.isEmpty else { return [] }
        let matches = businesses.filter { biz in
            let hay = biz.searchHaystack
            return tokens.contains { hay.contains($0) }
        }.prefix(20)
        return matches.map { BusinessEntityQuery.entity(from: $0) }
    }
}

// MARK: - Open business intent

struct OpenBusinessIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Place on Roatán"
    static var description = IntentDescription("Open a Roatán Insider business in the app.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Place")
    var place: BusinessAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$place)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let url = AppConstants.businessShareURL(slug: place.slug)
            ?? URL(string: "roataninsider://business/\(place.slug)")!
        AppIntentDataBridge.shared.requestRoute(url: url)
        return .result()
    }
}

// MARK: - Shortcut provider

struct RoatanInsiderShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenBusinessIntent(),
            phrases: [
                "Open \(.applicationName) place",
                "Show me a place in \(.applicationName)",
                "Find on \(.applicationName)"
            ],
            shortTitle: "Find a place",
            systemImageName: "magnifyingglass"
        )
    }
}

// MARK: - Data bridge

/// App Intents run outside the SwiftUI view tree and can't read `@Environment`,
/// so they need a way to reach the DataManager and DeepLinkRouter. The bridge
/// is a tiny singleton populated by the app once `DataManager` and
/// `DeepLinkRouter` exist. Synchronous reads only — App Intents block on this.
@MainActor
final class AppIntentDataBridge {
    static let shared = AppIntentDataBridge()
    private init() {}

    private(set) var allBusinesses: [Business] = []
    private weak var router: DeepLinkRouter?

    func install(dataManager: DataManager, router: DeepLinkRouter) {
        self.allBusinesses = dataManager.businesses
        self.router = router
    }

    func refreshBusinesses(_ businesses: [Business]) {
        self.allBusinesses = businesses
    }

    func requestRoute(url: URL) {
        router?.handle(url)
    }
}
