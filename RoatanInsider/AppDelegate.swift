import UIKit

/// SwiftUI-friendly AppDelegate adaptor. Exists for the one job no SwiftUI
/// lifecycle hook handles: receiving the APNs device token after registration.
///
/// SwiftUI's App lifecycle has no equivalent of
/// `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` —
/// `@UIApplicationDelegateAdaptor` is Apple's blessed escape hatch.
///
/// Keep this file tiny. Anything more than push-token plumbing belongs in
/// a Service that the App or ContentView owns.
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Don't auto-register here — we wait until the user has actually
        // granted notification permission via NotificationManager. Registration
        // before authorization is allowed but wastes a token that won't be
        // useful until the user opts in.
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            NotificationManager.shared.registerDeviceToken(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        AppLog.app.warning("APNs registration failed: \(error.localizedDescription)")
    }
}
