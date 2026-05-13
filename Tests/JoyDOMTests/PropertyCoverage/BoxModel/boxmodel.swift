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

    /// Renders every sample under `boxmodel/opacity/` and snapshots it
    /// to a leaf matching the JSON basename (e.g. `half.json` → `half.png`).
    func testOpacity() {
        assertSnapshotsForSamples(in: "boxmodel/opacity")
    }

    /// `boxmodel/opacity/responsive.json` declares the NARROW canvas
    /// where `.box` resolves to `opacity: 0.25`. At ≥768px the breakpoint
    /// flips `.box` to `opacity: 1`. This second snapshot renders the
    /// same JSON at a wide viewport to capture the breakpoint flip.
    func testOpacityResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "boxmodel-opacity-responsive"),
            "opacity responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/boxmodel/opacity")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 900,
            height: 100,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }

    func testBorderRadius() {
        assertSnapshotsForSamples(in: "boxmodel/border-radius")
    }

    /// Wide-viewport companion to `responsive.json`. Re-renders the same JSON
    /// at viewport 800×120 to trigger the `width >= 768px` breakpoint that
    /// swaps borderRadius from 4px → 32px.
    func testBorderRadiusResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "boxmodel-border-radius-responsive"),
            "responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/boxmodel/border-radius")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 800,
            height: 120,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }

    func testPadding() {
        assertSnapshotsForSamples(in: "boxmodel/padding")
    }

    /// `boxmodel/padding/responsive.json` declares the NARROW canvas (padding 8).
    /// The >=768px breakpoint flips `#root` to `padding: 32`. This method
    /// captures the wide-viewport branch.
    func testPaddingResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "boxmodel-padding-responsive"),
            "padding responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/boxmodel/padding")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 900,
            height: 140,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }

    // MARK: - margin

    func testMargin() {
        assertSnapshotsForSamples(in: "boxmodel/margin")
    }

    /// `margin/responsive.json` declares the NARROW canvas (margin: 4 on
    /// each item). The ≥768px breakpoint flips `.tile` to `margin: 16`,
    /// visibly enlarging the inter-item spacing. This method captures the
    /// wide-viewport branch.
    func testMarginResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "boxmodel-margin-responsive"),
            "margin responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/boxmodel/margin")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 900,
            height: 180,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }

    // MARK: - borderColor

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
