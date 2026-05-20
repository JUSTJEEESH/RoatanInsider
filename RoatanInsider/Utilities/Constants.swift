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
    // The Supabase **anon** key is a public client key — protected by the
    // database's RLS policies, not by secrecy. Embedding it in source is the
    // standard pattern for Supabase apps, same as the Storage and Functions
    // URLs above. Rotate via Supabase dashboard → Project Settings → API
    // → "Generate new anon key" and update the constant below.
    static let supabaseRESTBaseURL = "https://vbxmmslzanixvqswtnnv.supabase.co/rest/v1"
    static let supabaseFunctionsBaseURL = "https://vbxmmslzanixvqswtnnv.supabase.co/functions/v1"
    static let generateItineraryURL = supabaseFunctionsBaseURL + "/generate-itinerary"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZieG1tc2x6YW5peHZxc3d0bm52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MTQwODAsImV4cCI6MjA4ODM5MDA4MH0.pr7pUqefRULoNpIS-7b_HO7XlYskoLYYyuuI2uZZFoU"

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
