import Foundation
import CoreLocation

enum AppConstants {
    static let appName = "Roatán Insider"
    static let subtitle = "Your Local Guide to Roatán"
    static let tagline = "Explore the island like a local."

    // Currency
    static let usdToHnlRate: Double = 24.85

    // Map
    static let roatanCenter = CLLocationCoordinate2D(latitude: 16.3300, longitude: -86.5200)
    static let roatanSpanLat: Double = 0.20
    static let roatanSpanLon: Double = 0.40

    // Supabase Storage
    static let supabaseStorageBaseURL = "https://vbxmmslzanixvqswtnnv.supabase.co/storage/v1/object/public/business-photos/"

    // Design
    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 16
    static let buttonHeight: CGFloat = 50
    static let minTapTarget: CGFloat = 44
    static let sectionPadding: CGFloat = 48

    // Default tip percentages
    static let tipPercentages = [10, 15, 18, 20]
    static let quickAmounts = [5, 10, 20, 50, 100]
}
