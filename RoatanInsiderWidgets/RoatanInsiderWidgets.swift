import WidgetKit
import SwiftUI

/// Widget bundle entry point. Add a new "Widget Extension" target in Xcode
/// named `RoatanInsiderWidgets`, replace the stub `*Bundle.swift` with this
/// file, and drop the rest of the files in this folder beside it.
///
/// All widgets here are read-only — they pull from local-only data
/// (SunsetCalculator) or from values written by the host app into a shared
/// App Group via `WidgetSharedDefaults`. No network calls happen inside the
/// widget process; WidgetKit refreshes are budgeted by iOS.
@main
struct RoatanInsiderWidgets: WidgetBundle {
    var body: some Widget {
        SunsetWidget()
        TodayWidget()
        // Cruise Live Activity is defined in CruiseLiveActivity.swift —
        // ActivityConfiguration counts as a Widget so it goes in this bundle.
        CruiseLiveActivity()
    }
}
