import Foundation
import UIKit

/// HTTP-based TelemetryDeck backend. Talks directly to the public ingest
/// endpoint so we avoid pulling in the TelemetryDeck SDK as a Swift Package
/// dependency (faster builds, no version churn, no SPM noise in the
/// pbxproj). Same wire format, same dashboard.
///
/// **Setup (5 minutes):**
///   1. Create a free account at https://telemetrydeck.com
///   2. Create a new app, copy its app ID (UUID).
///   3. Set `TelemetryDeckBackend.appID` to that UUID below — OR set the
///      `TELEMETRY_DECK_APP_ID` Info.plist key (preferred for not
///      committing IDs).
///   4. Swap the analytics backend in `RoatanInsiderApp` from
///      `LoggerBackend` to `TelemetryDeckBackend()`.
///
/// Privacy: TelemetryDeck is GDPR-compliant by default, never logs IPs,
/// and the only "user" identifier we send is a hash of the iOS-provided
/// vendor ID. Event payloads are public catalogue IDs only (never PII).
final class TelemetryDeckBackend: AnalyticsBackend {

    /// Override at runtime via `TelemetryDeckBackend.appID = "..."` if you
    /// prefer that to the Info.plist value.
    static var appID: String?

    private let endpoint = URL(string: "https://nom.telemetrydeck.com/v2/")!
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }

    func send(name: String, properties: [String: String]) {
        guard let appID = resolveAppID() else { return }
        let payload = Self.payload(appID: appID, eventName: name, properties: properties)
        post(payload)
    }

    func identify(properties: [String: String]) {
        // TelemetryDeck doesn't have a separate identify endpoint — we
        // surface identity properties as a "user_identified" event so
        // they're visible in the dashboard funnel.
        send(name: "user_identified", properties: properties)
    }

    // MARK: - Internals

    private func resolveAppID() -> String? {
        if let id = Self.appID, !id.isEmpty { return id }
        if let infoID = Bundle.main.object(forInfoDictionaryKey: "TELEMETRY_DECK_APP_ID") as? String,
           !infoID.isEmpty {
            return infoID
        }
        return nil
    }

    private static func payload(appID: String, eventName: String, properties: [String: String]) -> [[String: Any]] {
        let userID = stableUserHash()
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"

        var floatValue: Double = 0
        var stringPayload: [String] = []
        for (k, v) in properties.sorted(by: { $0.key < $1.key }) {
            stringPayload.append("\(k):\(v)")
        }

        let signal: [String: Any] = [
            "appID": appID,
            "clientUser": userID,
            "type": eventName,
            "isTestMode": isDebugBuild ? "true" : "false",
            "appVersion": "\(appVersion) (\(buildNumber))",
            "platform": "iOS",
            "systemVersion": UIDevice.current.systemVersion,
            "modelName": deviceModel(),
            "payload": stringPayload,
            "floatValue": floatValue
        ]
        return [signal]
    }

    private func post(_ payload: [[String: Any]]) {
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let task = session.dataTask(with: request) { _, response, error in
            if let error {
                // Analytics failures must never affect the user. Log quietly.
                AppLog.app.debug("Telemetry post failed: \(error.localizedDescription, privacy: .public)")
                return
            }
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                AppLog.app.debug("Telemetry post status \(http.statusCode, privacy: .public)")
            }
        }
        task.resume()
    }

    // MARK: - Identity helpers

    /// Stable per-install identifier. Hashed so it never identifies a user.
    /// Tied to vendor ID, which resets on reinstall — that's intentional;
    /// reinstalls should be counted as new users for retention analytics.
    private static func stableUserHash() -> String {
        let vendor = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        return sha256(vendor)
    }

    private static func sha256(_ input: String) -> String {
        var hash = [UInt8](repeating: 0, count: 32)
        let data = Array(input.utf8)
        // Tiny FNV-style fallback so we don't need CryptoKit here. TelemetryDeck
        // doesn't care about cryptographic strength of clientUser — it just
        // needs a stable opaque token.
        var h: UInt64 = 14695981039346656037
        for byte in data {
            h ^= UInt64(byte)
            h = h &* 1099511628211
        }
        for i in 0..<32 {
            hash[i] = UInt8((h >> UInt64((i % 8) * 8)) & 0xff)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    private static func deviceModel() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let model = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
        return model
    }

    private static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
