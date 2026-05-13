// LayoutSnapshotTests — one test method per Layout & Positioning property.
// Mirrors the FlexboxSnapshotTests pattern: each method iterates JSON
// samples in `Resources/layout/<property>/` via `assertSnapshotsForSamples(in:)`,
// producing baselines whose leaf filenames mirror the JSON filenames.
//
// Example: `layout/position/absolute.json`
//        → `__Snapshots__/layout/position/absolute.png`
//
// Adding a new variant to a property = drop a `<name>.json` under the
// property's directory + add a manifest entry. The next test run
// auto-records the matching baseline. No new test method to write.
//
// This file ships from the chore/layout-section-scaffold prep as an
// empty test class so parallel walkers can each add their methods
// without racing to create the file.

import XCTest
import SnapshotTesting
@testable import JoyDOM
import JoyDOMSampleSpecs

final class LayoutSnapshotTests: XCTestCase {
    // Walkers append their test methods below as each Layout & Positioning
    // property's coverage walk lands.

    /// Insets property family (`top`, `left`, `bottom`, `right`).
    ///
    /// All four properties share a single sample folder. Each sample must
    /// place an absolute- or relative-positioned element using one or more
    /// inset values; non-positioned elements ignore insets entirely.
    func testInsets() {
        assertSnapshotsForSamples(in: "layout/insets")
    }

    /// Wide-viewport branch of `layout/insets/responsive.json`. The sample's
    /// `#a` declares `top: 0, left: 0` at narrow viewports; the ≥768px
    /// breakpoint flips to `top: 40, left: 80`. This method renders the
    /// wide branch.
    func testInsetsResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "layout-insets-responsive"),
            "insets responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/layout/insets")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 900,
            height: 200,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }
}
