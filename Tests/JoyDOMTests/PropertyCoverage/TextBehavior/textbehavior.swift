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
}
