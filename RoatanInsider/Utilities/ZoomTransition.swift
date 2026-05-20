import SwiftUI

/// Environment key that lets nested view hierarchies opt into a shared zoom
/// namespace for `.matchedTransitionSource` / `.navigationTransition(.zoom)`
/// without each container threading a `@Namespace` through props.
///
/// Pattern:
///   1. A `NavigationStack` root declares `@Namespace private var zoomNS`
///      and writes it via `.environment(\.zoomNamespace, zoomNS)`.
///   2. Source views (BusinessCard) read it via `@Environment(\.zoomNamespace)`
///      and apply `.modifier(ZoomSourceModifier(id:, namespace:))`.
///   3. Destination views (BusinessDetailView) read the same value and apply
///      `.modifier(ZoomDestinationModifier(id:, namespace:))`.
///
/// Both modifiers no-op cleanly on iOS 17 (where the underlying APIs don't
/// exist) and when no namespace has been injected — so the app degrades to
/// the standard slide-in push transition.
private struct ZoomNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var zoomNamespace: Namespace.ID? {
        get { self[ZoomNamespaceKey.self] }
        set { self[ZoomNamespaceKey.self] = newValue }
    }
}

/// Applies `.matchedTransitionSource(id:in:)` on iOS 18+ when a namespace is
/// available. iOS 17 and unset-namespace cases are silently passthrough.
struct ZoomSourceModifier: ViewModifier {
    let id: String
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *), let namespace {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

/// Applies `.navigationTransition(.zoom(sourceID:in:))` on iOS 18+ when a
/// namespace is available. Same passthrough behaviour as the source modifier.
struct ZoomDestinationModifier: ViewModifier {
    let id: String
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *), let namespace {
            content.navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            content
        }
    }
}
