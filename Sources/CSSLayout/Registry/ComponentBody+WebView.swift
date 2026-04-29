// ComponentBody+WebView — embed static HTML content via WKWebView.
//
// Useful for rendering server-authored rich text, markdown previews,
// chart SVGs, or any snippet that's easier to describe in HTML than to
// translate into SwiftUI. The `onMessage` channel turns the embed into a
// two-way surface: JavaScript running inside the page can
// `window.webkit.messageHandlers.cssLayout.postMessage({...})` and the
// Swift handler receives the dictionary synchronously.
//
// Platform guard: WKWebView is unavailable on tvOS and watchOS. On
// macOS WebKit ships via `NSViewRepresentable`; on iOS via
// `UIViewRepresentable`. Both wrappers live in this file and are
// selected by the same guard.

#if canImport(WebKit) && !os(tvOS) && !os(watchOS)

import SwiftUI
import WebKit

extension ComponentBody {

    /// Build a `ComponentBody` that renders `html` in a `WKWebView`.
    ///
    /// - Parameters:
    ///   - html: The HTML string to load. Served via `loadHTMLString`,
    ///     so external stylesheet / script references resolve relative
    ///     to `baseURL`.
    ///   - baseURL: Optional root URL for relative resource loads.
    ///   - onMessage: Callback invoked when JavaScript running inside
    ///     the page posts a dictionary to the `cssLayout` message
    ///     handler. The payload is the message's `body` if it decodes
    ///     as a `[String: String]`; other shapes are ignored.
    public static func webView(
        html: String,
        baseURL: URL? = nil,
        onMessage: @escaping ([String: String]) -> Void = { _ in }
    ) -> ComponentBody {
        ComponentBody(storage: .webView(
            html: html,
            baseURL: baseURL,
            onMessage: onMessage
        ))
    }

    // MARK: - Internal test hooks

    /// Tuple view of the stored web-view payload for
    /// `@testable import` tests. Returns nil when the body is not a
    /// webView case.
    internal var _webViewPayload: (
        html: String,
        baseURL: URL?,
        onMessage: ([String: String]) -> Void
    )? {
        if case .webView(let html, let baseURL, let onMessage) = storage {
            return (html, baseURL, onMessage)
        }
        return nil
    }
}

// MARK: - SwiftUI adapter (platform-split)

#if canImport(UIKit)

internal struct _WebViewRepresentable: UIViewRepresentable {
    let html: String
    let baseURL: URL?
    let onMessage: ([String: String]) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "cssLayout")
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.loadHTMLString(html, baseURL: baseURL)
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Re-loading on every update would reset scroll position and
        // JS state; leave the page alone and rely on the factory
        // being re-invoked when the schema actually changes.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onMessage: onMessage)
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let onMessage: ([String: String]) -> Void
        init(onMessage: @escaping ([String: String]) -> Void) {
            self.onMessage = onMessage
        }
        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            if let payload = message.body as? [String: String] {
                onMessage(payload)
            }
        }
    }
}

#elseif canImport(AppKit)

import AppKit

internal struct _WebViewRepresentable: NSViewRepresentable {
    let html: String
    let baseURL: URL?
    let onMessage: ([String: String]) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "cssLayout")
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.loadHTMLString(html, baseURL: baseURL)
        return wv
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onMessage: onMessage)
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let onMessage: ([String: String]) -> Void
        init(onMessage: @escaping ([String: String]) -> Void) {
            self.onMessage = onMessage
        }
        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            if let payload = message.body as? [String: String] {
                onMessage(payload)
            }
        }
    }
}

#endif

#endif
