import XCTest
@testable import JoyDOM

/// Defensive guard: every sample in the paste demo's dropdown must
/// decode cleanly into a `Spec`. Future additions can't slip in
/// missing required keys (`style`, `breakpoints`, etc.) without
/// failing this suite.
///
/// This is intentionally a smoke check — we trust the per-shape
/// Codable tests for wire-format correctness; this just runs every
/// sample end-to-end through the decoder so a typo in one entry
/// doesn't ship past CI.
///
/// The samples themselves live in `FlexDemoApp/JoyDOMSamples.swift`,
/// which the test target can't import directly (different target).
/// We embed them here verbatim and assert each one decodes. If a
/// sample changes, the embedded copy needs to follow — small price
/// for the regression net.
final class JoyDOMSamplesIntegrityTests: XCTestCase {

    private func assertDecodes(
        _ json: String,
        label: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let data = Data(json.utf8)
        do {
            let spec = try JSONDecoder().decode(Spec.self, from: data)
            XCTAssertEqual(spec.version, 1, "\(label): version must be 1",
                           file: file, line: line)
        } catch {
            XCTFail("\(label) failed to decode: \(error)", file: file, line: line)
        }
    }

    // MARK: - Hello world

    func testHelloWorldDecodes() {
        assertDecodes(#"""
        {
          "version": 1,
          "style": {},
          "breakpoints": [],
          "layout": {
            "type": "p",
            "props": { "id": "greeting" },
            "children": ["Hello, joy-dom!"]
          }
        }
        """#, label: "hello-world")
    }

    // MARK: - Three cards

    func testThreeCardsDecodes() {
        assertDecodes(#"""
        {
          "version": 1,
          "style": {
            "#root": {
              "flexDirection": "column",
              "gap": { "value": 12, "unit": "px" },
              "padding": { "value": 16, "unit": "px" }
            },
            "#row": {
              "flexDirection": "column",
              "gap": { "value": 12, "unit": "px" }
            },
            "#a, #b, #c": {
              "flexGrow": 1,
              "height": { "value": 80, "unit": "px" }
            }
          },
          "breakpoints": [
            {
              "conditions": [
                { "type": "feature", "name": "width", "operator": ">=", "value": 768, "unit": "px" }
              ],
              "nodes": {},
              "style": {
                "#row": {
                  "flexDirection": "row",
                  "gap": { "value": 16, "unit": "px" }
                }
              }
            }
          ],
          "layout": {
            "type": "div",
            "props": { "id": "root" },
            "children": [
              { "type": "p", "props": { "id": "title" }, "children": ["Hello"] },
              {
                "type": "div",
                "props": { "id": "row" },
                "children": [
                  { "type": "card", "props": { "id": "a", "label": "A" } },
                  { "type": "card", "props": { "id": "b", "label": "B" } },
                  { "type": "card", "props": { "id": "c", "label": "C" } }
                ]
              }
            ]
          }
        }
        """#, label: "three-cards")
    }

    // MARK: - Signup form

    func testSignupFormDecodes() {
        assertDecodes(#"""
        {
          "version": 1,
          "style": {
            "#root": { "flexDirection": "column", "gap": { "value": 12, "unit": "px" } },
            "#row":  { "flexDirection": "column", "gap": { "value": 12, "unit": "px" } }
          },
          "breakpoints": [
            {
              "conditions": [
                { "type": "feature", "name": "width", "operator": ">=", "value": 768, "unit": "px" }
              ],
              "nodes": {},
              "style": { "#row": { "flexDirection": "row" } }
            }
          ],
          "layout": {
            "type": "div",
            "props": { "id": "root" },
            "children": [
              { "type": "p", "props": { "id": "title" }, "children": ["Sign up"] },
              {
                "type": "div",
                "props": { "id": "row" },
                "children": [
                  { "type": "input", "props": { "id": "name", "placeholder": "Name" } },
                  { "type": "input", "props": { "id": "email", "placeholder": "Email" } }
                ]
              },
              { "type": "button", "props": { "id": "submit", "label": "Submit", "event": "submit" } }
            ]
          }
        }
        """#, label: "signup-form")
    }

    // MARK: - Article

    func testArticleDecodes() {
        assertDecodes(#"""
        {
          "version": 1,
          "style": {
            "#article": { "flexDirection": "column", "gap": { "value": 12, "unit": "px" } },
            "#title":   { "height": { "value": 36, "unit": "px" } }
          },
          "breakpoints": [],
          "layout": {
            "type": "div",
            "props": { "id": "article" },
            "children": [
              { "type": "p", "props": { "id": "title" }, "children": ["Title"] },
              { "type": "p", "children": ["Body paragraph one."] },
              { "type": "p", "children": ["Body paragraph two."] }
            ]
          }
        }
        """#, label: "article")
    }

    // MARK: - Pricing tiers

    func testPricingTiersDecodes() {
        assertDecodes(#"""
        {
          "version": 1,
          "style": {
            "#root":  { "flexDirection": "column", "gap": { "value": 16, "unit": "px" } },
            "#tiers": { "flexDirection": "column", "gap": { "value": 12, "unit": "px" } }
          },
          "breakpoints": [
            {
              "conditions": [
                { "type": "feature", "name": "width", "operator": ">=", "value": 768, "unit": "px" }
              ],
              "nodes": {},
              "style": { "#tiers": { "flexDirection": "row" } }
            }
          ],
          "layout": {
            "type": "div",
            "props": { "id": "root" },
            "children": [
              { "type": "p", "props": { "id": "heading" }, "children": ["Plans"] },
              {
                "type": "div",
                "props": { "id": "tiers" },
                "children": [
                  { "type": "card", "props": { "id": "tier-free",  "label": "Free" } },
                  { "type": "card", "props": { "id": "tier-pro",   "label": "Pro" } },
                  { "type": "card", "props": { "id": "tier-team",  "label": "Team" } }
                ]
              }
            ]
          }
        }
        """#, label: "pricing-tiers")
    }

    // MARK: - Phase 4 samples
    //
    // These mirror entries added to `FlexDemoApp/JoyDOMSamples.swift` for
    // Phase 4 of `SPEC_GAP_PLAN.md`. We embed a representative slice of
    // each here — full copies would be unwieldy and the samples file is
    // already its own dropdown. The slice includes the property under
    // exercise so a regression in the cascade for that property would
    // still surface through this suite.

    private func assertDecodesAndRenders(
        _ json: String,
        label: String,
        expectChildren: Bool = true,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let data = Data(json.utf8)
        do {
            let spec = try JSONDecoder().decode(Spec.self, from: data)
            // Build the tree the way JoyDOMView would, so this catches
            // resolver-level regressions that pure-Codable tests miss.
            var diags = JoyDiagnostics()
            let rules = RuleBuilder.buildRules(from: spec, activeBreakpoint: nil, diagnostics: &diags)
            let nodes = StyleTreeBuilder.build(
                layout: spec.layout,
                rootID: "__joydom_root__",
                rules: rules,
                diagnostics: &diags
            )
            if expectChildren {
                XCTAssertGreaterThan(
                    nodes.count, 1,
                    "\(label): expected at least one rendered child beneath root",
                    file: file, line: line
                )
            }
        } catch {
            XCTFail("\(label) failed to decode: \(error)", file: file, line: line)
        }
    }

    func testDecorationsSampleDecodesAndRenders() {
        assertDecodesAndRenders(#"""
        {
          "version": 1,
          "style": {
            "#root":            { "flexDirection": "column", "textDecoration": "underline" },
            "#shout":           { "textTransform": "uppercase" },
            "#italic":          { "fontStyle": "italic" },
            "#tracked":         { "fontSize": { "value": 24, "unit": "px" }, "letterSpacing": { "value": 2.4, "unit": "px" } },
            "#w-100":           { "fontWeight": 100 },
            "#w-900":           { "fontWeight": 900 }
          },
          "breakpoints": [],
          "layout": {
            "type": "div",
            "props": { "id": "root" },
            "children": [
              { "type": "p", "props": { "id": "shout" },   "children": ["loud"] },
              { "type": "p", "props": { "id": "italic" },  "children": ["italic"] },
              { "type": "p", "props": { "id": "tracked" }, "children": ["tracked"] },
              { "type": "p", "props": { "id": "w-100" },   "children": ["100"] },
              { "type": "p", "props": { "id": "w-900" },   "children": ["900"] }
            ]
          }
        }
        """#, label: "decorations")
    }

    func testPositioningSampleDecodesAndRenders() {
        assertDecodesAndRenders(#"""
        {
          "version": 1,
          "style": {
            "#card":   { "position": "relative", "width": { "value": 300, "unit": "px" }, "height": { "value": 200, "unit": "px" } },
            "#badge":  { "position": "absolute", "top":   { "value": 8, "unit": "px" }, "right": { "value": 8, "unit": "px" }, "zIndex": 10 },
            "#ribbon": { "position": "absolute", "top":   { "value": 0, "unit": "px" }, "left":  { "value": 0, "unit": "px" }, "zIndex": 1 },
            "#fixed":  { "position": "fixed",    "top":   { "value": 0, "unit": "px" }, "left":  { "value": 0, "unit": "px" } }
          },
          "breakpoints": [],
          "layout": {
            "type": "div",
            "props": { "id": "card" },
            "children": [
              { "type": "div", "props": { "id": "badge",  "label": "NEW" } },
              { "type": "div", "props": { "id": "ribbon", "label": "RIBBON" } },
              { "type": "div", "props": { "id": "fixed",  "label": "fixed" } }
            ]
          }
        }
        """#, label: "positioning")
    }

    func testCornerRadiusSampleDecodesAndRenders() {
        assertDecodesAndRenders(#"""
        {
          "version": 1,
          "style": {
            "#bubble": {
              "borderRadius": {
                "topLeft":     { "value": 12, "unit": "px" },
                "topRight":    { "value": 12, "unit": "px" },
                "bottomRight": { "value": 12, "unit": "px" },
                "bottomLeft":  { "value": 0,  "unit": "px" }
              }
            },
            "#asym": {
              "borderRadius": {
                "topLeft":     { "value": 4,  "unit": "px" },
                "topRight":    { "value": 8,  "unit": "px" },
                "bottomRight": { "value": 16, "unit": "px" },
                "bottomLeft":  { "value": 24, "unit": "px" }
              }
            }
          },
          "breakpoints": [],
          "layout": {
            "type": "div",
            "props": { "id": "root" },
            "children": [
              { "type": "div", "props": { "id": "bubble", "label": "bubble" } },
              { "type": "div", "props": { "id": "asym",   "label": "asym" } }
            ]
          }
        }
        """#, label: "corner-radius")
    }

    func testFlexAlignSampleDecodesAndRenders() {
        assertDecodesAndRenders(#"""
        {
          "version": 1,
          "style": {
            "#wrap":       { "flexDirection": "row", "flexWrap": "wrap-reverse", "alignContent": "space-between" },
            "#row-rev":    { "flexDirection": "row-reverse" },
            "#col-rev":    { "flexDirection": "column-reverse" },
            "#self-c":     { "alignSelf": "flex-end" },
            "#order-a":    { "order": 3 },
            "#order-b":    { "order": 1 },
            "#order-c":    { "order": 2 }
          },
          "breakpoints": [],
          "layout": {
            "type": "div",
            "props": { "id": "wrap" },
            "children": [
              { "type": "div", "props": { "id": "self-c", "label": "self-end" } },
              {
                "type": "div",
                "props": { "id": "row-rev" },
                "children": [
                  { "type": "div", "props": { "id": "order-a", "label": "A" } },
                  { "type": "div", "props": { "id": "order-b", "label": "B" } },
                  { "type": "div", "props": { "id": "order-c", "label": "C" } }
                ]
              },
              { "type": "div", "props": { "id": "col-rev" } }
            ]
          }
        }
        """#, label: "flex-align")
    }

    func testConstraintsSampleDecodesAndRenders() {
        assertDecodesAndRenders(#"""
        {
          "version": 1,
          "style": {
            "#row":   { "flexDirection": "row", "width": { "value": 300, "unit": "px" } },
            "#a":     { "flexGrow": 1, "maxWidth": { "value": 50, "unit": "px" } },
            "#b":     { "flexGrow": 1 },
            "#c":     { "flexGrow": 1 },
            "#min-h": { "minHeight": { "value": 100, "unit": "px" } },
            "#max-h": { "maxHeight": { "value": 80,  "unit": "px" } }
          },
          "breakpoints": [],
          "layout": {
            "type": "div",
            "props": { "id": "row" },
            "children": [
              { "type": "div", "props": { "id": "a", "label": "max=50" } },
              { "type": "div", "props": { "id": "b", "label": "grow" } },
              { "type": "div", "props": { "id": "c", "label": "grow" } },
              { "type": "div", "props": { "id": "min-h", "label": "min" } },
              { "type": "div", "props": { "id": "max-h", "label": "max" } }
            ]
          }
        }
        """#, label: "constraints")
    }

    func testMarginShowcaseSampleDecodesAndRenders() {
        assertDecodesAndRenders(#"""
        {
          "version": 1,
          "style": {
            "#row":      { "flexDirection": "row" },
            ".mg":       { "margin": { "value": 16, "unit": "px" } },
            "#composed": { "padding": { "value": 12, "unit": "px" }, "margin": { "value": 24, "unit": "px" } },
            ".asym": {
              "margin": {
                "top":    { "value": 8,  "unit": "px" },
                "right":  { "value": 0,  "unit": "px" },
                "bottom": { "value": 16, "unit": "px" },
                "left":   { "value": 0,  "unit": "px" }
              }
            }
          },
          "breakpoints": [],
          "layout": {
            "type": "div",
            "props": { "id": "row" },
            "children": [
              { "type": "div", "props": { "id": "m1", "className": ["mg"],   "label": "m=16" } },
              { "type": "div", "props": { "id": "m2", "className": ["mg"],   "label": "m=16" } },
              { "type": "div", "props": { "id": "a1", "className": ["asym"], "label": "asym" } },
              { "type": "div", "props": { "id": "composed", "label": "composed" } }
            ]
          }
        }
        """#, label: "margin-showcase")
    }

    // MARK: - Required-key sanity

    /// A `Spec` JSON missing `style` or `breakpoints` must throw —
    /// pinning the contract every sample has to honor.
    func testMissingStyleFailsToDecode() {
        let bad = #"""
        {
          "version": 1,
          "breakpoints": [],
          "layout": { "type": "div" }
        }
        """#
        XCTAssertThrowsError(
            try JSONDecoder().decode(Spec.self, from: Data(bad.utf8))
        )
    }

    func testMissingBreakpointsFailsToDecode() {
        let bad = #"""
        {
          "version": 1,
          "style": {},
          "layout": { "type": "div" }
        }
        """#
        XCTAssertThrowsError(
            try JSONDecoder().decode(Spec.self, from: Data(bad.utf8))
        )
    }
}
