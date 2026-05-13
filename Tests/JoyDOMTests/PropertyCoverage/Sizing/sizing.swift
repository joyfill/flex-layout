// SizingSnapshotTests — one test method per Sizing property.
// Mirrors the FlexboxSnapshotTests / LayoutSnapshotTests pattern: each
// method iterates JSON samples in `Resources/sizing/<property>/` via
// `assertSnapshotsForSamples(in:)`, producing baselines whose leaf
// filenames mirror the JSON filenames.
//
// Example: `sizing/width/percent.json`
//        → `__Snapshots__/sizing/width/percent.png`
//
// This file ships from the chore/section-3-4-scaffold prep as an empty
// test class so parallel walkers (width, height, min-max) can each add
// their methods without racing to create the file.

import XCTest
import SnapshotTesting
@testable import JoyDOM
import JoyDOMSampleSpecs

final class SizingSnapshotTests: XCTestCase {
    // Walkers append their test methods below as each Sizing property's
    // coverage walk lands.

    // MARK: - minWidth / maxWidth / minHeight / maxHeight

    func testMinMax() {
        assertSnapshotsForSamples(in: "sizing/min-max")
    }

    /// `sizing/min-max/responsive.json` declares the NARROW canvas
    /// (`minWidth: 60` on each box). The ≥768px breakpoint flips every box's
    /// `minWidth` to `200`, forcing the row to expand across the wide
    /// viewport. This method captures the wide-viewport branch.
    func testMinMaxResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "sizing-min-max-responsive"),
            "min-max responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/sizing/min-max")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 820,
            height: 120,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }
}
