import XCTest
import SwiftUI
@testable import JoyDOM

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Regression coverage for the cross-axis measurement bug that
/// surfaced in the `visualCSS` sample's stats-card row at narrow
/// viewports.
///
/// The bug: when a flex container's cross-size measurement pass
/// proposed the full cross constraint to ROW children, content-sized
/// items (like the stat cards) claimed the full constraint instead of
/// hugging their natural height. Result: the AT A GLANCE section's
/// first card stretched to ~238pt at narrow viewports, hiding the
/// other two cards behind a wall of empty card background.
///
/// These tests host the visualCSS sample at multiple viewport widths
/// and assert the total rendered height stays bounded — i.e. the
/// section content hugs naturally as cards wrap to multiple lines.
final class VisualCSSSampleHeightTests: XCTestCase {

    /// Embedded copy of `FlexDemoApp/JoyDOMSamples.swift`'s `visualCSS`
    /// payload — verbatim slice covering the hero + stats sections,
    /// which is what's visible in the user's broken screenshot.
    private static let visualCSSSlice = #"""
    {
      "version": 1,
      "style": {
        "#root":            { "flexDirection": "column", "gap": { "value": 0, "unit": "px" }, "backgroundColor": "#F8F9FA" },
        ".section":         { "flexDirection": "column", "padding": { "value": 20, "unit": "px" }, "margin": { "value": 12, "unit": "px" }, "backgroundColor": "#FFFFFF", "borderRadius": { "value": 12, "unit": "px" }, "borderWidth": { "value": 1, "unit": "px" }, "borderColor": "#E0E0E0", "borderStyle": "solid" },
        "h1":               { "fontSize": { "value": 28, "unit": "px" }, "fontWeight": 700, "color": "#1A1A2E", "lineHeight": 1.2 },
        "h3":               { "fontSize": { "value": 16, "unit": "px" }, "fontWeight": 500, "color": "#0F3460", "textTransform": "uppercase", "letterSpacing": { "value": 1, "unit": "px" } },
        "p":                { "fontSize": { "value": 14, "unit": "px" }, "color": "#555555", "lineHeight": 1.6 },
        ".badge":           { "backgroundColor": "#E8F4FD", "borderRadius": { "value": 20, "unit": "px" }, "padding": { "top": { "value": 4, "unit": "px" }, "right": { "value": 12, "unit": "px" }, "bottom": { "value": 4, "unit": "px" }, "left": { "value": 12, "unit": "px" } }, "borderWidth": { "value": 1, "unit": "px" }, "borderColor": "#B3D9F5", "borderStyle": "solid" },
        ".badge-text":      { "fontSize": { "value": 12, "unit": "px" }, "fontWeight": 600, "color": "#1976D2", "textTransform": "uppercase", "letterSpacing": { "value": 0.5, "unit": "px" } },
        ".row":             { "flexDirection": "row", "flexWrap": "wrap", "columnGap": { "value": 12, "unit": "px" }, "rowGap": { "value": 8, "unit": "px" } },
        ".card":            { "flexDirection": "column", "flexGrow": 1, "minWidth": { "value": 120, "unit": "px" }, "maxWidth": { "value": 200, "unit": "px" }, "padding": { "value": 16, "unit": "px" }, "backgroundColor": "#F0F4FF", "borderRadius": { "value": 8, "unit": "px" } },
        ".card-value":      { "fontSize": { "value": 24, "unit": "px" }, "fontWeight": 700, "color": "#3B4FE0", "textAlign": "center" },
        ".card-label":      { "fontSize": { "value": 11, "unit": "px" }, "color": "#888888", "textAlign": "center", "textTransform": "uppercase", "letterSpacing": { "value": 0.8, "unit": "px" } }
      },
      "breakpoints": [],
      "layout": {
        "type": "div",
        "props": { "id": "root" },
        "children": [
          {
            "type": "div",
            "props": { "id": "hero-section", "className": ["section"] },
            "children": [
              { "type": "div", "props": { "id": "badge-row", "className": ["row"] },
                "children": [
                  { "type": "div", "props": { "id": "badge-new", "className": ["badge"] },
                    "children": [{ "type": "p", "props": { "id": "badge-new-text", "className": ["badge-text"] }, "children": ["New"] }] },
                  { "type": "div", "props": { "id": "badge-v2", "className": ["badge"] },
                    "children": [{ "type": "p", "props": { "id": "badge-v2-text", "className": ["badge-text"] }, "children": ["v2.0"] }] }
                ]
              },
              { "type": "h1", "props": { "id": "hero-title" }, "children": ["Visual CSS in JoyDOM"] },
              { "type": "p",  "props": { "id": "hero-body" },  "children": ["This sample exercises the full visual CSS property set: borders, border radius, background colors, opacity, typography, min/max sizing, and more."] }
            ]
          },
          {
            "type": "div",
            "props": { "id": "stats-section", "className": ["section"] },
            "children": [
              { "type": "h3", "props": { "id": "stats-label" }, "children": ["At a glance"] },
              { "type": "div", "props": { "id": "stats-row", "className": ["row"] },
                "children": [
                  { "type": "div", "props": { "id": "stat-a", "className": ["card"] },
                    "children": [
                      { "type": "p", "props": { "id": "stat-a-val", "className": ["card-value"] }, "children": ["28"] },
                      { "type": "p", "props": { "id": "stat-a-lbl", "className": ["card-label"] }, "children": ["CSS props"] }
                    ]
                  },
                  { "type": "div", "props": { "id": "stat-b", "className": ["card"] },
                    "children": [
                      { "type": "p", "props": { "id": "stat-b-val", "className": ["card-value"] }, "children": ["8"] },
                      { "type": "p", "props": { "id": "stat-b-lbl", "className": ["card-label"] }, "children": ["HTML types"] }
                    ]
                  },
                  { "type": "div", "props": { "id": "stat-c", "className": ["card"] },
                    "children": [
                      { "type": "p", "props": { "id": "stat-c-val", "className": ["card-value"] }, "children": ["∞"] },
                      { "type": "p", "props": { "id": "stat-c-lbl", "className": ["card-label"] }, "children": ["Possible UIs"] }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    }
    """#

    @MainActor
    func testFullVisualCSSAt280ptViewportRendersBoundedHeight() throws {
        let spec = try JSONDecoder().decode(Spec.self, from: Data(Self.visualCSSSlice.utf8))
        let view = JoyDOMView(spec: spec).frame(width: 280, alignment: .topLeading)

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 280, height: 10)
        host.view.layoutIfNeeded()
        let rendered = host.view.systemLayoutSizeFitting(
            CGSize(width: 280, height: UIView.layoutFittingExpandedSize.height)
        )
        #elseif canImport(AppKit)
        let host = NSHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 280, height: 10)
        host.view.layoutSubtreeIfNeeded()
        let rendered = host.view.fittingSize
        #else
        throw XCTSkip("No SwiftUI hosting platform available")
        #endif

        // At 280pt viewport with the full visualCSS sample (hero +
        // stats), expected total height:
        // - hero section: ~250-350pt (badges, h1 wrapping, body text wrapping)
        // - stats section: ~250-350pt (h3, three cards stacked one per line)
        // - margins between: 24pt
        // Total: ~600-700pt. 1000pt is generous; 2000pt would mean the
        // bug is back.
        XCTAssertLessThan(
            rendered.height, 1000,
            "Full visualCSS sample at 280pt rendered \(rendered.height)pt — over-claim height bug is back"
        )
    }

    /// Drives the same sample at multiple viewport widths to verify
    /// the layout reflows monotonically — narrower viewport ⇒
    /// stats-row wraps to more lines ⇒ taller total. If the bug were
    /// back, all viewports would report the same (over-claimed) height.
    @MainActor
    func testHeightGrowsAsViewportNarrows() throws {
        let spec = try JSONDecoder().decode(Spec.self, from: Data(Self.visualCSSSlice.utf8))

        func render(at width: CGFloat) throws -> CGFloat {
            let view = JoyDOMView(spec: spec).frame(width: width, alignment: .topLeading)
            #if canImport(UIKit)
            let host = UIHostingController(rootView: view)
            host.view.frame = CGRect(x: 0, y: 0, width: width, height: 10)
            host.view.layoutIfNeeded()
            return host.view.systemLayoutSizeFitting(
                CGSize(width: width, height: UIView.layoutFittingExpandedSize.height)
            ).height
            #elseif canImport(AppKit)
            let host = NSHostingController(rootView: view)
            host.view.frame = CGRect(x: 0, y: 0, width: width, height: 10)
            host.view.layoutSubtreeIfNeeded()
            return host.view.fittingSize.height
            #else
            throw XCTSkip("No SwiftUI hosting platform available")
            #endif
        }

        let h600 = try render(at: 600)
        let h280 = try render(at: 280)
        XCTAssertLessThan(h600, h280,
            "expected narrower viewport to produce taller layout; got 600pt=\(h600) vs 280pt=\(h280)")
    }
}
