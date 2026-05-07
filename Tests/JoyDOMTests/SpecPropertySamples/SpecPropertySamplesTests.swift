// Smoke tests for the per-property samples shipped in
// `JoyDOMSampleSpecs`. Every sample must:
//   1. Decode as a JoyDOM `Spec`.
//   2. Walk through `RuleBuilder` + `StyleTreeBuilder` without
//      throwing or trapping.
//   3. Have a non-empty `summary` and a populated `json` payload.
//   4. Cover every category named in the manifest.
//
// Diagnostics are NOT asserted — `position: fixed`, `display:
// inline-flex`, etc. legitimately emit warnings while still
// resolving correctly. We only fail when the resolver itself
// throws or crashes.

import XCTest
@testable import JoyDOM
import JoyDOMSampleSpecs

final class SpecPropertySamplesTests: XCTestCase {

    /// Every bundled sample decodes as a JoyDOM `Spec`.
    func testEverySampleDecodesAsSpec() throws {
        for sample in SpecPropertySamples.all {
            do {
                _ = try JSONDecoder().decode(
                    Spec.self,
                    from: Data(sample.json.utf8)
                )
            } catch {
                XCTFail("\(sample.id) failed to decode: \(error)")
            }
        }
    }

    /// Every bundled sample resolves through the cascade without
    /// throwing or trapping. Diagnostics are tolerated — many spec
    /// extensions (position: fixed, display: inline-flex) warn but
    /// still produce a usable style tree.
    func testEverySampleResolvesWithoutCrash() throws {
        for sample in SpecPropertySamples.all {
            let spec = try JSONDecoder().decode(Spec.self, from: Data(sample.json.utf8))
            var diags = JoyDiagnostics()
            let rules = RuleBuilder.buildRules(
                from: spec,
                activeBreakpoint: nil,
                diagnostics: &diags
            )
            _ = StyleTreeBuilder.build(
                layout: spec.layout,
                rootID: "__joydom_root__",
                rules: rules,
                diagnostics: &diags
            )
        }
    }

    /// Manifest <-> sample-id integrity: each manifest entry resolves
    /// to a non-empty payload and a populated summary.
    func testManifestMatchesBundledFiles() throws {
        XCTAssertFalse(
            SpecPropertySamples.all.isEmpty,
            "manifest must list at least one sample"
        )
        for sample in SpecPropertySamples.all {
            XCTAssertFalse(
                sample.json.isEmpty,
                "\(sample.id) has empty JSON content"
            )
            XCTAssertFalse(
                sample.summary.isEmpty,
                "\(sample.id) missing summary"
            )
            XCTAssertFalse(
                sample.property.isEmpty,
                "\(sample.id) missing property name"
            )
            XCTAssertFalse(
                sample.category.isEmpty,
                "\(sample.id) missing category"
            )
        }
    }

    /// Coverage spot check — count expected categories. The reference
    /// doc has 11 spec sections (Layout, Sizing, Flexbox, Box Model,
    /// Typography, Text Behavior, Media, Selectors, Cascade,
    /// Breakpoints, Patterns).
    func testManifestSpansAllCategories() {
        let categories = Set(SpecPropertySamples.all.map { $0.category })
        XCTAssertEqual(
            categories.count, 11,
            "expected 11 categories from spec, got \(categories.sorted())"
        )
    }
}
