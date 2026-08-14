import WidgetKit
import SwiftUI

/// The extension's entry point.
///
/// Its absence is what produced "Invalid Mach-O header. The __swift5_entry
/// section is missing" at validation. That section is emitted for a Swift
/// binary's `@main`, and this extension had none — three `Widget` types
/// compiled in, and nothing declaring which of them the extension is. The
/// archive was shipping an app extension with no entry point.
///
/// Every widget must be listed here. A `Widget` that compiles but is not in
/// this bundle simply never appears in the picker, with no error anywhere to
/// explain why.
///
/// Two things about this folder are worth knowing before touching it:
///
/// It is a synchronized group, so target membership is implicit — files are
/// never listed individually in project.pbxproj and their absence there
/// means nothing. The app target used to claim this folder too, which would
/// have put a second `@main` in the app the moment this file existed. It no
/// longer does; widget code belongs only to the extension.
///
/// The extension has no access to the app's sources. `Colors.swift` and
/// `Fonts.swift` are compiled into both targets so `riNearBlack`, `riMint`,
/// `riPink` and `riType` mean the same thing on a widget as on a screen —
/// along with `SunsetCalculator` and `CruiseActivityAttributes`. Anything
/// else from the app has to be added to this target's Sources phase before
/// a widget can use it.
@main
struct RoatanInsiderWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
        SunsetWidget()
        CruiseLiveActivity()
    }
}
