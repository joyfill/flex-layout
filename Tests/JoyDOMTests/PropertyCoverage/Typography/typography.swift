// TypographySnapshotTests — one test method per Typography property.
// Mirrors the FlexboxSnapshotTests / LayoutSnapshotTests / BoxModelSnapshotTests
// / SizingSnapshotTests pattern: each method iterates JSON samples in
// `Resources/typography/<property>/` via `assertSnapshotsForSamples(in:)`,
// producing baselines whose leaf filenames mirror the JSON filenames.
//
// Example: `typography/font-size/medium.json`
//        → `__Snapshots__/typography/font-size/medium.png`
//
// This file ships from the chore/typography-section-scaffold prep as an
// empty test class so the 10 parallel walkers (color, fontFamily, fontSize,
// fontStyle, fontWeight, letterSpacing, lineHeight, textAlign,
// textDecoration, textTransform) can each add their methods without racing
// to create the file.
//
// NOTE: TypographySnapshotTests is registered in `.github/workflows/ci.yml`'s
// `--skip` list — snapshot tests run locally only (see ci.yml's comment block).

import XCTest
import SnapshotTesting
@testable import JoyDOM
import JoyDOMSampleSpecs

final class TypographySnapshotTests: XCTestCase {
    // Walkers append their test methods below as each Typography
    // property's coverage walk lands.

    // MARK: - fontSize

    func testFontSize() {
        assertSnapshotsForSamples(in: "typography/font-size")
    }

    /// Wide-viewport companion to `typography/font-size/responsive.json`.
    ///
    /// The manifest entry pins the narrow viewport (`360x100`) where the
    /// paragraph renders at 14px. This method re-renders the same JSON at
    /// `820x100` so the `width>=768px` breakpoint flips `fontSize` to 32px.
    func testFontSizeResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "typography-font-size-responsive"),
            "responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/typography/font-size")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 820,
            height: 100,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }

    // MARK: - fontStyle

    func testFontStyle() {
        assertSnapshotsForSamples(in: "typography/font-style")
    }

    /// Wide-viewport companion to `typography/font-style/responsive.json`.
    /// Narrow viewport renders `fontStyle: normal`; the `>=768px`
    /// breakpoint flips `#headline` to `fontStyle: italic`, applying
    /// SwiftUI's `.italic()` font modifier.
    func testFontStyleResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "typography-font-style-responsive"),
            "responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/typography/font-style")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 820,
            height: 100,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }
}
