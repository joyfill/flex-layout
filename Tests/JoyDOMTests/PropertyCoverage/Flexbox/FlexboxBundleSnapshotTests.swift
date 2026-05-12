// FlexboxBundleSnapshotTests — generic L3 snapshot tester for every
// sample in the Flexbox category.
//
// Instead of writing one XCTest method per sample (which scaled to 24
// methods for flexDirection alone, and would scale to ~200+ once the
// rest of Flexbox / Layout / Typography / etc. land), this is one
// data-driven test that iterates every Flexbox sample in
// `SpecPropertySamples.all` and asserts each renders identical to a
// committed PNG baseline.
//
// Per-sample canvas size lives in the manifest under the optional
// `"snapshot": { "viewportWidth": …, "height": … }` key. Samples without
// the hint use `SpecPropertySample.SnapshotConfig.default` (800×600).
//
// New samples added to the Flexbox section of the manifest are
// auto-tested on the next CI run — no test code changes required.
//
// One special-case method handles the responsive sample's wide
// viewport, because the bundle test renders each sample exactly once
// at its declared canvas size (and the responsive sample's "row at
// ≥768px" branch needs a 900-px-wide canvas to trigger).
//
// Baselines live under `__Snapshots__/FlexboxBundleSnapshotTests/` keyed
// by sample id.

import XCTest
import SnapshotTesting
@testable import JoyDOM
import JoyDOMSampleSpecs

final class FlexboxBundleSnapshotTests: XCTestCase {

    /// Renders every Flexbox sample at its declared canvas and diffs
    /// against a committed PNG baseline named by sample id. Replaces
    /// 23 hand-written per-method snapshot tests.
    func testEveryFlexboxSampleMatchesBaseline() throws {
        let flexbox = SpecPropertySamples.all.filter { $0.category == "Flexbox" }
        XCTAssertFalse(flexbox.isEmpty, "no Flexbox samples in bundle — manifest order or category name regressed")
        for sample in flexbox {
            let cfg = sample.snapshotConfig ?? .default
            assertJoyDOMSnapshot(
                json: sample.json,
                viewportWidth: CGFloat(cfg.viewportWidth),
                height: CGFloat(cfg.height),
                named: sample.id
            )
        }
    }

    // MARK: - Special case: the responsive sample needs a SECOND snapshot
    //
    // The manifest's snapshot config gives the "narrow viewport"
    // rendering (column). To prove the breakpoint flip we also need a
    // wide-viewport render (row) — captured here. Any future sample
    // needing a second rendering can follow the same pattern, or we
    // can extend the manifest schema to an array of snapshot configs
    // if multi-canvas testing becomes common.

    func test_flexDirection_responsive_atWide_rendersRow() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "flexbox-flex-direction-responsive"),
            "responsive sample missing from bundle"
        )
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 900,
            height: 140,
            named: "flexbox-flex-direction-responsive-wide"
        )
    }
}
