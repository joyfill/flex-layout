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

    // MARK: - Visual CSS — UA defaults integration
    //
    // Mirrors the `visualCSS` payload in `FlexDemoApp/JoyDOMSamples.swift`
    // in slimmed-down form: the heading hierarchy plus an author `h1`
    // override (`fontSize: 28`, `fontWeight: 700`). After running
    // through `RuleBuilder` + `StyleTreeBuilder`, `h4` should pick up
    // the UA bold/16 px defaults and `h1` should reflect the author
    // override (not the UA defaults). This is the regression net for
    // the "Heading 4 plain on iOS" cross-platform parity bug.

    private static let visualCSSSlice: String = #"""
    {
      "version": 1,
      "style": {
        "h1": {
          "fontSize": { "value": 28, "unit": "px" },
          "fontWeight": 700,
          "color": "#1A1A2E"
        }
      },
      "breakpoints": [],
      "layout": {
        "type": "div",
        "props": { "id": "root" },
        "children": [
          { "type": "h1", "props": { "id": "typo-h1" }, "children": ["Heading 1"] },
          { "type": "h4", "props": { "id": "typo-h4" }, "children": ["Heading 4"] }
        ]
      }
    }
    """#

    func testVisualCSSSliceDecodes() {
        assertDecodes(Self.visualCSSSlice, label: "visual-css")
    }

    func testVisualCSSSliceUADefaultsAndOverride() {
        let data = Data(Self.visualCSSSlice.utf8)
        let spec: Spec
        do {
            spec = try JSONDecoder().decode(Spec.self, from: data)
        } catch {
            XCTFail("visual-css slice failed to decode: \(error)"); return
        }

        var diags = JoyDiagnostics()
        let rules = RuleBuilder.buildRules(
            from: spec, activeBreakpoint: nil, diagnostics: &diags
        )
        let nodes = StyleTreeBuilder.build(
            layout: spec.layout,
            rootID: "__joydom_root__",
            rules: rules,
            diagnostics: &diags
        )
        var byID: [String: ComputedStyle] = [:]
        for n in nodes { byID[n.id] = n.computedStyle }

        // Unstyled h4 → UA defaults (bold, 16 px). This is the
        // exact bug the UA stylesheet is fixing.
        XCTAssertEqual(byID["typo-h4"]?.visual.fontWeight, .bold,
                       "h4 should resolve to bold via UA defaults")
        XCTAssertEqual(byID["typo-h4"]?.visual.fontSize, 16,
                       "h4 should resolve to 16 px via UA defaults")

        // h1 has an author rule that overrides UA — assert author won.
        XCTAssertEqual(byID["typo-h1"]?.visual.fontSize, 28,
                       "author h1 fontSize should override UA")
        XCTAssertEqual(byID["typo-h1"]?.visual.fontWeight, .numeric(700),
                       "author h1 fontWeight should override UA bold")
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
