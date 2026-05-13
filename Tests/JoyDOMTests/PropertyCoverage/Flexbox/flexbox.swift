// FlexboxSnapshotTests — one test method per Flexbox property. Each
// iterates JSON samples in `Resources/flexbox/<property>/` via the
// generic `assertSnapshotsForSamples(in:)` helper, producing baselines
// whose leaf filenames mirror the JSON filenames.
//
// Example: `flexbox/flex-direction/row.json`
//        → `__Snapshots__/FlexboxSnapshotTests/testFlexDirection.row.png`
//
// Adding a new variant to a property = drop a `<name>.json` under the
// property's directory + add a manifest entry. The next test run
// auto-records the matching baseline. No new test method to write.

import XCTest
import SnapshotTesting
@testable import JoyDOM
import JoyDOMSampleSpecs

final class FlexboxSnapshotTests: XCTestCase {

    func testFlexDirection() {
        assertSnapshotsForSamples(in: "flexbox/flex-direction")
    }

    /// iOS-only extensions of `flexDirection` (`row-reverse`, `column-reverse`).
    ///
    /// These values are NOT in the JoyDOM CSS spec (which restricts
    /// `flexDirection` to `'row' | 'column'`), but the underlying FlexLayout
    /// primitive supports them. Kept in a sibling folder so the iOS code path
    /// stays regression-tested without polluting the cross-platform sample set —
    /// JS/Kotlin runtimes won't implement these and shouldn't compare against
    /// the corresponding baselines.
    func testFlexDirectionIosExt() {
        assertSnapshotsForSamples(in: "flexbox/flex-direction-ios-ext")
    }

    func testFlexGrow() {
        assertSnapshotsForSamples(in: "flexbox/flex-grow")
    }

    func testFlexShrink() {
        assertSnapshotsForSamples(in: "flexbox/flex-shrink")
    }

    func testFlexBasis() {
        assertSnapshotsForSamples(in: "flexbox/flex-basis")
    }

    func testJustifyContent() {
        assertSnapshotsForSamples(in: "flexbox/justify-content")
    }

    func testAlignItems() {
        assertSnapshotsForSamples(in: "flexbox/align-items")
    }

    func testAlignSelf() {
        assertSnapshotsForSamples(in: "flexbox/align-self")
    }

    /// iOS-only extension of `alignSelf` (`baseline`).
    ///
    /// The value is NOT in the JoyDOM CSS spec (which restricts
    /// `alignSelf` to `'auto' | 'flex-start' | 'flex-end' | 'center' | 'stretch'`),
    /// but the underlying FlexLayout primitive supports it. Kept in a sibling
    /// folder so the iOS code path stays regression-tested without polluting
    /// the cross-platform sample set — JS/Kotlin runtimes won't implement it
    /// and shouldn't compare against the corresponding baseline.
    func testAlignSelfIosExt() {
        assertSnapshotsForSamples(in: "flexbox/align-self-ios-ext")
    }

    func testFlexWrap() {
        assertSnapshotsForSamples(in: "flexbox/flex-wrap")
    }

    func testGap() {
        assertSnapshotsForSamples(in: "flexbox/gap")
    }

    func testOrder() {
        assertSnapshotsForSamples(in: "flexbox/order")
    }

    // MARK: - Special case — responsive sample's second viewport
    //
    // `flex-direction/responsive.json` declares the NARROW canvas
    // (which renders the column branch). The breakpoint flip to row
    // needs a second canvas; this method captures that. If multi-
    // canvas samples become common we can extend the manifest schema
    // to an array of snapshot configs.

    func testFlexDirectionResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "flexbox-flex-direction-responsive"),
            "responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        // Land at `__Snapshots__/flexbox/flex-direction/responsive-wide.png`
        // next to its `responsive.png` sibling, using the path-controlled
        // overload so we get an exact filename (no library-inserted
        // `<testName>.<id>.png` suffix dance).
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/flexbox/flex-direction")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 900,
            height: 140,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }

    /// `flex-grow/responsive.json` declares the NARROW canvas (boxes
    /// stay at their fixed 60×60). The ≥768px breakpoint switches the
    /// `.box` class to `flexBasis: 0 + flexGrow: 1`, making the items
    /// stretch to fill. This method captures the wide-viewport branch.
    func testFlexGrowResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "flexbox-flex-grow-responsive"),
            "flex-grow responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/flexbox/flex-grow")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 900,
            height: 120,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }

    /// `flex-shrink/responsive.json` declares the NARROW canvas (3 boxes
    /// at 120px wide each shrink to fit the viewport). The ≥768px
    /// breakpoint flips `.box` to `flexShrink: 0`, letting items keep
    /// their natural 120px width with free space at the end. This method
    /// captures the wide-viewport branch.
    /// `align-self/responsive.json` declares the NARROW canvas (middle child
    /// overrides container alignItems via alignSelf: flex-start). The ≥768px
    /// breakpoint flips the override to `auto`, letting the child inherit the
    /// container's alignItems: flex-end. This method captures the wide branch.
    func testAlignSelfResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "flexbox-align-self-responsive"),
            "align-self responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/flexbox/align-self")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 900,
            height: 140,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }

    func testFlexShrinkResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "flexbox-flex-shrink-responsive"),
            "flex-shrink responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/flexbox/flex-shrink")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 900,
            height: 120,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }
}
