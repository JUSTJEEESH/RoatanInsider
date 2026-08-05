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

    // Web / Universal Links — used by ShareLink, future notifications, widgets,
    // and App Intents to deep-link into specific content. Update `webOrigin` to
    // match the live AASA-registered domain.
    static let webOrigin = "https://roataninsider.com"

    static func businessShareURL(slug: String) -> URL? {
        guard !slug.isEmpty else { return nil }
        return URL(string: "\(webOrigin)/b/\(slug)")
    }
}
