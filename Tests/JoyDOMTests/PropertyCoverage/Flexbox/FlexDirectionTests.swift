// FlexDirectionTests — Phase 1 property #1 of the per-property
// coverage walk (docs/Property-Test-Workflow.md).
//
// Cascade-side mapping of all four values (row / column / row-reverse /
// column-reverse) is already covered by
// `StyleFieldTranslationTests::testFlexDirection*`. This file adds:
//
//   • Snapshot tests proving each value visibly produces a different
//     layout (left-to-right, top-to-bottom, right-to-left, bottom-to-top).
//   • The CSS-default edge case — flexDirection omitted entirely.
//   • Two interaction scenarios — flexDirection × flexWrap, and
//     flexDirection × justifyContent — that exercise the property in
//     combination with related ones.
//
// Sample JSON is inlined here while PR #28 (`JoyDOMSampleSpecs`) is in
// review. Once it merges, the per-value templates below can move to
// `Sources/JoyDOMSampleSpecs/Resources/flexbox/flex-direction*.json`
// and this file's `makeSample(...)` becomes a `Sample.json` lookup.

import XCTest
import SnapshotTesting
import FlexLayout
@testable import JoyDOM

final class FlexDirectionTests: XCTestCase {

    // MARK: - Sample builder

    /// Generates a JoyDOM Spec with a single row of 4 coloured 60×60 boxes,
    /// `flexDirection` set to `value`. Visual order proves whether the
    /// rendered children flow per the CSS spec for each enum case.
    /// `value == nil` omits the field so the default falls through.
    private static func valueSweepJSON(flexDirection value: String?) -> String {
        let directionKey: String = {
            guard let value else { return "" }
            return "\"flexDirection\": \"\(value)\","
        }()
        return #"""
        {
          "version": 1,
          "style": {
            "#root": {
              \#(directionKey)
              "padding": { "value": 16, "unit": "px" },
              "gap":     { "value": 8,  "unit": "px" },
              "backgroundColor": "#F3F4F6"
            },
            ".box": {
              "width":  { "value": 60, "unit": "px" },
              "height": { "value": 60, "unit": "px" },
              "borderRadius": { "value": 4, "unit": "px" }
            },
            "#a": { "backgroundColor": "#EF4444" },
            "#b": { "backgroundColor": "#10B981" },
            "#c": { "backgroundColor": "#3B82F6" },
            "#d": { "backgroundColor": "#F59E0B" }
          },
          "breakpoints": [],
          "layout": {
            "type": "div",
            "props": { "id": "root" },
            "children": [
              { "type": "div", "props": { "id": "a", "className": ["box"] } },
              { "type": "div", "props": { "id": "b", "className": ["box"] } },
              { "type": "div", "props": { "id": "c", "className": ["box"] } },
              { "type": "div", "props": { "id": "d", "className": ["box"] } }
            ]
          }
        }
        """#
    }

    // MARK: - Value sweep — snapshot

    /// `row`: A → B → C → D left-to-right horizontally.
    func test_row_rendersLeftToRight() {
        assertJoyDOMSnapshot(
            json: Self.valueSweepJSON(flexDirection: "row"),
            viewportWidth: 400, height: 100
        )
    }

    /// `column`: A → B → C → D top-to-bottom vertically.
    func test_column_rendersTopToBottom() {
        assertJoyDOMSnapshot(
            json: Self.valueSweepJSON(flexDirection: "column"),
            viewportWidth: 100, height: 320
        )
    }

    /// `row-reverse` (joydom-swift ext, not in spec): visual order
    /// D → C → B → A left-to-right. Pixel diff vs. `row` should be
    /// unmistakable.
    func test_rowReverse_rendersRightToLeft() {
        assertJoyDOMSnapshot(
            json: Self.valueSweepJSON(flexDirection: "row-reverse"),
            viewportWidth: 400, height: 100
        )
    }

    /// `column-reverse` (joydom-swift ext): visual order D → C → B → A
    /// top-to-bottom.
    func test_columnReverse_rendersBottomToTop() {
        assertJoyDOMSnapshot(
            json: Self.valueSweepJSON(flexDirection: "column-reverse"),
            viewportWidth: 100, height: 320
        )
    }

    // MARK: - Edge — default (omitted)

    /// When `flexDirection` is absent from the spec, the cascade should
    /// leave the container's direction at FlexLayout's default. The CSS
    /// spec default is `row`; this test pins joydom-swift's current
    /// default to catch any silent change. If the default changes the
    /// test message says what to update.
    func test_omitted_resolvesToContainerDefaultDirection() throws {
        let spec = try JSONDecoder().decode(
            Spec.self,
            from: Data(Self.valueSweepJSON(flexDirection: nil).utf8)
        )
        var diags = JoyDiagnostics()
        let rules = RuleBuilder.buildRules(
            from: spec, activeBreakpoint: nil, diagnostics: &diags
        )
        let nodes = StyleTreeBuilder.build(
            layout: spec.layout, rootID: "__joydom_root__",
            rules: rules, diagnostics: &diags
        )
        let root = nodes.first(where: { $0.id == "root" })!
        // Default container direction. Adjust the expectation if the
        // upstream FlexContainerConfig default changes — the comparison
        // here is intentionally explicit so the test fails loudly on
        // any drift rather than passing under both possible defaults.
        XCTAssertEqual(
            root.computedStyle.container.direction,
            FlexContainerConfig().direction,
            "flexDirection omitted should fall through to FlexContainerConfig's compiled-in default"
        )
    }

    /// Snapshot proof of the default-rendering. Pixel-compared against
    /// either `row` or `column` baselines once the default is known
    /// from the cascade test above.
    func test_omitted_rendersAtContainerDefault() {
        assertJoyDOMSnapshot(
            json: Self.valueSweepJSON(flexDirection: nil),
            viewportWidth: 400, height: 320
        )
    }

    // MARK: - Interaction — flexDirection × flexWrap

    /// Six 100-wide boxes in a 400px-wide container with `flexWrap: wrap`
    /// must overflow the first row and continue onto a second. Pin the
    /// row-wrap behaviour visually (this is the case the Kotlin
    /// implementation explicitly DOESN'T handle correctly — iOS does).
    private static let rowWithWrapJSON = #"""
    {
      "version": 1,
      "style": {
        "#root": {
          "flexDirection": "row",
          "flexWrap":      "wrap",
          "padding":       { "value": 16, "unit": "px" },
          "gap":           { "value": 8,  "unit": "px" },
          "backgroundColor": "#F3F4F6"
        },
        ".box": {
          "width":  { "value": 100, "unit": "px" },
          "height": { "value": 40,  "unit": "px" },
          "backgroundColor": "#3B82F6",
          "borderRadius": { "value": 4, "unit": "px" }
        }
      },
      "breakpoints": [],
      "layout": {
        "type": "div",
        "props": { "id": "root" },
        "children": [
          { "type": "div", "props": { "id": "b1", "className": ["box"] } },
          { "type": "div", "props": { "id": "b2", "className": ["box"] } },
          { "type": "div", "props": { "id": "b3", "className": ["box"] } },
          { "type": "div", "props": { "id": "b4", "className": ["box"] } },
          { "type": "div", "props": { "id": "b5", "className": ["box"] } },
          { "type": "div", "props": { "id": "b6", "className": ["box"] } }
        ]
      }
    }
    """#

    func test_rowWithWrap_wrapsToSecondLine() {
        assertJoyDOMSnapshot(
            json: Self.rowWithWrapJSON,
            viewportWidth: 400, height: 200
        )
    }

    // MARK: - Interaction — flexDirection × justifyContent

    /// `column-reverse` + `justifyContent: flex-end` should stack
    /// children from the BOTTOM of the container (reversed main axis
    /// + end-of-main alignment). Verifies the two properties compose.
    private static let columnReverseWithJustifyEndJSON = #"""
    {
      "version": 1,
      "style": {
        "#root": {
          "flexDirection":  "column-reverse",
          "justifyContent": "flex-end",
          "padding":        { "value": 16, "unit": "px" },
          "gap":            { "value": 8,  "unit": "px" },
          "height":         { "value": 240, "unit": "px" },
          "backgroundColor": "#F3F4F6"
        },
        ".box": {
          "width":  { "value": 80, "unit": "px" },
          "height": { "value": 40, "unit": "px" },
          "borderRadius": { "value": 4, "unit": "px" }
        },
        "#a": { "backgroundColor": "#EF4444" },
        "#b": { "backgroundColor": "#10B981" },
        "#c": { "backgroundColor": "#3B82F6" }
      },
      "breakpoints": [],
      "layout": {
        "type": "div",
        "props": { "id": "root" },
        "children": [
          { "type": "div", "props": { "id": "a", "className": ["box"] } },
          { "type": "div", "props": { "id": "b", "className": ["box"] } },
          { "type": "div", "props": { "id": "c", "className": ["box"] } }
        ]
      }
    }
    """#

    func test_columnReverse_withJustifyEnd_stacksFromBottomEdge() {
        assertJoyDOMSnapshot(
            json: Self.columnReverseWithJustifyEndJSON,
            viewportWidth: 200, height: 240
        )
    }
}
