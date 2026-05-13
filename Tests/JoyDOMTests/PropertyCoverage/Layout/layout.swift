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

    func testBoxSizing() {
        assertSnapshotsForSamples(in: "layout/box-sizing")
    }

    /// Wide-viewport companion to `layout/box-sizing/responsive.json`.
    ///
    /// The manifest entry pins the narrow viewport (`360x200`) which renders
    /// the default content-box mode. This method re-renders the same JSON at
    /// the wide viewport (`820x200`) so the `width>=768px` breakpoint flips
    /// `boxSizing` to `border-box` — the same outer width 120 now includes
    /// padding+border inside.
    func testBoxSizingResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "layout-box-sizing-responsive"),
            "responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/layout/box-sizing")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 820,
            height: 200,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }
}
