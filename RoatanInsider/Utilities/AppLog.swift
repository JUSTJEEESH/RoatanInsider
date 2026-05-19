import Foundation
import os

/// Centralised `Logger` categories. Replaces `print` so messages survive in
/// the unified logging system (Console.app, sysdiagnose) and can be filtered
/// per subsystem without touching code.
enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.roataninsider.app"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let data = Logger(subsystem: subsystem, category: "data")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let images = Logger(subsystem: subsystem, category: "images")
    static let favorites = Logger(subsystem: subsystem, category: "favorites")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let search = Logger(subsystem: subsystem, category: "search")
    static let purchase = Logger(subsystem: subsystem, category: "purchase")
}
