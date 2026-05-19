import Foundation
import UserNotifications
import UIKit

/// Centralised notification orchestration. Handles both local notifications
/// (scheduled by the app — no backend needed) and APNs device-token
/// registration (handed off to your Supabase backend for remote sends).
///
/// Local notifications shipped here:
///   - Sunset alert: fires 30 min before sundown if the user has saved at
///     least one west-facing place.
///   - Trip arrival reminder: 1 day before arrivalDate, if the user filled
///     in their dates during onboarding.
///   - Final-day nudge: morning of departureDate.
///
/// Remote push hookup:
///   - When APNs returns a token via UIApplication.shared.registerForRemoteNotifications
///     the AppDelegate forwards it to `registerDeviceToken(_:)`.
///   - That posts to a Supabase Edge Function (`/functions/v1/register-device`)
///     so the backend can target this device for editorial pushes ("Tonight
///     only: live music at Sundowners").
///   - Until the backend exists, registration is a no-op stub.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: - Authorization

    func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            if granted {
                await UIApplication.shared.registerForRemoteNotifications()
            }
            return granted
        @unknown default:
            return false
        }
    }

    // MARK: - Local notifications

    enum Reminder {
        static let sunset = "ri.reminder.sunset"
        static let arrival = "ri.reminder.arrival"
        static let departure = "ri.reminder.departure"
    }

    /// Schedule (or re-schedule) all local notifications based on the latest
    /// profile state. Call this on app launch, after onboarding, after the
    /// user edits their trip dates, and on .active scene phase.
    func scheduleAll(profile: UserProfile) async {
        await cancelAll()

        // Sunset alert — daily, 30 min before today's sundown.
        await scheduleSunsetAlert()

        // Trip-stage reminders.
        if let arrival = profile.arrivalDate {
            await scheduleArrivalReminder(arrival: arrival)
        }
        if let departure = profile.departureDate {
            await scheduleDepartureReminder(departure: departure)
        }
    }

    private func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            Reminder.sunset, Reminder.arrival, Reminder.departure
        ])
    }

    private func scheduleSunsetAlert() async {
        let sunset = SunsetCalculator.todaySunset()
        let triggerDate = sunset.addingTimeInterval(-30 * 60)
        guard triggerDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Sunset in 30 minutes"
        content.body = "Grab a west-facing seat. \(SunsetCalculator.sunsetTimeString()) on the dot."
        content.sound = .default
        content.threadIdentifier = "sunset"

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: Reminder.sunset, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    private func scheduleArrivalReminder(arrival: Date) async {
        let cal = Calendar.current
        guard let triggerDate = cal.date(byAdding: .day, value: -1, to: arrival),
              triggerDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "You're on Roatán tomorrow"
        content.body = "Your itinerary is ready. Don't forget cash and a snorkel."
        content.sound = .default
        content.threadIdentifier = "trip"

        var components = cal.dateComponents([.year, .month, .day], from: triggerDate)
        components.hour = 18
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: Reminder.arrival, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    private func scheduleDepartureReminder(departure: Date) async {
        let cal = Calendar.current
        var components = cal.dateComponents([.year, .month, .day], from: departure)
        components.hour = 8
        components.minute = 30
        guard let triggerDate = cal.date(from: components), triggerDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Last day on the island"
        content.body = "Make it count. The good places stay open late."
        content.sound = .default
        content.threadIdentifier = "trip"

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: Reminder.departure, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Remote push registration

    /// Called from the AppDelegate when APNs returns a device token.
    func registerDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        AppLog.app.notice("Got APNs device token (\(tokenString.count, privacy: .public) chars)")

        // Hand off to the Supabase edge function. Wire this once the backend
        // function exists; until then, just log and return.
        Task {
            await sendTokenToBackend(tokenString)
        }
    }

    private func sendTokenToBackend(_ token: String) async {
        guard let url = URL(string: "\(AppConstants.webOrigin)/functions/v1/register-device") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "token": token,
            "platform": "ios",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                AppLog.app.warning("Token registration returned \(http.statusCode)")
            }
        } catch {
            // Backend may not exist yet — log quietly and move on.
            AppLog.app.debug("Token registration not delivered: \(error.localizedDescription)")
        }
    }
}
