// MediaSnapshotTests — one test method per Media property.
// Mirrors the FlexboxSnapshotTests / TypographySnapshotTests pattern: each
// method iterates JSON samples in `Resources/media/<property>/` via
// `assertSnapshotsForSamples(in:)`, producing baselines whose leaf filenames
// mirror the JSON filenames.
//
// Example: `media/object-fit/cover.json`
//        → `__Snapshots__/media/object-fit/cover.png`
//
// This file ships from the chore/textbehavior-media-section-scaffold prep
// as an empty test class so parallel walkers (objectFit, objectPosition) can
// each add their methods without racing to create the file.
//
// NOTE: MediaSnapshotTests is registered in `.github/workflows/ci.yml`'s
// `--skip` list — snapshot tests run locally only.

import XCTest
import SnapshotTesting
@testable import JoyDOM
import JoyDOMSampleSpecs

final class MediaSnapshotTests: XCTestCase {
    // Walkers append their test methods below as each Media property's
    // coverage walk lands.

    // MARK: - objectFit

    func testObjectFit() {
        assertSnapshotsForSamples(in: "media/object-fit")
    }

    /// Wide-viewport companion to `media/object-fit/responsive.json`.
    /// Narrow viewport renders `objectFit: contain`; the `>=768px`
    /// breakpoint flips to `cover`, exercising the responsive cascade
    /// path on the object-fit env value.
    func testObjectFitResponsiveWide() throws {
        let sample = try XCTUnwrap(
            SpecPropertySamples.sample(withID: "media-object-fit-responsive"),
            "objectFit responsive sample missing from JoyDOMSampleSpecs bundle"
        )
        let testFileDir = ((#filePath) as NSString).deletingLastPathComponent
        let snapshotDir = (testFileDir as NSString)
            .appendingPathComponent("__Snapshots__/media/object-fit")
        assertJoyDOMSnapshot(
            json: sample.json,
            viewportWidth: 820,
            height: 160,
            snapshotDirectory: snapshotDir,
            snapshotName: "responsive-wide"
        )
    }
}
