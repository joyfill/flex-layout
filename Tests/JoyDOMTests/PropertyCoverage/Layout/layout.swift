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

    func testZIndex() {
        assertSnapshotsForSamples(in: "layout/z-index")
    }

    /// Wide-viewport variant of `layout/z-index/responsive.json` — at
    /// width ≥ 768px the breakpoint flips green's zIndex from `1` to `-1`
    /// so red paints on top instead of green.
    func testZIndexResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "layout-z-index-responsive"),
            "responsive zIndex sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/layout/z-index")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 800,
            height: 200,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }
}
