import SwiftUI
import SwiftData

@main
struct RoatanInsiderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Favorite.self)
    }
}
