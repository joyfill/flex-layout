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

    // MARK: - borderStyle

    /// CSS spec coverage for `borderStyle` (`'solid' | 'none'`).
    func testBorderStyle() {
        assertSnapshotsForSamples(in: "boxmodel/border-style")
    }

    /// iOS-only extensions of `borderStyle` (`dashed`, `dotted`, `double`).
    ///
    /// These values are NOT in the JoyDOM CSS spec (which restricts
    /// `borderStyle` to `'solid' | 'none'`), but joydom-swift renders them
    /// via SwiftUI `StrokeStyle` dash arrays (`dashed`, `dotted`) and a
    /// pair of concentric strokes (`double`). Kept in a sibling folder so
    /// the iOS code path stays regression-tested without polluting the
    /// cross-platform sample set — JS/Kotlin runtimes won't implement
    /// these and shouldn't compare against the corresponding baselines.
    func testBorderStyleIosExt() {
        assertSnapshotsForSamples(in: "boxmodel/border-style-ios-ext")
    }

    /// Wide-viewport companion to `boxmodel/border-style/responsive.json`.
    /// Narrow viewport renders `borderStyle: solid`; the `>=768px`
    /// breakpoint flips `#card` to `borderStyle: none`, suppressing the
    /// stroke even though `borderWidth` and `borderColor` are unchanged.
    func testBorderStyleResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "boxmodel-border-style-responsive"),
            "responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/boxmodel/border-style")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 820,
            height: 140,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }
}
