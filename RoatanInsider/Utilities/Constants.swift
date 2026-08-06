import Foundation
import CoreLocation

enum AppConstants {
    static let appName = "Roatán Insider"
    static let subtitle = "Your Local Guide to Roatán"
    static let tagline = "Explore the island like a local."

    // Currency — OFFLINE FALLBACK ONLY. `ExchangeRateService` fetches live
    // rates on launch; these are what a user sees with no signal, so they
    // are labelled as approximate in the UI rather than presented as today's
    // rate. Verified against open.er-api.com on 5 Aug 2026 — refresh when
    // they drift more than a few percent.
    static let usdToHnlRate: Double = 26.80
    static let usdToCadRate: Double = 1.41
    static let usdToEurRate: Double = 0.87

    // Map
    static let roatanCenter = CLLocationCoordinate2D(latitude: 16.3300, longitude: -86.5200)
    static let roatanSpanLat: Double = 0.20
    static let roatanSpanLon: Double = 0.40

    // Supabase Storage
    static let supabaseStorageBaseURL = "https://vbxmmslzanixvqswtnnv.supabase.co/storage/v1/object/public/business-photos/"

    // Remote data (Supabase Storage bucket: app-data)
    static let supabaseDataBaseURL = "https://vbxmmslzanixvqswtnnv.supabase.co/storage/v1/object/public/app-data/"
    static let remoteManifestURL = supabaseDataBaseURL + "manifest.json"
    static let remoteBusinessesURL = supabaseDataBaseURL + "businesses.json"
    static let dataRefreshMinInterval: TimeInterval = 900 // 15 minutes

    // Supabase REST API (reactions + future user data).
    // The Supabase **anon** key is a public client key — protected by the
    // database's RLS policies, not by secrecy. Embedding it in source is the
    // standard pattern for Supabase apps, same as the Storage and Functions
    // URLs above. Rotate via Supabase dashboard → Project Settings → API
    // → "Generate new anon key" and update the constant below.
    static let supabaseRESTBaseURL = "https://vbxmmslzanixvqswtnnv.supabase.co/rest/v1"
    static let supabaseFunctionsBaseURL = "https://vbxmmslzanixvqswtnnv.supabase.co/functions/v1"
    static let generateItineraryURL = supabaseFunctionsBaseURL + "/generate-itinerary"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZieG1tc2x6YW5peHZxc3d0bm52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MTQwODAsImV4cCI6MjA4ODM5MDA4MH0.pr7pUqefRULoNpIS-7b_HO7XlYskoLYYyuuI2uZZFoU"

    // TelemetryDeck (privacy-first product analytics — https://telemetrydeck.com).
    // Sign in → create app → copy the App ID UUID → paste below. Until this
    // string is non-empty, Analytics stays on the local LoggerBackend (events
    // print to the Xcode console only).
    static let telemetryDeckAppID = "1AAD1B5F-E28F-4C1C-84FB-E79D23BAD654"

    // Sentry (crash reporting + perf — https://sentry.io). DSN is a public
    // identifier safe to commit (it routes events to our project; you can't
    // read events back from it). Auth token for dSYM upload lives in
    // .sentryclirc which is gitignored.
    static let sentryDSN = "https://2fae8a0d2affb47b0f9dfa47cf522505@o4511424942374912.ingest.us.sentry.io/4511424946503680"

    // Design
    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 16
    static let buttonHeight: CGFloat = 50
    static let minTapTarget: CGFloat = 44
    static let sectionPadding: CGFloat = 48

    // MARK: - Radius scale
    //
    // Three values, down from nine (2, 4, 8, 10, 12, 14, 16 and 18 were all
    // in use). Inconsistent rounding is the detail a trained eye catches
    // before it can name it — it reads as assembled rather than drawn.
    enum Radius {
        static let small: CGFloat = 8    // chips, tags, inputs
        static let card: CGFloat = 16    // cards, list rows, panels
        static let sheet: CGFloat = 28   // sheets, hero surfaces
    }

    // MARK: - Spacing scale
    //
    // Six steps, anchored to the 20pt gutter and 48pt section padding
    // already in use above, so adopting it moves nothing that exists.
    enum Space {
        static let hair: CGFloat = 4     // inside a label
        static let tight: CGFloat = 8    // inside a control
        static let snug: CGFloat = 12    // between rows in a card
        static let gutter: CGFloat = 20  // card padding, page margins
        static let block: CGFloat = 32   // between blocks in a section
        static let section: CGFloat = 48 // between sections
    }

    // Default tip percentages
    static let tipPercentages = [10, 15, 18, 20]
    static let quickAmounts = [5, 10, 20, 50, 100]

    // MARK: - Real, verified destinations
    //
    // These are the live Casa Mañana pages. Everything user-facing (Settings,
    // paywall, support) must point here. They are NOT derived from
    // `webOrigin` — that constant is a placeholder domain (see below) and
    // deriving legal links from it is how they were wrong for months.
    static let privacyURL = "https://www.casamananaroatan.com/app/privacy/"
    static let supportURL = "https://www.casamananaroatan.com/app/support/"
    static let supportEmail = "josh@casamananaroatan.com"

    /// Terms of Use. An auto-renewing subscription must link one, and until
    /// Casa Mañana publishes its own we link Apple's standard EULA — the
    /// documented, App-Review-accepted answer when you haven't written your
    /// own. Set this to the real page (e.g. .../app/terms/) and every link
    /// switches over.
    static let ownTermsURL = ""
    static let appleStandardEULA = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    static var termsURL: String { ownTermsURL.isEmpty ? appleStandardEULA : ownTermsURL }

    // MARK: - Sharing
    //
    // Shared links point at the App Store listing: there's no per-business
    // web page to send people to, and a friend who taps the link gets the
    // app. Previously these pointed at roataninsider.com/b/<slug>, a domain
    // that has never existed — every link ever shared from this app is dead.
    //
    // ⚠️ SET THIS. Find it in App Store Connect → your app → App Information
    // → "Apple ID" (a 9–10 digit number). While it's empty, sharing falls
    // back to text only — no link at all — because a share with no URL is
    // better than a share with a broken one.
    static let appStoreID = ""

    static var appStoreURL: URL? {
        guard !appStoreID.isEmpty else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreID)")
    }

    /// Nil until `appStoreID` is set, which callers must treat as
    /// "share without a link" rather than substituting a placeholder.
    static func businessShareURL(slug: String) -> URL? {
        appStoreURL
    }

    // Universal Links — the inbound half of deep linking. `DeepLinkRouter`
    // still parses this host, but there's no associated-domains entitlement,
    // so no https link currently reopens the app; only the roataninsider://
    // custom scheme works. Kept for the router's parsing and for widgets.
    static let webOrigin = "https://roataninsider.com"
}
