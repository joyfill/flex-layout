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

    func testOverflow() {
        assertSnapshotsForSamples(in: "layout/overflow")
    }

    /// Second snapshot of the `responsive` sample, rendered at a viewport
    /// width past the `>=480px` breakpoint to capture the alternate
    /// (`overflow: visible`) layout.
    func testOverflowResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "layout-overflow-responsive"),
            "responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/layout/overflow")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 600,
            height: 260,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }
}
