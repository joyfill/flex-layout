// SizingSnapshotTests — one test method per Sizing property.
// Mirrors the FlexboxSnapshotTests / LayoutSnapshotTests pattern: each
// method iterates JSON samples in `Resources/sizing/<property>/` via
// `assertSnapshotsForSamples(in:)`, producing baselines whose leaf
// filenames mirror the JSON filenames.
//
// Example: `sizing/width/percent.json`
//        → `__Snapshots__/sizing/width/percent.png`
//
// This file ships from the chore/section-3-4-scaffold prep as an empty
// test class so parallel walkers (width, height, min-max) can each add
// their methods without racing to create the file.

import XCTest
import SnapshotTesting
@testable import JoyDOM
import JoyDOMSampleSpecs

final class SizingSnapshotTests: XCTestCase {
    // Walkers append their test methods below as each Sizing property's
    // coverage walk lands.
}
