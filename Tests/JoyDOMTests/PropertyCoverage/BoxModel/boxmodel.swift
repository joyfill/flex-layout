// BoxModelSnapshotTests — one test method per Box Model & Visuals property.
// Mirrors the FlexboxSnapshotTests / LayoutSnapshotTests pattern: each
// method iterates JSON samples in `Resources/boxmodel/<property>/` via
// `assertSnapshotsForSamples(in:)`, producing baselines whose leaf
// filenames mirror the JSON filenames.
//
// Example: `boxmodel/background-color/hex.json`
//        → `__Snapshots__/boxmodel/background-color/hex.png`
//
// This file ships from the chore/section-3-4-scaffold prep as an empty
// test class so parallel walkers (backgroundColor, opacity, padding,
// margin, borderWidth, borderColor, borderStyle, borderRadius) can each
// add their methods without racing to create the file.

import XCTest
import SnapshotTesting
@testable import JoyDOM
import JoyDOMSampleSpecs

final class BoxModelSnapshotTests: XCTestCase {
    // Walkers append their test methods below as each Box Model &
    // Visuals property's coverage walk lands.

    func testBorderColor() {
        assertSnapshotsForSamples(in: "boxmodel/border-color")
    }

    /// `border-color/responsive.json` declares the NARROW canvas (red
    /// border). The ≥768px breakpoint flips the border to blue. This
    /// method captures the wide-viewport branch.
    func testBorderColorResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "boxmodel-border-color-responsive"),
            "border-color responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/boxmodel/border-color")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 900,
            height: 140,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }
}
