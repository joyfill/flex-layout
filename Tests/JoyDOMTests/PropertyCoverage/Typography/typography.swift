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

    func testLetterSpacing() {
        assertSnapshotsForSamples(in: "typography/letter-spacing")
    }

    /// Wide-viewport companion to `typography/letter-spacing/responsive.json`.
    ///
    /// The manifest entry pins the narrow viewport (`400x120`) which renders
    /// `letterSpacing: 0px` (tight). This method re-renders the same JSON at
    /// the wide viewport (`820x120`) so the `width>=768px` breakpoint flips
    /// `letterSpacing` to `6px` — visibly wider tracking on the same line.
    func testLetterSpacingResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "typography-letter-spacing-responsive"),
            "letter-spacing responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/typography/letter-spacing")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 820,
            height: 120,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }
}
