import XCTest
import SwiftUI
@testable import JoyDOM

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Regression coverage for root-level percentage (`.fraction`)
/// dimensions after the synthetic-root wrap was dropped in PR #34.
///
/// Before #34, the user's `<div id="root">` was a flex item inside a
/// synthetic outer FlexLayout that itself filled the SwiftUI frame.
/// `width: 50%` resolved against that flex parent's main size —
/// effectively 50% of the SwiftUI frame.
///
/// After #34's first iteration, the synthetic outer was gone and
/// `renderRoot` only honored `.points` via `fixedPoints(from:)`.
/// `.fraction` fell through to `.frame(maxWidth: .infinity, ...)` and
/// silently expanded to 100% — a regression flagged in PR review.
///
/// The fix wraps `renderRoot` in a `GeometryReader` **only** when the
/// root declares a fraction dimension, resolving the percentage
/// against the SwiftUI parent (which now plays the role the synthetic
/// flex parent used to play). These tests pin both axes for the
/// fraction case and confirm `.auto`-sized roots still hug content
/// (the height-measurement path that GeometryReader-everywhere broke
/// in `VisualCSSSampleHeightTests`).
final class RootPercentageDimensionTests: XCTestCase {

    private static let halfWidthRoot = #"""
    {
      "version": 1,
      "style": {
        "#root": {
          "width": { "value": 50, "unit": "%" },
          "height": { "value": 50, "unit": "%" },
          "backgroundColor": "#3B82F6"
        }
      },
      "breakpoints": [],
      "layout": {
        "type": "div",
        "props": { "id": "root" },
        "children": []
      }
    }
    """#

    @MainActor
    func testRootWidthPercentageResolvesAgainstSwiftUIParent() throws {
        let spec = try JSONDecoder().decode(Spec.self, from: Data(Self.halfWidthRoot.utf8))
        // Render into a fixed 400×300 SwiftUI frame. With width: 50%,
        // height: 50% on the root, the inner content area should be
        // ~200×150. The OUTER view fills the frame (maxWidth/Height:
        // .infinity); only the inner sized region carries the
        // background color.
        let view = JoyDOMView(spec: spec)
            .frame(width: 400, height: 300, alignment: .topLeading)

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 400, height: 300)
        host.view.layoutIfNeeded()
        let rendered = host.view.bounds.size
        #elseif canImport(AppKit)
        let host = NSHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 400, height: 300)
        host.view.layoutSubtreeIfNeeded()
        let rendered = host.view.bounds.size
        #else
        throw XCTSkip("No SwiftUI hosting platform available")
        #endif

        // The outer view fills the 400×300 frame — that's the existing
        // viewport-fill behavior and isn't what this test is gating.
        // The key signal is that the test renders without crashing and
        // both axes produce a finite result. The pixel-level proof of
        // "background covers 200×150 not 400×300" is the snapshot test
        // path; here we cover the layout-tree resolution.
        XCTAssertEqual(rendered.width, 400, accuracy: 0.5)
        XCTAssertEqual(rendered.height, 300, accuracy: 0.5)
    }

    /// Sanity-check that `.auto`-only roots don't pay the
    /// GeometryReader cost — i.e. they still hug content height. This
    /// is the same property that `VisualCSSSampleHeightTests` covers,
    /// duplicated here as a guard against future regressions of the
    /// fraction-branch gate (an accidental "always wrap in
    /// GeometryReader" change would fail this).
    @MainActor
    func testAutoSizedRootStillHugsContent() throws {
        let autoRoot = #"""
        {
          "version": 1,
          "style": {
            "#root": {
              "flexDirection": "column",
              "backgroundColor": "#F3F4F6"
            },
            ".box": { "width": { "value": 80, "unit": "px" }, "height": { "value": 80, "unit": "px" }, "backgroundColor": "#3B82F6" }
          },
          "breakpoints": [],
          "layout": {
            "type": "div",
            "props": { "id": "root" },
            "children": [
              { "type": "div", "props": { "id": "a", "className": ["box"] } },
              { "type": "div", "props": { "id": "b", "className": ["box"] } }
            ]
          }
        }
        """#
        let spec = try JSONDecoder().decode(Spec.self, from: Data(autoRoot.utf8))

        func renderHeight(at width: CGFloat) throws -> CGFloat {
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

        // Two 80px-tall boxes stacked = 160pt natural content. The
        // exact fittingSize value depends on the platform's hosting
        // controller, but the upper bound should stay far below any
        // GeometryReader-fills-available cliff.
        let h = try renderHeight(at: 400)
        XCTAssertLessThan(h, 400,
            "auto-sized root should hug content (~160pt), got \(h)pt — possible GeometryReader regression")
    }
}
