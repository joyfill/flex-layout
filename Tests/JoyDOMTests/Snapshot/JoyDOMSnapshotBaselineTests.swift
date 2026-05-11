// JoyDOMSnapshotBaselineTests — proves the snapshot harness works.
//
// One trivial test rendering a deterministic, layout-stable Spec (a
// single positioned div with a fixed-size text child — no images, no
// fonts that vary across simulators). If this test passes after a
// clean checkout, the snapshot pipeline is wired correctly and other
// per-property snapshot tests can rely on the helper.

import XCTest
import SnapshotTesting
@testable import JoyDOM

final class JoyDOMSnapshotBaselineTests: XCTestCase {

    /// Deterministic minimal spec — fixed dimensions, system font,
    /// solid colour fill. No async resources, no breakpoints. The
    /// rendered output should be byte-identical across runs.
    private static let baselineJSON = #"""
    {
      "version": 1,
      "style": {
        "#root": {
          "width":  { "value": 400, "unit": "px" },
          "height": { "value": 200, "unit": "px" },
          "padding": { "value": 24, "unit": "px" },
          "backgroundColor": "#1F2937",
          "borderRadius":    { "value": 12, "unit": "px" }
        },
        "#label": {
          "color":      "#F9FAFB",
          "fontSize":   { "value": 20, "unit": "px" },
          "fontWeight": "bold"
        }
      },
      "breakpoints": [],
      "layout": {
        "type": "div",
        "props": { "id": "root" },
        "children": [
          {
            "type": "p",
            "props": { "id": "label" },
            "children": ["JoyDOM snapshot baseline"]
          }
        ]
      }
    }
    """#

    func testBaselineSnapshot() {
        assertJoyDOMSnapshot(
            json: Self.baselineJSON,
            viewportWidth: 400,
            height: 200
        )
    }
}
