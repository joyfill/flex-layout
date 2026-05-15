// MediaSnapshotTests — one test method per Media property.
// Mirrors the FlexboxSnapshotTests / TypographySnapshotTests pattern: each
// method iterates JSON samples in `Resources/media/<property>/` via
// `assertSnapshotsForSamples(in:)`, producing baselines whose leaf filenames
// mirror the JSON filenames.
//
// Example: `media/object-fit/cover.json`
//        → `__Snapshots__/media/object-fit/cover.png`
//
// NOTE: MediaSnapshotTests is registered in `.github/workflows/ci.yml`'s
// `--skip` list — snapshot tests run locally only.

import XCTest
import SnapshotTesting
@testable import JoyDOM
import JoyDOMSampleSpecs

final class MediaSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Make the spec-samples bundle reachable to `_DOMImage` so any
        // `bundle://<name>` URL in a sample resolves synchronously.
        // Registration is idempotent.
        DOMImageBundleRegistry.register(JoyDOMSampleSpecsBundle.bundle)
    }

    // MARK: - objectFit

    func testObjectFit() {
        assertSnapshotsForSamples(in: "media/object-fit")
    }

    /// iOS-only extensions of `objectFit`. The JoyDOM cross-platform
    /// spec lists 4 values (`fill | contain | cover | none`); CSS Image
    /// Module Level 3 adds `scale-down`, which `Style.ObjectFit`
    /// currently doesn't model. The sample lives here so iOS regression
    /// coverage is preserved when the Swift enum + cross-platform spec
    /// catch up.
    func testObjectFitIosExt() {
        assertSnapshotsForSamples(in: "media/object-fit-ios-ext")
    }

    /// Wide-viewport companion to `media/object-fit/responsive.json`.
    /// Narrow renders `contain`; at width>=768px flips to `cover`.
    func testObjectFitResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "media-object-fit-responsive"),
            "responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/media/object-fit")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 820,
            height: 200,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }

    // MARK: - objectPosition

    func testObjectPosition() {
        assertSnapshotsForSamples(in: "media/object-position")
    }

    /// Wide-viewport companion to `media/object-position/responsive.json`.
    /// Narrow renders `top-left`; at width>=768px flips to `bottom-right`.
    func testObjectPositionResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "media-object-position-responsive"),
            "responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/media/object-position")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 820,
            height: 320,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }
}
