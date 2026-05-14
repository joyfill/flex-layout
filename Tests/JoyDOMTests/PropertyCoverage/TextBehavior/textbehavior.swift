// TextBehaviorSnapshotTests — one test method per Text Behavior property.
// Mirrors the FlexboxSnapshotTests / TypographySnapshotTests pattern: each
// method iterates JSON samples in `Resources/textbehavior/<property>/` via
// `assertSnapshotsForSamples(in:)`, producing baselines whose leaf filenames
// mirror the JSON filenames.
//
// Example: `textbehavior/text-overflow/ellipsis.json`
//        → `__Snapshots__/textbehavior/text-overflow/ellipsis.png`
//
// This file ships from the chore/textbehavior-media-section-scaffold prep
// as an empty test class so parallel walkers (textOverflow, whiteSpace) can
// each add their methods without racing to create the file.
//
// NOTE: TextBehaviorSnapshotTests is registered in `.github/workflows/ci.yml`'s
// `--skip` list — snapshot tests run locally only.

import XCTest
import SnapshotTesting
@testable import JoyDOM
import JoyDOMSampleSpecs

final class TextBehaviorSnapshotTests: XCTestCase {
    // Walkers append their test methods below as each Text Behavior
    // property's coverage walk lands.

    // MARK: - whiteSpace

    func testWhiteSpace() {
        assertSnapshotsForSamples(in: "textbehavior/white-space")
    }

    /// Wide-viewport companion to `textbehavior/white-space/responsive.json`.
    /// Narrow viewport renders `whiteSpace: normal` (text wraps). The
    /// `width>=768px` breakpoint flips to `whiteSpace: nowrap`, forcing the
    /// paragraph onto a single line that overflows the 200px frame.
    func testWhiteSpaceResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "textbehavior-white-space-responsive"),
            "responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/textbehavior/white-space")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 820,
            height: 120,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }

    // MARK: - textOverflow

    func testTextOverflow() {
        assertSnapshotsForSamples(in: "textbehavior/text-overflow")
    }

    /// Wide-viewport companion to `textbehavior/text-overflow/responsive.json`.
    /// Narrow viewport renders `textOverflow: clip` (and `width: 200`); the
    /// `>=768px` breakpoint widens the frame to 320 and flips to
    /// `textOverflow: ellipsis`, so the truncated tail collapses to U+2026.
    func testTextOverflowResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "textbehavior-text-overflow-responsive"),
            "responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/textbehavior/text-overflow")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 820,
            height: 80,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }
}
