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

    // MARK: - display

    func testDisplay() {
        assertSnapshotsForSamples(in: "layout/display")
    }

    /// iOS-only extensions of `display` (`block`, `inline`, `inline-block`,
    /// `inline-flex`).
    ///
    /// These values are NOT in the JoyDOM CSS spec (which restricts
    /// `display` to `'flex' | 'none'`), but the underlying iOS resolver
    /// accepts them — `inline-flex` substitutes `flex` + emits a diagnostic,
    /// the others fall through to the engine's default flex behavior. Kept
    /// in a sibling folder so the iOS code path stays regression-tested
    /// without polluting the cross-platform sample set — JS/Kotlin runtimes
    /// won't implement these and shouldn't compare against the corresponding
    /// baselines.
    func testDisplayIosExt() {
        assertSnapshotsForSamples(in: "layout/display-ios-ext")
    }

    /// Wide-viewport companion to `display/responsive.json`: re-renders the
    /// same JSON at 800px to trigger the `>=768px` breakpoint that flips
    /// `#b` to `display: none`. Baseline lands next to `responsive.png` as
    /// `responsive-wide.png`.
    func testDisplayResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "layout-display-responsive"),
            "responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/layout/display")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 800,
            height: 120,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }
}
