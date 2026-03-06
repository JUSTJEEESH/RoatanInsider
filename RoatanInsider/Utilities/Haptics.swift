import UIKit

enum Haptics {
    private static let impactLight = UIImpactFeedbackGenerator(style: .light)
    private static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private static let selection = UISelectionFeedbackGenerator()
    private static let notification = UINotificationFeedbackGenerator()

    /// Light tap — filter chips, tab switches, minor toggles
    static func tap() {
        impactLight.impactOccurred()
    }

    /// Medium tap — favorite toggle, primary button presses
    static func impact() {
        impactMedium.impactOccurred()
    }

    /// Subtle selection change — scrolling through options, picker changes
    static func select() {
        selection.selectionChanged()
    }

    /// Success — conversion complete, favorite saved
    static func success() {
        notification.notificationOccurred(.success)
    }

    /// Error — invalid input
    static func error() {
        notification.notificationOccurred(.error)
    }
}
