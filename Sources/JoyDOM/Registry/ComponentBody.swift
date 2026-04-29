// ComponentBody — the wrapper value a `ComponentFactory` returns.
//
// Tier 2 introduces this type between the factory and the resolver so the
// registry's public API no longer speaks `AnyView` directly. That keeps the
// door open for non-SwiftUI rendering backends (UIKit, WKWebView, Flutter,
// etc.) — each arrives as its own static factory on `ComponentBody` that
// wraps the host-native view into a SwiftUI-consumable surface via
// `UIViewRepresentable` / `NSViewRepresentable`.
//
// Phase: Tier 2. Today only `.custom` is implemented; `.uiKit` and
// `.webView` land in subsequent units of this plan.

import SwiftUI

/// The output of a ``ComponentFactory``.
///
/// Construct one via a static factory (`.custom`, and — in later units —
/// `.uiKit`, `.webView`). The resolver calls ``makeView()`` to obtain the
/// SwiftUI-consumable view it inserts into the flex tree.
public struct ComponentBody {

    /// Type-erased storage for each supported backend. Kept internal so
    /// tests (`@testable import`) can introspect without the cases
    /// leaking into the public surface.
    internal enum Storage {
        /// A pure SwiftUI body built by the caller's `@ViewBuilder`.
        case custom(() -> AnyView)
        #if canImport(UIKit) && !os(watchOS)
        /// A UIKit `UIView` lifted into the pipeline. The closures are
        /// erased to `UIView` so `Storage` can remain non-generic; the
        /// public `.uiKit(make:update:)` factory re-casts at the edge.
        case uiKit(make: () -> UIView, update: (UIView) -> Void)
        #endif
        #if canImport(WebKit) && !os(tvOS) && !os(watchOS)
        /// Static HTML rendered through `WKWebView`, with an optional
        /// channel for JS-originated messages back into Swift.
        case webView(html: String, baseURL: URL?, onMessage: ([String: String]) -> Void)
        #endif
    }

    /// Tag mirrored onto `Storage` for test assertions.
    internal enum Kind: Equatable {
        case custom
        #if canImport(UIKit) && !os(watchOS)
        case uiKit
        #endif
        #if canImport(WebKit) && !os(tvOS) && !os(watchOS)
        case webView
        #endif
    }

    internal let storage: Storage

    internal var kind: Kind {
        switch storage {
        case .custom: return .custom
        #if canImport(UIKit) && !os(watchOS)
        case .uiKit:  return .uiKit
        #endif
        #if canImport(WebKit) && !os(tvOS) && !os(watchOS)
        case .webView: return .webView
        #endif
        }
    }

    internal init(storage: Storage) {
        self.storage = storage
    }

    /// Build a `ComponentBody` that renders a SwiftUI view.
    ///
    /// The closure runs every time ``makeView()`` is called. Callers must
    /// not assume single invocation — SwiftUI may rebuild the wrapped view
    /// repeatedly during a layout pass.
    public static func custom<V: View>(_ build: @escaping () -> V) -> ComponentBody {
        ComponentBody(storage: .custom { AnyView(build()) })
    }

    /// Produce the SwiftUI view. The resolver inserts the result into the
    /// flex tree — callers typically don't invoke this directly.
    public func makeView() -> AnyView {
        switch storage {
        case .custom(let build):
            return build()
        #if canImport(UIKit) && !os(watchOS)
        case .uiKit(let make, let update):
            return AnyView(_UIKitRepresentable(make: make, update: update))
        #endif
        #if canImport(WebKit) && !os(tvOS) && !os(watchOS)
        case .webView(let html, let baseURL, let onMessage):
            return AnyView(_WebViewRepresentable(
                html: html, baseURL: baseURL, onMessage: onMessage
            ))
        #endif
        }
    }
}

#if canImport(UIKit) && !os(watchOS)
import UIKit

/// Private SwiftUI adapter for UIKit-backed `ComponentBody` storage.
/// Consumers never see this type directly — they get an `AnyView` out
/// of `makeView()`.
internal struct _UIKitRepresentable: UIViewRepresentable {
    let make: () -> UIView
    let update: (UIView) -> Void

    func makeUIView(context: Context) -> UIView { make() }
    func updateUIView(_ uiView: UIView, context: Context) { update(uiView) }
}
#endif
