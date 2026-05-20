import Foundation
import CoreLocation

enum AppConstants {
    static let appName = "Roatán Insider"
    static let subtitle = "Your Local Guide to Roatán"
    static let tagline = "Explore the island like a local."

    // Currency (fallback rates when offline)
    static let usdToHnlRate: Double = 26.10
    static let usdToCadRate: Double = 1.44  // ~Mar 2026
    static let usdToEurRate: Double = 0.92  // ~Mar 2026

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
    // The base URL is constant; supply your project's **anon** public key
    // either by setting `supabaseAnonKey` to a non-empty string below or via
    // the `SUPABASE_ANON_KEY` Info.plist key (preferred — keeps the key out
    // of source). Empty means reactions stay local-only; sync silently skips.
    static let supabaseRESTBaseURL = "https://vbxmmslzanixvqswtnnv.supabase.co/rest/v1"
    static var supabaseAnonKey: String {
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String, !key.isEmpty {
            return key
        }
        return ""
    }

    // Design
    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 16
    static let buttonHeight: CGFloat = 50
    static let minTapTarget: CGFloat = 44
    static let sectionPadding: CGFloat = 48

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
