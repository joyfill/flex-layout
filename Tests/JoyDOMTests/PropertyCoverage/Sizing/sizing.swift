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

    func testHeight() {
        assertSnapshotsForSamples(in: "sizing/height")
    }

    /// Wide-viewport companion to `sizing/height/responsive.json`.
    ///
    /// Manifest entry pins the narrow viewport (360x140) where the breakpoint
    /// does NOT match so each `.box` is height 80. This method re-renders the
    /// same JSON at the wide viewport (820x260) so the `width>=768px`
    /// breakpoint flips `.box` height to 200.
    func testHeightResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "sizing-height-responsive"),
            "responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/sizing/height")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 820,
            height: 260,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }
}
