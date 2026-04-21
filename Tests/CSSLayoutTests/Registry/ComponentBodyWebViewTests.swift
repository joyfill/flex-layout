#if canImport(WebKit) && !os(tvOS) && !os(watchOS)

import XCTest
import SwiftUI
@testable import CSSLayout

/// Unit 6 — `ComponentBody.webView(html:baseURL:onMessage:)` embeds a
/// static HTML page via WKWebView with a JS → Swift message channel.
///
/// We drive the stored `onMessage` closure directly through
/// `_webViewPayload` so the tests never construct a real `WKWebView`
/// (which would flake outside a SwiftUI layout pass and cost a WebKit
/// process per case). Live `WKWebView` instantiation is covered by the
/// demo smoke checklist in Unit 8.
final class ComponentBodyWebViewTests: XCTestCase {

    func testWebViewStoresHTMLAndBaseURL() {
        let html = "<h1>hi</h1>"
        let base = URL(string: "https://example.com")!
        let body = ComponentBody.webView(html: html, baseURL: base)

        guard let payload = body._webViewPayload else {
            XCTFail("_webViewPayload must return the stored webView parameters")
            return
        }
        XCTAssertEqual(payload.html, html)
        XCTAssertEqual(payload.baseURL, base)
    }

    func testWebViewOnMessageDispatchesPayloads() {
        var received: [[String: String]] = []
        let body = ComponentBody.webView(
            html: "<p/>",
            onMessage: { received.append($0) }
        )

        guard let payload = body._webViewPayload else {
            XCTFail("_webViewPayload must return the stored webView parameters")
            return
        }
        payload.onMessage(["event": "click", "id": "btn"])
        payload.onMessage(["event": "submit"])

        XCTAssertEqual(received.count, 2)
        XCTAssertEqual(received.first?["event"], "click")
        XCTAssertEqual(received.last?["event"], "submit")
    }

    func testWebViewMakeViewReturnsAnyView() {
        let body = ComponentBody.webView(html: "<p/>")
        // Construction smoke only — the test house style never
        // introspects `AnyView`, so asserting its shape is out of
        // scope.
        _ = body.makeView()
    }

    func testWebViewKindTag() {
        let body = ComponentBody.webView(html: "<p/>")
        XCTAssertEqual(body.kind, .webView)
    }
}

#endif
