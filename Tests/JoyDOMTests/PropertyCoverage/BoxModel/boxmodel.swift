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

    func testBorderWidth() {
        assertSnapshotsForSamples(in: "boxmodel/border-width")
    }

    /// Wide-viewport companion to `boxmodel/border-width/responsive.json`.
    ///
    /// The manifest entry pins the narrow viewport (`320x140`) which renders
    /// the 1px border. This method re-renders the same JSON at the wide
    /// viewport (`800x140`) so the `width>=768px` breakpoint flips borderWidth
    /// to 10px.
    func testBorderWidthResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "boxmodel-border-width-responsive"),
            "responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/boxmodel/border-width")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 800,
            height: 140,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }
}
