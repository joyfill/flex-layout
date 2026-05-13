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

    func testPosition() {
        assertSnapshotsForSamples(in: "layout/position")
    }

    /// iOS-only extensions of `position` (`fixed`, `sticky`).
    ///
    /// These values are NOT in the JoyDOM CSS spec (which restricts
    /// `position` to `'absolute' | 'relative'`), but joydom-swift renders
    /// them as `absolute` and emits a warning diagnostic. Kept in a sibling
    /// folder so the iOS code path stays regression-tested without
    /// polluting the cross-platform sample set — JS/Kotlin runtimes won't
    /// implement these and shouldn't compare against the corresponding
    /// baselines.
    func testPositionIosExt() {
        assertSnapshotsForSamples(in: "layout/position-ios-ext")
    }

    /// `position/responsive.json` declares the NARROW canvas (middle box
    /// stays in flow as `position: relative`). The ≥768px breakpoint flips
    /// `#b` to `position: absolute` with `top: 32, left: 200`, detaching it
    /// from the flow. This method captures the wide-viewport branch.
    func testPositionResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "layout-position-responsive"),
            "position responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/layout/position")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 900,
            height: 200,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }

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

    // MARK: - insets (top / left / bottom / right)

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
