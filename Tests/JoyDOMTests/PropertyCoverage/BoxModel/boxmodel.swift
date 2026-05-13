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
}
