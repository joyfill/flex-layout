// FlexboxSnapshotTests — one test method per Flexbox property. Each
// iterates JSON samples in `Resources/flexbox/<property>/` via the
// generic `assertSnapshotsForSamples(in:)` helper, producing baselines
// whose leaf filenames mirror the JSON filenames.
//
// Example: `flexbox/flex-direction/row.json`
//        → `__Snapshots__/FlexboxSnapshotTests/testFlexDirection.row.png`
//
// Adding a new variant to a property = drop a `<name>.json` under the
// property's directory + add a manifest entry. The next test run
// auto-records the matching baseline. No new test method to write.

import XCTest
import SnapshotTesting
@testable import JoyDOM
import JoyDOMSampleSpecs

final class FlexboxSnapshotTests: XCTestCase {

    func testFlexDirection() {
        assertSnapshotsForSamples(in: "flexbox/flex-direction")
    }

    func testFlexGrow() {
        assertSnapshotsForSamples(in: "flexbox/flex-grow")
    }

    func testFlexShrink() {
        assertSnapshotsForSamples(in: "flexbox/flex-shrink")
    }

    func testFlexBasis() {
        assertSnapshotsForSamples(in: "flexbox/flex-basis")
    }

    func testJustifyContent() {
        assertSnapshotsForSamples(in: "flexbox/justify-content")
    }

    func testAlignItems() {
        assertSnapshotsForSamples(in: "flexbox/align-items")
    }

    func testAlignSelf() {
        assertSnapshotsForSamples(in: "flexbox/align-self")
    }

    func testFlexWrap() {
        assertSnapshotsForSamples(in: "flexbox/flex-wrap")
    }

    func testGap() {
        assertSnapshotsForSamples(in: "flexbox/gap")
    }

    func testOrder() {
        assertSnapshotsForSamples(in: "flexbox/order")
    }

    // MARK: - Special case — responsive sample's second viewport
    //
    // `flex-direction/responsive.json` declares the NARROW canvas
    // (which renders the column branch). The breakpoint flip to row
    // needs a second canvas; this method captures that. If multi-
    // canvas samples become common we can extend the manifest schema
    // to an array of snapshot configs.

    func testFlexDirectionResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "flexbox-flex-direction-responsive"),
            "responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 900,
            height: 140,
            named: "responsive-wide"
        )
    }
}
